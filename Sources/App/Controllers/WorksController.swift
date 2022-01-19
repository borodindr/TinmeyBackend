//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Vapor
import Fluent
import TinmeyCore

struct WorksController: RouteCollection {
    let imageFolder = "WorkImages"
    
    func boot(routes: RoutesBuilder) throws {
        let worksRoutes = routes.grouped("api", ":workType")
        worksRoutes.get(use: getAllHandler)
        worksRoutes.get(":workID", use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = worksRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":workID", use: deleteHandler)
        tokenAuthGroup.put(":workID", use: updateHandler)
        tokenAuthGroup.put(":workID", "reorder", ":direction", use: reorderHandler)
        
        let imagesGroup = routes.grouped("api", "work_images")
        imagesGroup.get(use: getAllImages)
        imagesGroup.get(":imageID", use: downloadImageHandler)
        let tokenAuthImagesGroup = imagesGroup.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthImagesGroup.on(.POST, ":imageID", body: .collect(maxSize: "10mb"), use: addImageHandler)
        tokenAuthImagesGroup.delete(":imageID", use: deleteImageHandler)
        
        // For preview
        worksRoutes.get("preview", "firstImage", use: downloadFirstPreviewImageHandler)
        worksRoutes.get("preview", "secondImage", use: downloadSecondPreviewImageHandler)
    }
    
    // TEMP
    func getAllImages(_ req: Request) -> EventLoopFuture<[WorkImage]> {
        WorkImage.query(on: req.db).all()
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[WorkAPIModel]> {
        let type = try Work.WorkType.detect(from: req)
        return Work.query(on: req.db)
            .filter(\.$type == type)
            .sort(\.$sortIndex, .descending)
            .all()
            .convertToAPIModel(on: req.db)
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToAPIModel(on: req.db)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        let type = try Work.WorkType.detect(from: req)
        return try req.content
            .decode(WorkAPIModel.Create.self)
            .create(on: req, type: type)
            .convertToAPIModel(on: req.db)
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { work -> EventLoopFuture<Int> in
                let sortIndex = work.sortIndex
                return [Tag.deleteAll(from: work, on: req),
                        work.deleteImages(on: req)]
                    .flatten(on: req.eventLoop)
                    .flatMap {
                        work.delete(on: req.db)
                    }
                    .map { sortIndex }
            }
            .flatMap { deletedSortIndex in
                // Reorder other works
                Work.query(on: req.db)
                    .filter(\.$sortIndex > deletedSortIndex)
                    .all()
                    .flatMapEach(on: req.eventLoop) { workToUpdate in
                        workToUpdate.sortIndex -= 1
                        return workToUpdate.save(on: req.db)
                    }
            }
            .transform(to: .noContent)
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        let updatedWorkData = try req.content.decode(WorkAPIModel.Create.self)
        
        return Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { work in
                work.title = updatedWorkData.title
                work.description = updatedWorkData.description
                work.seeMoreLink = updatedWorkData.seeMoreLink?.absoluteString
                work.bodyIndex = updatedWorkData.bodyIndex
                return work.save(on: req.db)
                    .flatMap {
                        Tag.update(to: updatedWorkData.tags, in: work, on: req)
                    }
                    .flatMap {
                        work.updateImages(to: updatedWorkData.images, on: req)
                    }
                    .flatMap { work.convertToAPIModel(on: req.db) }
            }
    }
    
    func reorderHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        guard let directionRawValue = req.parameters.get("direction"),
              let direction = WorkAPIModel.ReorderDirection(rawValue: directionRawValue) else {
            throw Abort(.badRequest, reason: "Wrong direction type")
        }
        
        switch direction {
        case .forward:
            return try reorderWorkForward(req)
        case .backward:
            return try reorderWorkBackward(req)
        }
    }
    
    private func reorderWorkForward(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { workToReorder in
                // find work, which is at new index
                Work.query(on: req.db)
                    .filter(\.$sortIndex == workToReorder.sortIndex + 1)
                    .first()
                    .unwrap(or: Abort(.badRequest, reason: "Unable to move work forward because it is already first."))
                    .map { workAtNewIndex -> [Work] in
                        workToReorder.sortIndex += 1
                        workAtNewIndex.sortIndex -= 1
                        return [workToReorder, workAtNewIndex]
                    }
                    .flatMapEach(on: req.eventLoop) { work in
                        work.save(on: req.db)
                    }
                    .flatMap { workToReorder.convertToAPIModel(on: req.db) }
            }
    }
    
    private func reorderWorkBackward(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { workToReorder in
                // find work, which is at new index
                Work.query(on: req.db)
                    .filter(\.$sortIndex == workToReorder.sortIndex - 1)
                    .first()
                    .unwrap(or: Abort(.badRequest, reason: "Unable to move work backward because it is already last."))
                    .map { workAtNewIndex -> [Work] in
                        workToReorder.sortIndex -= 1
                        workAtNewIndex.sortIndex += 1
                        return [workToReorder, workAtNewIndex]
                    }
                    .flatMapEach(on: req.eventLoop) { work in
                        work.save(on: req.db)
                    }
                    .flatMap { workToReorder.convertToAPIModel(on: req.db) }
            }
    }
    
    func addImageHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let data = try req.content.decode(FileUploadData.self)
        let filename = data.file.filename
        try data.validateImageExtension()
        
        return WorkImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { image in
                let path: [String]
                do {
                    path = try FilePathBuilder().workImagePath(for: image)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
                return req.fileHandler.upload(data.file.data, named: filename, at: path)
                    .flatMap {
                        image.name = filename
                        return image.save(on: req.db).map { .created }
                    }
            }
    }
    
    func deleteImageHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        WorkImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { image in
                guard let filename = image.name else {
                    let error =  Abort(.notFound)
                    return req.eventLoop.makeFailedFuture(error)
                }
                let path: [String]
                do {
                    path = try FilePathBuilder().workImagePath(for: image)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
                return req.fileHandler.delete(filename, at: path)
                    .flatMap {
                        image.name = nil
                        return image.save(on: req.db)
                    }
            }
            .map { .noContent }
    }
    
    func downloadImageHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        WorkImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { image in
                guard let filename = image.name else {
                    let reason = "Image '\(image.id?.uuidString ?? "-")' is empty"
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: reason))
                }
                let path: [String]
                do {
                    path = try FilePathBuilder().workImagePath(for: image)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
                return req.fileHandler.download(filename, at: path)
            }
    }
    
}

private extension WorksController {
    func downloadFirstPreviewImageHandler(_ req: Request) throws -> Response {
        downloadPreviewImage(.firstImage, req: req)
    }
    
    func downloadSecondPreviewImageHandler(_ req: Request) throws -> Response {
        downloadPreviewImage(.secondImage, req: req)
    }
    
    func downloadPreviewImage(_ imageType: ImageType, req: Request) -> Response {
        let imageName = "Work-(PREVIEW)-\(imageType.rawValue).png"
        let path = req.application.directory.workingDirectory + imageFolder + "/" + imageName
        return req.fileio.streamFile(at: path)
    }
    
}

private extension WorksController {
    func workType(from req: Request) throws -> Work.WorkType {
        guard let typeKey = req.query[String.self, at: "type"],
              let type = Work.WorkType(rawValue: typeKey) else {
            throw Abort(.badRequest, reason: "Work type should be passed as query parameter: 'type={typeKey}'")
        }
        return type
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Vapor
import Fluent
import FluentSQL
import FluentPostgresDriver
import TinmeyCore

struct WorksController: RouteCollection {
    let imageFolder = "WorkImages/"
    
    enum ImageType: String, CaseIterable {
        case firstImage, secondImage
        
        var description: String {
            switch self {
            case .firstImage:
                return "first image"
            case .secondImage:
                return "second image"
            }
        }
    }
    
    func boot(routes: RoutesBuilder) throws {
        let worksRoutes = routes.grouped("api", "works")
        worksRoutes.get(use: getAllHandler)
        worksRoutes.get(":workID", use: getHandler)
        worksRoutes.post(use: createHandler)
        worksRoutes.delete(":workID", use: deleteHandler)
        worksRoutes.put(":workID", use: updateHandler)
        worksRoutes.put(":workID", "reorder", ":direction", use: reorderHandler)
        ImageType.allCases.forEach { imageType in
            worksRoutes.on(.POST, ":workID", "\(imageType.rawValue)", body: .collect(maxSize: "10mb"), use: {
                try addImageHandler($0, imageType: imageType)
            })
            worksRoutes.get(":workID", "\(imageType.rawValue)", use: {
                try downloadImageHandler($0, imageType: imageType)
            })
        }
        
        // For preview
        worksRoutes.get("preview", "firstImage", use: downloadFirstPreviewImageHandler)
        worksRoutes.get("preview", "secondImage", use: downloadSecondPreviewImageHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[WorkAPIModel]> {
        let type = try workType(from: req)
        return Work.query(on: req.db)
            .filter(\.$type == type)
            .sort(\.$sortIndex, .descending)
            .all()
            .flatMapEachThrowing { work in
                try WorkAPIModel(work)
            }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { work in
                try WorkAPIModel(work)
            }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<WorkAPIModel> {
        let data = try req.content.decode(WorkAPIModel.Create.self)
        
        return Work.query(on: req.db)
            .filter(\.$type == data.type)
            .sort(\.$sortIndex, .descending)
            .first()
            .map { lastWork in
                if let lastWork = lastWork {
                    return lastWork.sortIndex + 1
                } else {
                    return 0
                }
            }
            .map { data.makeWork(sortIndex: $0) }
            .flatMap { newWork in
                newWork.save(on: req.db)
                    .flatMapThrowing {
                        try WorkAPIModel(newWork)
                    }
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { workToDelete in
                workToDelete.delete(on: req.db)
                    .flatMap { _ in
                        Work.query(on: req.db)
                            .filter(\.$sortIndex > workToDelete.sortIndex)
                            .all()
                    }
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
                work.type = updatedWorkData.type
                work.title = updatedWorkData.title
                work.description = updatedWorkData.description
                return work.save(on: req.db)
                    .flatMapThrowing {
                        try WorkAPIModel(work)
                    }
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
                    .map { _ in workToReorder }
                    .flatMapThrowing { try WorkAPIModel($0) }
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
                    .map { _ in workToReorder }
                    .flatMapThrowing { try WorkAPIModel($0) }
            }
    }
    
    func addImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<HTTPStatus> {
        let data = try req.content.decode(ImageUploadData.self)
        
        guard let fileExtension = data.picture.extension,
              ["png", "jpg", "jpeg"].contains(fileExtension.lowercased()) else {
            return req.eventLoop.future(error: Abort(.badRequest, reason: "File extension should be png, jpg or jpeg"))
        }
        
        return Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { work in
                let workID: UUID
                do {
                    workID = try work.requireID()
                } catch {
                    return req.eventLoop.future(error: error)
                }
                let name = "Work-(\(workID))-\(imageType.rawValue).\(fileExtension)"
                let path = req.application.directory.workingDirectory + imageFolder + name
                
                return req.fileio
                    .writeFile(data.picture.data, at: path)
                    .flatMap {
                        switch imageType {
                        case .firstImage:
                            work.firstImageName = name
                        case .secondImage:
                            work.secondImageName = name
                        }
                        return work.save(on: req.db)
                            .map { .created }
                    }
            }
    }
    
    func downloadImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<Response> {
        guard let workID: UUID = req.parameters.get("workID") else {
            throw Abort(.badRequest, reason: "Work ID was was not passed")
        }
        return Work.find(workID, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "Work with ID \(workID) not found."))
            .flatMapThrowing { work in
                try imageName(for: imageType, from: work)
            }
            .map { imageName in
                let path = req.application.directory.workingDirectory + imageFolder + imageName
                return req.fileio.streamFile(at: path)
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
        let path = req.application.directory.workingDirectory + imageFolder + imageName
        return req.fileio.streamFile(at: path)
    }
    
}

private extension WorksController {
    func workType(from req: Request) throws -> WorkType {
        guard let typeKey = req.query[String.self, at: "type"],
              let type = WorkType(rawValue: typeKey) else {
            throw Abort(.badRequest, reason: "Work type should be passed as query parameter: 'type={typeKey}'")
        }
        return type
    }
    
    func imageName(for imageType: ImageType, from work: Work) throws -> String {
        let name: String?
        switch imageType {
        case .firstImage:
            name = work.firstImageName
        case .secondImage:
            name = work.secondImageName
        }
        
        guard let imageName = name else {
            let reason = "Work has no \(imageType.description)."
            let error = Abort(.notFound, reason: reason)
            throw error
        }
        return imageName
    }
}

struct ImageUploadData: Content {
    var picture: File
}
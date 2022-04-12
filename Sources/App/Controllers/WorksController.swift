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
        let worksRoutes = routes.grouped("api", "works")
        worksRoutes.get(use: getAllHandler)
        worksRoutes.get(":workID", use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = worksRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":workID", use: deleteHandler)
        tokenAuthGroup.put(":workID", use: updateHandler)
        tokenAuthGroup.put(":workID", "move", ":newReversedIndex", use: moveHandler)
        tokenAuthGroup.put(":workID", "reorder", ":direction", use: reorderHandler)
        
        let imagesGroup = worksRoutes.grouped("images")
        imagesGroup.get(":imageID", use: downloadImageHandler)
        let tokenAuthImagesGroup = imagesGroup.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthImagesGroup.on(.POST, ":imageID", body: .collect(maxSize: "10mb"), use: addImageHandler)
        tokenAuthImagesGroup.delete(":imageID", use: deleteImageHandler)
        
        // For preview
        worksRoutes.get("preview", "firstImage", use: downloadFirstPreviewImageHandler)
        worksRoutes.get("preview", "secondImage", use: downloadSecondPreviewImageHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [WorkAPIModel] {
        let query = Work.query(on: req.db).sort(\.$sortIndex, .descending)
        let works = try await query.all()
        return try await works.convertToAPIModel(on: req.db)
    }
    
    func getHandler(_ req: Request) async throws -> WorkAPIModel {
        guard let work = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await work.convertToAPIModel(on: req.db)
    }
    
    func createHandler(_ req: Request) async throws -> WorkAPIModel {
        let createWork = try req.content.decode(WorkAPIModel.Create.self)
        let work = try await createWork.create(on: req.db)
        return try await work.convertToAPIModel(on: req.db)
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let work = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let sortIndex = work.sortIndex
        try await Tag.deleteAll(from: work, on: req.db)
        try await work.deleteImages(on: req.db, fileHandler: req.fileHandler)
        try await work.delete(on: req.db)
        let worksToUpdateQuery = Work.query(on: req.db).filter(\.$sortIndex > sortIndex)
        let worksToUpdate = try await worksToUpdateQuery.all()
        
        for work in worksToUpdate {
            work.sortIndex -= 1
            try await work.save(on: req.db)
        }
        
        return .noContent
    }
    
    func updateHandler(_ req: Request) async throws -> WorkAPIModel {
        let updatedWorkData = try req.content.decode(WorkAPIModel.Create.self)
        guard let work = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        work.title = updatedWorkData.title
        work.description = updatedWorkData.description
        try await work.save(on: req.db)
        try await Tag.update(to: updatedWorkData.tags, in: work, on: req.db)
        try await work.updateImages(to: updatedWorkData.images, on: req.db, fileHandler: req.fileHandler)
        return try await work.convertToAPIModel(on: req.db)
    }
    
    func moveHandler(_ req: Request) async throws -> WorkAPIModel {
        guard let newReversedIndex: Int = req.parameters.get("newReversedIndex") else {
            throw Abort(.badRequest, reason: "New index not found")
        }
        guard let workToReorder = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        // reverse index
        let worksCount = try await Work.query(on: req.db).count()
        let newIndex = worksCount - newReversedIndex - 1
        
        guard newIndex >= 0 && newIndex < worksCount else {
            throw Abort(.badRequest, reason: "New index is out of bounds")
        }
        
        guard workToReorder.sortIndex != newIndex else {
            return try await workToReorder.convertToAPIModel(on: req.db)
        }
        
        let oldIndex = workToReorder.sortIndex
        
        if newIndex < oldIndex {
            let worksToShift = try await Work.query(on: req.db)
                .group { group in
                    group
                        .filter(\.$sortIndex >= newIndex)
                        .filter(\.$sortIndex < oldIndex)
                }
                .all()
            for work in worksToShift {
                work.sortIndex += 1
                try await work.save(on: req.db)
            }
        } else {
            let worksToShift = try await Work.query(on: req.db)
                .group { group in
                    group
                        .filter(\.$sortIndex > oldIndex)
                        .filter(\.$sortIndex <= newIndex)
                }
                .all()
            for work in worksToShift {
                work.sortIndex -= 1
                try await work.save(on: req.db)
            }
        }
        
        workToReorder.sortIndex = newIndex
        try await workToReorder.save(on: req.db)
        
        return try await workToReorder.convertToAPIModel(on: req.db)
    }
    
    func reorderHandler(_ req: Request) async throws -> WorkAPIModel {
        guard let directionRawValue = req.parameters.get("direction"),
              let direction = ReorderDirectionAPIModel(rawValue: directionRawValue) else {
            throw Abort(.badRequest, reason: "Wrong direction type")
        }
        
        switch direction {
        case .forward:
            return try await reorderWorkForward(req)
        case .backward:
            return try await reorderWorkBackward(req)
        }
    }
    
    private func reorderWorkForward(_ req: Request) async throws -> WorkAPIModel {
        guard let workToReorder = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let nextWorkQuery = Work.query(on: req.db).filter(\.$sortIndex == workToReorder.sortIndex + 1)
        guard let nextWork = try await nextWorkQuery.first() else {
            let reason = "Unable to move work forward because it is already first."
            throw Abort(.badRequest, reason: reason)
        }
        workToReorder.sortIndex += 1
        nextWork.sortIndex -= 1
        try await workToReorder.save(on: req.db)
        try await nextWork.save(on: req.db)
        return try await workToReorder.convertToAPIModel(on: req.db)
    }
    
    private func reorderWorkBackward(_ req: Request) async throws -> WorkAPIModel {
        guard let workToReorder = try await Work.find(req.parameters.get("workID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let previousWorkQuery = Work.query(on: req.db).filter(\.$sortIndex == workToReorder.sortIndex - 1)
        guard let previousWork = try await previousWorkQuery.first() else {
            let reason = "Unable to move work backward because it is already last."
            throw Abort(.badRequest, reason: reason)
        }
        workToReorder.sortIndex -= 1
        previousWork.sortIndex += 1
        try await workToReorder.save(on: req.db)
        try await previousWork.save(on: req.db)
        return try await workToReorder.convertToAPIModel(on: req.db)
    }
    
    func addImageHandler(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(FileUploadData.self)
        let filename = data.file.filename
        try data.validateImageExtension()
        guard let image = try await WorkImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let path = try FilePathBuilder().workImagePath(for: image)
        try await req.fileHandler.upload(data.file.data, named: filename, at: path)
        image.name = filename
        try await image.save(on: req.db)
        return .created
    }
    
    func deleteImageHandler(_ req: Request) async throws -> HTTPStatus {
        guard let image = try await WorkImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let filename = image.name else {
            throw Abort(.notFound)
        }
        let path = try FilePathBuilder().workImagePath(for: image)
        try await req.fileHandler.delete(filename, at: path)
        image.name = nil
        try await image.save(on: req.db)
        return .noContent
    }
    
    func downloadImageHandler(_ req: Request) async throws -> Response {
        guard let image = try await WorkImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let filename = image.name else {
            let reason = "Image '\(image.id?.uuidString ?? "-")' is empty"
            throw Abort(.notFound, reason: reason)
        }
        let path = try FilePathBuilder().workImagePath(for: image)
        return try await req.fileHandler.download(filename, at: path)
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

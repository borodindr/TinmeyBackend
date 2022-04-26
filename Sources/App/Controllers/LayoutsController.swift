//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.04.2022.
//

import Vapor
import Fluent
import TinmeyCore

struct LayoutsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let layoutsRoutes = routes.grouped("api", "layouts")
        layoutsRoutes.get(use: getAllHandler)
        layoutsRoutes.get(":layoutID", use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = layoutsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":layoutID", use: deleteHandler)
        tokenAuthGroup.put(":layoutID", use: updateHandler)
        tokenAuthGroup.put(":layoutID", "move", ":newReversedIndex", use: moveHandler)
        
        let imagesGroup = layoutsRoutes.grouped("images")
        let tokenAuthImagesGroup = imagesGroup.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthImagesGroup.on(.POST, ":imageID", body: .collect(maxSize: "10mb"), use: addImageHandler)
        tokenAuthImagesGroup.delete(":imageID", use: deleteImageHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [LayoutAPIModel] {
        let query = Layout.query(on: req.db).sort(\.$sortIndex, .descending)
        let layouts = try await query.all()
        return try await layouts.convertToAPIModel(on: req.db)
    }
    
    func getHandler(_ req: Request) async throws -> LayoutAPIModel {
        guard let layout = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await layout.convertToAPIModel(on: req.db)
    }
    
    func createHandler(_ req: Request) async throws -> LayoutAPIModel {
        let createLayout = try req.content.decode(LayoutAPIModel.Create.self)
        let layout = try await createLayout.create(on: req.db)
        return try await layout.convertToAPIModel(on: req.db)
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let layout = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let sortIndex = layout.sortIndex
        try await layout.deleteImages(on: req.db, attachmentHandler: req.attachmentHandler)
        try await layout.delete(on: req.db)
        let layoutsToUpdateQuery = Layout.query(on: req.db).filter(\.$sortIndex > sortIndex)
        let layoutsToUpdate = try await layoutsToUpdateQuery.all()
        
        for layout in layoutsToUpdate {
            layout.sortIndex -= 1
            try await layout.save(on: req.db)
        }
        
        return .noContent
    }
    
    func updateHandler(_ req: Request) async throws -> LayoutAPIModel {
        let updatedLayoutData = try req.content.decode(LayoutAPIModel.Create.self)
        guard let layout = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        layout.title = updatedLayoutData.title
        layout.description = updatedLayoutData.description
        try await layout.save(on: req.db)
        try await layout.updateImages(to: updatedLayoutData.images, on: req.db, attachmentHandler: req.attachmentHandler)
        return try await layout.convertToAPIModel(on: req.db)
    }
    
    func moveHandler(_ req: Request) async throws -> LayoutAPIModel {
        guard let newReversedIndex: Int = req.parameters.get("newReversedIndex") else {
            throw Abort(.badRequest, reason: "New index not found")
        }
        guard let layoutToReorder = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        // reverse index
        let layoutsCount = try await Layout.query(on: req.db).count()
        let newIndex = layoutsCount - newReversedIndex - 1
        
        guard newIndex >= 0 && newIndex < layoutsCount else {
            throw Abort(.badRequest, reason: "New index is out of bounds")
        }
        
        guard layoutToReorder.sortIndex != newIndex else {
            return try await layoutToReorder.convertToAPIModel(on: req.db)
        }
        
        let oldIndex = layoutToReorder.sortIndex
        
        if newIndex < oldIndex {
            let layoutsToShift = try await Layout.query(on: req.db)
                .group { group in
                    group
                        .filter(\.$sortIndex >= newIndex)
                        .filter(\.$sortIndex < oldIndex)
                }
                .all()
            for layout in layoutsToShift {
                layout.sortIndex += 1
                try await layout.save(on: req.db)
            }
        } else {
            let layoutsToShift = try await Layout.query(on: req.db)
                .group { group in
                    group
                        .filter(\.$sortIndex > oldIndex)
                        .filter(\.$sortIndex <= newIndex)
                }
                .all()
            for layout in layoutsToShift {
                layout.sortIndex -= 1
                try await layout.save(on: req.db)
            }
        }
        
        layoutToReorder.sortIndex = newIndex
        try await layoutToReorder.save(on: req.db)
        
        return try await layoutToReorder.convertToAPIModel(on: req.db)
    }
    
    private func reorderLayoutForward(_ req: Request) async throws -> LayoutAPIModel {
        guard let layoutToReorder = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let nextLayoutQuery = Layout.query(on: req.db).filter(\.$sortIndex == layoutToReorder.sortIndex + 1)
        guard let nextLayout = try await nextLayoutQuery.first() else {
            let reason = "Unable to move layout forward because it is already first."
            throw Abort(.badRequest, reason: reason)
        }
        layoutToReorder.sortIndex += 1
        nextLayout.sortIndex -= 1
        try await layoutToReorder.save(on: req.db)
        try await nextLayout.save(on: req.db)
        return try await layoutToReorder.convertToAPIModel(on: req.db)
    }
    
    private func reorderLayoutBackward(_ req: Request) async throws -> LayoutAPIModel {
        guard let layoutToReorder = try await Layout.find(req.parameters.get("layoutID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let previousLayoutQuery = Layout.query(on: req.db).filter(\.$sortIndex == layoutToReorder.sortIndex - 1)
        guard let previousLayout = try await previousLayoutQuery.first() else {
            let reason = "Unable to move layout backward because it is already last."
            throw Abort(.badRequest, reason: reason)
        }
        layoutToReorder.sortIndex -= 1
        previousLayout.sortIndex += 1
        try await layoutToReorder.save(on: req.db)
        try await previousLayout.save(on: req.db)
        return try await layoutToReorder.convertToAPIModel(on: req.db)
    }
    
    func addImageHandler(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(FileUploadData.self)
        let filename = data.file.filename
        try data.validateImageExtension()
        guard let image = try await LayoutImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let attachment = try await req.attachmentHandler.create(from: data.file.data, named: filename)
        
        image.$attachment.id = try attachment.requireID()
        try await image.save(on: req.db)
        
        return .created
    }
    
    func deleteImageHandler(_ req: Request) async throws -> HTTPStatus {
        guard
            let imageID: UUID = req.parameters.get("imageID"),
            let image = try await LayoutImage.find(imageID, on: req.db),
            let attachment = try await image.$attachment.get(on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        try await req.attachmentHandler.delete(attachment)
        image.$attachment.id = nil
        try await image.save(on: req.db)
        return .noContent
    }
}

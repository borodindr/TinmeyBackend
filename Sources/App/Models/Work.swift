//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Vapor
import Fluent
import TinmeyCore

final class Work: Model, Content {
    static var schema = v2021_11_04.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_11_04.sortIndex)
    var sortIndex: Int
    
    @Timestamp(key: v2021_11_04.createdAt, on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: v2021_11_04.updatedAt, on: .update, format: .iso8601)
    var updatedAt: Date?
    
    @Field(key: v2021_11_04.title)
    var title: String
    
    @Field(key: v2021_11_04.description)
    var description: String
    
    @Siblings(through: WorkTagPivot.self, from: \.$work, to: \.$tag)
    var tags: [Tag]
    
    @Children(for: \.$work)
    var images: [WorkImage]
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        title: String,
        description: String
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.description = description
    }
}

extension Work {
    enum LayoutType: String, Content {
        case leftBody
        case middleBody
        case rightBody
        case leftLargeBody
        case rightLargeBody
    }
}

extension Work {
    func deleteImages(on req: Request) -> EventLoopFuture<Void> {
        $images.query(on: req.db)
            .all()
            .flatMapThrowing { images in
                try images.compactMap { image in
                    let path = try FilePathBuilder().workImagePath(for: image)
                    if let imageName = image.name {
                        return req.fileHandler.delete(imageName, at: path)
                    } else {
                        return nil
                    }
                }
            }
            .flatMap { $0.flatten(on: req.eventLoop) }
    }
    
    func deleteImages(on req: Request) async throws {
        try await deleteImages(on: req).get()
    }
    
    func updateImages(to newImages: [WorkAPIModel.Image.Create], on req: Request) -> EventLoopFuture<Void> {
        $images.get(on: req.db)
            .flatMap { images in
                var images = images
                return newImages.enumerated().map { newImageIndex, newImage -> EventLoopFuture<Void> in
                    guard let newImageID = newImage.id else {
                        // New image has no id -> Create new image
                        return WorkImage.add(at: newImageIndex, to: self, on: req)
                    }
                    // New image has id -> updated
                    guard let index = images.firstIndex(where: { $0.id == newImageID }) else {
                        let reason = "Attempted to update image which is not related to the work"
                        let error = Abort(.notFound, reason: reason)
                        return req.eventLoop.makeFailedFuture(error)
                    }
                    // Found saved image with the id
                    let image = images.remove(at: index)
                    if image.sortIndex != newImageIndex {
                        // image was reordered -> update sortIndex and save
                        image.sortIndex = newImageIndex
                        return image.save(on: req.db)
                    }
                    return req.eventLoop.makeSucceededVoidFuture()
                }
                .flatten(on: req.eventLoop)
                .flatMap {
                    guard !images.isEmpty else {
                        return req.eventLoop.makeSucceededVoidFuture()
                    }
                    return images.flatMap { image -> [EventLoopFuture<Void>] in
                        let deleteFileTask: EventLoopFuture<Void>
                        let deleteModelTask = image.delete(on: req.db)
                        let path = try! FilePathBuilder().workImagePath(for: image)
                        if let imageName = image.name {
                            deleteFileTask = req.fileHandler.delete(imageName, at: path)
                        } else {
                            deleteFileTask = req.eventLoop.makeSucceededVoidFuture()
                        }
                        return [deleteFileTask, deleteModelTask]
                    }
                    .flatten(on: req.eventLoop)
                }
                
            }
    }
    
    func updateImages(to newImages: [WorkAPIModel.Image.Create], on req: Request) async throws {
        try await updateImages(to: newImages, on: req).get()
    }
}

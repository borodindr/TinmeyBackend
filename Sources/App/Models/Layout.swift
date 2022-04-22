//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.04.2022.
//

import Vapor
import Fluent
import TinmeyCore

final class Layout: Model, Content {
    static var schema = v2022_04_13.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2022_04_13.sortIndex)
    var sortIndex: Int
    
    @Timestamp(key: v2022_04_13.createdAt, on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: v2022_04_13.updatedAt, on: .update, format: .iso8601)
    var updatedAt: Date?
    
    @Field(key: v2022_04_13.title)
    var title: String
    
    @Field(key: v2022_04_13.description)
    var description: String
    
    @Children(for: \.$layout)
    var images: [LayoutImage]
    
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

extension Layout {
    func deleteImages(
        on database: Database,
        fileHandler: FileHandler
    ) -> EventLoopFuture<Void> {
        $images.query(on: database)
            .all()
            .flatMapThrowing { images in
                try images.compactMap { image in
                    let path = try FilePathBuilder().layoutImagePath(for: image)
                    if let imageName = image.name {
                        return fileHandler.delete(imageName, at: path)
                    } else {
                        return nil
                    }
                }
            }
            .flatMap { $0.flatten(on: database.eventLoop) }
    }
    
    func deleteImages(
        on database: Database,
        fileHandler: FileHandler
    ) async throws {
        try await deleteImages(on: database, fileHandler: fileHandler).get()
    }
    
    func updateImages(
        to newImages: [LayoutAPIModel.Image.Create],
        on database: Database,
        fileHandler: FileHandler
    ) -> EventLoopFuture<Void> {
        $images.get(on: database)
            .flatMap { images in
                var images = images
                return newImages.enumerated().map { newImageIndex, newImage -> EventLoopFuture<Void> in
                    guard let newImageID = newImage.id else {
                        // New image has no id -> Create new image
                        return LayoutImage.add(at: newImageIndex, to: self, on: database)
                    }
                    // New image has id -> updated
                    guard let index = images.firstIndex(where: { $0.id == newImageID }) else {
                        let reason = "Attempted to update image which is not related to the layout"
                        let error = Abort(.notFound, reason: reason)
                        return database.eventLoop.makeFailedFuture(error)
                    }
                    // Found saved image with the id
                    let image = images.remove(at: index)
                    if image.sortIndex != newImageIndex {
                        // image was reordered -> update sortIndex and save
                        image.sortIndex = newImageIndex
                        return image.save(on: database)
                    }
                    return database.eventLoop.makeSucceededVoidFuture()
                }
                .flatten(on: database.eventLoop)
                .flatMap {
                    guard !images.isEmpty else {
                        return database.eventLoop.makeSucceededVoidFuture()
                    }
                    return images.flatMap { image -> [EventLoopFuture<Void>] in
                        let deleteFileTask: EventLoopFuture<Void>
                        let deleteModelTask = image.delete(on: database)
                        let path = try! FilePathBuilder().layoutImagePath(for: image)
                        if let imageName = image.name {
                            deleteFileTask = fileHandler.delete(imageName, at: path)
                        } else {
                            deleteFileTask = database.eventLoop.makeSucceededVoidFuture()
                        }
                        return [deleteFileTask, deleteModelTask]
                    }
                    .flatten(on: database.eventLoop)
                }
                
            }
    }
    
    func updateImages(
        to newImages: [LayoutAPIModel.Image.Create],
        on database: Database,
        fileHandler: FileHandler
    ) async throws {
        try await updateImages(to: newImages, on: database, fileHandler: fileHandler).get()
    }
}


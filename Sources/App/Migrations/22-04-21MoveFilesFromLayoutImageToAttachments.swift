//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.04.2022.
//

import Fluent
import Vapor

struct MoveFilesFromLayoutImageToAttachments: AsyncMigration {
    let application: Application
    
    func prepare(on database: Database) async throws {
        let images = try await LayoutImage.ModelMovingFilesFromLayoutImageToAttachments.query(on: database).all()
        for image in images {
            guard let imageName = image.name else { continue }
            let attachment = Attachment(name: imageName)
            try await attachment.save(on: database)
            
            image.$attachment.id = try attachment.requireID()
            try await image.save(on: database)
            
            let srcPath = ["LayoutImages", image.$layout.id.uuidString, try image.requireID().uuidString]
            let dstPath = ["attachments", try attachment.requireID().uuidString]
            let request = Request(application: application, on: database.eventLoop)
            
            try await request.fileHandler.move(imageName, at: srcPath, to: dstPath)
        }
    }
    
    func revert(on database: Database) async throws {
        let images = try await LayoutImage.query(on: database).all()
        
        for image in images {
            guard let attachment = try await image.$attachment.get(on: database) else { continue }
            
            let srcPath = ["attachments", try attachment.requireID().uuidString]
            let dstPath = ["LayoutImages", image.$layout.id.uuidString, try image.requireID().uuidString]
            let request = Request(application: application, on: database.eventLoop)
            
            try await request.fileHandler.move(attachment.name, at: srcPath, to: dstPath)
            
            image.$attachment.id = nil
            try await image.save(on: database)
            
            try await attachment.delete(on: database)
        }
    }
}

extension LayoutImage {
    final class ModelMovingFilesFromLayoutImageToAttachments: Model, Content {
        static var schema = v2022_04_13.schemaName
        
        @ID
        var id: UUID?
        
        @OptionalField(key: v2022_04_13.name)
        var name: String?
        
        @Parent(key: v2022_04_13.layoutID)
        var layout: Layout
        
        @OptionalParent(key: v2022_04_21.attachmentID)
        var attachment: Attachment?
        
        init() { }
    }
}

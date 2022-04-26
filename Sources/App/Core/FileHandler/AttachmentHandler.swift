//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Vapor
import Fluent

struct AttachmentHandler {
    let fileHandler: FileHandler
    
    var pathBuilder: FilePathBuilder {
        FilePathBuilder()
    }
    
    func download(_ attachment: Attachment) async throws -> Response {
        let path = try pathBuilder.path(for: attachment)
        let attachmentETag = attachment.generateETag()
        if let clientETag = fileHandler.request.headers.first(name: .ifNoneMatch),
           attachmentETag == clientETag {
            return Response(status: .notModified)
        } else {
            let filename = attachment.name
            async let response = try fileHandler.download(filename, at: path)
            if let attachmentETag = attachmentETag {
                try await response.headers.replaceOrAdd(name: .eTag, value: attachmentETag)
            }
            return try await response
        }
    }
    
    func create(from data: ByteBuffer, named filename: String) async throws -> Attachment {
        let attachment = Attachment(name: filename)
        try await attachment.save(on: fileHandler.request.db)
        
        let path = try pathBuilder.path(for: attachment)
        try await fileHandler.upload(data, named: filename, at: path)
        
        return attachment
    }
    
    
    func delete(_ attachments: [Attachment]) async throws {
        for attachment in attachments {
            let path = try pathBuilder.path(for: attachment)
            try await fileHandler.delete(attachment.name, at: path)
        }
    }
    
    func delete(_ attachment: Attachment) async throws {
        let path = try pathBuilder.path(for: attachment)
        try await fileHandler.delete(attachment.name, at: path)
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 21.04.2022.
//

import Fluent
import Vapor

final class Attachment: Model, Content {
    static var schema = v2022_04_21.schemaName
    
    @ID
    var id: UUID?
    
    @Timestamp(key: v2022_04_21.createdAt, on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: v2022_04_21.updatedAt, on: .update, format: .iso8601)
    var updatedAt: Date?
    
    @Field(key: v2022_04_21.name)
    var name: String
    
    @OptionalField(key: v2022_04_21.eTag)
    var eTag: String?
    
    init() { }
    
    init(
        id: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        name: String,
        eTag: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.eTag = eTag
    }
}

extension Attachment {
    func downloadPath() throws -> String {
        ["api", "attachments", try requireID().uuidString].joined(separator: "/")
    }
}

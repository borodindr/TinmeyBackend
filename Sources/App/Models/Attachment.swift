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
    
    init() { }
    
    init(
        id: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        name: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
    }
}

extension Attachment {
    func downloadPath() throws -> String {
        ["download", try requireID().uuidString, name].joined(separator: "/")
    }
    
    func generateETag() -> String? {
        guard let updatedAt = updatedAt, let id = id else { return nil }
        return "\(updatedAt.timeIntervalSince1970)-\(id.uuidString)"
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 21.04.2022.
//

import Fluent

struct CreateAttachment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Attachment.v2022_04_21.schemaName)
            .id()
            .field(Attachment.v2022_04_21.createdAt, .string)
            .field(Attachment.v2022_04_21.updatedAt, .string)
            .field(Attachment.v2022_04_21.name, .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Attachment.v2022_04_21.schemaName).delete()
    }
}

extension Attachment {
    enum v2022_04_21 {
        static let schemaName = "attachments"
        static let id = FieldKey(stringLiteral: "id")
        static let createdAt = FieldKey(stringLiteral: "created_at")
        static let updatedAt = FieldKey(stringLiteral: "updated_at")
        static let name = FieldKey(stringLiteral: "name")
    }
}

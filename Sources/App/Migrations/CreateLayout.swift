//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.04.2022.
//

import Fluent

struct CreateLayout: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Layout.v2022_04_13.schemaName)
            .id()
            .field(Layout.v2022_04_13.sortIndex, .int, .required)
            .field(Layout.v2022_04_13.createdAt, .string)
            .field(Layout.v2022_04_13.updatedAt, .string)
            .field(Layout.v2022_04_13.title, .string, .required)
            .field(Layout.v2022_04_13.description, .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Layout.v2022_04_13.schemaName).delete()
    }
}

extension Layout {
    enum v2022_04_13 {
        static let schemaName = "layouts"
        static let id = FieldKey(stringLiteral: "id")
        static let sortIndex = FieldKey(stringLiteral: "sort_index")
        static let createdAt = FieldKey(stringLiteral: "created_at")
        static let updatedAt = FieldKey(stringLiteral: "updated_at")
        static let title = FieldKey(stringLiteral: "title")
        static let description = FieldKey(stringLiteral: "description")
    }
}

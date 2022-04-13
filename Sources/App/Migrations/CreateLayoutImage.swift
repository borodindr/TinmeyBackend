//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.04.2022.
//

import Fluent

struct CreateLayoutImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(LayoutImage.v2022_04_13.schemaName)
            .id()
            .field(LayoutImage.v2022_04_13.sortIndex, .int, .required)
            .field(LayoutImage.v2022_04_13.name, .string)
            .field(
                LayoutImage.v2022_04_13.layoutID,
                .uuid,
                .references(
                    LayoutImage.v2022_04_13.schemaName,
                    LayoutImage.v2022_04_13.id,
                    onDelete: .cascade
                )
            )
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(LayoutImage.v2022_04_13.schemaName).delete()
    }
}

extension LayoutImage {
    enum v2022_04_13 {
        static let schemaName = "layout_images"
        static let id = FieldKey(stringLiteral: "id")
        static let sortIndex = FieldKey(stringLiteral: "sort_index")
        static let name = FieldKey(stringLiteral: "name")
        static let layoutID = FieldKey(stringLiteral: "layoutID")
    }
}


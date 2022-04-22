//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.04.2022.
//

import Fluent

struct DeleteNameFromLayoutImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(LayoutImage.v2022_04_13.schemaName)
            .deleteField(LayoutImage.v2022_04_13.name)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(LayoutImage.v2022_04_13.schemaName)
            .field(LayoutImage.v2022_04_13.name, .string)
            .update()
    }
}

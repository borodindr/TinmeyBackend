//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.04.2022.
//

import Fluent

struct DeleteNameFromWorkImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(WorkImage.v2021_12_19.schemaName)
            .deleteField(WorkImage.v2021_12_19.name)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(WorkImage.v2021_12_19.schemaName)
            .field(WorkImage.v2021_12_19.name, .string)
            .update()
    }
}

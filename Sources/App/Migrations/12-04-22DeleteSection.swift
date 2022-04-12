//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.04.2022.
//

import Fluent

struct DeleteSection: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Section.v2021_11_04.schemaName).delete()
    }
    
    func revert(on database: Database) async throws {
        try await CreateSection().prepare(on: database).get()
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.04.2022.
//

import Fluent

struct DeleteProfile: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Profile.v2021_11_04.schemeName).delete()
    }
    
    func revert(on database: Database) async throws {
        try await CreateProfile().prepare(on: database).get()
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.03.2022.
//

import Fluent
import Vapor

struct UpdateWorkToV2: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Copy existing 'seeMoreLink' to the end of 'description' and save
        let works = try await Work.ModelUpdatingWorkToV2.query(on: database).all()
        for work in works {
            if let url = work.seeMoreLink {
                work.description = work.description + "\n" + url
                try await work.save(on: database)
            }
        }
        
        // Delete old fields
        try await database.schema(Work.v2021_11_04.schemaName)
            .deleteField(Work.v2021_11_04.type)
            .deleteField(Work.v2021_11_04.seeMoreLink)
            .deleteField(Work.v2021_12_30.bodyIndex)
            .update()
        
        // Delete WorkType enum
        try await database
            .enum(Work.WorkType.v2021_11_04.enumName)
            .delete()
    }
    
    func revert(on database: Database) async throws {
        // Create enum WorkType
        let workType = try await database
            .enum(Work.WorkType.v2021_11_04.enumName)
            .case(Work.WorkType.v2021_11_04.cover)
            .case(Work.WorkType.v2021_11_04.layout)
            .create()
        
        // Add back removed fields
        try await database.schema(Work.v2021_11_04.schemaName)
            .field(Work.v2021_11_04.type, workType, .required, .sql(.default(Work.WorkType.v2021_11_04.cover)))
            .field(Work.v2021_11_04.seeMoreLink, .string)
            .field(Work.v2021_12_30.bodyIndex, .int, .required, .sql(.default(0)))
            .update()
    }
}

fileprivate extension Work {
    final class ModelUpdatingWorkToV2: Model, Content {
        static var schema = v2021_11_04.schemaName
        
        @ID
        var id: UUID?
        
        @Field(key: v2021_11_04.description)
        var description: String
        
        @OptionalField(key: v2021_11_04.seeMoreLink)
        var seeMoreLink: String?
        
        init() { }
    }
}

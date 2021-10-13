//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Fluent

struct CreateTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tags")
            .id()
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tags").delete()
    }
}

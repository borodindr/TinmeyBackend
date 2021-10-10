//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tokens")
            .id()
            .field("value", .string, .required)
            .field("userID", .uuid, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tokens").delete()
    }
}

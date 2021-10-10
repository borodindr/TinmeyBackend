//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent

struct CreateProfile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profiles")
            .id()
            .field("userID", .uuid, .references("users", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("current_status", .string, .required)
            .field("short_about", .string, .required)
            .field("about", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profiles").delete()
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Fluent

struct CreateWorkTagPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("work-tag-pivot")
            .id()
            .field("workID", .uuid, .required, .references("works", "id", onDelete: .cascade))
            .field("tagID", .uuid, .required, .references("tags", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("work-tag-pivot").delete()
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Fluent

struct CreateTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.v2021_11_04.schemeName)
            .id()
            .field(Tag.v2021_11_04.name, .string, .required)
            .unique(on: Tag.v2021_11_04.name)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.v2021_11_04.schemeName).delete()
    }
}

extension Tag {
    enum v2021_11_04 {
        static let schemeName = "tags"
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
    }
}

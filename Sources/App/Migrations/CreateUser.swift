//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v2021_11_04.schemaName)
            .id()
            .field(User.v2021_11_04.isMain, .bool, .required)
            .field(User.v2021_11_04.username, .string, .required)
            .field(User.v2021_11_04.password, .string, .required)
            .unique(on: User.v2021_11_04.username)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v2021_11_04.schemaName).delete()
    }
}

extension User {
    enum v2021_11_04 {
        static let schemaName = "users"
        static let id = FieldKey(stringLiteral: "id")
        static let isMain = FieldKey(stringLiteral: "is_main")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
    }
}

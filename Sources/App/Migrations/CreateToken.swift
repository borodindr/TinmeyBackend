//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.v2021_11_04.schemaName)
            .id()
            .field(Token.v2021_11_04.value, .string, .required)
            .field(
                Token.v2021_11_04.userID,
                .uuid,
                .references(
                    User.v2021_11_04.schemaName,
                    User.v2021_11_04.id,
                    onDelete: .cascade
                )
            )
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.v2021_11_04.schemaName).delete()
    }
}

extension Token {
    enum v2021_11_04 {
        static let schemaName = "tokens"
        static let id = FieldKey(stringLiteral: "id")
        static let value = FieldKey(stringLiteral: "value")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}

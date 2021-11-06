//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent

struct CreateProfile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName)
            .id()
            .field(
                Profile.v2021_11_04.userID,
                .uuid,
                .references(
                    User.v2021_11_04.schemaName,
                    User.v2021_11_04.id,
                    onDelete: .cascade
                )
            )
            .field(Profile.v2021_11_04.name, .string, .required)
            .field(Profile.v2021_11_04.email, .string, .required)
            .field(Profile.v2021_11_04.currentStatus, .string, .required)
            .field(Profile.v2021_11_04.shortAbout, .string, .required)
            .field(Profile.v2021_11_04.about, .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName).delete()
    }
    
}

extension Profile {
    enum v2021_11_04 {
        static let schemeName = "profiles"
        static let id = FieldKey(stringLiteral: "id")
        static let userID = FieldKey(stringLiteral: "userID")
        static let name = FieldKey(stringLiteral: "name")
        static let email = FieldKey(stringLiteral: "email")
        static let currentStatus = FieldKey(stringLiteral: "current_status")
        static let shortAbout = FieldKey(stringLiteral: "short_about")
        static let about = FieldKey(stringLiteral: "about")
    }
    
}

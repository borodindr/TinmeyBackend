//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.12.2021.
//

import Fluent

struct AddLocationInProfile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName)
            .field(Profile.v2021_12_13.location, .string, .required, .sql(.default("")))
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName)
            .deleteField(Profile.v2021_12_13.location)
            .update()
    }
}

extension Profile {
    
    enum v2021_12_13 {
        static let location = FieldKey(stringLiteral: "location")
    }
    
}

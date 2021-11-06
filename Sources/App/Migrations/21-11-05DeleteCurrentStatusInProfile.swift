//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 05.11.2021.
//

import Vapor
import Fluent

struct DeleteCurrentStatusInProfile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName)
            .deleteField(Profile.v2021_11_04.currentStatus)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Profile.v2021_11_04.schemeName)
            .field(Profile.v2021_11_04.currentStatus, .string, .required)
            .update()
    }
    
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 30.12.2021.
//

import Fluent

extension Collection where Element: Model {
    func save(on database: Database) -> EventLoopFuture<Void> {
        map { $0.save(on: database) }.flatten(on: database.eventLoop)
    }
}

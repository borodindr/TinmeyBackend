//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 21.12.2021.
//

import Fluent
import TinmeyCore

struct CreateTestWorks: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        WorkAPIModel.Create(
            title: "A",
            description: "A",
            tags: ["tag"],
            seeMoreLink: nil,
            bodyIndex: 0,
            images: [.init(id: nil), .init(id: nil)]
        )
            .makeWork(type: .cover, sortIndex: 0)
            .save(on: database)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.future()
    }
}

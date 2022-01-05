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
        [
            WorkAPIModel.Create(type: .cover, title: "A", description: "B", layout: .leftBody, seeMoreLink: nil),
            WorkAPIModel.Create(type: .cover, title: "A", description: "B", layout: .middleBody, seeMoreLink: nil),
            WorkAPIModel.Create(type: .cover, title: "A", description: "B", layout: .rightBody, seeMoreLink: nil),
            WorkAPIModel.Create(type: .cover, title: "A", description: "B", layout: .leftLargeBody, seeMoreLink: nil),
            WorkAPIModel.Create(type: .cover, title: "A", description: "B", layout: .rightLargeBody, seeMoreLink: nil),
        ]
            .enumerated()
            .map { $1.makeWork(sortIndex: $0) }
            .map { $0.save(on: database) }
            .flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.future()
    }
}

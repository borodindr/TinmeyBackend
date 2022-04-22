//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.12.2021.
//

import Vapor
import Fluent
import TinmeyCore

final class WorkImage: Model, Content {
    static var schema = v20211219.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v20211219.sortIndex)
    var sortIndex: Int
    
    @OptionalField(key: v20211219.name)
    var name: String?
    
    @Parent(key: v20211219.workID)
    var work: Work
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        name: String? = nil,
        workID: Work.IDValue
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.name = name
        self.$work.id = workID
    }
}

extension WorkImage {
    static func add(at index: Int, to work: Work, on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededVoidFuture()
            .flatMapThrowing {
                WorkImage(sortIndex: index, workID: try work.requireID())
            }
            .flatMap { $0.save(on: database) }
    }
    
    static func add(
        _ createImages: [WorkAPIModel.Image.Create],
        to work: Work,
        on database: Database
    ) -> EventLoopFuture<Void> {
        database.eventLoop.future(createImages)
            .map(\.indices)
            .flatMapEachThrowing { index in
                WorkImage(sortIndex: index, workID: try work.requireID())
            }
            .flatMap { items in
                items.save(on: database)
            }
    }
    
    static func add(
        _ createImages: [WorkAPIModel.Image.Create],
        to work: Work,
        on database: Database
    ) async throws {
        var workImages: [WorkImage] = []
        for index in createImages.indices {
            let workImage = WorkImage(sortIndex: index, workID: try work.requireID())
            workImages.append(workImage)
        }
        try await workImages.save(on: database)
    }
}

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
    static var schema = v2021_12_19.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_12_19.sortIndex)
    var sortIndex: Int
    
    @OptionalField(key: v2021_12_19.name)
    var name: String?
    
    @Parent(key: v2021_12_19.workID)
    var work: Work
    
    @OptionalParent(key: v2022_04_21.attachmentID)
    var attachment: Attachment?
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        name: String? = nil,
        workID: Work.IDValue,
        attachmentID: Attachment.IDValue? = nil
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.name = name
        self.$work.id = workID
        self.$attachment.id = attachmentID
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

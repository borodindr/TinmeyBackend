//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.04.2022.
//

import Vapor
import Fluent
import TinmeyCore

final class LayoutImage: Model, Content {
    static var schema = v2022_04_13.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2022_04_13.sortIndex)
    var sortIndex: Int
    
    @Parent(key: v2022_04_13.layoutID)
    var layout: Layout
    
    @OptionalParent(key: v2022_04_21.attachmentID)
    var attachment: Attachment?
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        layoutID: Layout.IDValue,
        attachmentID: Attachment.IDValue? = nil
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.$layout.id = layoutID
        self.$attachment.id = attachmentID
    }
}

extension LayoutImage {
    static func add(at index: Int, to layout: Layout, on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededVoidFuture()
            .flatMapThrowing {
                LayoutImage(sortIndex: index, layoutID: try layout.requireID())
            }
            .flatMap { $0.save(on: database) }
    }
    
    static func add(
        _ createImages: [LayoutAPIModel.Image.Create],
        to layout: Layout,
        on database: Database
    ) -> EventLoopFuture<Void> {
        database.eventLoop.future(createImages)
            .map(\.indices)
            .flatMapEachThrowing { index in
                LayoutImage(sortIndex: index, layoutID: try layout.requireID())
            }
            .flatMap { items in
                items.save(on: database)
            }
    }
    
    static func add(
        _ createImages: [LayoutAPIModel.Image.Create],
        to layout: Layout,
        on database: Database
    ) async throws {
        var layoutImages: [LayoutImage] = []
        for index in createImages.indices {
            let layoutImage = LayoutImage(sortIndex: index, layoutID: try layout.requireID())
            layoutImages.append(layoutImage)
        }
        try await layoutImages.save(on: database)
    }
}

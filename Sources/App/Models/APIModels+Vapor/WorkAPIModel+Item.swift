//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Vapor
import Fluent
import TinmeyCore

extension WorkAPIModel.Image {
    init(_ workImage: WorkImage) throws {
        let path: String?
        if workImage.name != nil {
            let directoryPath = ["api", "works", "images", try workImage.requireID().uuidString].joined(separator: "/")
            path = "\(directoryPath)"
        } else {
            path = nil
        }
        self.init(
            id: try workImage.requireID(),
            // TODO: Change name to path
            path: path
        )
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

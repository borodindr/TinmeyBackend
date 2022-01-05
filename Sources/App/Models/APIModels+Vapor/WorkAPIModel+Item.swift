//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Vapor
import TinmeyCore

extension WorkAPIModel.Image {
    init(_ workImage: WorkImage) throws {
        let path: String?
        if workImage.name != nil {
            let directoryPath = ["api", "work_images", try workImage.requireID().uuidString].joined(separator: "/")
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
    static func add(at index: Int, to work: Work, on req: Request) -> EventLoopFuture<Void> {
        req.eventLoop.makeSucceededVoidFuture()
            .flatMapThrowing {
                WorkImage(sortIndex: index, workID: try work.requireID())
            }
            .flatMap { $0.save(on: req.db) }
    }
    
    static func add(_ createImages: [WorkAPIModel.Image.Create], to work: Work, on req: Request) -> EventLoopFuture<Void> {
        req.eventLoop.future(createImages)
            .map(\.indices)
            .flatMapEachThrowing { index in
                WorkImage(sortIndex: index, workID: try work.requireID())
            }
            .flatMap { items in
                items.save(on: req.db)
            }
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 18.08.2021.
//

import TinmeyCore
import Vapor
import Fluent

extension TimestampProperty {
    func orThrow() throws -> Date {
        guard let date = wrappedValue else {
            throw FluentError.missingField(name: $timestamp.key.description)
        }
        return date
    }
}

extension WorkAPIModel: Content { }
extension WorkAPIModel.ReorderDirection: Content { }

extension WorkAPIModel.Create {
    func makeWork(type: Work.WorkType, sortIndex: Int) -> Work {
        Work(
            sortIndex: sortIndex,
            type: type,
            title: title,
            description: description,
            seeMoreLink: seeMoreLink?.absoluteString,
            bodyIndex: bodyIndex
        )
    }
}

extension WorkAPIModel.Create {
    func create(on req: Request, type: Work.WorkType) -> EventLoopFuture<Work> {
        Work.query(on: req.db)
            .filter(\.$type == type)
            .sort(\.$sortIndex, .descending)
            .first()
            .map { lastWork -> Int in
                if let lastWork = lastWork {
                    return lastWork.sortIndex + 1
                } else {
                    return 0
                }
            }
            .map { makeWork(type: type, sortIndex: $0) }
            .flatMap { work -> EventLoopFuture<Work> in
                work.save(on: req.db).map { work }
            }
            .flatMap { work -> EventLoopFuture<Work> in
                WorkImage.add(images, to: work, on: req)
                    .map { work }
            }
            .flatMap { work in
                Tag.add(tags, to: work, on: req)
                    .map { work }
            }
    }
    
    func create(on req: Request, type: Work.WorkType) async throws -> Work {
        try await create(on: req, type: type).get()
    }
}

extension Work {
    func convertToAPIModel(on database: Database) -> EventLoopFuture<WorkAPIModel> {
        // TODO: change load to query
        let loadTags = $tags.load(on: database)
        let loadImages = $images.query(on: database).sort(\.$sortIndex, .ascending).all()
        return database.eventLoop.future(self)
            .flatMap { work in
                loadTags.and(loadImages)
                    .map { (_, images) in (work, images) }
            }
            .flatMapThrowing { work, images in
                let seeMoreLink: URL?
                if let linkString = work.seeMoreLink {
                    seeMoreLink = URL(string: linkString)
                } else {
                    seeMoreLink = nil
                }
                return try WorkAPIModel(
                    id: work.requireID(),
                    createdAt: work.$createdAt.orThrow(),
                    updatedAt: work.$updatedAt.orThrow(),
                    title: work.title,
                    description: work.description,
                    tags: work.tags.map { $0.name },
                    seeMoreLink: seeMoreLink,
                    bodyIndex: work.bodyIndex,
                    images: images.map(WorkAPIModel.Image.init)
                )
            }
    }
    
    func convertToAPIModel(on database: Database) async throws-> WorkAPIModel {
        try await convertToAPIModel(on: database).get()
    }
}

extension Array where Element == Work {
    func convertToAPIModel(on database: Database) async throws -> [WorkAPIModel] {
        try await database.eventLoop.future(self)
            .flatMapEach(on: database.eventLoop) {
                $0.convertToAPIModel(on: database)
            }
            .get()
    }
}

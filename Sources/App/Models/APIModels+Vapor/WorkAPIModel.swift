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
    func makeWork(sortIndex: Int) -> Work {
        Work(
            sortIndex: sortIndex,
            title: title,
            description: description
        )
    }
}

extension WorkAPIModel.Create {
    func create(on database: Database) async throws -> Work {
        let query = Work.query(on: database).sort(\.$sortIndex, .descending)
        let lastWork = try await query.first()
        let sortIndex: Int
        if let lastIndex = lastWork?.sortIndex {
            sortIndex = lastIndex + 1
        } else {
            sortIndex = 0
        }
        let work = makeWork(sortIndex: sortIndex)
        try await work.save(on: database)
        try await WorkImage.add(images, to: work, on: database)
        try await Tag.add(tags, to: work, on: database)
        return work
    }
}

extension Work {
    func convertToAPIModel(on database: Database) async throws-> WorkAPIModel {
        try await $tags.load(on: database)
        async let images = $images.query(on: database).sort(\.$sortIndex, .ascending).all()
        return try await WorkAPIModel(
            id: requireID(),
            createdAt: $createdAt.orThrow(),
            updatedAt: $updatedAt.orThrow(),
            title: title,
            description: description,
            tags: tags.map { $0.name },
            images: images.map(WorkAPIModel.Image.init)
        )
    }
}

extension Array where Element == Work {
    func convertToAPIModel(on database: Database) async throws -> [WorkAPIModel] {
        var apiModels: [WorkAPIModel] = []
        for work in self {
            let apiModel = try await work.convertToAPIModel(on: database)
            apiModels.append(apiModel)
        }
        return apiModels
    }
}

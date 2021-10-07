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

extension WorkAPIModel {
    init(_ work: Work) throws {
        let seeMoreLink: URL?
        if let linkString = work.seeMoreLink {
            seeMoreLink = URL(string: linkString)
        } else {
            seeMoreLink = nil
        }
        try self.init(
            id: work.requireID(),
            createdAt: work.$createdAt.orThrow(),
            updatedAt: work.$updatedAt.orThrow(),
            title: work.title,
            description: work.description,
            layout: work.layout,
            seeMoreLink: seeMoreLink
        )
    }
}

extension WorkAPIModel.Create {
    func makeWork(sortIndex: Int) -> Work {
        Work(
            sortIndex: sortIndex,
            type: type,
            title: title,
            description: description,
            layout: layout,
            seeMoreLink: seeMoreLink?.absoluteString
        )
    }
}

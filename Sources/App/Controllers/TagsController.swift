//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Fluent
import Vapor
import TinmeyCore

struct TagsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tagsGroup = routes.grouped("api", "tags")
        tagsGroup.get(use: getAllHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [String] {
        try await Tag.query(on: req.db).all().map { $0.name }
    }
}

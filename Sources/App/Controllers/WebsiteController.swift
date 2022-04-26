//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.10.2021.
//

import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: portfolioHandler)
        routes.get("portfolio", use: portfolioHandler)
        routes.get("layouts", use: layoutsHandler)
    }
    
    func portfolioHandler(_ req: Request) async throws -> View {
        let tagName = req.query[String.self, at: "tag"]
        let workModels = try await works(req, tagName: tagName)
        async let tags = Tag.query(on: req.db)
            .sort(\.$name, .ascending)
            .all()
        
        let meta = WebsiteMeta(title: "Portfolio")
        let availableTags = try await tags.map { $0.name }
        let header = TaggedHeader(
            availableTags: availableTags,
            selectedTag: tagName
        )
        
        for work in workModels {
            try await work.$images.load(on: req.db)
            for image in work.images {
                try await image.$attachment.load(on: req.db)
            }
        }
        
        let workItems: [WorksContext.Work] = try workModels
            .compactMap { work -> WorksContext.Work? in
                let imagePaths = try work.images
                    .sorted { $0.sortIndex < $1.sortIndex }
                    .compactMap(\.attachment)
                    .map { try $0.downloadPath() }
                
                guard let firstImagePath = imagePaths.first else {
                    return nil
                }
                var otherImagePaths = imagePaths
                otherImagePaths.removeFirst()
                
                return WorksContext.Work(
                    title: work.title,
                    description: work.description,
                    coverPath: firstImagePath,
                    otherImagesPaths: otherImagePaths,
                    tags: work.tags.map(\.name).sorted()
                )
            }
        
        let context = WorksContext(
            meta: meta,
            header: header,
            works: workItems
        )
        return try await req.view.render("works", context)
    }
    
    func layoutsHandler(_ req: Request) async throws -> View {
        let meta = WebsiteMeta(title: "Layouts")
        
        let layoutModels = try await Layout.query(on: req.db)
            .with(\.$images)
            .sort(\.$sortIndex, .descending)
            .all()
        
        for layout in layoutModels {
            try await layout.$images.load(on: req.db)
            for image in layout.images {
                try await image.$attachment.load(on: req.db)
            }
        }
        
        let layouts = try layoutModels
            .compactMap { layout -> LayoutsContext.Layout in
                let imagePaths = try layout.images
                    .sorted { $0.sortIndex < $1.sortIndex }
                    .compactMap(\.attachment)
                    .map { try $0.downloadPath() }
                
                return LayoutsContext.Layout(
                    title: layout.title,
                    description: layout.description,
                    imagePaths: imagePaths
                )
            }
        
        let context = LayoutsContext(
            meta: meta,
            layouts: layouts
        )
        return try await req.view.render("layouts", context)
    }
    
    func works(_ req: Request, tagName: String?) async throws -> [Work] {
        guard let tagName = tagName else {
            return try await allWorks(req)
        }
        let query = Tag.query(on: req.db).filter(\.$name == tagName)
        guard let tag = try await query.first() else {
            throw Abort(.notFound)
        }
        return try await tag.$works
            .query(on: req.db)
            .sort(\.$sortIndex, .descending)
            .with(\.$tags)
            .with(\.$images)
            .all()
    }
    
    func allWorks(_ req: Request) async throws -> [Work] {
        try await Work.query(on: req.db)
            .with(\.$tags)
            .with(\.$images)
            .sort(\.$sortIndex, .descending)
            .all()
    }
}

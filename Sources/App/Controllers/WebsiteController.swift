//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.10.2021.
//

import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    let worksImageFolder = "WorkImages"
    
    let resumeFolder = "Resume"
    let resumeName = "Katya_Tinmey-Resume.pdf"
    
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
        let header = Header(
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
        let tagName = req.query[String.self, at: "tag"]
        async let tags = Tag.query(on: req.db)
            .sort(\.$name, .ascending)
            .all()
        
        let meta = WebsiteMeta(title: "Layouts")
        let availableTags = try await tags.map { $0.name }
        let header = Header(
            availableTags: availableTags,
            selectedTag: tagName
        )
        
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
            header: header,
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

// MARK: - Context
protocol WebsiteContext: Encodable {
    var meta: WebsiteMeta { get }
    var header: Header { get }
}

struct WorksContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: Header
    let works: [Work]
}

extension WorksContext {
    struct Work: Encodable {
        init(
            title: String,
            description: String,
            coverPath: String,
            otherImagesPaths: [String],
            tags: [String]
        ) {
            self.title = title.multilineHTML()
            self.description = description.multilineHTML()
            self.coverPath = coverPath
            self.otherImagesPaths = otherImagesPaths
            self.tags = tags
        }
        
        let title: String
        let description: String
        let coverPath: String
        let otherImagesPaths: [String]
        let tags: [String]
    }
}

struct LayoutsContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: Header
    let layouts: [Layout]
}

extension LayoutsContext {
    struct Layout: Encodable {
        init(
            title: String,
            description: String,
            imagePaths: [String]
        ) {
            self.title = title.multilineHTML()
            self.description = description.multilineHTML()
            self.imagePaths = imagePaths
        }
        
        let title: String
        let description: String
        let imagePaths: [String]
    }
}

// MARK: - Meta
struct WebsiteMeta: Encodable {
    let canonical: String = "https://tinmey.com"
    let siteName: String = "Tinmey Design"
    let title: String
    let author: String = "Katya Tinmey"
    let description: String = "I'm Katya Tinmey. Graphic designer."
    let email: String = "katya@tinmey.com"
    
    init(title: String) {
        self.title = title
    }
}

// MARK: - Header
struct Header: Encodable {
    let availableTags: [String]
    let selectedTag: String?
    
    init(
        availableTags: [String],
        selectedTag: String?
    ) {
        self.availableTags = availableTags
        self.selectedTag = selectedTag
    }
}

extension String {
    func multilineHTML() -> String {
        self.replacingOccurrences(of: "\n", with: "<br>")
    }
}

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
        routes.get("download", "work_images", ":imageID", use: getWorkImageHandler)
        routes.get("download", "layout_images", ":imageID", use: getLayoutImageHandler)
    }
    
    func portfolioHandler(_ req: Request) async throws -> View {
        let tagName = req.query[String.self, at: "tag"]
        async let works = works(req, tagName: tagName)
        async let tags = Tag.query(on: req.db)
            .sort(\.$name, .ascending)
            .all()
        
        let meta = WebsiteMeta(title: "Portfolio")
        let availableTags = try await tags.map { $0.name }
        let header = Header(
            availableTags: availableTags,
            selectedTag: tagName
        )
        let workItems: [WorksContext.Work] = try await works
            .compactMap { work in
                let images = work.images.sorted {
                    $0.sortIndex < $1.sortIndex
                }
                
                guard let firstImageID = try images.first?.requireID().uuidString else {
                    return nil
                }
                var otherImagePaths = try images
                    .map { try $0.requireID().uuidString }
                    .map { "/download/work_images/\($0)" }
                otherImagePaths.removeFirst()
                
                return WorksContext.Work(
                    title: work.title,
                    description: work.description,
                    coverPath: "/download/work_images/\(firstImageID)",
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
        
        let layouts = try await Layout.query(on: req.db)
            .with(\.$images)
            .sort(\.$sortIndex, .descending)
            .all()
            .compactMap { layout -> LayoutsContext.Layout in
                let images = try layout.images
                    .sorted { $0.sortIndex < $1.sortIndex }
                    .map { try $0.requireID().uuidString }
                    .map { "/download/layout_images/\($0)" }
                
                return LayoutsContext.Layout(
                    title: layout.title,
                    description: layout.description,
                    imagePaths: images
                )
            }
        
        let context = LayoutsContext(
            meta: meta,
            header: header,
            layouts: layouts
        )
        return try await req.view.render("layouts", context)
    }
    
    func getWorkImageHandler(_ req: Request) async throws -> Response {
        guard let image = try await WorkImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let filename = image.name else {
            let reason = "Image '\(image.id?.uuidString ?? "-")' is empty"
            throw Abort(.notFound, reason: reason)
        }
        let path = try FilePathBuilder().workImagePath(for: image)
        return try await req.fileHandler.download(filename, at: path)
    }
    
    func getLayoutImageHandler(_ req: Request) async throws -> Response {
        guard let image = try await LayoutImage.find(req.parameters.get("imageID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let filename = image.name else {
            let reason = "Image '\(image.id?.uuidString ?? "-")' is empty"
            throw Abort(.notFound, reason: reason)
        }
        let path = try FilePathBuilder().layoutImagePath(for: image)
        return try await req.fileHandler.download(filename, at: path)
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
    
    // TODO: delete it
    func downloadResumeHandler(_ req: Request) async throws -> Response {
        try await req.fileHandler.download(resumeName, at: resumeFolder)
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

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 12.10.2021.
//

import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    let sectionsImageFolder = "SectionImages"
    let worksImageFolder = "WorkImages"
    
    let resumeFolder = "Resume"
    let resumeName = "Katya_Tinmey-Resume.pdf"
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("sections", ":sectionType", ":imageType", use: getSectionImageHandler)
        routes.get("covers", use: coversHandler)
        routes.get("layouts", use: layoutsHandler)
        routes.get("works", ":workID", ":imageType", use: getWorkImageHandler)
        routes.get("download", "resume", use: downloadResumeHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Section.query(on: req.db)
            .sort(\.$sortIndex, .ascending)
            .all()
            .flatMap { sections in
                getMainProfile(req)
                    .flatMap { profile in
                        let meta = WebsiteMeta(title: "Home", profile: profile)
                        let header = IndexHeader(profile: profile)
                        let items = sections.map(SectionItem.init)
                        let context = IndexContext(
                            meta: meta,
                            header: header,
                            about: profile.about,
                            items: items
                        )
                        return req.view.render("index", context)
                    }
            }
    }
    
    func coversHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let sectionFuture = Section.query(on: req.db)
            .filter(\.$type == .covers)
            .first()
            .unwrap(or: Abort(.notFound))
        
        let tagName = req.query[String.self, at: "tag"]
        let worksFuture = worksFuture(req, type: .cover, tagName: tagName)
        
        let tagsFuture = Tag.query(on: req.db)
            .all()
        
        return EventLoopFuture
            .combine(
                sectionFuture,
                worksFuture,
                tagsFuture,
                getMainProfile(req)
            )
            .flatMap { (section, works, tags, profile) in
                let meta = WebsiteMeta(title: "Covers", profile: profile)
                let availableTags = tags.map { $0.name }
                let header = WorkHeader(
                    section: section,
                    availableTags: availableTags,
                    selectedTag: tagName
                )
                let items = works.map(PreviewItem.init)
                let context = WorkContext(
                    meta: meta,
                    header: header,
                    items: items
                )
                return req.view.render("works", context)
            }
    }
    
    func layoutsHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let sectionFuture = Section.query(on: req.db)
            .filter(\.$type == .layouts)
            .first()
            .unwrap(or: Abort(.notFound))
        
        let worksFuture = allWorksFuture(req, type: .layout)
        
        return EventLoopFuture
            .combine(
                sectionFuture,
                worksFuture,
                getMainProfile(req)
            )
            .flatMap { section, works, profile in
                let meta = WebsiteMeta(title: "Layouts", profile: profile)
                let header = WorkHeader(section: section)
                let items = works.map(PreviewItem.init)
                let context = WorkContext(
                    meta: meta,
                    header: header,
                    items: items
                )
                return req.view.render("works", context)
            }
    }
    
    func getSectionImageHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let sectionType = try Section.SectionType.detect(from: req)
        let imageType = try ImageType.detect(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { section in
                try imageType.imageName(in: section)
            }
            .flatMap { imageName in
                req.fileHandler.download(imageName, at: sectionsImageFolder)
            }
    }
    
    func getWorkImageHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let imageType = try ImageType.detect(from: req)
        
        return Work.find(req.parameters.get("workID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { work in
                try imageType.imageName(in: work)
            }
            .flatMap { imageName in
                req.fileHandler.download(imageName, at: worksImageFolder)
            }
    }
    
    func getMainProfile(_ req: Request) -> EventLoopFuture<Profile> {
        User.query(on: req.db)
            .filter(\.$isMain == true)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { mainUser in
                mainUser.$profile
                    .get(on: req.db)
                    .map { $0.first }
                    .unwrap(or: Abort(.notFound))
            }
    }
    
    func workType(from req: Request) throws -> Work.WorkType {
        guard let typeKey = req.parameters.get("workType"),
              let type = Work.WorkType(rawValue: typeKey) else {
            throw Abort(.badRequest, reason: "Wrong work type")
        }
        return type
    }
    
    func worksFuture(_ req: Request, type: Work.WorkType, tagName: String?) -> EventLoopFuture<[Work]> {
        if let tagName = tagName {
            return Tag.query(on: req.db)
                .filter(\.$name == tagName)
                .first()
                .unwrap(or: Abort(.notFound))
                .flatMap { $0.$works.query(on: req.db).with(\.$tags).all() }
        } else {
            return allWorksFuture(req, type: type)
        }
    }
    
    func allWorksFuture(_ req: Request, type: Work.WorkType) -> EventLoopFuture<[Work]> {
        Work.query(on: req.db).with(\.$tags)
            .filter(\.$type == type)
            .sort(\.$sortIndex, .descending)
            .all()
    }
    
    func downloadResumeHandler(_ req: Request) -> EventLoopFuture<Response> {
        req.fileHandler.download(resumeName, at: resumeFolder)
    }
}

// MARK: - Context
protocol WebsiteContext: Encodable {
    associatedtype HeaderType: Header
    
    var meta: WebsiteMeta { get }
    var header: HeaderType { get }
}

struct IndexContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: IndexHeader
    let about: String
    let items: [SectionItem]
}

struct WorkContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: WorkHeader
    let items: [PreviewItem]
}

// MARK: - Meta
struct WebsiteMeta: Encodable {
    let canonical: String
    let siteName: String = "tinmey design"
    let title: String
    let author: String
    let description: String
    
    init(title: String, profile: Profile) {
        self.canonical = "https://tinmey.com" //req.application.http.server.configuration.urlString()
        self.title = title
        self.author = profile.name
        self.description = profile.shortAbout
    }
}

// MARK: - Header
protocol Header: Encodable {
    var title: String { get }
    var description: String { get }
}

struct IndexHeader: Header {
    let title: String
    let description: String
    let email: String?
    
    init(profile: Profile) {
        self.title = profile.name
        self.description = profile.shortAbout
        self.email = profile.email
    }
}

struct WorkHeader: Header {
    let title: String
    let description: String
    let availableTags: [String]
    let selectedTag: String?
    
    init(section: Section, availableTags: [String], selectedTag: String?) {
        self.title = section.previewTitle
        self.description = section.sectionSubtitle
        self.availableTags = availableTags
        self.selectedTag = selectedTag
    }
    
    init(section: Section) {
        self.init(section: section, availableTags: [], selectedTag: nil)
    }
}

// MARK: - Item
struct SectionItem: Encodable {
    let layout: String
    let title: String
    let description: String
    let buttonDirection: String
    let buttonText: String
    let firstImageLink: String
    let secondImageLink: String
    
    init(section: Section) {
        switch section.type {
        case .covers:
            self.layout = Work.LayoutType.rightBody.rawValue
            self.buttonText = "See covers"
        case .layouts:
            self.layout = Work.LayoutType.middleBody.rawValue
            self.buttonText = "See layouts"
        }
        self.title = section.previewTitle
        self.description = section.previewSubtitle
        self.buttonDirection = "/\(section.type.rawValue)"
        self.firstImageLink = "/sections/\(section.type.rawValue)/firstImage"
        self.secondImageLink = "/sections/\(section.type.rawValue)/secondImage"
    }
}

struct PreviewItem: Encodable {
    let layout: String
    let title: String
    let description: String
    let tags: [String]
    let firstImageLink: String
    let secondImageLink: String
    
    init(work: Work) {
        self.layout = work.layout.rawValue
        self.title = work.title
        self.description = work.description
        self.tags = work.tags.map { $0.name }
        if let id = work.id?.uuidString {
            self.firstImageLink = "/works/\(id)/firstImage"
            self.secondImageLink = "/works/\(id)/secondImage"
        } else {
            // TODO: Add placeholder image
            self.firstImageLink = ""
            self.secondImageLink = ""
        }
    }
}

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
        routes.get("download", "work_images", ":imageID", use: getWorkImageHandler)
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
                do {
                    let context = WorkContext(
                        meta: meta,
                        header: header,
                        items: try works.map(WorkItem.init)
                    )
                    return req.view.render("works", context)
                } catch {
                    return indexHandler(req)
                }
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
                do {
                    let context = WorkContext(
                        meta: meta,
                        header: header,
                        items: try works.map(WorkItem.init)
                    )
                    return req.view.render("works", context)
                } catch {
                    return indexHandler(req)
                }
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
        WorkImage.find(req.parameters.get("imageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { image in
                guard let filename = image.name else {
                    let reason = "Image '\(image.id?.uuidString ?? "-")' is empty"
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: reason))
                }
                let path: [String]
                do {
                    path = try FilePathBuilder().workImagePath(for: image)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
                return req.fileHandler.download(filename, at: path)
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
                .flatMap { tag in
                    tag.$works
                        .query(on: req.db)
                        .sort(\.$sortIndex, .descending)
                        .with(\.$tags)
                        .with(\.$images)
                        .all()
                }
        } else {
            return allWorksFuture(req, type: type)
        }
    }
    
    func allWorksFuture(_ req: Request, type: Work.WorkType) -> EventLoopFuture<[Work]> {
        Work.query(on: req.db).with(\.$tags).with(\.$images)
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
    let items: [WorkItem]
}

// MARK: - Meta
struct WebsiteMeta: Encodable {
    let canonical: String
    let siteName: String = "tinmey design"
    let title: String
    let author: String
    let description: String
    let email: String
    
    init(title: String, profile: Profile) {
        self.canonical = "https://tinmey.com"
        self.title = title
        self.author = profile.name
        self.description = profile.shortAbout
        self.email = profile.email
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
    let location: String
    
    init(profile: Profile) {
        self.title = profile.name
        self.description = profile.shortAbout
        self.location = profile.location
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
    let rows: [[Item]]
    
    struct Item: Encodable {
        let itemType: ItemType
        let title: String?
        let description: String?
        let buttonDirection: String?
        let buttonText: String?
        let imageLink: String?
        
        init(
            itemType: SectionItem.Item.ItemType,
            title: String? = nil,
            description: String? = nil,
            buttonDirection: String? = nil,
            buttonText: String? = nil,
            imageLink: String? = nil
        ) {
            self.itemType = itemType
            self.title = title
            self.description = description
            self.buttonDirection = buttonDirection
            self.buttonText = buttonText
            self.imageLink = imageLink
        }
        
        enum ItemType: String, Encodable {
            case body
            case image
            case clear
        }
    }
    
    static func makeTwoDArray(from items: [SectionItem.Item]) -> [[SectionItem.Item]] {
        let columns = 3
        
        var column = 0
        var columnIndex = 0
        var result = [[SectionItem.Item]]()
        
        for item in items {
            if columnIndex < columns {
                if columnIndex == 0 {
                    result.insert([item], at: column)
                    columnIndex += 1
                } else {
                    result[column].append(item)
                    columnIndex += 1
                }
            } else {
                column += 1
                result.insert([item], at: column)
                columnIndex = 1
            }
        }
        return result
    }
    
    init(section: Section) {
        let firstImageItem = Item(itemType: .image, imageLink: "/sections/\(section.type.rawValue)/firstImage")
        let secondImageItem = Item(itemType: .image, imageLink: "/sections/\(section.type.rawValue)/secondImage")
        
        switch section.type {
        case .covers:
            let bodyItem = Item(
                itemType: .body,
                title: section.previewTitle,
                description: section.previewSubtitle,
                buttonDirection: "/\(section.type.rawValue)",
                buttonText: "See covers"
            )
            self.rows = [[firstImageItem, secondImageItem, bodyItem]]
            
        case .layouts:
            let bodyItem = Item(
                itemType: .body,
                title: section.previewTitle,
                description: section.previewSubtitle,
                buttonDirection: "/\(section.type.rawValue)",
                buttonText: "See layouts"
            )
            self.rows = [[firstImageItem, bodyItem, secondImageItem]]
            
        }
    }
}

struct WorkItem: Encodable {
    let rows: [[Item]]
    
    init(work: Work) throws {
        var list: [WorkItem.Item] = try work.images.map {
            $0.name == nil ? .clear() : try .image($0)
        }
        list.insert(.body(work), at: work.bodyIndex)
        self.rows = WorkItem.makeTwoDArray(from: list)
    }
    
    struct Item: Encodable {
        let itemType: ItemType
        let title: String?
        let description: String?
        let tags: [String]?
        let imageLink: String?
        
        init(
            itemType: WorkItem.Item.ItemType,
            title: String? = nil,
            description: String? = nil,
            tags: [String]? = nil,
            imageLink: String? = nil
        ) {
            self.itemType = itemType
            self.title = title
            self.description = description
            self.tags = tags
            self.imageLink = imageLink
       }
        
        static func image(_ image: WorkImage) throws -> Self {
            try self.init(
                itemType: .image,
                imageLink: "/download/work_images/\(image.requireID().uuidString)"
            )
        }
        
        static func body(_ work: Work) -> Self {
            self.init(
                itemType: .body,
                title: work.title,
                description: work.description,
                tags: work.tags.map { $0.name }
            )
        }
        
        static func clear() -> Self {
            self.init(itemType: .clear)
        }
        
        enum ItemType: String, Encodable {
            case body
            case image
            case clear
        }
    }
    
    static func makeTwoDArray(from items: [WorkItem.Item]) -> [[WorkItem.Item]] {
        let columns = 3
        
        var column = 0
        var columnIndex = 0
        var result = [[WorkItem.Item]]()
        
        for item in items {
            if columnIndex < columns {
                if columnIndex == 0 {
                    result.insert([item], at: column)
                    columnIndex += 1
                } else {
                    result[column].append(item)
                    columnIndex += 1
                }
            } else {
                column += 1
                result.insert([item], at: column)
                columnIndex = 1
            }
        }
        return result
    }
}

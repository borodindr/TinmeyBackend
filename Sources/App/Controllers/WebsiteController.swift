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
                        let context = IndexContext(
                            meta: meta,
                            header: header,
                            about: profile.about,
                            objects: sections.map { section in
                                    .generate(from: .generate(from: section))
                            }
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
                        objects: try works.map {
                            .generate(from: try .generate(from: $0))
                        }
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
                        objects: try works.map {
                            .generate(from: try .generate(from: $0))
                        }
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
    let objects: [WebsiteObject<SectionBody>]
    
    init(meta: WebsiteMeta, header: IndexHeader, about: String, objects: [WebsiteObject<SectionBody>]) {
        self.meta = meta
        self.header = header
        self.about = about.multilineHTML()
        self.objects = objects
    }
}

struct WorkContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: WorkHeader
    let objects: [WebsiteObject<WorkBody>]
}

// MARK: - Meta
struct WebsiteMeta: Encodable {
    let canonical: String
    var siteName: String = "tinmey design"
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
        self.description = profile.shortAbout.multilineHTML()
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
        self.description = section.sectionSubtitle.multilineHTML()
        self.availableTags = availableTags
        self.selectedTag = selectedTag
    }
    
    init(section: Section) {
        self.init(section: section, availableTags: [], selectedTag: nil)
    }
}

// MARK: - Item
struct WebsiteObject<Body: Encodable>: Encodable {
    var rows: [Row]
    
    static func generate(from contents: [Content]) -> Self {
        let columns = 3
        
        var result = [Row]()
        
        let rowsCount = contents.count / columns
        
        for rowIndex in 0..<rowsCount {
            var items = [Item]()
            let firstItemIndex = rowIndex * columns
            let lastItemIndex = firstItemIndex + columns - 1
            var isPreviousImage = false
            for itemIndex in firstItemIndex...lastItemIndex {
                if itemIndex < contents.count {
                    let indexInRow = itemIndex - rowIndex * columns
                    let isFirst = indexInRow == 0
                    let content = contents[itemIndex]
                    
                    let leftSep: SeparatorStyle
                    
                    if isFirst {
                        leftSep = .none
                    } else if content.isImage || isPreviousImage {
                        leftSep = .fill
                    } else {
                        leftSep = .clear
                    }
                    
                    let item = Item(
                        content: content,
                        leftSeparator: leftSep
                    )
                    items.append(item)
                    
                    isPreviousImage = content.isImage
                }
            }
            
            let row = Row(items: items, isLast: rowIndex == rowsCount - 1)
            result.append(row)
        }
        
        return .init(rows: result)
    }
}

extension WebsiteObject {
    struct Row: Encodable {
        let items: [Item]
        let isLast: Bool
    }
}

extension WebsiteObject {
    struct Item: Encodable {
        let content: Content
        let leftSeparator: SeparatorStyle
    }
    
    enum Content: Encodable {
        case body(body: Body)
        case image(imageLink: String)
        case clear
        
        var isImage: Bool {
            if case .image = self {
                return true
            }
            return false
        }
    }
    
    enum SeparatorStyle: String, Encodable {
        case fill, clear, none
    }
}

struct SectionBody: Encodable {
    let title: String
    let description: String
    let buttonDirection: String
    let buttonText: String
    
    init(title: String, description: String, buttonDirection: String, buttonText: String) {
        self.title = title.multilineHTML()
        self.description = description.multilineHTML()
        self.buttonDirection = buttonDirection
        self.buttonText = buttonText
    }
}

struct WorkBody: Encodable {
    let title: String
    let description: String
    let tags: [String]
    var seeMoreLink: String?
    
    init(title: String, description: String, tags: [String], seeMoreLink: String?) {
        self.title = title.multilineHTML()
        self.description = description.multilineHTML()
        self.tags = tags
        self.seeMoreLink = seeMoreLink
    }
}

extension Array where Element == WebsiteObject<SectionBody>.Content {
    static func generate(from section: Section) -> [Element] {
        let firstImageItem = Element.image(imageLink: "/sections/\(section.type.rawValue)/firstImage")
        let secondImageItem = Element.image(imageLink: "/sections/\(section.type.rawValue)/secondImage")
        
        switch section.type {
        case .covers:
            let bodyItem = Element.body(body: SectionBody(
                title: section.previewTitle,
                description: section.previewSubtitle,
                buttonDirection: "/\(section.type.rawValue)",
                buttonText: "Show works"
            )
            )
            return [firstImageItem, secondImageItem, bodyItem]
            
        case .layouts:
            let bodyItem = Element.body(body: SectionBody(
                title: section.previewTitle,
                description: section.previewSubtitle,
                buttonDirection: "/\(section.type.rawValue)",
                buttonText: "Show works"
            )
            )
            return [firstImageItem, bodyItem, secondImageItem]
            
        }
    }
}

extension Array where Element == WebsiteObject<WorkBody>.Content {
    static func generate(from work: Work) throws -> [Element] {
        var list: [Element] = try work.images
            .sorted(by: { $0.sortIndex < $1.sortIndex })
            .map {
                $0.name == nil ? .clear : try .image(imageLink: "/download/work_images/\($0.requireID().uuidString)")
            }
        let body = WorkBody(
            title: work.title,
            description: work.description,
            tags: work.tags.map { $0.name },
            seeMoreLink: work.seeMoreLink
        )
        list.insert(.body(body: body), at: work.bodyIndex)
        return list
    }
}

extension String {
    func multilineHTML() -> String {
        self.replacingOccurrences(of: "\n", with: "<br>")
    }
}

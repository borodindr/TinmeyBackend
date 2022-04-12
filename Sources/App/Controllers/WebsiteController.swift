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
        routes.get(use: portfolioHandler)
        routes.get("portfolio", use: portfolioHandler)
        routes.get("download", "work_images", ":imageID", use: getWorkImageHandler)
    }
    
    func portfolioHandler(_ req: Request) async throws -> View {
        let tagName = req.query[String.self, at: "tag"]
        async let works = works(req, tagName: tagName)
        async let tags = Tag.query(on: req.db)
            .sort(\.$name, .ascending)
            .all()
        
        let meta = WebsiteMeta(title: "Portfolio")
        let availableTags = try await tags.map { $0.name }
        let header = WorkHeader(
            title: "",
            description: "",
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
        
        let context = await WorksContext(
            meta: meta,
            header: header,
            objects: try works.map {
                .generate(from: try .generate(from: $0))
            },
            works: workItems
        )
        return try await req.view.render("works", context)
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
    associatedtype HeaderType: Header
    
    var meta: WebsiteMeta { get }
    var header: HeaderType { get }
}

struct WorksContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: WorkHeader
    let objects: [WebsiteObject<WorkBody>]
    let works: [Work]
}

extension WorksContext {
    struct Work: Encodable {
        internal init(title: String, description: String, coverPath: String, otherImagesPaths: [String], tags: [String]) {
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

// MARK: - Meta
struct WebsiteMeta: Encodable {
    let canonical: String = "https://tinmey.com"
    let siteName: String = "Katya Tinmey"
    let title: String
    let author: String = "Katya Tinmey"
    let description: String = "Hey it's Katya Tinmey!"
    let email: String = "katya@tinmey.com"
    
    init(title: String) {
        self.title = title
    }
}

// MARK: - Header
protocol Header: Encodable {
    var title: String { get }
    var description: String { get }
}

struct WorkHeader: Header {
    let title: String
    let description: String
    let availableTags: [String]
    let selectedTag: String?
    
    init(
        title: String,
        description: String,
        availableTags: [String],
        selectedTag: String?
    ) {
        self.title = title
        self.description = description
        self.availableTags = availableTags
        self.selectedTag = selectedTag
    }
    
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
    
    init(title: String, description: String, tags: [String]) {
        self.title = title.multilineHTML()
        self.description = description.multilineHTML()
        self.tags = tags
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
                buttonDirection: "https://www.behance.net/gallery/61774655/Japanese-book-design",//"/\(section.type.rawValue)",
                buttonText: "Behance"//"Show works"
            )
            )
            return [firstImageItem, bodyItem, .clear]
            
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
            tags: work.tags.map { $0.name }
        )
        list.insert(.body(body: body), at: 0)
        return list
    }
}

extension String {
    func multilineHTML() -> String {
        self.replacingOccurrences(of: "\n", with: "<br>")
    }
}

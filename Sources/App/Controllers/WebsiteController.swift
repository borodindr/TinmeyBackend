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
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("sections", ":sectionType", ":imageType", use: getSectionImageHandler)
        routes.get("covers", use: coversHandler)
        routes.get("layouts", use: layoutsHandler)
        routes.get("works", ":workID", ":imageType", use: getWorkImageHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Section.query(on: req.db)
            .sort(\.$sortIndex, .ascending)
            .all()
            .flatMap { sections in
                getMainProfile(req)
                    .flatMap { profile in
                        let items = sections.map(PreviewItem.init)
                        let header = Header(profile: profile)
                        let context = IndexContext(title: "Home page", header: header, items: items)
                        return req.view.render("index", context)
                    }
            }
    }
    
    func coversHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Work.query(on: req.db)
            .filter(\.$type == .cover)
            .sort(\.$sortIndex, .descending)
            .all()
            .flatMap { works in
                return Section.query(on: req.db)
                    .filter(\.$type == .covers)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .flatMap { section in
                        let items = works.map(PreviewItem.init)
                        let header = Header(section: section)
                        let context = IndexContext(title: "Home page", header: header, items: items)
                        return req.view.render("works", context)
                    }
            }
    }
    
    func layoutsHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Work.query(on: req.db)
            .filter(\.$type == .layout)
            .sort(\.$sortIndex, .descending)
            .all()
            .flatMap { works in
                return Section.query(on: req.db)
                    .filter(\.$type == .layouts)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .flatMap { section in
                        let items = works.map(PreviewItem.init)
                        let header = Header(section: section)
                        let context = IndexContext(title: "Home page", header: header, items: items)
                        return req.view.render("works", context)
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
                req.aws.s3.download(imageName, at: sectionsImageFolder)
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
                req.aws.s3.download(imageName, at: worksImageFolder)
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
}

struct IndexContext: Encodable {
    let title: String
    let header: Header
    let items: [PreviewItem]
}

struct PreviewItem: Encodable {
    let layout: String
    let title: String
    let description: String
    let buttonDirection: String?
    let buttonText: String?
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
        case .about:
            self.layout = Work.LayoutType.rightLargeBody.rawValue
            self.buttonText = "Learn more"
        }
        self.title = section.previewTitle
        self.description = section.previewSubtitle
        self.buttonDirection = "/\(section.type.rawValue)"
        self.firstImageLink = "/sections/\(section.type.rawValue)/firstImage"
        self.secondImageLink = "/sections/\(section.type.rawValue)/secondImage"
    }
    
    init(work: Work) {
        self.layout = work.layout.rawValue
        self.title = work.title
        self.description = work.description
        self.buttonDirection = work.seeMoreLink
        self.buttonText = "See more"
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

struct Header: Encodable {
    let title: String
    let description: String
    let status: String?
    let email: String?
    
    init(profile: Profile) {
        self.title = profile.name
        self.description = profile.shortAbout
        self.status = profile.currentStatus
        self.email = profile.email
    }
    
    init(section: Section) {
        self.title = section.previewTitle
        self.description = section.previewSubtitle
        self.status = nil
        self.email = nil
    }
}

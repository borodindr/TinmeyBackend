//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Vapor
import Fluent
import TinmeyCore

struct SectionsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sectionsGroup = routes.grouped("api", "sections")
        sectionsGroup.get(":sectionType", use: getHandler)
        sectionsGroup.put(":sectionType", use: updateHandler)
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<SectionAPIModel> {
        let sectionType = try sectionType(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { SectionAPIModel($0) }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<SectionAPIModel> {
        let updatedSection = try req.content.decode(SectionAPIModel.self)
        let sectionType = try sectionType(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { section in
                section.previewTitle = updatedSection.preview.title
                section.previewSubtitle = updatedSection.preview.subtitle
                
                return section.save(on: req.db)
                    .map { SectionAPIModel(section) }
            }
    }
}

private extension SectionsController {
    func sectionType(from req: Request) throws -> Section.SectionType {
        guard let sectionRawValue = req.parameters.get("sectionType"),
              let section = Section.SectionType(rawValue: sectionRawValue) else {
            throw Abort(.badRequest, reason: "Wrong section type")
        }
        
        return section
    }
}

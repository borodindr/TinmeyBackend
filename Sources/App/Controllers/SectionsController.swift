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
    let imageFolder = "SectionImages/"
    
    func boot(routes: RoutesBuilder) throws {
        let sectionsGroup = routes.grouped("api", "sections")
        sectionsGroup.get(":sectionType", use: getHandler)
        sectionsGroup.put(":sectionType", use: updateHandler)
        
        ImageType.allCases.forEach { imageType in
            sectionsGroup.on(.POST, ":sectionType", "\(imageType.rawValue)", body: .collect(maxSize: "10mb"), use: {
                try addImageHandler($0, imageType: imageType)
            })
            sectionsGroup.get(":sectionType", "\(imageType.rawValue)", use: {
                try downloadImageHandler($0, imageType: imageType)
            })
        }
        
        // For preview
        sectionsGroup.get("preview", "firstImage", use: downloadFirstPreviewImageHandler)
        sectionsGroup.get("preview", "secondImage", use: downloadSecondPreviewImageHandler)
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
    
    func addImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<HTTPStatus> {
        let sectionType = try sectionType(from: req)
        let data = try req.content.decode(ImageUploadData.self)
        let fileExtension = try data.validExtension()
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { section in
                let name = "Section-\(section.type.rawValue)-\(imageType.rawValue).\(fileExtension)"
                let path = req.application.directory.workingDirectory + imageFolder + name
                
                return req.fileio
                    .writeFile(data.picture.data, at: path)
                    .flatMap {
                        switch imageType {
                        case .firstImage:
                            section.firstImageName = name
                        case .secondImage:
                            section.secondImageName = name
                        }
                        return section.save(on: req.db)
                            .map { .created }
                    }
            }
    }
    
    func downloadImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<Response> {
        let sectionType = try sectionType(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { section in
                try imageName(for: imageType, from: section)
            }
            .map { imageName in
                let path = req.application.directory.workingDirectory + imageFolder + imageName
                return req.fileio.streamFile(at: path)
            }
    }
}

private extension SectionsController {
    func downloadFirstPreviewImageHandler(_ req: Request) throws -> Response {
        downloadPreviewImage(.firstImage, req: req)
    }
    
    func downloadSecondPreviewImageHandler(_ req: Request) throws -> Response {
        downloadPreviewImage(.secondImage, req: req)
    }
    
    func downloadPreviewImage(_ imageType: ImageType, req: Request) -> Response {
        let imageName = "Section-(PREVIEW)-\(imageType.rawValue).png"
        let path = req.application.directory.workingDirectory + imageFolder + imageName
        return req.fileio.streamFile(at: path)
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
    
    func imageName(for imageType: ImageType, from section: Section) throws -> String {
        let name: String?
        switch imageType {
        case .firstImage:
            name = section.firstImageName
        case .secondImage:
            name = section.secondImageName
        }
        
        guard let imageName = name else {
            let reason = "Section has no \(imageType.description)."
            let error = Abort(.notFound, reason: reason)
            throw error
        }
        return imageName
    }
}

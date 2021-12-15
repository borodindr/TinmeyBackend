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
    let imageFolder = "SectionImages"
    
    func boot(routes: RoutesBuilder) throws {
        let sectionsGroup = routes.grouped("api", "sections")
        sectionsGroup.get(":sectionType", use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = sectionsGroup.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(":sectionType", use: updateHandler)
        
        ImageType.allCases.forEach { imageType in
            tokenAuthGroup.on(.POST, ":sectionType", "\(imageType.rawValue)", body: .collect(maxSize: "10mb"), use: {
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
        let sectionType = try Section.SectionType.detect(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { SectionAPIModel($0) }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<SectionAPIModel> {
        let updatedSection = try req.content.decode(SectionAPIModel.self)
        let sectionType = try Section.SectionType.detect(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { section in
                section.previewTitle = updatedSection.preview.title
                section.previewSubtitle = updatedSection.preview.subtitle
                section.sectionSubtitle = updatedSection.subtitle
                
                return section.save(on: req.db)
                    .map { SectionAPIModel(section) }
            }
    }
    
    func addImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<HTTPStatus> {
        let sectionType = try Section.SectionType.detect(from: req)
        let data = try req.content.decode(FileUploadData.self)
        let fileExtension = try data.validImageExtension()
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { section in
                let name = "Section-\(section.type.rawValue)-\(imageType.rawValue).\(fileExtension)"
                return req.fileHandler.upload(data.file.data, named: name, at: imageFolder)
                    .flatMap {
                        switch imageType {
                        case .firstImage:
                            section.firstImageName = name
                        case .secondImage:
                            section.secondImageName = name
                        }
                        return section.save(on: req.db)
                    }
            }
            .map { .created }
    }
    
    func downloadImageHandler(_ req: Request, imageType: ImageType) throws -> EventLoopFuture<Response> {
        let sectionType = try Section.SectionType.detect(from: req)
        
        return Section.query(on: req.db)
            .filter(\.$type == sectionType)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { section in
                try imageType.imageName(in: section)
            }
            .flatMap { imageName in
                req.fileHandler.download(imageName, at: imageFolder)
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
        let path = req.application.directory.workingDirectory + imageFolder + "/" + imageName
        return req.fileio.streamFile(at: path)
    }
    
}

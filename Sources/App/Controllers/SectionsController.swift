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
                try await addImageHandler($0, imageType: imageType)
            })
            sectionsGroup.get(":sectionType", "\(imageType.rawValue)", use: {
                try await downloadImageHandler($0, imageType: imageType)
            })
        }
        
        // For preview
        sectionsGroup.get("preview", "firstImage", use: downloadFirstPreviewImageHandler)
        sectionsGroup.get("preview", "secondImage", use: downloadSecondPreviewImageHandler)
    }
    
    func getHandler(_ req: Request) async throws -> SectionAPIModel {
        let sectionType = try Section.SectionType.detect(from: req)
        let query = Section.query(on: req.db).filter(\.$type == sectionType)
        guard let section = try await query.first() else {
            throw Abort(.notFound)
        }
        return SectionAPIModel(section)
    }
    
    func updateHandler(_ req: Request) async throws -> SectionAPIModel {
        let updatedSection = try req.content.decode(SectionAPIModel.self)
        let sectionType = try Section.SectionType.detect(from: req)
        let query = Section.query(on: req.db).filter(\.$type == sectionType)
        guard let section = try await query.first() else {
            throw Abort(.notFound)
        }
        section.previewTitle = updatedSection.preview.title
        section.previewSubtitle = updatedSection.preview.subtitle
        section.sectionSubtitle = updatedSection.subtitle
        try await section.save(on: req.db)
        return SectionAPIModel(section)
    }
    
    func addImageHandler(_ req: Request, imageType: ImageType) async throws -> HTTPStatus {
        let sectionType = try Section.SectionType.detect(from: req)
        let data = try req.content.decode(FileUploadData.self)
        let fileExtension = try data.validImageExtension()
        let query = Section.query(on: req.db).filter(\.$type == sectionType)
        guard let section = try await query.first() else {
            throw Abort(.notFound)
        }
        let name = "Section-\(section.type.rawValue)-\(imageType.rawValue).\(fileExtension)"
        try await req.fileHandler.upload(data.file.data, named: name, at: imageFolder)
        switch imageType {
        case .firstImage:
            section.firstImageName = name
        case .secondImage:
            section.secondImageName = name
        }
        try await section.save(on: req.db)
        return .created
    }
    
    func downloadImageHandler(_ req: Request, imageType: ImageType) async throws -> Response {
        let sectionType = try Section.SectionType.detect(from: req)
        let query = Section.query(on: req.db).filter(\.$type == sectionType)
        guard let section = try await query.first() else {
            throw Abort(.notFound)
        }
        let imageName = try imageType.imageName(in: section)
        return try await req.fileHandler.download(imageName, at: imageFolder)
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

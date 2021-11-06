//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 04.11.2021.
//

import Vapor

struct ResumeController: RouteCollection {
    let resumeFolder = "Resume"
    let resumeName = "Katya_Tinmey-Resume.pdf"
    
    func boot(routes: RoutesBuilder) throws {
        let resumeGroup = routes.grouped("api", "resume")
        resumeGroup.get(use: downloadHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = resumeGroup.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.on(.POST, body: .collect(maxSize: "10mb"), use: uploadHandler)
    }
    
    func downloadHandler(_ req: Request) -> EventLoopFuture<Response> {
        req.fileHandler.download(resumeName, at: resumeFolder)
    }
    
    func uploadHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let data = try req.content.decode(FileUploadData.self)
        try data.validateExtension(["pdf"])
        return req.fileHandler
            .upload(data.file.data, named: resumeName, at: resumeFolder)
            .map { .accepted }
    }
}


//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Vapor
import Fluent

struct AttachmentsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("download", ":attachmentID", ":attachmentName", use: getHandler)
//        let attachmentsRoutes = routes.grouped("api", "attachments")
    }
    
    func getHandler(_ req: Request) async throws -> Response {
        guard
            let attachmentID: UUID = req.parameters.get("attachmentID"),
            let attachment = try await Attachment.find(attachmentID, on: req.db),
            let attachmentName: String = req.parameters.get("attachmentName"),
            attachment.name == attachmentName
        else {
            throw Abort(.notFound)
        }
        let path = try FilePathBuilder().path(for: attachment)
        return try await req.fileHandler.download(attachmentName, at: path)
    }
}

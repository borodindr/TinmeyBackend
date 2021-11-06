//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

struct LocalFileHandler: FileHandler {
    let request: Request
    
    private func path(for fileName: String, at pathComponents: [String]) -> String {
        let workingDirectory = request.application.directory.workingDirectory + "DevelopFiles/"
        let directory = pathComponents.reduce(workingDirectory) { $0 + "\($1)/" }
        return directory + fileName
    }
    
    // MARK: - Download
    func download(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Response> {
        let path = path(for: fileName, at: pathComponents)
        guard FileManager.default.fileExists(atPath: path) else {
            return request.eventLoop.future(error: Abort(.notFound))
        }
        let response = request.fileio.streamFile(at: path)
        return request.eventLoop.future(response)
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        let path = path(for: fileName, at: pathComponents)
        return request.fileio.writeFile(data, at: path)
    }
    
    // MARK: - Delete
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void> {
        fileNames
            .map { delete($0, at: pathComponents) }
            .flatten(on: request.eventLoop)
    }
    
    func delete(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        delete(fileName, at: pathComponents)
    }
    
    private func delete(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Void> {
        request.eventLoop.future()
            .flatMapThrowing {
                let path = path(for: fileName, at: pathComponents)
                try FileManager.default.removeItem(atPath: path)
            }
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

struct LocalFileHandler: FileHandler {
    let request: Request
    
    let fileManager = FileManager.default
    
    private func path(for fileName: String? = nil, at pathComponents: [String]) -> String {
        let workingDirectory = request.application.directory.workingDirectory + "DevelopFiles/"
        let directory = pathComponents.reduce(workingDirectory) { $0 + "\($1)/" }
        if let fileName = fileName {
            return directory + fileName
        } else {
            return directory
        }
    }
    
    // MARK: - Download
    func download(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Response> {
        download(fileName, at: pathComponents)
    }
    
    func download(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Response> {
        let path = path(for: fileName, at: pathComponents)
        guard FileManager.default.fileExists(atPath: path) else {
            return request.eventLoop.future(error: Abort(.notFound))
        }
        let response = request.fileio.streamFile(at: path)
        return request.eventLoop.future(response)
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        upload(data, named: fileName, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String]) -> EventLoopFuture<Void> {
        request.eventLoop.future()
            .flatMapThrowing {
                let directoryPath = path(at: pathComponents)
                if !fileManager.fileExists(atPath: directoryPath) {
                    try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
                }
            }
            .flatMap {
                let path = path(for: fileName, at: pathComponents)
                return request.fileio.writeFile(data, at: path)
            }
    }
    
    // MARK: - Delete
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void> {
        delete(fileNames, at: pathComponents)
    }
    
    func delete(_ fileNames: [String], at pathComponents: [String]) -> EventLoopFuture<Void> {
        fileNames
            .map { delete($0, at: pathComponents) }
            .flatten(on: request.eventLoop)
    }
    
    func delete(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        delete(fileName, at: pathComponents)
    }
    
    func delete(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Void> {
        request.eventLoop.future()
            .flatMapThrowing {
                let path = path(for: fileName, at: pathComponents)
                try FileManager.default.removeItem(atPath: path)
            }
            .flatMapThrowing {
                var pathComponents = pathComponents
                while !pathComponents.isEmpty {
                    let directoryPath = path(at: pathComponents)
                    if try fileManager.contentsOfDirectory(atPath: directoryPath).isEmpty {
                        try fileManager.removeItem(atPath: directoryPath)
                        pathComponents.removeLast()
                    } else {
                        return
                    }
                }
            }
    }
    
    // MARK: - Move
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: String...) -> EventLoopFuture<Void> {
        move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: String...) -> EventLoopFuture<Void> {
        move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: [String]) -> EventLoopFuture<Void> {
        move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: [String]) -> EventLoopFuture<Void> {
        request.eventLoop.future()
            .flatMapThrowing {
                let srcPath = path(for: fileName, at: srcPathComponents)
                let dstPath = path(for: fileName, at: dstPathComponents)
                let dstDirectoryPath = path(at: dstPathComponents)
                
                if !fileManager.fileExists(atPath: dstDirectoryPath) {
                    try fileManager.createDirectory(atPath: dstDirectoryPath, withIntermediateDirectories: true)
                }
                
                if fileManager.fileExists(atPath: srcPath) {
                    try fileManager.moveItem(atPath: srcPath, toPath: dstPath)
                }
            }
    }
}

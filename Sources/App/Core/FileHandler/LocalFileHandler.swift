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
    func download(_ fileName: String, at pathComponents: String...) async throws -> Response {
        try await download(fileName, at: pathComponents)
    }
    
    func download(_ fileName: String, at pathComponents: [String]) async throws -> Response {
        let path = path(for: fileName, at: pathComponents)
        guard FileManager.default.fileExists(atPath: path) else {
            throw Abort(.notFound)
        }
        return request.fileio.streamFile(at: path)
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) async throws {
        try await upload(data, named: fileName, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String]) async throws {
        let directoryPath = path(at: pathComponents)
        if !fileManager.fileExists(atPath: directoryPath) {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        let path = path(for: fileName, at: pathComponents)
        return try await request.fileio.writeFile(data, at: path)
    }
    
    // MARK: - Delete
    func delete(_ fileNames: [String], at pathComponents: String...) async throws {
        try await delete(fileNames, at: pathComponents)
    }
    
    func delete(_ fileNames: [String], at pathComponents: [String]) async throws {
        for fileName in fileNames {
            try await delete(fileName, at: pathComponents)
        }
    }
    
    func delete(_ fileName: String, at pathComponents: String...) async throws {
        try await delete(fileName, at: pathComponents)
    }
    
    func delete(_ fileName: String, at pathComponents: [String]) async throws {
        let filePath = path(for: fileName, at: pathComponents)
        try FileManager.default.removeItem(atPath: filePath)
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
    
    // MARK: - Move
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: String...) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: String...) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: [String]) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: [String]) async throws {
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

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
    
    private func path(for filename: String? = nil, at pathComponents: [String]) -> String {
        let workingDirectory = request.application.directory.workingDirectory + "DevelopFiles/"
        let directory = pathComponents.reduce(workingDirectory) { $0 + "\($1)/" }
        if let filename = filename {
            return directory + filename
        } else {
            return directory
        }
    }
    
    // MARK: - Download
    func download(_ filename: String, at pathComponents: String...) async throws -> Response {
        try await download(filename, at: pathComponents)
    }
    
    func download(_ filename: String, at pathComponents: [String]) async throws -> Response {
        let path = path(for: filename, at: pathComponents)
        guard FileManager.default.fileExists(atPath: path) else {
            throw Abort(.notFound)
        }
        return request.fileio.streamFile(at: path)
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: String...) async throws {
        try await upload(data, named: filename, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: [String]) async throws {
        let directoryPath = path(at: pathComponents)
        if !fileManager.fileExists(atPath: directoryPath) {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        let path = path(for: filename, at: pathComponents)
        return try await request.fileio.writeFile(data, at: path)
    }
    
    // MARK: - Delete
    func delete(_ filenames: [String], at pathComponents: String...) async throws {
        try await delete(filenames, at: pathComponents)
    }
    
    func delete(_ filenames: [String], at pathComponents: [String]) async throws {
        for filename in filenames {
            try await delete(filename, at: pathComponents)
        }
    }
    
    func delete(_ filename: String, at pathComponents: String...) async throws {
        try await delete(filename, at: pathComponents)
    }
    
    func delete(_ filename: String, at pathComponents: [String]) async throws {
        let filePath = path(for: filename, at: pathComponents)
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
    func move(_ filename: String, at srcPathComponents: String..., to dstPathComponents: String...) async throws {
        try await move(filename, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ filename: String, at srcPathComponents: [String], to dstPathComponents: String...) async throws {
        try await move(filename, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ filename: String, at srcPathComponents: String..., to dstPathComponents: [String]) async throws {
        try await move(filename, at: srcPathComponents, to: dstPathComponents)
    }
    
    func move(_ filename: String, at srcPathComponents: [String], to dstPathComponents: [String]) async throws {
        let srcPath = path(for: filename, at: srcPathComponents)
        let dstPath = path(for: filename, at: dstPathComponents)
        let dstDirectoryPath = path(at: dstPathComponents)
        
        if !fileManager.fileExists(atPath: dstDirectoryPath) {
            try fileManager.createDirectory(atPath: dstDirectoryPath, withIntermediateDirectories: true)
        }
        
        if fileManager.fileExists(atPath: srcPath) {
            try fileManager.moveItem(atPath: srcPath, toPath: dstPath)
        }
    }
}

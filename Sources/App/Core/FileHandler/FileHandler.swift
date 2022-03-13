//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

protocol FileHandler {
    func download(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Response>
    func download(_ fileName: String, at pathComponents: [String] ) -> EventLoopFuture<Response>
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void>
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String] ) -> EventLoopFuture<Void>
    
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void>
    func delete(_ fileNames: [String], at pathComponents: [String] ) -> EventLoopFuture<Void>
    func delete(_ fileName:  String,   at pathComponents: String...) -> EventLoopFuture<Void>
    func delete(_ fileName:  String,   at pathComponents: [String] ) -> EventLoopFuture<Void>
    
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: String...) -> EventLoopFuture<Void>
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: String...) -> EventLoopFuture<Void>
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: [String] ) -> EventLoopFuture<Void>
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: [String] ) -> EventLoopFuture<Void>
}

extension FileHandler {
    var pathBuilder: FilePathBuilder {
        FilePathBuilder()
    }
}

extension FileHandler {
    // Download
    func download(_ fileName: String, at pathComponents: String...) async throws -> Response {
        try await download(fileName, at: pathComponents)
    }
    func download(_ fileName: String, at pathComponents: [String] ) async throws -> Response {
        try await download(fileName, at: pathComponents).get()
    }
    
    // Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) async throws {
        try await upload(data, named: fileName, at: pathComponents)
    }
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String] ) async throws {
        try await upload(data, named: fileName, at: pathComponents).get()
    }
    
    func delete(_ fileNames: [String], at pathComponents: String...) async throws {
        try await delete(fileNames, at: pathComponents)
    }
    func delete(_ fileNames: [String], at pathComponents: [String] ) async throws {
        try await delete(fileNames, at: pathComponents).get()
    }
    func delete(_ fileName:  String,   at pathComponents: String...) async throws {
        try await delete(fileName, at: pathComponents)
    }
    func delete(_ fileName:  String,   at pathComponents: [String] ) async throws {
        try await delete(fileName, at: pathComponents).get()
    }
    
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: String...) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: String...) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: [String] ) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents)
    }
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: [String] ) async throws {
        try await move(fileName, at: srcPathComponents, to: dstPathComponents).get()
    }
}

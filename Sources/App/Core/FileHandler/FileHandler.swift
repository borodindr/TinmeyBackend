//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

protocol FileHandler {
    func download(_ fileName: String, at pathComponents: String...) async throws -> Response
    func download(_ fileName: String, at pathComponents: [String] ) async throws -> Response
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) async throws
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String] ) async throws
    
    func delete(_ fileNames: [String], at pathComponents: String...) async throws
    func delete(_ fileNames: [String], at pathComponents: [String] ) async throws
    func delete(_ fileName:  String,   at pathComponents: String...) async throws
    func delete(_ fileName:  String,   at pathComponents: [String] ) async throws
    
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: String...) async throws
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: String...) async throws
    func move(_ fileName: String, at srcPathComponents: String..., to dstPathComponents: [String] ) async throws
    func move(_ fileName: String, at srcPathComponents: [String],  to dstPathComponents: [String] ) async throws
}

extension FileHandler {
    var pathBuilder: FilePathBuilder {
        FilePathBuilder()
    }
}

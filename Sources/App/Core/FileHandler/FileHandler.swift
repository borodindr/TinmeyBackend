//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

protocol FileHandler {
    var request: Request { get }
    
    func download(_ filename: String, at pathComponents: String...) async throws -> Response
    func download(_ filename: String, at pathComponents: [String] ) async throws -> Response
    
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: String...) async throws
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: [String] ) async throws
    
    func delete(_ filenames: [String], at pathComponents: String...) async throws
    func delete(_ filenames: [String], at pathComponents: [String] ) async throws
    func delete(_ filename:  String,   at pathComponents: String...) async throws
    func delete(_ filename:  String,   at pathComponents: [String] ) async throws
    
    func move(_ filename: String, at srcPathComponents: String..., to dstPathComponents: String...) async throws
    func move(_ filename: String, at srcPathComponents: [String],  to dstPathComponents: String...) async throws
    func move(_ filename: String, at srcPathComponents: String..., to dstPathComponents: [String] ) async throws
    func move(_ filename: String, at srcPathComponents: [String],  to dstPathComponents: [String] ) async throws
}

extension FileHandler {
    var pathBuilder: FilePathBuilder {
        FilePathBuilder()
    }
}

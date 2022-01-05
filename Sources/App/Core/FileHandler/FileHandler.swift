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

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor
import SotoS3

struct S3FileHandler: FileHandler {
    let request: Request
    let bucketName: String
    
    private func objectRequestKey(for filename: String, at pathComponents: [String]) -> String {
        let location = pathComponents.reduce("upload/") { $0 + "\($1)/" }
        return location + filename
    }
    private var s3: S3 {
        request.aws.s3
    }
    
    
    // MARK: - Download
    func download(_ filename: String, at pathComponents: String...) async throws -> Response {
        try await download(filename, at: pathComponents)
    }
    
    func download(_ filename: String, at pathComponents: [String]) async throws -> Response {
        let key = objectRequestKey(for: filename, at: pathComponents)
        let request = S3.GetObjectRequest(bucket: bucketName, key: key)
        
        var headers: HTTPHeaders = [:]
        if let fileExtension = filename.components(separatedBy: ".").last,
           let type = HTTPMediaType.fileExtension(fileExtension) {
            headers.contentType = type
        }
        let response = Response(status: .ok, headers: headers)
        response.body = .init(stream: { stream in
            s3.getObjectStreaming(request, on: self.request.eventLoop) { buffer, eventLoop in
                stream.write(.buffer(buffer), promise: eventLoop.makePromise())
                return eventLoop.makeSucceededVoidFuture()
            }
            .whenComplete { result in
                switch result {
                case .failure(let error):
                    stream.write(.error(error), promise: nil)
                case .success:
                    stream.write(.end, promise: nil)
                }
            }
        })
        return response
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: String...) async throws {
        try await upload(data, named: filename, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named filename: String, at pathComponents: [String]) async throws {
        let key = objectRequestKey(for: filename, at: pathComponents)
        let request = S3.PutObjectRequest(body: .byteBuffer(data), bucket: bucketName, key: key)
        _ = try await s3.putObject(request)
    }
    
    // MARK: - Delete
    func delete(_ filename: String, at pathComponents: String...) async throws {
        try await delete(filename, at: pathComponents)
    }
    
    func delete(_ filename: String, at pathComponents: [String]) async throws {
        let key = objectRequestKey(for: filename, at: pathComponents)
        let request = S3.DeleteObjectRequest(bucket: bucketName, key: key)
        _ = try await  s3.deleteObject(request)
    }
    
    func delete(_ filenames: [String], at pathComponents: String...) async throws {
        try await delete(filenames, at: pathComponents)
    }
    
    func delete(_ filenames: [String], at pathComponents: [String]) async throws {
        guard !filenames.isEmpty else {
            return
        }
        let objects = filenames
            .map { objectRequestKey(for: $0, at: pathComponents) }
            .map { S3.ObjectIdentifier(key: $0) }
        let delete = S3.Delete(objects: objects)
        let request = S3.DeleteObjectsRequest(bucket: bucketName, delete: delete)
        _ = try await s3.deleteObjects(request)
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
        try await copy(filename, at: srcPathComponents, to: dstPathComponents)
        try await delete(filename, at: srcPathComponents)
    }
    
    func copy(_ filename: String, at srcPathComponents: [String], to dstPathComponents: [String]) async throws {
        let srcKey = objectRequestKey(for: filename, at: srcPathComponents)
        let dstKey = objectRequestKey(for: filename, at: dstPathComponents)
        let copyRequest = S3.CopyObjectRequest(bucket: bucketName,
                                               copySource: "\(bucketName)/\(srcKey)",
                                               key: dstKey)
        _ = try await s3.copyObject(copyRequest)
    }
}

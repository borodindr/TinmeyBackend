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
    
    private func objectRequestKey(for fileName: String, at pathComponents: [String]) -> String {
        let location = pathComponents.reduce("upload/") { $0 + "\($1)/" }
        return location + fileName
    }
    private var s3: S3 {
        request.aws.s3
    }
    
    
    // MARK: - Download
    func download(_ fileName: String, at pathComponents: String...) async throws -> Response {
        try await download(fileName, at: pathComponents)
    }
    
    func download(_ fileName: String, at pathComponents: [String]) async throws -> Response {
        let headOutput = try await getFileMetadata(for: fileName, at: pathComponents)
        if let clientETag = request.headers.first(name: .ifNoneMatch),
           let fileETag = headOutput.eTag,
           fileETag == clientETag {
            return Response(status: .notModified)
        } else {
            return try await getFile(fileName, at: pathComponents, eTag: headOutput.eTag)
        }
    }
    
    private func getFileMetadata(for fileName: String, at pathComponents: [String]) async throws -> S3.HeadObjectOutput {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.HeadObjectRequest(bucket: bucketName, key: key)
        return try await s3.headObject(request)
    }
    
    private func getFile(_ fileName: String, at pathComponents: [String], eTag: String?) async throws -> Response {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.GetObjectRequest(bucket: bucketName, key: key)
        
        var headers: HTTPHeaders = [:]
        if let eTag = eTag {
            headers.replaceOrAdd(name: .eTag, value: eTag)
        }
        if let fileExtension = fileName.components(separatedBy: ".").last,
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
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) async throws {
        try await upload(data, named: fileName, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String]) async throws {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.PutObjectRequest(body: .byteBuffer(data), bucket: bucketName, key: key)
        _ = try await s3.putObject(request)
    }
    
    // MARK: - Delete
    func delete(_ fileName: String, at pathComponents: String...) async throws {
        try await delete(fileName, at: pathComponents)
    }
    
    func delete(_ fileName: String, at pathComponents: [String]) async throws {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.DeleteObjectRequest(bucket: bucketName, key: key)
        _ = try await  s3.deleteObject(request)
    }
    
    func delete(_ fileNames: [String], at pathComponents: String...) async throws {
        try await delete(fileNames, at: pathComponents)
    }
    
    func delete(_ fileNames: [String], at pathComponents: [String]) async throws {
        guard !fileNames.isEmpty else {
            return
        }
        let objects = fileNames
            .map { objectRequestKey(for: $0, at: pathComponents) }
            .map { S3.ObjectIdentifier(key: $0) }
        let delete = S3.Delete(objects: objects)
        let request = S3.DeleteObjectsRequest(bucket: bucketName, delete: delete)
        _ = try await s3.deleteObjects(request)
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
        try await copy(fileName, at: srcPathComponents, to: dstPathComponents)
        try await delete(fileName, at: srcPathComponents)
    }
    
    func copy(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: [String]) async throws {
        let srcKey = objectRequestKey(for: fileName, at: srcPathComponents)
        let dstKey = objectRequestKey(for: fileName, at: dstPathComponents)
        let copyRequest = S3.CopyObjectRequest(bucket: bucketName,
                                               copySource: "\(bucketName)/\(srcKey)",
                                               key: dstKey)
        _ = try await s3.copyObject(copyRequest)
    }
}

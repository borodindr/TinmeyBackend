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
    func download(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Response> {
        guard let clientETag = request.headers.first(name: .ifNoneMatch) else {
            return getFile(fileName, at: pathComponents)
        }
        return getFileMetadata(for: fileName, at: pathComponents)
            .flatMap { headOutput in
                if let fileETag = headOutput.eTag, fileETag == clientETag {
                    return request.eventLoop.future(Response(status: .notModified))
                } else {
                    return getFile(fileName, at: pathComponents)
                }
            }
    }
    
    private func getFileMetadata(for fileName: String, at pathComponents: [String]) -> EventLoopFuture<S3.HeadObjectOutput> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.HeadObjectRequest(bucket: bucketName, key: key)
        return s3.headObject(request)
    }
    
    private func getFile(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Response> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.GetObjectRequest(bucket: bucketName, key: key)
        return s3.getObject(request)
            .map { output in
                guard let buffer = output.body?.asByteBuffer() else {
                    return Response(status: .noContent)
                }
                var headers: HTTPHeaders = [:]
                if let eTag = output.eTag {
                    headers.replaceOrAdd(name: .eTag, value: eTag)
                }
                if let fileExtension = fileName.components(separatedBy: ".").last,
                   let type = HTTPMediaType.fileExtension(fileExtension) {
                    headers.contentType = type
                }
                
                return Response(status: .ok, headers: headers, body: .init(buffer: buffer))
            }
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.PutObjectRequest(body: .byteBuffer(data), bucket: bucketName, key: key)
        return s3.putObject(request)
            .map { _ in }
    }
    
    // MARK: - Delete
    func delete(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.DeleteObjectRequest(bucket: bucketName, key: key)
        return s3.deleteObject(request)
            .map { _ in }
    }
    
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void> {
        guard !fileNames.isEmpty else {
            return s3.eventLoopGroup.next().makeSucceededVoidFuture()
        }
        let objects = fileNames
            .map { objectRequestKey(for: $0, at: pathComponents) }
            .map { S3.ObjectIdentifier(key: $0) }
        let delete = S3.Delete(objects: objects)
        let request = S3.DeleteObjectsRequest(bucket: bucketName, delete: delete)
        return s3.deleteObjects(request)
            .map { _ in }
    }
}

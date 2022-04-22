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
        download(fileName, at: pathComponents)
    }
    
    func download(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Response> {
        getFileMetadata(for: fileName, at: pathComponents)
            .flatMap { headOutput in
                if let clientETag = request.headers.first(name: .ifNoneMatch),
                   let fileETag = headOutput.eTag,
                   fileETag == clientETag {
                    return request.eventLoop.future(Response(status: .notModified))
                } else {
                    return getFile(fileName, at: pathComponents, eTag: headOutput.eTag)
                }
            }
    }
    
    private func getFileMetadata(for fileName: String, at pathComponents: [String]) -> EventLoopFuture<S3.HeadObjectOutput> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.HeadObjectRequest(bucket: bucketName, key: key)
        return s3.headObject(request)
    }
    
    private func getFile(_ fileName: String, at pathComponents: [String], eTag: String?) -> EventLoopFuture<Response> {
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
        return self.request.eventLoop.makeSucceededFuture(response)
    }
    
    // MARK: - Upload
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        upload(data, named: fileName, at: pathComponents)
    }
    
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: [String]) -> EventLoopFuture<Void> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.PutObjectRequest(body: .byteBuffer(data), bucket: bucketName, key: key)
        return s3.putObject(request)
            .map { _ in }
    }
    
    // MARK: - Delete
    func delete(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        delete(fileName, at: pathComponents)
    }
    
    func delete(_ fileName: String, at pathComponents: [String]) -> EventLoopFuture<Void> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = S3.DeleteObjectRequest(bucket: bucketName, key: key)
        return s3.deleteObject(request)
            .map { _ in }
    }
    
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void> {
        delete(fileNames, at: pathComponents)
    }
    
    func delete(_ fileNames: [String], at pathComponents: [String]) -> EventLoopFuture<Void> {
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
        copy(fileName, at: srcPathComponents, to: dstPathComponents)
            .flatMap { _ in
                delete(fileName, at: srcPathComponents)
            }
            .map { _ in }
    }
    
    func copy(_ fileName: String, at srcPathComponents: [String], to dstPathComponents: [String]) -> EventLoopFuture<Void> {
        let srcKey = objectRequestKey(for: fileName, at: srcPathComponents)
        let dstKey = objectRequestKey(for: fileName, at: dstPathComponents)
        let copyRequest = S3.CopyObjectRequest(bucket: bucketName,
                                               copySource: "\(bucketName)/\(srcKey)",
                                               key: dstKey)
        
        return s3.copyObject(copyRequest)
            .map { _ in }
    }
}

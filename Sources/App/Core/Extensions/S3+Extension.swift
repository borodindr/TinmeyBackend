//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.10.2021.
//

import Vapor
import SotoS3

extension S3 {
    private var bucketName: String {
        "tinmey-website"
    }
    
    private func objectRequestKey(for fileName: String, at pathComponents: [String]) -> String {
        let location = pathComponents.reduce("upload/") { $0 + "\($1)/" }
        return location + fileName
    }
}

// MARK: - Download
extension S3 {
    func download(_ fileName: String, at pathComponents: String...) -> EventLoopFuture<Response> {
        // TODO: Add cache
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = GetObjectRequest(bucket: bucketName, key: key)
        return getObject(request)
            .map { output in
                guard let buffer = output.body?.asByteBuffer() else {
                    return Response(status: .noContent)
                }
                return Response(body: .init(buffer: buffer))
            }
    }
    
}

// MARK: - Upload
extension S3 {
    func upload(_ data: ByteBuffer, named fileName: String, at pathComponents: String...) -> EventLoopFuture<Void> {
        let key = objectRequestKey(for: fileName, at: pathComponents)
        let request = PutObjectRequest(body: .byteBuffer(data), bucket: bucketName, key: key)
        return putObject(request)
            .map { _ in }
    }
}

// MARK: - Delete
extension S3 {
    func delete(_ fileNames: [String], at pathComponents: String...) -> EventLoopFuture<Void> {
        guard !fileNames.isEmpty else {
            return eventLoopGroup.next().makeSucceededVoidFuture()
        }
        let objects = fileNames
            .map { objectRequestKey(for: $0, at: pathComponents) }
            .map { ObjectIdentifier(key: $0) }
        let delete = Delete(objects: objects)
        let request = DeleteObjectsRequest(bucket: bucketName, delete: delete)
        return deleteObjects(request)
            .map { _ in }
    }
}

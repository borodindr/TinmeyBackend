//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

extension Request {
    var fileHandler: FileHandler {
        switch application.environment {
        case .production:
            return S3FileHandler(request: self, bucketName: "tinmey-website")
        case .staging:
            return S3FileHandler(request: self, bucketName: "tinmey-website-test")
        default:
            return LocalFileHandler(request: self)
        }
    }
}

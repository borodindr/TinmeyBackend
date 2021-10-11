//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 11.10.2021.
//

import Vapor

struct ImageUploadData: Content {
    var picture: File
}

extension ImageUploadData {
    private var availableExtensions: [String] {
        ["png", "jpg", "jpeg"]
    }
    
    func validExtension() throws -> String {
        guard let fileExtension = picture.extension,
              availableExtensions.contains(fileExtension.lowercased()) else {
            throw Abort(.badRequest, reason: "File extension should be png, jpg or jpeg")
        }
        return fileExtension
    }
}

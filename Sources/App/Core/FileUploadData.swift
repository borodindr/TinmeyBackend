//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 11.10.2021.
//

import Vapor

struct FileUploadData: Content {
    var file: File
}

extension FileUploadData {
    private var imageExtensions: [String] {
        ["png", "jpg", "jpeg", "gif"]
    }
    
    private func validExtension(_ availableExtensions: [String]) throws -> String {
        guard let fileExtension = file.extension,
              availableExtensions.contains(fileExtension.lowercased()) else {
            throw Abort(.badRequest, reason: "File extension should be \(availableExtensions.joined(separator: ", "))")
        }
        return fileExtension
    }
    
    func validateExtension(_ availableExtensions: [String]) throws {
        _ = try validExtension(availableExtensions)
    }
    
    func validImageExtension() throws -> String {
        try validExtension(imageExtensions)
    }
    
    func validateImageExtension() throws {
        try validateExtension(imageExtensions)
    }
}

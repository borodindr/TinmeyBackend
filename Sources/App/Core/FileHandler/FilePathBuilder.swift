//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Foundation

struct FilePathBuilder {
    private let workImagesFolder = "WorkImages"
    private let layoutImagesFolder = "LayoutImages"
    
    func workImagePath(for image: WorkImage) throws -> [String] {
        [workImagesFolder,
         image.$work.id.uuidString,
         try image.requireID().uuidString]
    }
    
    func layoutImagePath(for image: LayoutImage) throws -> [String] {
        [layoutImagesFolder,
         image.$layout.id.uuidString,
         try image.requireID().uuidString]
    }
    
    func path(for attachment: Attachment) throws -> [String] {
        ["attachments", try attachment.requireID().uuidString]
    }
}

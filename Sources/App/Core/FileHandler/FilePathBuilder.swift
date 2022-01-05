//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Foundation

struct FilePathBuilder {
    private let workImagesFolder = "WorkImages"
    
    func workImagePath(for image: WorkImage) throws -> [String] {
        [workImagesFolder,
         image.$work.id.uuidString,
         try image.requireID().uuidString]
    }
}

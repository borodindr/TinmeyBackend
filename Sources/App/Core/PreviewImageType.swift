//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 11.10.2021.
//

import Vapor

enum ImageType: String, CaseIterable {
    case firstImage, secondImage
    
    var description: String {
        switch self {
        case .firstImage:
            return "first image"
        case .secondImage:
            return "second image"
        }
    }
    
    static func detect(from req: Request) throws -> ImageType {
        guard let imageTypeRawValue = req.parameters.get("imageType"),
              let imageType = ImageType(rawValue: imageTypeRawValue) else {
            throw Abort(.badRequest, reason: "Wrong image type")
        }
        
        return imageType
    }
    
    func imageName(in container: TwoImagesContainer) throws -> String {
        let name: String?
        switch self {
        case .firstImage:
            name = container.firstImageName
        case .secondImage:
            name = container.secondImageName
        }
        
        guard let imageName = name else {
            let reason = "\(type(of: container)) has no \(description)."
            let error = Abort(.notFound, reason: reason)
            throw error
        }
        return imageName
    }
}

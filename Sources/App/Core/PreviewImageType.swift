//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 11.10.2021.
//

import Foundation

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
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

struct LayoutsContext: WebsiteContext {
    let meta: WebsiteMeta
    let header = Header()
    let layouts: [Layout]
}

extension LayoutsContext {
    struct Layout: Encodable {
        init(
            title: String,
            description: String,
            imagePaths: [String]
        ) {
            self.title = title.multilineHTML()
            self.description = description.multilineHTML()
            self.imagePaths = imagePaths
        }
        
        let title: String
        let description: String
        let imagePaths: [String]
    }
}

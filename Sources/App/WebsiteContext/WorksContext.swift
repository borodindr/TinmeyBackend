//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

struct WorksContext: WebsiteContext {
    let meta: WebsiteMeta
    let header: TaggedHeader
    let works: [Work]
}

extension WorksContext {
    struct Work: Encodable {
        init(
            title: String,
            description: String,
            coverPath: String,
            otherImagesPaths: [String],
            tags: [String]
        ) {
            self.title = title.multilineHTML()
            self.description = description.multilineHTML()
            self.coverPath = coverPath
            self.otherImagesPaths = otherImagesPaths
            self.tags = tags
        }
        
        let title: String
        let description: String
        let coverPath: String
        let otherImagesPaths: [String]
        let tags: [String]
    }
}

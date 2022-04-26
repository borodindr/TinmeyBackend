//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

struct WebsiteMeta: Encodable {
    let canonical: String = "https://tinmey.com"
    let siteName: String = "Tinmey Design"
    let title: String
    let author: String = "Katya Tinmey"
    let description: String = "I'm Katya Tinmey. Graphic designer."
    let email: String = "katya@tinmey.com"
    
    init(title: String) {
        self.title = title
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

struct TaggedHeader: HeaderProvider {
    let availableTags: [String]
    let selectedTag: String?
    
    init(
        availableTags: [String],
        selectedTag: String?
    ) {
        self.availableTags = availableTags
        self.selectedTag = selectedTag
    }
}

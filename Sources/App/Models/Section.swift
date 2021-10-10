//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Fluent
import Vapor

final class Section: Model, Content {
    static var schema = "section"
    
    @ID
    var id: UUID?
    
//    @Enum(key: "section_type")
//    var sectionType: String
    
    @Field(key: "preview_title")
    var previewTitle: String
    
    @Field(key: "preview_subtitle")
    var previewSubtitle: String
    
    
    
}

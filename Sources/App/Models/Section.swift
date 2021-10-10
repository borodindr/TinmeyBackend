//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Fluent
import Vapor

final class Section: Model, Content {
    static var schema = "sections"
    
    @ID
    var id: UUID?
    
    @Enum(key: "type")
    var type: SectionType
    
    @Field(key: "preview_title")
    var previewTitle: String
    
    @Field(key: "preview_subtitle")
    var previewSubtitle: String
    
    @OptionalField(key: "first_image_name")
    var firstImageName: String?
    
    @OptionalField(key: "second_image_name")
    var secondImageName: String?
    
    init() { }
    
    init(
        id: UUID? = nil,
        type: SectionType,
        previewTitle: String,
        previewSubtitle: String,
        firstImageName: String? = nil,
        secondImageName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.previewTitle = previewTitle
        self.previewSubtitle = previewSubtitle
        self.firstImageName = firstImageName
        self.secondImageName = secondImageName
    }
}

extension Section {
    enum SectionType: String, Content {
        case covers
        case layouts
        case about
    }
}

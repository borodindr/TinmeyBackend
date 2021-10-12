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
    
    @Field(key: "sort_index")
    var sortIndex: Int
    
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
        sortIndex: Int,
        type: SectionType,
        previewTitle: String,
        previewSubtitle: String,
        firstImageName: String? = nil,
        secondImageName: String? = nil
    ) {
        self.id = id
        self.sortIndex = sortIndex
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
        
        static func detect(from req: Request) throws -> SectionType {
            guard let sectionTypeRawValue = req.parameters.get("sectionType"),
                  let sectionType = SectionType(rawValue: sectionTypeRawValue) else {
                throw Abort(.badRequest, reason: "Wrong section type")
            }
            
            return sectionType
        }
    }
}

extension Section: TwoImagesContainer { }

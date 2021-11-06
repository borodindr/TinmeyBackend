//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Fluent
import Vapor

final class Section: Model, Content {
    static var schema = v2021_11_04.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_11_04.sortIndex)
    var sortIndex: Int
    
    @Enum(key: v2021_11_04.type)
    var type: SectionType
    
    @Field(key: v2021_11_04.previewTitle)
    var previewTitle: String
    
    @Field(key: v2021_11_04.previewSubtitle)
    var previewSubtitle: String
    
    @Field(key: v2021_11_04.sectionSubtitle)
    var sectionSubtitle: String
    
    @OptionalField(key: v2021_11_04.firstImageName)
    var firstImageName: String?
    
    @OptionalField(key: v2021_11_04.secondImageName)
    var secondImageName: String?
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        type: SectionType,
        previewTitle: String,
        previewSubtitle: String,
        sectionSubtitle: String,
        firstImageName: String? = nil,
        secondImageName: String? = nil
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.type = type
        self.previewTitle = previewTitle
        self.previewSubtitle = previewSubtitle
        self.sectionSubtitle = sectionSubtitle
        self.firstImageName = firstImageName
        self.secondImageName = secondImageName
    }
}

extension Section {
    enum SectionType: String, Content {
        case covers
        case layouts
        
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

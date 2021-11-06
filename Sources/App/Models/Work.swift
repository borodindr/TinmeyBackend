//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Vapor
import Fluent

final class Work: Model, Content {
    static var schema = v2021_11_04.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_11_04.sortIndex)
    var sortIndex: Int
    
    @Timestamp(key: v2021_11_04.createdAt, on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: v2021_11_04.updatedAt, on: .update, format: .iso8601)
    var updatedAt: Date?
    
    @Enum(key: v2021_11_04.type)
    var type: WorkType
    
    @Field(key: v2021_11_04.title)
    var title: String
    
    @Field(key: v2021_11_04.description)
    var description: String
    
    @Enum(key: v2021_11_04.layout)
    var layout: LayoutType
    
    @OptionalField(key: v2021_11_04.firstImageName)
    var firstImageName: String?
    
    @OptionalField(key: v2021_11_04.seeMoreLink)
    var secondImageName: String?
    
    @OptionalField(key: v2021_11_04.seeMoreLink)
    var seeMoreLink: String?
    
    @Siblings(through: WorkTagPivot.self, from: \.$work, to: \.$tag)
    var tags: [Tag]
    
    // comments
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        type: WorkType,
        title: String,
        description: String,
        layout: LayoutType,
        firstImageName: String? = nil,
        secondImageName: String? = nil,
        seeMoreLink: String?
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.type = type
        self.title = title
        self.description = description
        self.layout = layout
        self.firstImageName = firstImageName
        self.secondImageName = secondImageName
        self.seeMoreLink = seeMoreLink
    }
}

extension Work {
    enum LayoutType: String, Content {
        case leftBody
        case middleBody
        case rightBody
        case leftLargeBody
        case rightLargeBody
    }
    
    enum WorkType: String, Content {
        case cover
        case layout
    }
}

extension Work: TwoImagesContainer { }

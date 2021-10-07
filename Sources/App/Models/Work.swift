//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Vapor
import Fluent

final class Work: Model, Content {
    static var schema = "works"
    
    @ID
    var id: UUID?
    
    @Field(key: "sort_index")
    var sortIndex: Int
    
    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?
    
    @Enum(key: "type")
    var type: WorkType
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Enum(key: "layout")
    var layout: WorkLayoutType
    
    @OptionalField(key: "first_image_name")
    var firstImageName: String?
    
    @OptionalField(key: "second_image_name")
    var secondImageName: String?
    
    @OptionalField(key: "see_more_link")
    var seeMoreLink: String?
    
    // tags
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
        layout: WorkLayoutType,
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



struct Input {
    var file: File
}

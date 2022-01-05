//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Fluent

struct CreateWork: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database
            .enum(Work.WorkType.v2021_11_04.enumName)
            .case(Work.WorkType.v2021_11_04.cover)
            .case(Work.WorkType.v2021_11_04.layout)
            .create()
            .flatMap { workType in
                database
                    .enum(Work.LayoutType.v2021_11_04.enumName)
                    .case(Work.LayoutType.v2021_11_04.leftBody)
                    .case(Work.LayoutType.v2021_11_04.middleBody)
                    .case(Work.LayoutType.v2021_11_04.rightBody)
                    .case(Work.LayoutType.v2021_11_04.leftLargeBody)
                    .case(Work.LayoutType.v2021_11_04.rightLargeBody)
                    .create()
                    .flatMap { workLayoutType in
                        database.schema(Work.v2021_11_04.schemaName)
                            .id()
                            .field(Work.v2021_11_04.sortIndex, .int, .required)
                            .field(Work.v2021_11_04.createdAt, .string)
                            .field(Work.v2021_11_04.updatedAt, .string)
                            .field(Work.v2021_11_04.type, workType, .required)
                            .field(Work.v2021_11_04.title, .string, .required)
                            .field(Work.v2021_11_04.description, .string, .required)
                            .field(Work.v2021_11_04.layout, workLayoutType, .required)
                            .field(Work.v2021_11_04.firstImageName, .string)
                            .field(Work.v2021_11_04.secondImageName, .string)
                            .field(Work.v2021_11_04.seeMoreLink, .string)
                            .create()
                    }
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Work.v2021_11_04.schemaName).delete()
    }
}

extension Work {
    enum v2021_11_04 {
        static let schemaName = "works"
        static let id = FieldKey(stringLiteral: "id")
        static let sortIndex = FieldKey(stringLiteral: "sort_index")
        static let createdAt = FieldKey(stringLiteral: "created_at")
        static let updatedAt = FieldKey(stringLiteral: "updated_at")
        static let type = FieldKey(stringLiteral: "type")
        static let title = FieldKey(stringLiteral: "title")
        static let description = FieldKey(stringLiteral: "description")
        static let layout = FieldKey(stringLiteral: "layout")
        static let firstImageName = FieldKey(stringLiteral: "first_image_name")
        static let secondImageName = FieldKey(stringLiteral: "second_image_name")
        static let seeMoreLink = FieldKey(stringLiteral: "see_more_link")
    }
}

extension Work {
    enum v2021_12_30 {
        static let bodyIndex = FieldKey(stringLiteral: "body_index")
    }
}

extension Work.WorkType {
    enum v2021_11_04 {
        static let enumName = "work_type"
        static let cover = "cover"
        static let layout = "layout"
    }
}

extension Work.LayoutType {
    enum v2021_11_04 {
        static var enumName = "work_layout"
        static let leftBody = "leftBody"
        static let middleBody = "middleBody"
        static let rightBody = "rightBody"
        static let leftLargeBody = "leftLargeBody"
        static let rightLargeBody = "rightLargeBody"
        
    }
}

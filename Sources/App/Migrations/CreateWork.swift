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
            .enum(Work.WorkType.name)
            .case(Work.WorkType.cover.rawValue)
            .case(Work.WorkType.layout.rawValue)
            .create()
            .flatMap { workType in
                database
                    .enum(Work.LayoutType.name)
                    .case(Work.LayoutType.leftBody.rawValue)
                    .case(Work.LayoutType.middleBody.rawValue)
                    .case(Work.LayoutType.rightBody.rawValue)
                    .case(Work.LayoutType.leftLargeBody.rawValue)
                    .case(Work.LayoutType.rightLargeBody.rawValue)
                    .create()
                    .flatMap { workLayoutType in
                        database.schema(Work.schema)
                            .id()
                            .field("sort_index", .int, .required)
                            .field("created_at", .string)
                            .field("updated_at", .string)
                            .field("type", workType, .required)
                            .field("title", .string, .required)
                            .field("description", .string, .required)
                            .field("layout", workLayoutType, .required)
                            .field("first_image_name", .string)
                            .field("second_image_name", .string)
                            .field("see_more_link", .string)
                            .create()
                    }
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Work.schema).delete()
    }
}

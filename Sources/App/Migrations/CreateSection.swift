//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Fluent
import Vapor

struct CreateSection: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database
            .enum("section_type")
            .case(Section.SectionType.covers.rawValue)
            .case(Section.SectionType.layouts.rawValue)
            .create()
            .flatMap { sectionType in
                database
                    .schema("sections")
                    .id()
                    .field("sort_index", .int, .required)
                    .field("type", sectionType, .required)
                    .field("preview_title", .string, .required)
                    .field("preview_subtitle", .string, .required)
                    .field("section_subtitle", .string, .required)
                    .field("first_image_name", .string)
                    .field("second_image_name", .string)
                    .create()
            }
            
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("sections").delete()
    }
}

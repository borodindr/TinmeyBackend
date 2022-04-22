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
            .enum(Section.SectionType.v2021_11_04.enumName)
            .case(Section.SectionType.v2021_11_04.covers)
            .case(Section.SectionType.v2021_11_04.layouts)
            .create()
            .flatMap { sectionType in
                database
                    .schema(Section.v2021_11_04.schemaName)
                    .id()
                    .field(Section.v2021_11_04.sortIndex, .int, .required)
                    .field(Section.v2021_11_04.type, sectionType, .required)
                    .field(Section.v2021_11_04.previewTitle, .string, .required)
                    .field(Section.v2021_11_04.previewSubtitle, .string, .required)
                    .field(Section.v2021_11_04.sectionSubtitle, .string, .required)
                    .field(Section.v2021_11_04.firstImageName, .string)
                    .field(Section.v2021_11_04.secondImageName, .string)
                    .create()
            }
            
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Section.v2021_11_04.schemaName).delete()
    }
}

struct Section {
    enum v2021_11_04 {
        static let schemaName = "sections"
        static let id = FieldKey(stringLiteral: "id")
        static let sortIndex = FieldKey(stringLiteral: "sort_index")
        static let type = FieldKey(stringLiteral: "type")
        static let previewTitle = FieldKey(stringLiteral: "preview_title")
        static let previewSubtitle = FieldKey(stringLiteral: "preview_subtitle")
        static let sectionSubtitle = FieldKey(stringLiteral: "section_subtitle")
        static let firstImageName = FieldKey(stringLiteral: "first_image_name")
        static let secondImageName = FieldKey(stringLiteral: "second_image_name")
    }
}

extension Section {
    enum SectionType {
        enum v2021_11_04 {
            static let enumName = "section_type"
            static let covers = "covers"
            static let layouts = "layouts"
        }
    }
}

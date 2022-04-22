//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.12.2021.
//

import Fluent

struct CreateWorkImage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(WorkImage.v2021_12_19.schemaName)
            .id()
            .field(WorkImage.v2021_12_19.sortIndex, .int, .required)
            .field(WorkImage.v2021_12_19.name, .string)
            .field(
                WorkImage.v2021_12_19.workID,
                .uuid,
                .references(
                    Work.v2021_11_04.schemaName,
                    Work.v2021_11_04.id,
                    onDelete: .cascade
                )
            )
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(WorkImage.v2021_12_19.schemaName)
            .delete()
    }
}

extension WorkImage {
    enum v2021_12_19 {
        static let schemaName = "work_images"
        static let id = FieldKey(stringLiteral: "id")
        static let sortIndex = FieldKey(stringLiteral: "sort_index")
        static let name = FieldKey(stringLiteral: "name")
        static let workID = FieldKey(stringLiteral: "workID")
    }
}

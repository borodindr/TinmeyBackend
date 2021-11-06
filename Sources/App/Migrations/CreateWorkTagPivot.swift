//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Fluent

struct CreateWorkTagPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(WorkTagPivot.v2021_11_04.schemaName)
            .id()
            .field(
                WorkTagPivot.v2021_11_04.workID,
                .uuid,
                .required,
                .references(
                    Work.v2021_11_04.schemaName,
                    Work.v2021_11_04.id,
                    onDelete: .cascade
                )
            )
            .field(
                WorkTagPivot.v2021_11_04.tagID,
                .uuid,
                .required,
                .references(
                    Tag.v2021_11_04.schemeName,
                    Tag.v2021_11_04.id,
                    onDelete: .cascade
                )
            )
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(WorkTagPivot.v2021_11_04.schemaName).delete()
    }
}

extension WorkTagPivot {
    enum v2021_11_04 {
        static let schemaName = "work-tag-pivot"
        static let id = FieldKey(stringLiteral: "id")
        static let workID = FieldKey(stringLiteral: "workID")
        static let tagID = FieldKey(stringLiteral: "tagID")
    }
}

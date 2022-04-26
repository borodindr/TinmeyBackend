//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.04.2022.
//

import Fluent

struct AddAttachmentToWorkImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(WorkImage.v2021_12_19.schemaName)
            .field(
                WorkImage.v2022_04_21.attachmentID,
                .uuid,
                .references(
                    Attachment.v2022_04_21.schemaName,
                    Attachment.v2022_04_21.id,
                    onDelete: .cascade
                )
            )
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(WorkImage.v2021_12_19.schemaName)
            .deleteField(WorkImage.v2022_04_21.attachmentID)
            .update()
    }
}

extension WorkImage {
    enum v2022_04_21 {
        static let attachmentID = FieldKey(stringLiteral: "attachment_id")
    }
}

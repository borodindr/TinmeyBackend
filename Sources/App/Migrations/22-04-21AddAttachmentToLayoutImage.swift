//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.04.2022.
//

import Fluent

struct AddAttachmentToLayoutImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(LayoutImage.v2022_04_13.schemaName)
            .field(
                LayoutImage.v2022_04_21.attachmentID,
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
        try await database.schema(LayoutImage.v2022_04_13.schemaName)
            .deleteField(LayoutImage.v2022_04_21.attachmentID)
            .update()
    }
}

extension LayoutImage {
    enum v2022_04_21 {
        static let attachmentID = FieldKey(stringLiteral: "attachment_id")
    }
}

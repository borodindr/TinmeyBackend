//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Foundation

struct FilePathBuilder {
    func path(for attachment: Attachment) throws -> [String] {
        ["attachments", try attachment.requireID().uuidString]
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 22.12.2021.
//

import Vapor
import Fluent
import TinmeyCore

extension WorkAPIModel.Image {
    init(_ workImage: WorkImage) throws {
        let path: String?
        if let attachmentID = try workImage.attachment?.requireID() {
            let directoryPath = ["api", "works", "attachment", attachmentID.uuidString].joined(separator: "/")
            path = "\(directoryPath)"
        } else {
            path = nil
        }
        self.init(
            id: try workImage.requireID(),
            // TODO: Change name to path
            path: path
        )
    }
}

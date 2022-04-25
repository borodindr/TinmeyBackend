//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.04.2022.
//

import Vapor
import Fluent
import TinmeyCore

extension LayoutAPIModel.Image {
    init(_ layoutImage: LayoutImage) throws {
        let path: String?
        if let attachmentID = try layoutImage.attachment?.requireID() {
            let directoryPath = ["api", "layouts", "attachment", attachmentID.uuidString].joined(separator: "/")
            path = "\(directoryPath)"
        } else {
            path = nil
        }
        self.init(
            id: try layoutImage.requireID(),
            // TODO: Change name to path
            path: path
        )
    }
}

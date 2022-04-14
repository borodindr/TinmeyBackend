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
        if workImage.name != nil {
            let directoryPath = ["api", "works", "images", try workImage.requireID().uuidString].joined(separator: "/")
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

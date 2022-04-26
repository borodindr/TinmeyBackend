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
        self.init(
            id: try workImage.requireID(),
            path: try workImage.attachment?.downloadPath()
        )
    }
}

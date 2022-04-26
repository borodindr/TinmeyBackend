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
        self.init(
            id: try layoutImage.requireID(),
            path: try layoutImage.attachment?.downloadPath()
        )
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 26.04.2022.
//

import Vapor

extension Request {
    var attachmentHandler: AttachmentHandler {
        return AttachmentHandler(fileHandler: fileHandler)
    }
}

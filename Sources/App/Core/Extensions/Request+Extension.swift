//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 18.12.2021.
//

import Vapor

extension Request {
    var isApiRequest: Bool {
        url.path.split(separator: "/").first == "api"
    }
}

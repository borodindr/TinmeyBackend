//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 06.11.2021.
//

import Vapor

extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 04.10.2021.
//

import Foundation
import Vapor
import Fluent
import TinmeyCore

typealias WorkLayoutType = WorkAPIModel.LayoutTypeAPIModel

extension WorkLayoutType {
    static var name = "work_layout"
}
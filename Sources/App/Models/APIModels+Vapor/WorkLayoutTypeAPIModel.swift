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

//typealias WorkLayoutType = WorkAPIModel.LayoutTypeAPIModel
//
extension WorkAPIModel.LayoutTypeAPIModel {
    var forSchema: Work.LayoutType {
        switch self {
        case .leftBody:
            return .leftBody
        case .middleBody:
            return .middleBody
        case .rightBody:
            return .rightBody
        case .leftLargeBody:
            return .leftLargeBody
        case .rightLargeBody:
            return .rightLargeBody
        }
    }
}

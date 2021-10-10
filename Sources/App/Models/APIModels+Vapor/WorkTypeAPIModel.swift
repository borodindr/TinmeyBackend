//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 27.08.2021.
//

import Foundation
import TinmeyCore

extension WorkTypeAPIModel {
    var forSchema: Work.WorkType {
        switch self {
        case .cover:
            return .cover
        case .layout:
            return .layout
        }
    }
}

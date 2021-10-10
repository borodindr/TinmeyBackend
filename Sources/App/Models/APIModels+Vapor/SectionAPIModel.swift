//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import TinmeyCore
import Fluent
import Vapor

extension SectionAPIModel: Content { }
extension SectionAPIModel.SectionType: Content { }

extension SectionAPIModel {
    init(_ section: Section) {
        self.init(
            type: section.type.asAPIModel,
            preview: Preview(
                title: section.previewTitle,
                subtitle: section.previewSubtitle
            )
        )
    }
}

extension Section.SectionType {
    var asAPIModel: SectionAPIModel.SectionType {
        switch self {
        case .covers:
            return .covers
        case .layouts:
            return .layouts
        case .about:
            return .about
        }
    }
}

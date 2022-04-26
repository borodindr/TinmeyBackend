//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.04.2022.
//

import TinmeyCore
import Vapor
import Fluent

extension LayoutAPIModel: Content { }

extension LayoutAPIModel.Create {
    func makeLayout(sortIndex: Int) -> Layout {
        Layout(
            sortIndex: sortIndex,
            title: title,
            description: description
        )
    }
}

extension LayoutAPIModel.Create {
    func create(on database: Database) async throws -> Layout {
        let query = Layout.query(on: database).sort(\.$sortIndex, .descending)
        let lastLayout = try await query.first()
        let sortIndex: Int
        if let lastIndex = lastLayout?.sortIndex {
            sortIndex = lastIndex + 1
        } else {
            sortIndex = 0
        }
        let layout = makeLayout(sortIndex: sortIndex)
        try await layout.save(on: database)
        try await LayoutImage.add(images, to: layout, on: database)
        return layout
    }
}

extension Layout {
    func convertToAPIModel(on database: Database) async throws-> LayoutAPIModel {
        async let images = $images
            .query(on: database)
            .sort(\.$sortIndex, .ascending)
            .with(\.$attachment)
            .all()
        return try await LayoutAPIModel(
            id: requireID(),
            createdAt: $createdAt.orThrow(),
            updatedAt: $updatedAt.orThrow(),
            title: title,
            description: description,
            images: images.map(LayoutAPIModel.Image.init)
        )
    }
}

extension Array where Element == Layout {
    func convertToAPIModel(on database: Database) async throws -> [LayoutAPIModel] {
        var apiModels: [LayoutAPIModel] = []
        for layout in self {
            let apiModel = try await layout.convertToAPIModel(on: database)
            apiModels.append(apiModel)
        }
        return apiModels
    }
}

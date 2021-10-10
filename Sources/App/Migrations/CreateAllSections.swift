//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 10.10.2021.
//

import Fluent
import Vapor

struct CreateAllSections: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let coversSection = Section(
            type: .covers,
            previewTitle: "Book covers",
            previewSubtitle: "Check out my works done using different design techniques."
        )
        let layoutsSection = Section(
            type: .layouts,
            previewTitle: "Book layouts",
            previewSubtitle: "My passion is to create beautiful layouts so that the reader enjoys the book on every spread."
        )
        let aboutSection = Section(
            type: .about,
            previewTitle: "Book covers",
            previewSubtitle: "Created in 2019–2021 for Russian book market."
        )
        
        return coversSection.save(on: database)
            .flatMap {
                layoutsSection.save(on: database)
            }
            .flatMap {
                aboutSection.save(on: database)
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        Section.query(on: database).all()
            .flatMapEach(on: database.eventLoop) { section in
                section.delete(on: database)
            }
    }
}
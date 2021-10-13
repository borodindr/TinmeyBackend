//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Vapor
import Fluent

final class Tag: Model, Content {
    static var schema = "tags"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: WorkTagPivot.self, from: \.$tag, to: \.$work)
    var works: [Work]
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag {
    static func addTag(_ name: String, to work: Work, on req: Request) -> EventLoopFuture<Void> {
        Tag.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                if let existingTag = foundTag {
                    return work.$tags
                        .attach(existingTag, on: req.db)
                } else {
                    let tag = Tag(name: name)
                    return tag.save(on: req.db)
                        .flatMap {
                            work.$tags
                                .attach(tag, on: req.db)
                        }
                }
            }
    }
}

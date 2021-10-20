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
    
    static func deleteTag(_ name: String, from work: Work, on req: Request) -> EventLoopFuture<Void> {
        Tag.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                guard let foundTag = foundTag else {
                    return req.eventLoop.makeSucceededFuture(())
                }
                return work.$tags.detach(foundTag, on: req.db)
            }
    }
    
    static func addTags(_ tags: [String], to work: Work, on req: Request) -> EventLoopFuture<Void> {
        tags
            .map { tagName in
                Tag.addTag(tagName, to: work, on: req)
            }
            .flatten(on: req.eventLoop)
    }
    
    static func deleteTags(_ tags: [String], from work: Work, on req: Request) -> EventLoopFuture<Void> {
        tags
            .map { tagName in
                Tag.deleteTag(tagName, from: work, on: req)
            }
            .flatten(on: req.eventLoop)
    }
    
    static func updateTags(to newTags: [String], in work: Work, on req: Request) -> EventLoopFuture<Void> {
        work.$tags.get(on: req.db)
            .flatMap { existingTags in
                let existingTagsSet = Set(existingTags.map { $0.name })
                let newTagsSet = Set(newTags)
                
                let tagsToDelete = existingTagsSet.subtracting(newTagsSet).map { $0 }
                let tagsToAdd = newTagsSet.subtracting(existingTagsSet).map { $0 }
                
                return [deleteTags(tagsToDelete, from: work, on: req),
                 addTags(tagsToAdd, to: work, on: req)]
                    .flatten(on: req.eventLoop)
            }
    }
}

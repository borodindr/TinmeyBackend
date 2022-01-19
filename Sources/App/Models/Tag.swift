//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Vapor
import Fluent

final class Tag: Model, Content {
    static var schema = v2021_11_04.schemeName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_11_04.name)
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
    static func add(_ name: String, to work: Work, on req: Request) -> EventLoopFuture<Void> {
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
    
    static func add(_ names: [String], to work: Work, on req: Request) -> EventLoopFuture<Void> {
        names
            .map { tagName in
                Tag.add(tagName, to: work, on: req)
            }
            .flatten(on: req.eventLoop)
    }
    
    static func delete(_ tag: Tag, from work: Work, on req: Request) -> EventLoopFuture<Void> {
        work.$tags.detach(tag, on: req.db)
            .flatMap {
                tag.$works.load(on: req.db)
            }
            .flatMap {
                if tag.works.isEmpty || tag.works.map({ $0.id }) == [work.id] {
                    return tag.delete(on: req.db)
                } else {
                    return req.eventLoop.makeSucceededVoidFuture()
                }
            }
    }
    
    static func delete(_ name: String, from work: Work, on req: Request) -> EventLoopFuture<Void> {
        Tag.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                guard let foundTag = foundTag else {
                    return req.eventLoop.makeSucceededFuture(())
                }
                return Tag.delete(foundTag, from: work, on: req)
            }
            
    }
    
    static func delete(_ tags: [Tag], from work: Work, on req: Request) -> EventLoopFuture<Void> {
        tags
            .map { tag in
                Tag.delete(tag, from: work, on: req)
            }
            .flatten(on: req.eventLoop)
    }
    
    static func delete(_ names: [String], from work: Work, on req: Request) -> EventLoopFuture<Void> {
        names
            .map { tagName in
                Tag.delete(tagName, from: work, on: req)
            }
            .flatten(on: req.eventLoop)
    }
    
    static func deleteAll(from work: Work, on req: Request) -> EventLoopFuture<Void> {
        work.$tags.query(on: req.db).all()
            .flatMap {
                Tag.delete($0, from: work, on: req)
            }
    }
    
    static func update(to newTags: [String], in work: Work, on req: Request) -> EventLoopFuture<Void> {
        work.$tags.get(on: req.db)
            .flatMap { existingTags in
                let existingTagsSet = Set(existingTags.map { $0.name })
                let newTagsSet = Set(newTags)
                
                let tagsToDelete = existingTagsSet.subtracting(newTagsSet).map { $0 }
                let tagsToAdd = newTagsSet.subtracting(existingTagsSet).map { $0 }
                
                return [delete(tagsToDelete, from: work, on: req),
                        add(tagsToAdd, to: work, on: req)]
                    .flatten(on: req.eventLoop)
            }
    }
}

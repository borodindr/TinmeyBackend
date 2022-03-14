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
    static func add(_ name: String, to work: Work, on database: Database) -> EventLoopFuture<Void> {
        Tag.query(on: database)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                if let existingTag = foundTag {
                    return work.$tags
                        .attach(existingTag, on: database)
                } else {
                    let tag = Tag(name: name)
                    return tag.save(on: database)
                        .flatMap {
                            work.$tags
                                .attach(tag, on: database)
                        }
                }
            }
    }
    
    static func add(_ names: [String], to work: Work, on database: Database) -> EventLoopFuture<Void> {
        names
            .map { tagName in
                Tag.add(tagName, to: work, on: database)
            }
            .flatten(on: database.eventLoop)
    }
    
    static func delete(_ tag: Tag, from work: Work, on database: Database) -> EventLoopFuture<Void> {
        work.$tags.detach(tag, on: database)
            .flatMap {
                tag.$works.load(on: database)
            }
            .flatMap {
                if tag.works.isEmpty || tag.works.map({ $0.id }) == [work.id] {
                    return tag.delete(on: database)
                } else {
                    return database.eventLoop.makeSucceededVoidFuture()
                }
            }
    }
    
    static func delete(_ name: String, from work: Work, on database: Database) -> EventLoopFuture<Void> {
        Tag.query(on: database)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                guard let foundTag = foundTag else {
                    return database.eventLoop.makeSucceededFuture(())
                }
                return Tag.delete(foundTag, from: work, on: database)
            }
            
    }
    
    static func delete(_ tags: [Tag], from work: Work, on database: Database) -> EventLoopFuture<Void> {
        tags
            .map { tag in
                Tag.delete(tag, from: work, on: database)
            }
            .flatten(on: database.eventLoop)
    }
    
    static func delete(_ names: [String], from work: Work, on database: Database) -> EventLoopFuture<Void> {
        names
            .map { tagName in
                Tag.delete(tagName, from: work, on: database)
            }
            .flatten(on: database.eventLoop)
    }
    
    static func deleteAll(from work: Work, on database: Database) -> EventLoopFuture<Void> {
        work.$tags.query(on: database).all()
            .flatMap {
                Tag.delete($0, from: work, on: database)
            }
    }
    
    static func update(to newTags: [String], in work: Work, on database: Database) -> EventLoopFuture<Void> {
        work.$tags.get(on: database)
            .flatMap { existingTags in
                let existingTagsSet = Set(existingTags.map { $0.name })
                let newTagsSet = Set(newTags)
                
                let tagsToDelete = existingTagsSet.subtracting(newTagsSet).map { $0 }
                let tagsToAdd = newTagsSet.subtracting(existingTagsSet).map { $0 }
                
                return [delete(tagsToDelete, from: work, on: database),
                        add(tagsToAdd, to: work, on: database)]
                    .flatten(on: database.eventLoop)
            }
    }
}

extension Tag {
    static func add(_ name: String, to work: Work, on database: Database) async throws {
        try await add(name, to: work, on: database).get()
    }
    
    static func add(_ names: [String], to work: Work, on database: Database) async throws {
        try await add(names, to: work, on: database).get()
    }
    
    static func delete(_ tag: Tag, from work: Work, on database: Database) async throws {
        try await delete(tag, from: work, on: database).get()
    }
    
    static func delete(_ name: String, from work: Work, on database: Database) async throws {
        try await delete(name, from: work, on: database).get()
            
    }
    
    static func delete(_ tags: [Tag], from work: Work, on database: Database) async throws {
        try await delete(tags, from: work, on: database).get()
    }
    
    static func delete(_ names: [String], from work: Work, on database: Database) async throws {
        try await delete(names, from: work, on: database).get()
    }
    
    static func deleteAll(from work: Work, on database: Database) async throws {
        try await deleteAll(from: work, on: database).get()
    }
    
    static func update(to newTags: [String], in work: Work, on database: Database) async throws {
        try await update(to: newTags, in: work, on: database).get()
    }
}

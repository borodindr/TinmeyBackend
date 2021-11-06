//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 13.10.2021.
//

import Foundation
import Fluent

final class WorkTagPivot: Model {
    static var schema = v2021_11_04.schemaName
    
    @ID
    var id: UUID?
    
    @Parent(key: v2021_11_04.workID)
    var work: Work
    
    @Parent(key: v2021_11_04.tagID)
    var tag: Tag
    
    init() { }
    
    init(id: UUID? = nil, work: Work, tag: Tag) throws {
        self.id = id
        self.$work.id = try work.requireID()
        self.$tag.id = try tag.requireID()
    }
}

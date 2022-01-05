//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.12.2021.
//

import Vapor
import Fluent

final class WorkImage: Model, Content {
    static var schema = v20211219.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v20211219.sortIndex)
    var sortIndex: Int
    
    @OptionalField(key: v20211219.name)
    var name: String?
    
    @Parent(key: v20211219.workID)
    var work: Work
    
    init() { }
    
    init(
        id: UUID? = nil,
        sortIndex: Int,
        name: String? = nil,
        workID: Work.IDValue
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.name = name
        self.$work.id = workID
    }
}




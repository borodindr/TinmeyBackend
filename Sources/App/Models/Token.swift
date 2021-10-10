//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Vapor
import Fluent

final class Token: Model, Content {
    static var schema = "tokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "userID")
    var user: User
    
    init() { }
    
    init(
        id: UUID? = nil,
        value: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    typealias User = App.User
    
    static var valueKey = \Token.$value
    static var userKey = \Token.$user
    
    var isValid: Bool {
        true
    }
    
    
    
}

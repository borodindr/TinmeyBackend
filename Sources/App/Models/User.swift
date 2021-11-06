//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Vapor
import Fluent

final class User: Model, Content {
    static var schema = v2021_11_04.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v2021_11_04.isMain)
    var isMain: Bool
    
    @Field(key: v2021_11_04.username)
    var username: String
    
    @Field(key: v2021_11_04.password)
    var password: String
    
    @Children(for: \.$user)
    var profile: [Profile]
    
    init() { }
    
    init(
        id: UUID? = nil,
        isMain: Bool = false,
        username: String,
        password: String
    ) {
        self.id = id
        self.isMain = isMain
        self.username = username
        self.password = password
    }
    
}

extension User: ModelAuthenticatable {
    static var usernameKey = \User.$username
    
    static var passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
    
}

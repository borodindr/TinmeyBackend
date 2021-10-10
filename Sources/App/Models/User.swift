//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Vapor
import Fluent

final class User: Model, Content {
    static var schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "is_main")
    var isMain: Bool
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var profile: [Profile]
    
    /*
     To add:
     - Photo
     - Location
     - Phone
     - Links
     */
    
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

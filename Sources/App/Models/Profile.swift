//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent
import Vapor

final class Profile: Model, Content {
    static var schema = "profiles"
    
    @ID
    var id: UUID?
    
    @Parent(key: "userID")
    var user: User
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "current_status")
    var currentStatus: String
    
    @Field(key: "short_about")
    var shortAbout: String
    
    @Field(key: "about")
    var about: String
    
    init() { }
    
    init(
        id: UUID? = nil,
        userID: User.IDValue,
        name: String,
        email: String,
        currentStatus: String,
        shortAbout: String,
        about: String
    ) {
        self.id = id
        self.$user.id = userID
        self.name = name
        self.email = email
        self.currentStatus = currentStatus
        self.shortAbout = shortAbout
        self.about = about
    }
}

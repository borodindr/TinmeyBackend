//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent
import Vapor

final class Profile: Model, Content {
    static var schema = v2021_11_04.schemeName
    
    @ID
    var id: UUID?
    
    @Parent(key: v2021_11_04.userID)
    var user: User
    
    @Field(key: v2021_11_04.name)
    var name: String
    
    @Field(key: v2021_11_04.email)
    var email: String
    
//    @Field(key: v2021_11_04.currentStatus)
//    var currentStatus: String
    
    @Field(key: v2021_11_04.shortAbout)
    var shortAbout: String
    
    @Field(key: v2021_11_04.about)
    var about: String
    
    init() { }
    
    init(
        id: UUID? = nil,
        userID: User.IDValue,
        name: String,
        email: String,
        shortAbout: String,
        about: String
    ) {
        self.id = id
        self.$user.id = userID
        self.name = name
        self.email = email
        self.shortAbout = shortAbout
        self.about = about
    }
}

//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import TinmeyCore
import Vapor

extension UserAPIModel: Content { }
extension UserAPIModel.LoginResult: Content { }
extension UserAPIModel.ChangePassword: Content { }

extension UserAPIModel {
    init(_ user: User) throws {
        self.init(
            id: try user.requireID(),
            username: user.username,
            isMain: user.isMain
        )
    }
    
}

extension UserAPIModel.LoginResult {
    init(_ token: Token) throws {
        self.init(user: try UserAPIModel(token.user), token: token.value)
    }
}

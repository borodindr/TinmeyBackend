//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Vapor
import Fluent
import TinmeyCore

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoutes = routes.grouped("api", "users")
        usersRoutes.get(use: getAllHandler)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.put("changePassword", use: changePasswordHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[UserAPIModel]> {
        User.query(on: req.db).all()
            .flatMapEachThrowing { user in
                try UserAPIModel(user)
            }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<UserAPIModel.LoginResult> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        
        return token.save(on: req.db)
            .flatMap { token.$user.load(on: req.db) }
            .flatMapThrowing {
                try UserAPIModel.LoginResult(token)
            }
    }
    
    func changePasswordHandler(_ req: Request) throws -> EventLoopFuture<UserAPIModel> {
        let user = try req.auth.require(User.self)
        let data = try req.content.decode(UserAPIModel.ChangePassword.self)
        
        return User
            .find(try user.requireID(), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { user in
                try validate(data, for: user)
                let newPassword = try Bcrypt.hash(data.newPassword)
                user.password = newPassword
                return user
            }
            .flatMap { user in
                user.save(on: req.db)
                    .flatMapThrowing { try UserAPIModel(user) }
            }
    }
    
}

private extension UsersController {
    enum ChangePasswordError: AbortError {
        case wrongCurrentPassword
        case passwordTooEasy
        case newPasswordNotConfirmed
        case newPasswordSameAsCurrent
        
        var status: HTTPResponseStatus {
            .forbidden
        }
        
        var reason: String {
            switch self {
            case .newPasswordNotConfirmed:
                return "New password should be entered twice. Please make sure you confirmed new password correctly."
            case .passwordTooEasy:
                return "You entered insecure password. It should be at least 8 characters long."
            case .wrongCurrentPassword:
                return "Wrong current password. Please enter current password from current account."
            case .newPasswordSameAsCurrent:
                return "You're trying to change password to the same one. Please enter different password."
            }
        }
    }
    
    func validate(_ data: UserAPIModel.ChangePassword, for user: User) throws {
        guard data.newPassword == data.repeatNewPassword else {
            throw ChangePasswordError.newPasswordNotConfirmed
        }
        guard data.newPassword.count >= 8 else {
            throw ChangePasswordError.passwordTooEasy
        }
        guard try Bcrypt.verify(data.currentPassword, created: user.password) else {
            throw ChangePasswordError.wrongCurrentPassword
        }
    }
    
}

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
    
    func getAllHandler(_ req: Request) async throws -> [UserAPIModel] {
        let users = try await User.query(on: req.db).all()
        return try users.map(UserAPIModel.init)
    }
    
    func loginHandler(_ req: Request) async throws -> UserAPIModel.LoginResult {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        try await token.$user.load(on: req.db)
        return try UserAPIModel.LoginResult(token)
    }
    
    func changePasswordHandler(_ req: Request) async throws -> UserAPIModel {
        let userID = try req.auth.require(User.self).requireID()
        let data = try req.content.decode(UserAPIModel.ChangePassword.self)
        
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        try validate(data, for: user)
        let newPassword = try Bcrypt.hash(data.newPassword)
        user.password = newPassword
        
        try await user.save(on: req.db)
        return try UserAPIModel(user)
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

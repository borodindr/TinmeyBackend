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
}

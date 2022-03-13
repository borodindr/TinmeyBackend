//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Vapor
import Fluent
import TinmeyCore

struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoutes = routes.grouped("api", "profile")
        usersRoutes.get(use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(use: updateHandler)
    }
    
    func getHandler(_ req: Request) async throws -> ProfileAPIModel {
        let profile = try await getMainProfile(req)
        return try ProfileAPIModel(profile)
    }
    
    func updateHandler(_ req: Request) async throws -> ProfileAPIModel {
        let updatedProfile = try req.content.decode(ProfileAPIModel.self)
        let profile = try await getMainProfile(req)
        profile.name = updatedProfile.name
        profile.email = updatedProfile.email
        profile.location = updatedProfile.location
        profile.shortAbout = updatedProfile.shortAbout
        profile.about = updatedProfile.about
        
        try await profile.save(on: req.db)
        return try ProfileAPIModel(profile)
    }
    
    func getMainProfile(_ req: Request) async throws -> Profile {
        let query = User.query(on: req.db).filter(\.$isMain == true)
        guard let mainUser = try await query.first() else {
            throw Abort(.notFound)
        }
        let profiles = try await mainUser.$profile.get(on: req.db)
        guard let mainProfile = profiles.first else {
            throw Abort(.notFound)
        }
        return mainProfile
    }
}

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
        usersRoutes.put(use: updateHandler)
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<ProfileAPIModel> {
        try getMainProfile(req)
            .flatMapThrowing {
                try ProfileAPIModel($0)
            }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<ProfileAPIModel> {
        let updatedProfile = try req.content.decode(ProfileAPIModel.self)
        return try getMainProfile(req)
            .flatMap { profile in
                profile.name = updatedProfile.name
                profile.email = updatedProfile.email
                profile.currentStatus = updatedProfile.currentStatus
                profile.shortAbout = updatedProfile.shortAbout
                profile.about = updatedProfile.about
                
                return profile.save(on: req.db)
                    .flatMapThrowing {
                        try ProfileAPIModel(profile)
                    }
            }
    }
    
    func getMainProfile(_ req: Request) throws -> EventLoopFuture<Profile> {
        User.query(on: req.db)
            .filter(\.$isMain == true)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { mainUser in
                mainUser.$profile
                    .get(on: req.db)
                    .map { $0.first }
                    .unwrap(or: Abort(.notFound))
            }
    }
}

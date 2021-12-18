//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import Fluent
import Vapor

struct CreateMainUser: Migration {
    let environment: Environment
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let username = "e.tinmey"
        let password = generatePassword()
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash(password)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
        let user = User(
            isMain: true,
            username: username,
            password: passwordHash
        )
        
        return user.save(on: database)
            .flatMapThrowing {
                try Profile(
                    userID: user.requireID(),
                    name: "Katya Tinmey",
                    email: "katya@tinmey.com",
                    location: "Austin, TX",
                    shortAbout: "Graphic designer specializing in book design.",
                    about: """
        Katya is a graphic designer specializing on book design.
        Since 2019 she has worked in-house for the Eksmo Publishing House, where she created covers for books of various genres in different techniques.
        Katya graduated from HSE ART AND DESIGN SCHOOL after studying Communication Design.
        In 2020 Katya received a grant to study Japanese typography in posters from the Ishibashi Foundation.
        """
                )
            }
            .flatMap { $0.save(on: database) }
            .map {
                let message = newUserLogMessage(username: username, password: password)
                database.logger.debug(message)
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\User.$isMain == true)
            .delete()
    }
    
    private func generatePassword() -> String {
        if environment == .production {
            return Data([UInt8].random(count: 32)).base32EncodedString()
        } else {
            return "admin"
        }
    }
    
    private func newUserLogMessage(username: String, password: String) -> Logger.Message {
        """
        
        **********
        Created main user. Please change its password.
        username: \(username)
        password: \(password)
        **********
        
        """
    }
}

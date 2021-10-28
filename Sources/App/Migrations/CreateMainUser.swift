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
                    email: "e.tinmey@gmail.com",
                    currentStatus: "",
                    shortAbout: "",
                    about: ""
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
        if environment == .development {
            return "admin"
        } else {
            return Data([UInt8].random(count: 32)).base32EncodedString()
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

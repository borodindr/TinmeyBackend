//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 08.10.2021.
//

import TinmeyCore
import Vapor

extension ProfileAPIModel: Content { }

extension ProfileAPIModel {
    init(_ profile: Profile) throws {
        self.init(
            name: profile.name,
            email: profile.email,
            currentStatus: profile.currentStatus,
            shortAbout: profile.shortAbout,
            about: profile.about
        )
    }
}

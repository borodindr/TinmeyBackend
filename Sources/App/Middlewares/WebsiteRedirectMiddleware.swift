//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 18.12.2021.
//

import Vapor

final class WebsiteRedirectMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request)
            .flatMapErrorThrowing { error in
                if (error as? AbortError)?.status == .notFound && !request.isApiRequest {
                    return request.redirect(to: "/")
                }
                throw error
            }
    }
    
}

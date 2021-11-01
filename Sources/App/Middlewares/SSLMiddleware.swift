//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 31.10.2021.
//

import Vapor

final class SSLMiddleware: Middleware {
    let enabled: Bool
    /// Creates a new `XFPMiddleware`.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    /// See `Middleware`.
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard enabled, request.headers.first(name: HTTPHeaders.Name("X-Forwarded-Proto")) == "http" else {
            return next.respond(to: request)
        }
        
        let urlString = request.application.http.server.configuration.urlString()
        let redirectPath = urlString.replacingOccurrences(of: "http://", with: "https://")
        return request.eventLoop.future(request.redirect(to: redirectPath, type: RedirectType.temporary))
    }
}

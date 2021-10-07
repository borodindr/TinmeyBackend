//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 29.08.2021.
//

import Vapor

extension HTTPServer.Configuration {
    func urlString() -> String {
        let scheme = tlsConfiguration == nil ? "http" : "https"
        let addressDescription: String
        switch address {
        case .hostname(let hostname, let port):
            addressDescription = "\(scheme)://\(hostname ?? self.hostname):\(port ?? self.port)"
        case .unixDomainSocket(let socketPath):
            addressDescription = "\(scheme)+unix: \(socketPath)"
        }
        return addressDescription
    }
}

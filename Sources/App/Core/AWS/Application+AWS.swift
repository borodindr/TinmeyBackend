//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.10.2021.
//

import Vapor
import SotoS3

extension Application {
    var aws: AWS {
        .init(application: self)
    }
    
    struct AWS {
        struct ClientKey: StorageKey {
            typealias Value = AWSClient
        }
        
        public var client: AWSClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("AWSClient not setup. Use application.aws.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    try $0.syncShutdown()
                }
            }
        }
        
        let application: Application
    }
}

extension Application.AWS {
    struct S3Key: StorageKey {
        typealias Value = S3
    }
    
    public var s3: S3 {
        get {
            guard let s3 = self.application.storage[S3Key.self] else {
                fatalError("S3 not setup. Use application.aws.s3 = ...")
            }
            return s3
        }
        nonmutating set {
            self.application.storage[S3Key.self] = newValue
        }
    }
}

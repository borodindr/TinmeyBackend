//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 19.10.2021.
//

import Vapor
import SotoS3

extension Request {
    var aws: AWS {
        .init(request: self)
    }
    
    struct AWS {
        var client: AWSClient {
            request.application.aws.client
        }
        
        let request: Request
    }
}

extension Request.AWS {
    var s3: S3 {
        request.application.aws.s3
    }
}

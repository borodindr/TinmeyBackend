//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 05.11.2021.
//

import Vapor

extension EventLoopFuture where Value == Any {
    static func combine<V1, V2>(
        _ future1: EventLoopFuture<V1>,
        _ future2: EventLoopFuture<V2>
    ) -> EventLoopFuture<(V1, V2)> {
        future1.and(future2)
    }
    
    static func combine<V1, V2, V3>(
        _ future1: EventLoopFuture<V1>,
        _ future2: EventLoopFuture<V2>,
        _ future3: EventLoopFuture<V3>
    ) -> EventLoopFuture<(V1, V2, V3)> {
        combine(future1, future2)
            .and(future3)
            .map { (args: (arg1: V1, arg2: V2), arg3: V3) in
                (args.arg1, args.arg2, arg3)
            }
    }
    
    static func combine<V1, V2, V3, V4>(
        _ future1: EventLoopFuture<V1>,
        _ future2: EventLoopFuture<V2>,
        _ future3: EventLoopFuture<V3>,
        _ future4: EventLoopFuture<V4>
    ) -> EventLoopFuture<(V1, V2, V3, V4)> {
        combine(future1, future2, future3)
            .and(future4)
            .map { (args: (arg1: V1, arg2: V2, arg3: V3), arg4: V4) in
                (args.arg1, args.arg2, args.arg3, arg4)
            }
    }
}

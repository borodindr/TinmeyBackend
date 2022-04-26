//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

protocol WebsiteContext: Encodable {
    associatedtype HeaderType: HeaderProvider
    var meta: WebsiteMeta { get }
    var header: HeaderType { get }
}

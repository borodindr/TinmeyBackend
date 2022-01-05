//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 21.12.2021.
//

import Foundation

//enum WorkItemType: RawRepresentable, Codable {
//    typealias RawValue = String
//
//    case body
//    case image(name: String?)
//    case clear
//
//    var rawValue: String {
//        let JSONObject: [String: String?]
//        switch self {
//        case .body:
//            JSONObject = ["type": "body"]
//        case .image(let imageName):
//            JSONObject = ["type": "image", "imageName": imageName]
//        case .clear:
//            JSONObject = ["type": "clear"]
//        }
//
//        guard let data = try? JSONSerialization.data(withJSONObject: JSONObject, options: .fragmentsAllowed),
//              let string = String(data: data, encoding: .utf8) else {
//                  return ""
//              }
//        return string
//    }
//
//    init?(rawValue: String) {
//        guard let data = rawValue.data(using: .utf8),
//              let object = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
//              let dict = object as? [String: String?],
//              let type = dict["type"] else {
//                  return nil
//              }
//
//        switch type {
//        case "body":
//            self = .body
//        case "image":
//            let imageName = dict["imageName"] ?? nil
//            self = .image(name: imageName)
//        case "clear":
//            self = .clear
//        default:
//            return nil
//        }
//    }
//
//}

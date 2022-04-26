//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

protocol HeaderProvider: Encodable {
    var title: String { get }
    var description: String { get }
}

extension HeaderProvider {
    static var defaultTitle: String {
        "Hey it's Katya Tinmey!"
    }
    
    static var defaultDescription: String {
        """
        I’m a graphic designer born and raised in the Tyva Republic, currently live in Austin, TX. After working four years in automotive business in sales analysis, I enrolled in art school and completed my Master degree in graphic design. Last couple of years I devoted myself to book cover design.
        """
    }
}

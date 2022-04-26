//
//  File.swift
//  
//
//  Created by Dmitry Borodin on 25.04.2022.
//

import Foundation

extension String {
    func multilineHTML() -> String {
        self.replacingOccurrences(of: "\n", with: "<br>")
    }
}

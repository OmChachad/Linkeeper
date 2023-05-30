//
//  URL.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation

extension URL {
    var sanitise: URL {
        // Check if the scheme already exists
        if self.scheme == nil {
            // Append "http://" to the URL if it doesn't have a scheme
            let urlString = "https://" + self.absoluteString
            print(urlString)
            return URL(string: urlString) ?? self
        }
        return self
    }
}

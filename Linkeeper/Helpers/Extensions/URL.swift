//
//  URL.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation

extension URL { // This adds https to the URL if the URl doesn't have it already

    //Source: https://stackoverflow.com/questions/70209276/how-can-i-add-http-or-https-to-a-swift-url
    
    var sanitise: URL {
        if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if components.scheme == nil {
                components.scheme = "https"
            }
            return components.url ?? self
        }
        return self
    }
}

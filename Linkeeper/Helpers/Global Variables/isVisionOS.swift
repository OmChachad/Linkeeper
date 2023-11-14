//
//  isVisionOS.swift
//  Linkeeper
//
//  Created by Om Chachad on 14/11/23.
//

import Foundation

var isVisionOS: Bool {
    #if os(visionOS)
        return true
    #else
    return false
    #endif
}

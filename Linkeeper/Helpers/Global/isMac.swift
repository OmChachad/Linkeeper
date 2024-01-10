//
//  isMac.swift
//  Linkeeper
//
//  Created by Om Chachad on 09/01/24.
//

import Foundation

var isMac: Bool {
    #if os(macOS)
    return true
    #else
    return false
    #endif
}

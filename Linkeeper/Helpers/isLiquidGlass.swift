//
//  isLiquidGlass.swift
//  Linkeeper
//
//  Created by Om Chachad on 22/12/25.
//

import Foundation

var isLiquidGlass: Bool {
    #if os(visionOS)
    return false
    #else
    if #available(iOS 26.0, macOS 26.0, *) { return true } else { return false }
    #endif
}

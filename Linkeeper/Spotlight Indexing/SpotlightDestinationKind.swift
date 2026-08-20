//
//  SpotlightDestinationKind.swift
//  Linkeeper
//
//  Created by Om Chachad on 20/08/26.
//


import Foundation

/// A destination that Linkeeper can open after Spotlight launches the app.
enum SpotlightDestinationKind: String, Sendable {
    case bookmark
    case folder
}
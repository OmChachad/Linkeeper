//
//  Bookmark.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import Foundation
import SwiftUI

struct Bookmark: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var title: String
    var url: URL
    var host: String
    var notes: String
    var date: Date
    var favorited = false
    var folder: Folder?
}

struct Folder: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var title: String
    var symbol: String
    var accentColor: String
}


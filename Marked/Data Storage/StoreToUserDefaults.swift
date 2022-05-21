//
//  Bookmarks.swift
//  Marked
//
//  Created by Om Chachad on 26/04/22.
//

import Foundation
import SwiftUI
import Combine
class Bookmarks: ObservableObject {
    @Published var items = [Bookmark]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Bookmarks")
            }
        }
    }
    
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Bookmarks") {
            if let decodedItems = try?
            JSONDecoder().decode([Bookmark].self, from: savedItems) {
                items = decodedItems
                return
            }
        }
        items = []
    }
}

class Folders: ObservableObject {
    @Published var items = [Folder]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Folders")
            }
        }
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Folders") {
            if let decodedItems = try?
            JSONDecoder().decode([Folder].self, from: savedItems) {
                items = decodedItems
                return
            }
        }
        items = []
    }
}

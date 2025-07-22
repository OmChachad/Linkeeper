//
//  Column.swift
//  Linkeeper
//
//  Created by Om Chachad on 7/22/25.
//

import Foundation

enum Column: String, CaseIterable {
    case host
    case folder
    case dateAdded
    
    var title: String {
        switch self {
        case .host: return "Host"
        case .folder: return "Folder"
        case .dateAdded: return "Date Added"
        }
    }
}

import SwiftUI

@propertyWrapper
struct AppStorageColumns: DynamicProperty {
    @State private var value: [Column]
    
    private let key: String
    private let userDefaults: UserDefaults

    init(wrappedValue: [Column], _ key: String, store: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = store
        let stored = (store.array(forKey: key) as? [String])?
            .compactMap(Column.init(rawValue:)) ?? wrappedValue
        _value = State(initialValue: stored)
    }

    var wrappedValue: [Column] {
        get { value }
        nonmutating set {
            value = newValue
            let rawValues = newValue.map(\.rawValue)
            userDefaults.set(rawValues, forKey: key)
        }
    }
}

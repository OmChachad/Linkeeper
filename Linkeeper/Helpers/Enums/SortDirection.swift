//
//  SortDirection.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import Foundation

enum SortDirection: String, Codable, CaseIterable {
    case ascending
    case descending
    
    var label: String {
        let sortMethod: SortMethod = SortMethod(rawValue: UserDefaults.standard.string(forKey: "SortMethod") ?? "Date Created") ?? .dateCreated
        switch(sortMethod) {
        case .dateCreated:
            return self == .ascending ? "Oldest First" : "Newest First"
        case .title:
            return self == .ascending ? "Ascending" : "Descending"
        }
    }
}

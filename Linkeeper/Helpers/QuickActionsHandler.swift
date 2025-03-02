//
//  QuickActionsHandler.swift
//  Linkeeper
//
//  Created by Om Chachad on 3/2/25.
//

import Foundation
import UIKit

class QuickActionsHandler: ObservableObject {
    static let shared = QuickActionsHandler()
    
    private init() {}
    
    func handleItem(_ item: UIApplicationShortcutItem) {
        guard let actionItem = QuickAction.allCases.first(where: {$0.id == item.type}) else { return }
        switch actionItem {
        case .addBookmark:
            if let url = URL(string: "linkeeper://addBookmark") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

enum QuickAction: Hashable, CaseIterable {
    case addBookmark
    
    var id: String {
        switch self {
        case .addBookmark:
            return "org.starlightapps.Linkeeper.AddBookmark"
        }
    }
}

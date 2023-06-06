//
//  AppShortcuts Provider.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/06/23.
//

import Foundation
import AppIntents

@available(iOS 16.0, *)
struct LinkeeperShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .purple
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddBookmark(),
            phrases: ["Create a bookmark in \(.applicationName)",
                      "Create a \(.applicationName) bookmark",
                      "Add a \(.applicationName) bookmark",
                     "Add a bookmark to \(.applicationName)",
                      "Keep a link in \(.applicationName)"
                     ],
            shortTitle: "Add a bookmark"
        )
        
        AppShortcut(
            intent: AddFolder(),
            phrases: ["Create a folder in \(.applicationName)",
                     "Add a folder to \(.applicationName)"
                     ]
        )
    }
}

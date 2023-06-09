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
            phrases: ["Add a \(.applicationName) bookmark",
                      "Create a bookmark in \(.applicationName)",
                      "Create a \(.applicationName) bookmark",
                      "Create a new \(.applicationName) bookmark",
                     "Add a bookmark to \(.applicationName)",
                      "Keep a link in \(.applicationName)"
                     ],
            shortTitle: "New Bookmark",
            systemImageName: "plus"
        )
        
        AppShortcut(
            intent: AddFolder(),
            phrases: ["Create a folder in \(.applicationName)",
                      "Create a new \(.applicationName) folder",
                     "Add a folder to \(.applicationName)"
                     ],
            shortTitle: "New Folder",
            systemImageName: "folder.fill.badge.plus"
        )
    }
}

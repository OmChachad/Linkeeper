//
//  AppShortcuts Provider.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/06/23.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct LinkeeperShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .purple
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BookmarkURLIntent(),
            phrases:
                [
                "Save a link in \(.applicationName)",
                "Bookmark a website with \(.applicationName)",
                "Add a bookmark to \(.applicationName)"
            ],
            shortTitle: "Save Bookmark",
            systemImageName: "bookmark.fill"
        )

        AppShortcut(
            intent: AddBookmark(),
            phrases: [
                "Save a link to \(\.$folder) in \(.applicationName)",
                "Add a bookmark to \(\.$folder) in \(.applicationName)"
            ],
            shortTitle: "Save to Folder",
            systemImageName: "folder.fill.badge.plus"
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

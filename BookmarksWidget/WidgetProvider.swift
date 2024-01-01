//
//  WidgetProvider.swift
//  WidgetProvider
//
//  Created by Om Chachad on 21/12/23.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BookmarksEntry {
        BookmarksEntry(date: Date(), bookmarks: [], configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> BookmarksEntry {
        BookmarksEntry(date: Date(), bookmarks: BookmarksManager.shared.getAllBookmarks().toEntity(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<BookmarksEntry> {
        var config = configuration
        
        let bookmarks = configuration.folder.flatMap { folder in
            FoldersManager.shared.doesExist(withId: folder.id) ? folder.bookmarks.sorted(by: { $0.dateAdded > $1.dateAdded }) : BookmarksManager.shared.getAllBookmarks().toEntity()
        } ?? BookmarksManager.shared.getAllBookmarks().toEntity()

        if let folder = config.folder {
            if !FoldersManager.shared.doesExist(withId: folder.id) {
                config = ConfigurationAppIntent.allBookmarks
            }
        }
        
        let entry = BookmarksEntry(date: Date.now, bookmarks: bookmarks, configuration: config)
        
        return Timeline(entries: [entry], policy: .never)
    }
}

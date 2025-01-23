//
//  BookmarksEntry.swift
//  BookmarksWidgetExtension
//
//  Created by Om Chachad on 01/01/24.
//

import Foundation
import WidgetKit

struct BookmarksEntry: TimelineEntry {
    let date: Date
    let bookmarks: [LinkeeperBookmarkEntity]
    let configuration: ConfigurationAppIntent
}

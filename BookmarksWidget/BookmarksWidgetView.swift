//
//  FolderWidget.swift
//  Linkeeper
//
//  Created by Om Chachad on 01/01/24.
//

import SwiftUI
import WidgetKit

struct BookmarksWidget: Widget {
    let kind: String = "BookmarksWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
                BookmarksWidgetEntryView(entry: entry)
                    
        }
        .configurationDisplayName("Bookmarks")
        .description("Quickly glance at all your bookmarks, or bookmarks from a particular folder.")
        .containerBackgroundRemovable(true)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BookmarksWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch(family) {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            default:
                MediumOrLargeWidgetView(entry: entry)
            }
        }
        .overlay {
            if entry.bookmarks.isEmpty {
                Text("No bookmarks here, yet!")
                    .multilineTextAlignment(.center)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}



//
//  MediumOrDefaultWidgetView.swift
//  BookmarksWidgetExtension
//
//  Created by Om Chachad on 01/01/24.
//

import Foundation
import WidgetKit
import SwiftUI

struct MediumOrLargeWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var bookmarksLimit: Int {
        switch(family) {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        case .systemLarge:
            return 5
        default:
            fatalError()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if let folder = entry.configuration.folder {
                    Label(folder.title, systemImage: folder.symbol)
                        .lineLimit(1)
                        .foregroundColor(Color(uiColor: UIColor(ColorOption(rawValue: folder.color)?.color ?? .gray)))
                } else {
                    Label("All Bookmarks", systemImage: "bookmark.fill")
                        .foregroundColor(.secondary)
                }
            }
            .fontDesign(.rounded)
            .bold()
            
            if entry.bookmarks.count >= bookmarksLimit {
                Spacer()
            }
            
            ForEach(entry.bookmarks.prefix(bookmarksLimit), id: \.self) { bookmark in
                BookmarkItemView(bookmark: bookmark)
                    .padding(.vertical, 5)
            }
            
            if entry.bookmarks.count < bookmarksLimit {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .topLeading)
        .font(.system(size: 15))
        .background {
            Color.clear
                    if let folderID = entry.configuration.folder?.id {
                        Link(destination: URL(string: "linkeeper://openFolder/\(folderID)")!, label: {
                            Color.clear
                        })
                    }
        }
        .containerBackground(Color("WidgetBackground"), for: .widget)
    }
}

//
//  SmallWidgetView.swift
//  BookmarksWidgetExtension
//
//  Created by Om Chachad on 01/01/24.
//

import Foundation
import WidgetKit
import SwiftUI

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let bookmark = entry.bookmarks.first {
            Link(destination: URL(string: "linkeeper://openURL/\(bookmark.id)")!) {
                VStack(alignment: .leading) {
                        title
                        
                        Spacer()
                        
                        Text(bookmark.title)
                            .lineLimit(4)
                            .bold()
                            .foregroundStyle(.primary)
                        Text(bookmark.host)
                            .lineLimit(1)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                }
                .shadow(color: Color("WidgetBackground").opacity(0.8), radius: 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 15, design: .rounded))
            }
            .containerBackground(for: .widget) {
                Group {
                    if let thumbnail = CacheManager.instance.get(id: bookmark.id)?.image {
                        thumbnail
                            .resizable()
                            .blur(radius: 4)
                            .scaleEffect(1.1)
                    } else {
                        if let firstChar: Character = bookmark.title.first {
                            Color(uiColor: .systemGray2)
                                .overlay(
                                    Text(String(firstChar))
                                        .font(.largeTitle.weight(.medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .aspectRatio(contentMode: .fill)
                .overlay(Color("WidgetBackground").gradient.opacity(0.7))
            }
        } else {
            title
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private var title: some View {
        Group {
            if let folder = entry.configuration.folder {
                Label(folder.title, systemImage: folder.symbol)
                    .foregroundColor(Color(uiColor: UIColor(ColorOption(rawValue: folder.color)?.color ?? .gray)))
            } else {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 15, design: .rounded))
        .fontWeight(.semibold)
    }
}

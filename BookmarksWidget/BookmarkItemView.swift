//
//  BookmarkItemView.swift
//  BookmarksWidgetExtension
//
//  Created by Om Chachad on 01/01/24.
//

import Foundation
import SwiftUI
import WidgetKit

struct BookmarkItemView: View {
    @Environment(\.widgetFamily) var family
    var bookmark: BookmarkEntity
    
    var body: some View {
        Link(destination: URL(string: "linkeeper://openURL/\(bookmark.id)")!) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bookmark.title)
                        .lineLimit(1)
                    Text(bookmark.host)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Group {
                    if let thumbnail = CacheManager.instance.get(id: bookmark.id)?.image {
                        thumbnail
                            .resizable()
                    } else {
                        if let firstChar: Character = bookmark.title.first {
                            Group {
                            #if os(macOS)
                                Color(uiColor: .gray)
                            #else
                                Color(uiColor: .systemGray2)
                            #endif
                            }
                                .overlay(
                                    Text(String(firstChar).capitalized)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: family == .systemMedium ? 37.5 : 40, height: family == .systemMedium ? 37.5 : 40)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 7.5))
                .shadow(radius: 1)
            }
        }
    }
}



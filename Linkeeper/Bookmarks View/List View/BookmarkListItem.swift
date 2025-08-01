//
//  BookmarkListItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/01/24.
//

import Foundation
import SwiftUI

struct BookmarkListItem: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.editMode) var editMode
    @Environment(\.openURL) var openURL
    
    var bookmark: Bookmark
    
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @State private var cachedPreview: cachedPreview?
    
    var isEditing: Bool {
        #if os(macOS)
        return self._editMode.wrappedValue == .active
        #else
        return self.editMode?.wrappedValue == .active
        #endif
    }
    
    init(bookmark: Bookmark, showDetails: Binding<Bool>, toBeEditedBookmark: Binding<Bookmark?>) {
        self.bookmark = bookmark
        self._showDetails = showDetails
        self._toBeEditedBookmark = toBeEditedBookmark
        
        #if !os(macOS)
        let cacheManager = CacheManager.instance
        
        self._cachedPreview = State(initialValue: cacheManager.get(for: bookmark))
        #endif
    }
    
    var body: some View {
        HStack {
            Group {
                if let preview = cachedPreview?.image {
                    preview
                        .resizable()
                        .scaledToFit()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipped()
                        .cornerRadius(8, style: .continuous)
                        .shadow(radius: 2)
                } else if let firstChar = bookmark.wrappedTitle.first {
                    Text(String(firstChar))
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background {
                            Group {
                                #if os(macOS)
                                Color(nsColor: .tertiaryLabelColor)
                                #else
                                Color(uiColor: .tertiaryLabel)
                                #endif
                            }
                            .background(Color.white)
                            .cornerRadius(8, style: .continuous)
                            .shadow(radius: 2)
                        }
                }
            }
            .padding([.vertical, .trailing], 5)
            .padding(.vertical, 5)
            
            VStack(alignment: .leading) {
                Text(bookmark.wrappedTitle)
                    .lineLimit(3)
                Text(bookmark.wrappedHost)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .bookmarkItemActions(bookmark: bookmark, toBeEditedBookmark: $toBeEditedBookmark, showDetails: $showDetails, cachedPreview: $cachedPreview, includeOpenBookmarkButton: true)
    }
    
    func openBookmark() {
        if !isEditing {
            openURL(bookmark.wrappedURL)
            Task {
                await bookmark.cachePreviewInto($cachedPreview)
            }
        }
    }
}

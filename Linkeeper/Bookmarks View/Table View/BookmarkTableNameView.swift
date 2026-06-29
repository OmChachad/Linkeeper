//
//  BookmarkTableNameView.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/01/24.
//

import Foundation
import SwiftUI

struct TableNameView: View {
    var bookmark: Bookmark
    
    var cachedPreview: cachedPreview? {
        return CacheManager.instance.get(for: bookmark)
    }
    
    var body: some View {
        HStack {
            BookmarkThumbnail(cachedPreview: cachedPreview, title: bookmark.wrappedTitle)
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipped()
                .cornerRadius(8, style: .continuous)
                .shadow(radius: 1)
                .padding(.vertical, 5)
                .padding(.trailing, 10)
            
            Text(bookmark.wrappedTitle)
        }
        .task {
            bookmark.cachedImage(saveTo: .constant(nil)) // To refresh the cachedPreview
        }
    }
}

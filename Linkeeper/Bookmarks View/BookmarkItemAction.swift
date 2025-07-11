//
//  BookmarkItemAction.swift
//  Linkeeper
//
//  Created by Om Chachad on 06/01/24.
//

import Foundation
import SwiftUI

struct BookmarkItemAction: ViewModifier {
    @Environment(\.editMode) var editMode
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    
    var bookmark: Bookmark
    
    @Binding var cachedPreview: cachedPreview?
    @Binding var toBeEditedBookmark: Bookmark?
    @Binding var showDetails: Bool
    @State var isMovingBookmark = false
    
    @State var deleteConfirmation: Bool = false
    @State var toBeDeletedBookmark: Bookmark?
    
    var includeOpenBookmarkButton: Bool
    
    @State var isFavorited = false
    
    var isEditing: Bool {
        #if os(macOS)
        return self._editMode.wrappedValue == .active
        #else
        return self.editMode?.wrappedValue == .active
        #endif
    }
    
    func body(content: Content) -> some View {
        content
            .draggable(bookmark)
            .contextMenu {
                Group {
                    if !isEditing {
                        if includeOpenBookmarkButton {
                            Button("Open in browser", systemImage: "safari") {
                                openURL(bookmark.wrappedURL)
                            }
                            .labelStyle(.titleAndIcon)
                            
                            Divider()
                        }
                        
                        Button {
                            isFavorited.toggle()
                        } label: {
                            if isFavorited == false {
                                ModernLabel("Add to favorites", systemImage: "heart")
                            } else {
                                ModernLabel("Remove from favorites", systemImage: "heart.slash")
                            }
                        }
                        
                        Button("Show details", systemImage: "info.circle") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    toBeEditedBookmark = bookmark
                                    showDetails = true
                                }
                            }
                        }
                        .labelStyle(.titleAndIcon)
                        
                        Button("Copy link", systemImage: "doc.on.doc", action: bookmark.copyURL)
                        .labelStyle(.titleAndIcon)
                        
                        ShareButton(url: bookmark.wrappedURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .labelStyle(.titleAndIcon)
                        }
                        
                        Button("Move", systemImage: "folder") {
                            isMovingBookmark.toggle()
                        }
                        .labelStyle(.titleAndIcon)
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            toBeDeletedBookmark = bookmark
                            deleteConfirmation = true
                        }
                        .labelStyle(.titleAndIcon)
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                if #available(iOS 15.0, macOS 15.0, *) {
                    Button("Delete", systemImage: "trash") {
                        deleteConfirmation = true
                    }
                    .tint(.red)
                    
                    Button("Details", systemImage: "info.circle") {
                        toBeEditedBookmark = bookmark
                        showDetails = true
                    }
                } else {
                    Button("Details", systemImage: "info.circle") {
                        toBeEditedBookmark = bookmark
                        showDetails = true
                    }
                    
                    Button("Delete", systemImage: "trash") {
                        deleteConfirmation = true
                    }
                    .tint(.red)
                }
                
            }
            .swipeActions(edge: .leading) {
                Button {
                    isFavorited.toggle()
                } label: {
                    if isFavorited == false {
                        Label("Add to favorites", systemImage: "heart")
                    } else {
                        Label("Remove from favorites", systemImage: "heart.slash")
                    }
                }
                .tint(.pink)
            }
            .confirmationDialog("Are you sure you want to delete this bookmark?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                Button("Delete Bookmark", role: .destructive) {
                    BookmarksManager.shared.deleteBookmark(bookmark)
                    try? moc.save()
                }
            } message: {
                Text("It will be deleted from all your iCloud devices.")
            }
            .sheet(isPresented: $isMovingBookmark) {
                MoveBookmarksView(toBeMoved: [bookmark]) {}
            }
            .onChange(of: isFavorited) { newValue in
                bookmark.isFavorited = newValue
                try? moc.save()
            }
            .animation(.default, value: cachedPreview?.previewState)
            .task {
                if cachedPreview == nil {
                    bookmark.cachedImage(saveTo: $cachedPreview)
                }
                isFavorited = bookmark.isFavorited
            }
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

extension View {
    func bookmarkItemActions(bookmark: Bookmark, toBeEditedBookmark: Binding<Bookmark?>, showDetails: Binding<Bool>, cachedPreview: Binding<cachedPreview?>, includeOpenBookmarkButton: Bool = false) -> some View {
        self
            .modifier(BookmarkItemAction(bookmark: bookmark, cachedPreview: cachedPreview, toBeEditedBookmark: toBeEditedBookmark, showDetails: showDetails, includeOpenBookmarkButton: includeOpenBookmarkButton))
    }
}

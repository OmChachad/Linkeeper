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
    
    func body(content: Content) -> some View {
        content
            .draggable(bookmark)
            .contextMenu {
                Group {
                    if editMode?.wrappedValue != .active {
                        if includeOpenBookmarkButton {
                            Button {
                                openURL(bookmark.wrappedURL)
                            } label: {
                                Label("Open in browser", systemImage: "safari")
                            }
                            
                            Divider()
                        }
                        
                        Button {
                            isFavorited.toggle()
                        } label: {
                            if isFavorited == false {
                                Label("Add to favorites", systemImage: "heart")
                            } else {
                                Label("Remove from favorites", systemImage: "heart.slash")
                            }
                        }
                        
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    toBeEditedBookmark = bookmark
                                    showDetails = true
                                }
                            }
                        } label: {
                            Label("Show details", systemImage: "info.circle")
                        }
                        
                        Button(action: bookmark.copyURL) {
                            Label("Copy link", systemImage: "doc.on.doc")
                        }
                        
                        ShareButton(url: bookmark.wrappedURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            isMovingBookmark.toggle()
                        } label: {
                            Label("Move", systemImage: "folder")
                        }
                        
                        Button(role: .destructive) {
                            toBeDeletedBookmark = bookmark
                            deleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    deleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .tint(.red)
                }
                
                
                Button {
                    toBeEditedBookmark = bookmark
                    showDetails = true
                } label: {
                    Label("Edit", systemImage: "info.circle")
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
            .onLongPressGesture(minimumDuration: 0.3, perform: {
                #if targetEnvironment(macCatalyst)
                toBeEditedBookmark = bookmark
                showDetails.toggle()
                #endif
            })
            .onChange(of: isFavorited) { newValue in
                bookmark.isFavorited = newValue
                try? moc.save()
            }
            .animation(.default, value: cachedPreview?.previewState)
            .task {
                bookmark.cachedImage(saveTo: $cachedPreview)
                isFavorited = bookmark.isFavorited
            }
    }
    
    func openBookmark() {
        if editMode?.wrappedValue != .active {
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

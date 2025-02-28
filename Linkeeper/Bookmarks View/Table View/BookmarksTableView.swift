//
//  BookmarksTableView.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct BookmarksTableView: View {
    @Environment(\.openURL) var openURL
    var bookmarks: [Bookmark]
    var folder: Folder?
    @Binding var selectedBookmarks: Set<Bookmark.ID>
    @Binding var sortOrder: [KeyPathComparator<Bookmark>]
    
    @Binding var toBeEditedBookmark: Bookmark?
    @Binding var showDetails: Bool
    
    @State private var toBeMovedBookmark: Bookmark?
    @State private var isMoving = false
    
    @State private var toBeDeletedBookmark: Bookmark?
    @State private var deleteConfirmation = false
    
    @State private var folderSortOrder: [KeyPathComparator<Folder>] = [KeyPathComparator(\Folder.wrappedTitle, order: .reverse)]
    
    @Namespace var nm
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let folder, let children = folder.childFoldersArray {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 15) {
                            ForEach(children, id: \.self) { subFolder in
                                FolderGridItem(folder: subFolder, namespace: nm, isEditing: false)
                                    .frame(minWidth: 150, maxWidth: 300)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
            }
            
            if #available(iOS 17.0, macOS 14.0, *) {
                Table(of: Bookmark.self, selection: isMac ? .constant(selectedBookmarks) : $selectedBookmarks, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.wrappedTitle) { bookmark in
                        TableNameView(bookmark: bookmark)
                    }
                    .width(min: 200)
                    
                    TableColumn("Host", value: \.wrappedHost)
                        .width(max: 200)
                    
                    TableColumn("Folder", value: \.wrappedFolderName)
                        .width(max: 200)
                    
                    TableColumn("Date Added", value: \.wrappedDate) { bookmark in
                        Text(bookmark.wrappedDate, style: .date)
                            .tag(bookmark.wrappedDate)
                    }
                    .width(max: isVisionOS ? 200 : 150)
                } rows: {
                    ForEach(bookmarks.sorted(using: sortOrder)) { bookmark in
                        TableRow(bookmark)
                            .draggable(bookmark.draggable)
                            .contextMenu {
                                menuItems(bookmark: bookmark)
                            }
                    }
                }
            } else {
                Table(of: Bookmark.self, selection: isMac ? .constant(selectedBookmarks) : $selectedBookmarks, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.wrappedTitle) { bookmark in
                        TableNameView(bookmark: bookmark)
                    }
                    .width(min: 200)
                    
                    TableColumn("Host", value: \.wrappedHost)
                        .width(max: 200)
                    
                    TableColumn("Folder", value: \.wrappedFolderName)
                        .width(max: 200)
                    
                    TableColumn("Date Added", value: \.wrappedDate) { bookmark in
                        Text(bookmark.wrappedDate, style: .date)
                            .tag(bookmark.wrappedDate)
                    }
                    .width(max: isVisionOS ? 200 : 150)
                } rows: {
                    ForEach(bookmarks.sorted(using: sortOrder)) { bookmark in
                        TableRow(bookmark)
                            .contextMenu {
                                menuItems(bookmark: bookmark)
                            }
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this bookmark?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Delete Bookmark", role: .destructive) {
                BookmarksManager.shared.deleteBookmark(toBeDeletedBookmark!)
            }
        } message: {
            Text("It will be deleted from all your iCloud devices.")
        }
    }
    
    func menuItems(bookmark: Bookmark) -> some View {
        Group {
            Button("Open in browser", systemImage: "safari") {
                openURL(bookmark.wrappedURL)
            }
            .labelStyle(.titleAndIcon)
            
            Divider()
            
            Button {
                bookmark.isFavorited.toggle()
            } label: {
                if bookmark.isFavorited == false {
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
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                toBeDeletedBookmark = bookmark
                deleteConfirmation = true
            }
            .labelStyle(.titleAndIcon)
        }
    }
}

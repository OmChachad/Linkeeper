//
//  BookmarksListView.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import SwiftUI

struct BookmarksListView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.editMode) var editState
    var bookmarks: any Collection<Bookmark>
    var searchText: String
    
    var folder: Folder?
    var favorites: Bool?
    
    // For Detail View
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @Binding var selectedBookmarks: Set<Bookmark.ID>
    @Binding var deleteConfirmation: Bool
    @Binding var movingBookmarks: Bool
    
    @AppStorage("GroupAllByFolders") var groupByFolders: Bool = true
    
    @AppStorage("SortMethod") private var sortMethod: SortMethod = .dateCreated
    @AppStorage("SortDirection") private var sortDirection: SortDirection = .descending
    
    
    //var ungroupedBookmarks: [Bookmark]
    var orderedFolders: [Folder]
    
    var sortedBookmarks: [Bookmark] {
        let ascend = sortDirection == .ascending

        switch(sortMethod) {
        case .dateCreated:
            return bookmarks.sorted(by: { ascend ? $0.wrappedDate < $1.wrappedDate : $0.wrappedDate > $1.wrappedDate })
        case .title:
            return bookmarks.sorted(by: { ascend ? $0.wrappedTitle < $1.wrappedTitle : $0.wrappedTitle > $1.wrappedTitle})
        }
    }
    
    var ungroupedBookmarks: [Bookmark] {
        let ungroupedBookmarks = sortedBookmarks.filter{$0.folder == nil}
        
        if searchText.isEmpty {
            return ungroupedBookmarks
        } else {
            return ungroupedBookmarks.filter { $0.doesMatch(searchText) }
        }
    }
    
    var filteredBookmarks: [Bookmark] {
            if searchText.isEmpty {
                return [Bookmark](sortedBookmarks)
            } else {
                return sortedBookmarks.filter{ $0.doesMatch(searchText) }
            }
        }
    
    func filteredBookmarks(for folder: Folder) -> [Bookmark] {
        if searchText.isEmpty {
            return sortedBookmarks.filter{ $0.folder == folder }
        } else {
            return bookmarks.filter { $0.doesMatch(searchText, folder: folder) }
        }
    }
    
    var body: some View {
        List(selection: $selectedBookmarks) {
            Group {
                if groupByFolders && folder == nil {
                    Group {
                        if !ungroupedBookmarks.isEmpty {
                            Section {
                                list(for: ungroupedBookmarks)
                            }
                        }
                        
                        ForEach(orderedFolders, id: \.self) { folder in
                            let folderHasBookmarks = !folder.bookmarksArray.isEmpty
                            let showGroup = favorites == true ? (!filteredBookmarks(for: folder).isEmpty) : (searchText.isEmpty || !filteredBookmarks(for: folder).isEmpty)
                            if showGroup && folderHasBookmarks {
                                Section {
                                    list(for: filteredBookmarks(for: folder))
                                } header: {
                                    Label(folder.wrappedTitle, systemImage: folder.wrappedSymbol)
                                        .font(.headline)
                                        .foregroundColor(folder.wrappedColor)
                                }
                            }
                        }
                    }
                } else {
                    list(for: filteredBookmarks)
                }
            }
        }
    }
    
    func list(for bookmarks: [Bookmark]) -> some View {
        ForEach(bookmarks, id: \.self) { bookmark in
            BookmarkListItem(bookmark: bookmark, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark)
                .tag(bookmark.id)
        }
    }
}

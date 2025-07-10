//
//  BookmarksGridView.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import SwiftUI
import CoreData

struct BookmarksGridView: View {
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
    
    var minimumItemWidth: CGFloat {
        #if os(visionOS)
         return 165
        #else
        #if os(macOS)
        return 165
        #else
        if UIScreen.main.bounds.width <= 320 {
            return 140
        } else {
            return 165
        }
        #endif
        #endif
    }
    
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
    
    var isEditing: Bool {
        #if os(macOS)
        return self._editState.wrappedValue == .active
        #else
        return self.editState?.wrappedValue == .active
        #endif
    }
    
    var body: some View {
        ScrollView {
            Group {
                if groupByFolders && folder == nil {
                    VStack {
                        if !ungroupedBookmarks.isEmpty {
                            BookmarksGrid(for: ungroupedBookmarks)
                                .padding([.top, .leading, .trailing], 15)
                        }
                        
                        let folders = (favorites == true ? ((Set<Folder?>(bookmarks.map(\.folder))).compactMap { $0 }) : orderedFolders).sorted(by: { $0.index < $1.index })
                        ForEach(folders, id: \.self) { folder in
                            //let folderHasBookmarks = !folder.bookmarksArray.isEmpty
                            let showGroup = favorites == true ? (!filteredBookmarks(for: folder).isEmpty) : (searchText.isEmpty || !filteredBookmarks(for: folder).isEmpty)
                            if showGroup {
                                Section {
                                    VStack {
                                        SubFoldersGrid(folder: folder)
                                        BookmarksGrid(for: filteredBookmarks(for: folder), folder: folder)
                                    }
                                    .contentUnavailabilityView(isUnavailable: (folder.childFoldersArray == nil) && folder.bookmarksArray.isEmpty, unavailabilityView: noBookmarksInSection)
                                    .padding(.horizontal, 15)
                                } header: {
                                    Label(folder.wrappedTitle, systemImage: folder.wrappedSymbol)
                                        .font(.headline)
                                        .imageScale(.large)
                                        .foregroundColor(folder.wrappedColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(5)
                                        .padding(.horizontal, 10)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 15)
                } else {
                    VStack {
                        SubFoldersGrid(folder: folder)
                        BookmarksGrid(for: filteredBookmarks, folder: folder)
                    }
                        .padding(15)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func SubFoldersGrid(folder: Folder?) -> some View {
        Group {
            if let folder, let children = folder.childFoldersArray {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumItemWidth, maximum: 200))], spacing: 20) {
                    ForEach(children, id: \.self) { subFolder in
                        FolderGridItem(folder: subFolder, namespace: namespace, isEditing: isEditing)
                            .padding(.horizontal, 5)
                    }
                }
                .contentShape(Rectangle())
                
                if !folder.bookmarksArray.isEmpty {
                    Divider()
                        .padding(.vertical, 10)
                }
            }
        }
    }
    
    func BookmarksGrid(for bookmarks: [Bookmark], folder: Folder? = nil) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumItemWidth, maximum: 200))], spacing: 15) {
            ForEach(bookmarks, id: \.self) { bookmark in
                BookmarkGridItem(bookmark: bookmark, namespace: namespace, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, selectedBookmarks: $selectedBookmarks)
                    .padding(.horizontal, 5)
            }
        }
        .contentShape(Rectangle())
        .dropDestination { bookmark, url in
            if favorites == true {
                if let bookmark {
                    bookmark.isFavorited = true
                } else {
                    let bookmark = BookmarksManager.shared.addDroppedURL(url)
                    bookmark?.isFavorited = true
                }
            } else {
                if let bookmark {
                    bookmark.folder = folder
                } else {
                    BookmarksManager.shared.addDroppedURL(url, to: folder)
                }
            }
            try? moc.save()
        }
    }
    
    func noBookmarksInSection() -> some View {
        Text("No Bookmarks")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80, idealHeight: 100, maxHeight: 100)
            .background(.regularMaterial)
            .cornerRadius(15, style: .continuous)
            .padding(.horizontal, 5)
            .dropDestination { bookmark, url in
                if let bookmark {
                    bookmark.folder = folder
                } else {
                    BookmarksManager.shared.addDroppedURL(url, to: folder)
                }
                try? moc.save()
            }
    }
}

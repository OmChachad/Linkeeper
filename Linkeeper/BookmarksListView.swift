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

struct BookmarkListItem: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.editMode) var editMode
    @Environment(\.openURL) var openURL
    
    var bookmark: Bookmark
    
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @State private var cachedPreview: cachedPreview?
    
    var body: some View {
        HStack {
            Group {
                if let preview = cachedPreview?.image {
                    preview
                        .resizable()
                        .scaledToFit()
                } else if let firstChar = bookmark.wrappedTitle.first {
                    Text(String(firstChar))
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.tertiary)
                }
            }
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipped()
            .cornerRadius(8, style: .continuous)
            .shadow(radius: 2)
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
        if editMode?.wrappedValue != .active {
            openURL(bookmark.wrappedURL)
            Task {
                await bookmark.cachePreviewInto($cachedPreview)
            }
        }
    }
}

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
            .animation(.default, value: cachedPreview?.image)
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

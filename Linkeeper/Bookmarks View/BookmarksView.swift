//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI
import Pow

struct BookmarksView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // CoreData FetchRequests
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    var folder: Folder?
    var favorites: Bool?
    
    @State private var folderTitle = ""
    
    // For Detail View
    @Namespace var nm
    @State private var showDetails = false
    @State private var toBeEditedBookmark: Bookmark?
    
    @State private var selectedBookmarks: Set<Bookmark.ID> = []
    @State private var deleteConfirmation = false
    @State private var movingBookmarks = false
    
    // ToolbarItems-related variables
    @State var editState: EditMode = .inactive
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    @AppStorage("GroupAllByFolders") var groupByFolders: Bool = true
    @AppStorage("ViewOption") private var viewOption: ViewOption = .grid
    
    @AppStorage("SortMethod") private var sortMethod: SortMethod = .dateCreated
    @AppStorage("SortDirection") private var sortDirection: SortDirection = .descending
    
    @State private var sortOrder = [KeyPathComparator(\Bookmark.wrappedDate, order: .reverse)]
    
    var shouldDisallowTable: Bool {
        if #available(iOS 16.0, macOS 13.0, *) {
        #if os(macOS)
            return false
        #else
            return horizontalSizeClass == .compact || UIDevice.current.userInterfaceIdiom == .phone
        #endif
        } else {
            return false
        }
    }
    
    var minimumItemWidth: CGFloat {
        #if os(visionOS)
         return 165
        #else
        #if os(macOS)
        return 165
        #else
        if UIScreen.main.bounds.width == 320 {
            return 145
        } else {
            return 165
        }
        #endif
        #endif
    }
    
    var orderedFolders: [Folder] {
        return folders.sorted(using: [
            KeyPathComparator(\.isPinned, order: .reverse),
            KeyPathComparator(\.index, order: .forward)]
        )
    }
    
    init() {}
    
    init(folder: Folder) {
        _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "folder == %@", folder))
        
        self.folder = folder
        self._folderTitle = State(initialValue: folder.wrappedTitle)
    }
    
    init(onlyFavorites: Bool = true) {
        _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true"))
        self.favorites = onlyFavorites
    }
    
    var body: some View {
        Group {
            if !searchText.isEmpty && filteredBookmarks.isEmpty {
                Text("No results found for **\"\(searchText)\"**")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                switch(viewOption) {
                case .grid:
                    BookmarksGridView(bookmarks: bookmarks, searchText: searchText, folder: folder, favorites: favorites, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, selectedBookmarks: $selectedBookmarks, deleteConfirmation: $deleteConfirmation, movingBookmarks: $movingBookmarks, orderedFolders: orderedFolders)
                case .list:
                    BookmarksListView(bookmarks: bookmarks, searchText: searchText, folder: folder, favorites: favorites, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, selectedBookmarks: $selectedBookmarks, deleteConfirmation: $deleteConfirmation, movingBookmarks: $movingBookmarks, orderedFolders: orderedFolders)
                case .table:
                    if #available(iOS 16.0, macOS 13.0, *), !shouldDisallowTable {
                        BookmarksTableView(bookmarks: filteredBookmarks, selectedBookmarks: $selectedBookmarks, sortOrder: $sortOrder, toBeEditedBookmark: $toBeEditedBookmark, showDetails: $showDetails)
                    } else {
                        BookmarksListView(bookmarks: bookmarks, searchText: searchText, folder: folder, favorites: favorites, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, selectedBookmarks: $selectedBookmarks, deleteConfirmation: $deleteConfirmation, movingBookmarks: $movingBookmarks, orderedFolders: orderedFolders)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Find a bookmark...")
        .contentUnavailabilityView(for: bookmarks, unavailabilityView: noBookmarksView)
        .overlay {
            if showDetails && !isVisionOS {
                Color("primaryInverted").opacity(0.3)
                    .background(.thinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDetails = false
                    }
                
                BookmarkDetails(bookmark: toBeEditedBookmark!, namespace: nm, showDetails: $showDetails, hideFavoriteOption: favorites == true)
                    .if(viewOption != .grid) { view in
                        view.transition(.movingParts.glare)
                    }
            }
        }
        .navigationTitle(for: folder, folderTitle: $folderTitle, onlyFavorites: favorites ?? false)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            HStack {
                if editState == .inactive {
                    Picker("View Style", selection: $viewOption) {
                        ForEach(ViewOption.allCases.filter { !(shouldDisallowTable && $0 == .table && viewOption != .table) }, id: \.self) { option in
                            Label(option.title, systemImage: option.iconString)
                                .labelStyle(.iconOnly)
                                .tag(option)
                        }
                    }
                    
                    .if(shouldDisallowTable) { view in
                        view.pickerStyle(.menu)
                    }
                    .if(!shouldDisallowTable) { view in
                        view.pickerStyle(.segmented)
                    }
                    
                    if viewOption != .table || !isMac && !bookmarks.isEmpty {
                        Menu {
                            toolbarItems()
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    
                } else {
                    Button("Done") { editState = .inactive }
                }
            }
        }
        #if os(macOS)
        .safeAreaInset(edge: .bottom, content: {
            HStack {
                Button {
                    addingBookmark = true
                } label: {
                    Label("New Bookmark", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.headline)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Spacer()
            }
            .foregroundColor(folder?.wrappedColor)
            .padding()
            .background(.thickMaterial)
            .buttonStyle(.borderless)
        })
        #endif
        .overlay {
            #if !os(visionOS)
            if editState == .active || selectedBookmarks.count > 1 {
                bottomEditToolbar()
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
            }
            #endif
        }
        #if os(macOS)
        .environment(\.editMode, editState)
        #else
        .environment(\.editMode, $editState)
        #endif
        .sheet(isPresented: $movingBookmarks) {
            MoveBookmarksView(toBeMoved: [Bookmark](selectedBookmarks.map{BookmarksManager.shared.findBookmark(withId: $0!)})) {
                selectedBookmarks.removeAll()
                editState = .inactive
            }
        }
        .sheet(isPresented: $addingBookmark) {
            AddBookmarkView(folderPreset: folder)
        }
        .onChange(of: editState) { _ in
            selectedBookmarks.removeAll()
        }
        .onChange(of: viewOption) { _ in
            selectedBookmarks.removeAll()
        }
        .onChange(of: folderTitle, perform: { newTitle in
            if let folder = folder {
                if folder.wrappedTitle != newTitle {
                    if !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        folder.title = newTitle
                        try? moc.save()
                    } else {
                        folderTitle = folder.wrappedTitle
                    }
                }
            }
        })
        .animation(.spring().speed(0.75), value: filteredBookmarks)
        .animation(.spring(), value: showDetails)
        .animation(.easeInOut.speed(0.5), value: editState)
        #if os(visionOS)
        .ornament(visibility: editState == .active ? .visible : .hidden, attachmentAnchor: .scene(.bottom)) {
            bottomEditToolbar()
                .padding()
                .glassBackgroundEffect(in: Capsule())
        }
        .ornament(visibility: showDetails ? .visible : .hidden, attachmentAnchor: .scene(.trailing), contentAlignment: .leading) {
            if showDetails {
                BookmarkDetails(bookmark: toBeEditedBookmark!, namespace: nm, showDetails: $showDetails, hideFavoriteOption: favorites == true)
            }
        }
        #endif
    }
    
    func bottomEditToolbar() -> some View {
        HStack {
            Button(role: .destructive) {
                deleteConfirmation.toggle()
            } label: {
                Image(systemName: "trash")
                    .imageScale(.large)
                    #if os(macOS)
                    .foregroundColor(selectedBookmarks.isEmpty ? nil : .red)
                    #endif
            }
            .confirmationDialog("Are you sure you want to delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                Button("Delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)", role: .destructive) {
                    selectedBookmarks.forEach { bookmark in
                        BookmarksManager.shared.deleteBookmark(withId: bookmark ?? UUID())
                    }
                    try? moc.save()
                    selectedBookmarks.removeAll()
                    editState = .inactive
                }
            } message: {
                Text("^[\(selectedBookmarks.count) Bookmark](inflect: true) will be deleted from all your iCloud devices.")
            }
            
            Spacer()
                .frame(width: 20)
            
            Button {
                movingBookmarks.toggle()
            } label: {
                Image(systemName: "folder")
                    .imageScale(.large)
            }
        }
        .disabled(selectedBookmarks.isEmpty)
    }
    
    func noBookmarksView() -> some View {
        VStack {
            Image(systemName: "bookmark.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(favorites != true ? "You do not have any bookmarks \(folder != nil ? "in this folder" : "")" : "You do not have any favorites")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
                .padding(5)
            
            if favorites != true {
                Button("Create a bookmark") {
                    addingBookmark.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    func toolbarItems() -> some View {
        Group {
            if !isMac || viewOption == .grid {
                Button { editState = .active } label: { Label("Select", systemImage: "checkmark.circle") }
            }
            
            
            if viewOption != .table || shouldDisallowTable {
                if folder == nil {
                    Toggle(isOn: $groupByFolders.animation(), label: { Label("Group by Folders", systemImage: "rectangle.grid.1x2") })
                }
                
                Menu {
                    Picker("Sort By", selection: $sortMethod) {
                        ForEach(SortMethod.allCases, id: \.self) { sortMethod in
                            Text(sortMethod.rawValue)
                                .tag(sortMethod)
                        }
                    }
                    
                    Picker("Sort Direction", selection: $sortDirection) {
                        ForEach(SortDirection.allCases, id: \.self) { sortDirection in
                            Text(sortDirection.label)
                                .tag(sortDirection)
                        }
                    }
                    
                } label: {
                    Label("""
                    Sort By
                    \(sortMethod.rawValue)
                    """, systemImage: "arrow.up.arrow.down")
                }
            }
            
            #if !os(macOS)
            Divider()
            
            Button { addingBookmark.toggle() } label: { Label("Add Bookmark", systemImage: "plus") }
                .keyboardShortcut("n", modifiers: .command)
            #endif
        }
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
    
    var filteredBookmarks: [Bookmark] {
        if searchText.isEmpty {
            return [Bookmark](sortedBookmarks)
        } else {
            return sortedBookmarks.filter{ $0.doesMatch(searchText) }
        }
    }
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarksView()
        }
    }
}

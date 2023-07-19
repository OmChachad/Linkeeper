//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI

struct BookmarksView: View {
    @Environment(\.managedObjectContext) var moc
    
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
    
    @State private var selectedBookmarks: Set<Bookmark> = []
    @State private var deleteConfirmation = false
    @State private var movingBookmarks = false
    
    // ToolbarItems-related variables
    @State var editState: EditMode = .inactive
    @State private var addingBookmark = false
    @State private var searchText = ""
    @AppStorage("GroupAllByFolders") var groupByFolders: Bool = true
    @AppStorage("SortMethod") private var sortMethod: SortMethod = .dateCreated
    @AppStorage("SortDirection") private var sortDirection: SortDirection = .descending
    
    private enum SortMethod: String, Codable, CaseIterable {
        case dateCreated = "Creation Date"
        case title = "Title"
    }
    
    private enum SortDirection: String, Codable, CaseIterable {
        case ascending
        case descending
        
        var label: String {
            let sortMethod: SortMethod = SortMethod(rawValue: UserDefaults.standard.string(forKey: "SortMethod") ?? "Date Created") ?? .dateCreated
            switch(sortMethod) {
            case .dateCreated:
                return self == .ascending ? "Oldest First" : "Newest First"
            case .title:
                return self == .ascending ? "Ascending" : "Descending"
            }
        }
    }
    
    var minimumItemWidth: CGFloat {
        if UIScreen.main.bounds.width == 320 {
            return 145
        } else {
            return 165
        }
    }
    
    
    init() {}
    
    init(folder: Folder) {
        _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "folder == %@", folder))
        
        self.folder = folder
    }
    
    init(onlyFavorites: Bool = true) {
        _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true"))
        self.favorites = onlyFavorites
    }
    
    var body: some View {
        Group {
            if bookmarks.isEmpty {
                noBookmarksView()
            } else {
                ScrollView {
                    Group {
                        if !searchText.isEmpty && filteredBookmarks.isEmpty {
                            Text("No results found for **\"\(searchText)\"**")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        if groupByFolders && folder == nil {
                            LazyVStack(pinnedViews: [.sectionHeaders]) {
                                if !ungroupedBookmarks.isEmpty {
                                    BookmarksGrid(for: ungroupedBookmarks)
                                        .padding([.top, .leading, .trailing], 15)
                                }
                                
                                ForEach(folders, id: \.self) { folder in
                                    let folderHasBookmarks = !folder.bookmarksArray.isEmpty
                                    let showGroup = favorites == true ? (!filteredBookmarks(for: folder).isEmpty) : (searchText.isEmpty || !filteredBookmarks(for: folder).isEmpty)
                                    if showGroup {
                                        Section {
                                            Group {
                                                if folderHasBookmarks {
                                                    BookmarksGrid(for: filteredBookmarks(for: folder), folder: folder)
                                                } else {
                                                    noBookmarksInSection()
                                                }
                                            }
                                            .padding(.horizontal, 15)
                                        } header: {
                                            HStack {
                                                Label(folder.wrappedTitle, systemImage: folder.wrappedSymbol)
                                                    .font(.headline)
                                                    .imageScale(.large)
                                                    .foregroundColor(folder.wrappedColor)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 15)
                                            .background(Color(uiColor: .systemBackground).opacity(0.95))
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 15)
                        } else {
                            BookmarksGrid(for: filteredBookmarks, folder: folder)
                                .padding(15)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .searchable(text: $searchText, prompt: "Find a bookmark...")
            }
        }
        .overlay {
            if showDetails {
                Color("primaryInverted").opacity(0.3)
                    .background(.thinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDetails = false
                    }
                
                BookmarkDetails(bookmark: toBeEditedBookmark!, namespace: nm, showDetails: $showDetails)
            }
        }
        .navigationTitle(for: folder, folderTitle: $folderTitle, onlyFavorites: favorites ?? false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if editState == .inactive {
                    Menu {
                        toolbarItems()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                } else {
                    #if !targetEnvironment(macCatalyst)
                    Button("Done") { editState = .inactive }
                    #endif
                }
                
                #if targetEnvironment(macCatalyst)
                EditButton()
                #endif
            }
        }
        .overlay {
            if editState == .active {
                HStack {
                    Button(role: .destructive) {
                        deleteConfirmation.toggle()
                    } label: {
                        Image(systemName: "trash")
                            .imageScale(.large)
                    }
                    .tint(Color.red)
                    .confirmationDialog("Are you sure you want to delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                        Button("Delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)", role: .destructive) {
                            selectedBookmarks.forEach { bookmark in
                                moc.delete(bookmark)
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .environment(\.editMode, $editState)
        .sheet(isPresented: $movingBookmarks) {
            MoveBookmarksView(toBeMoved: [Bookmark](selectedBookmarks)) {
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
        .onAppear {
            if let folder = folder {
                self.folderTitle = folder.wrappedTitle
            }
        }
        .animation(.spring(), value: filteredBookmarks)
        .animation(.spring(), value: showDetails)
        .animation(.easeInOut.speed(0.5), value: editState)
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
    }
    
    func noBookmarksInSection() -> some View {
        Text("No Bookmarks")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80, idealHeight: 100, maxHeight: 100)
            .background(.regularMaterial)
            .cornerRadius(15, style: .continuous)
            .padding(.horizontal, 5)
    }
    
    func toolbarItems() -> some View {
        Group {
            Button { editState = .active } label: { Label("Select", systemImage: "checkmark.circle") }
            
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
                #if targetEnvironment(macCatalyst)
                
                Label("Sort By", systemImage: "arrow.up.arrow.down")
                #else
                
                Label("""
Sort By
\(sortMethod.rawValue)
""", systemImage: "arrow.up.arrow.down")
                #endif
            }
            
            Button { addingBookmark.toggle() } label: { Label("Add Bookmark", systemImage: "plus") }
                .keyboardShortcut("n", modifiers: .command)
        }
        .borderlessMacCatalystButton()
    }
    
    func BookmarksGrid(for bookmarks: [Bookmark], folder: Folder? = nil) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumItemWidth, maximum: 200))], spacing: 15) {
            ForEach(bookmarks, id: \.self) { bookmark in
                BookmarkItem(bookmark: bookmark, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, selectedBookmarks: $selectedBookmarks)
                    .padding(.horizontal, 5)
            }
        }
        .contentShape(Rectangle())
        .dropDestination { bookmark, url in
            if let bookmark {
                bookmark.folder = folder
                try? moc.save()
            } else {
                BookmarksManager.shared.addDroppedURL(url, to: folder)
            }
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
    
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarksView()
        }
    }
}

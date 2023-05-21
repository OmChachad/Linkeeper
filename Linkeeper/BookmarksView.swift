//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI

struct BookmarksView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    var folder: Folder?
    var favorites: Bool?
    
    @State private var folderTitle = ""
    
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    @State var editState: EditMode = .inactive
    
    @Namespace var nm
    @State private var showDetails = false
    @State private var toBeEditedBookmark: Bookmark?
    
    @State private var detailViewImage: DetailsPreview?
    
    @State private var selectedBookmarks: Set<Bookmark> = []
    @State private var deleteConfirmation = false
    @State private var movingBookmarks = false
    
    @AppStorage("GroupAllByFolders") var groupByFolders: Bool = true
    
    var minimumItemWidth: CGFloat {
        if UIScreen.main.bounds.width == 320 {
            return 145
        } else {
            return 165
        }
    }
    
    init(folder: Folder?, onlyFavorites: Bool) {
        if let folder = folder {
            _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "folder == %@", folder))
        } else if onlyFavorites {
            _bookmarks = FetchRequest<Bookmark>(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true"))
        }
        
        self.folder = folder
        self.favorites = onlyFavorites
    }
    
    var body: some View {
        Group {
            if bookmarks.isEmpty {
                VStack {
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
                            BookmarksGrid(for: ungroupedBookmarks)
                                .padding(.horizontal, 15)
                                .padding(.bottom , 2.5)
                            
                            ForEach(folders, id: \.self) { folder in
                                let folderHasBookmarks = !folder.bookmarksArray.isEmpty
                                if searchText.isEmpty || !filteredBookmarks(for: folder).isEmpty {
                                    DisclosureGroup {
                                        if folderHasBookmarks {
                                            BookmarksGrid(for: filteredBookmarks(for: folder))
                                                .padding(.vertical, 5)
                                        } else {
                                            Text("No Bookmarks")
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, minHeight: 80, idealHeight: 100, maxHeight: 100)
                                                .background(.regularMaterial)
                                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                                .padding(.horizontal, 5)
                                        }
                                    } label: {
                                        Label {
                                            Text(folder.wrappedTitle)
                                                .foregroundColor(.primary)
                                        } icon: {
                                            Image(systemName: folder.wrappedSymbol)
                                                .imageScale(.large)
                                                .foregroundColor(folder.wrappedColor)
                                        }
                                        .padding(.vertical, 5)
                                    }
                                    .expandByDefault(folderHasBookmarks)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 5)
                                }
                            }
                        } else {
                            BookmarksGrid(for: filteredBookmarks)
                                .padding(.horizontal, 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .searchable(text: $searchText, prompt: "Find a bookmark...")
            }
        }
        .overlay {
            if showDetails {
                Color("primaryInverted").opacity(0.6)
                    .background(.thinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDetails.toggle()
                    }
                
                BookmarkDetails(bookmark: toBeEditedBookmark!, namespace: nm, showDetails: $showDetails, detailViewImage: detailViewImage)
            }
        }
        .navigationTitle(for: folder, folderTitle: $folderTitle, onlyFavorites: favorites ?? false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editState == .inactive {
                Menu {
                    Button { editState = .active } label: { Label("Select", systemImage: "checkmark.circle") }
                    
                    if folder == nil {
                        Toggle(isOn: $groupByFolders.animation(), label: { Label("Group by Folders", systemImage: "rectangle.grid.1x2") })
                    }
                    
                    Button { addingBookmark.toggle() } label: { Label("Add Bookmark", systemImage: "plus") }
                        .keyboardShortcut("n", modifiers: .command)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                Button("Done") { editState = .inactive }
            }
        }
        .overlay {
            if editState == .active {
                HStack {
                    Button() {
                        deleteConfirmation.toggle()
                    } label: {
                        Image(systemName: "trash")
                            .imageScale(.large)
                    }
                    .disabled(selectedBookmarks.isEmpty)
                    .confirmationDialog("Are you sure you want to delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                        Button("Delete ^[\(selectedBookmarks.count) Bookmark](inflect: true)", role: .destructive) {
                            selectedBookmarks.forEach { bookmark in
                                moc.delete(bookmark)
                            }
                            try? moc.save()
                            
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .environment(\.editMode, $editState)
        .sheet(isPresented: $movingBookmarks) {
            MoveBookmarksView(toBeMoved: [Bookmark](selectedBookmarks))
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
    
    func BookmarksGrid(for bookmarks: [Bookmark]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumItemWidth))], spacing: 15) {
            ForEach(bookmarks, id: \.self) { bookmark in
                BookmarkItem(bookmark: bookmark, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, detailViewImage: $detailViewImage, selectedBookmarks: $selectedBookmarks)
                    .padding(.horizontal, 5)
            }
        }
    }
    
    var ungroupedBookmarks: [Bookmark] {
        let ungroupedBookmarks = bookmarks.filter{$0.folder == nil}
        
        if searchText.isEmpty {
            return ungroupedBookmarks
        } else {
            return ungroupedBookmarks.filter { $0.doesMatch(searchText) }
        }
    }
    
    var filteredBookmarks: [Bookmark] {
            if searchText.isEmpty {
                return [Bookmark](bookmarks)
            } else {
                return bookmarks.filter{ $0.doesMatch(searchText) }
            }
        }
    
    func filteredBookmarks(for folder: Folder) -> [Bookmark] {
        if searchText.isEmpty {
            return bookmarks.filter{ $0.folder == folder }
        } else {
            return bookmarks.filter { $0.doesMatch(searchText, folder: folder) }
        }
    }
    
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarksView(folder: nil, onlyFavorites: false)
        }
    }
}

extension View {
    func navigationTitle(for folder: Folder?, folderTitle: Binding<String>, onlyFavorites: Bool) -> some View {
        Group {
            if #available(iOS 16.0, *), folder != nil {
                self
                    .navigationTitle(folderTitle)
            } else {
                self
                    .navigationTitle(folder?.wrappedTitle ?? (onlyFavorites == true ? "Favorites" : "All Bookmarks"))
            }
        }
    }
}

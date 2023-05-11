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
    
    var folder: Folder?
    var favorites: Bool?
    
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    @State var editState: EditMode = .inactive
    
    @Namespace var nm
    @State private var showDetails = false
    @State private var toBeEditedBookmark: Bookmark?
    
    @State private var detailViewImage: DetailsPreview?
    
    @State private var selectedBookmarks: Set<Bookmark> = []
    @State private var deleteConfirmation = false
    
    var minimumItemWidth: CGFloat {
        if UIScreen.main.bounds.width == 320 {
            return 145
        } else {
            return 160
        }
    }
    
    var body: some View {
        Group {
            if bookmarks.count == 0 {
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
                    if !searchText.isEmpty && filteredBookmarks.count == 0 {
                        Text("No results found for \"\(searchText)\"")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    GeometryReader { geo in
                        let columns = Array(repeating: GridItem(.flexible(minimum: minimumItemWidth, maximum: 170)), count: Int(floor(geo.size.width / 160)))
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filteredBookmarks, id: \.self) { bookmark in
                                BookmarkItem(bookmark: bookmark, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark, detailViewImage: $detailViewImage, selectedBookmarks: $selectedBookmarks)
                                    .padding(5)
                            }
                        }
                        .animation(.spring(), value: geo.size.width)
                    }
                    .searchable(text: $searchText, prompt: "Find a bookmark...")
                }
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
        .navigationTitle(folder?.wrappedTitle ?? (favorites == true ? "Favorites" : "All Bookmarks"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editState == .inactive {
                Menu {
                    Button { editState = .active } label: { Label("Select", systemImage: "checkmark.circle") }
                    
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
                    Button() {
                        
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
        .sheet(isPresented: $addingBookmark) {
            AddBookmarkView(folderPreset: folder)
        }
        .animation(.spring(), value: filteredBookmarks)
        .animation(.spring(), value: showDetails)
        .animation(.easeInOut.speed(0.5), value: editState)
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
    
    var filteredBookmarks: [Bookmark] {
        if searchText.isEmpty {
            return [Bookmark](bookmarks)
        } else {
            return bookmarks.filter { $0.wrappedTitle.localizedCaseInsensitiveContains(searchText) || $0.wrappedNotes.localizedCaseInsensitiveContains(searchText) || $0.wrappedHost.localizedCaseInsensitiveContains(searchText) }
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
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


//.confirmationDialog("Are you sure you want to delete \(toBeDeleted?.count == 1 ? "this bookmark? It" : "these bookmarks? They") will be deleted from all your iCloud devices.", isPresented: $deleteConfirmation, titleVisibility: .visible) {

extension View {
    func glow() -> some View {
            self
                .background(self.blur(radius: 5))
    }
}

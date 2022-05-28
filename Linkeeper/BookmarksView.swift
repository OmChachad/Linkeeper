//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI

struct BookmarksView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var bookmarks: FetchedResults<Bookmark>
    
    var folder: Folder?
    var favorites: Bool?
    
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    @State var editState: EditMode = .inactive
    
    @Namespace var nm
    @State private var showDetails = false
    @State private var toBeEditedBookmark: Bookmark?
    
    var columns: [GridItem] {
        if UIDevice.current.model == "iPhone" {
            return [UIScreen.main.bounds.width == 320  ? GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 20) : GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 20)]
        } else {
            return [GridItem(.adaptive(minimum: 170, maximum: 180), spacing: 20)]
        }
    }
    
    var body: some View {
        ZStack {
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
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredBookmarks, id: \.self) { bookmark in
                            BookmarkItem(bookmark: bookmark, namespace: nm, showDetails: $showDetails, toBeEditedBookmark: $toBeEditedBookmark)
                                .frame(minHeight: 156, idealHeight: 218.2, maxHeight: 218.2)
                                .glow() // MARK: Make this optional in settings
                            //  .shadow(color: .secondary.opacity(0.5), radius: 3) // MARK: Make this optional in settings
                                .transition(.opacity)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Find a bookmark...")
                    .padding(.horizontal)
                    
                }
            }
            if showDetails {
                
                Color("primaryInverted").opacity(0.6)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDetails = false
                    }
                
                BookmarkDetails(bookmark: toBeEditedBookmark!, namespace: nm, showDetails: $showDetails)
                    .shadow(color: .black.opacity(0.25), radius: 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editState == .inactive {
                Menu {
                    Button { editState = .active } label: { Label("Select", systemImage: "checkmark.circle") }
                    Button { addingBookmark.toggle() } label: { Label("Add Bookmark", systemImage: "plus") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                Button("Done") { editState = .inactive }
            }
        }
        .environment(\.editMode, $editState)
        .sheet(isPresented: $addingBookmark) {
            AddBookmarkView(folderPreset: folder)
        }
        .animation(.spring(), value: filteredBookmarks)
        .animation(.spring(), value: showDetails)
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

//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI

struct BookmarksView: View {
    var folder: Folder?
    var favorites: Bool?
    @ObservedObject var bookmarks: Bookmarks
    @ObservedObject var folders: Folders
    
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    
    @State private var deleteConfirmation = false
    
    @State private var toBeDeleted: [Bookmark]?
    @State var editState: EditMode = .inactive
    
    @State private var wiggleAmount = 0.0
    
    var columns: [GridItem] {
        if UIDevice.current.model == "iPhone" {
            return [UIScreen.main.bounds.width == 320  ? GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 20) : GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 20)]
        } else {
            return [GridItem(.adaptive(minimum: 170, maximum: 180), spacing: 20)]
        }
    }
    
    var body: some View {
        ZStack {
            if allBookmarks.count == 0 {
                VStack {
                    Text(favorites != true ? "You do not have any bookmarks \(folder != nil ? "in this folder" : "")" : "You do not have any favorites")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(alignment: .center)
                    .padding(5)
                    Button("Create a bookmark") {
                        addingBookmark.toggle()
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredBookmarks, id:\.self) { bookmark in
                            BookmarkView(bookmark: bookmark)
                            //  .shadow(color: .secondary.opacity(0.5), radius: 3) // MARK: Make this optional in settings
                                .if(editState == .active) { view in
                                    view.rotationEffect(.degrees(wiggleAmount))
                                }
                                .transition(.opacity)
                                .frame(minHeight: 156, idealHeight: 218.2, maxHeight: 218.2)
                                .contextMenu {
                                                                        
                                    Button {
                                        var favoritedBookmark = bookmark
                                        favoritedBookmark.favorited.toggle()
                                        let index = indexOf(bookmark: bookmark, folder: nil)!
                                        bookmarks.items.remove(at: index)
                                        bookmarks.items.insert(favoritedBookmark, at: index)
                                    } label: {
                                        if bookmark.favorited == false {
                                            Label("Add to favorites", systemImage: "heart")
                                        } else {
                                            Label("Remove from favorites", systemImage: "heart.slash")
                                        }
                                    }
                                                                        
                                    
                                    Button {
                                        // Code to edit the bookmark
                                    } label: {
                                        Label("Show details", systemImage: "info.circle")
                                    }
                                    
                                    Button {
                                        UIPasteboard.general.url = bookmark.url
                                    } label: {
                                        Label("Copy link", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button {
                                        share(url: bookmark.url)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button {
                                        // Code to move
                                    } label: {
                                        Label("Move", systemImage: "folder")
                                    }
                                    
                                    Button(role: .destructive) {
                                        toBeDeleted = [bookmark]
                                        deleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Find a bookmark...")
                    .padding(.horizontal)
                    
                }
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
            AddBookmarkView(bookmarks: bookmarks, folders: folders, folderPreset: folder)
        }
        .confirmationDialog("Are you sure you want to delete \(toBeDeleted?.count == 1 ? "this bookmark? It" : "these bookmarks? They") will be deleted from all your iCloud devices.", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button(toBeDeleted?.count == 1 ? "Delete" : "Delete \(toBeDeleted != nil ? toBeDeleted!.count : 0) Bookmarks", role: .destructive) {
                guard let toBeDeleted = toBeDeleted else { return }
                for bookmark in toBeDeleted {
                    bookmarks.items.remove(at: bookmarks.items.firstIndex(of: bookmark)!)
                }
                self.toBeDeleted = nil
            }
        }
        .animation(.spring(), value: filteredBookmarks)
    }
    
    var allBookmarks: [Bookmark] {
        return bookmarks.items.filter({ if folder != nil { return $0.folder == folder } else { return true } })
    }
    
    func indexOf(bookmark: Bookmark?, folder: Folder?) -> Int? {
        if let index = bookmarks.items.firstIndex(of: bookmark!) {
            return index
        } else if let index = folders.items.firstIndex(of: folder!) {
            return index
        } else {
            return nil
        }
    }
    
    var filteredBookmarks: [Bookmark] {
        let allBookmarks = bookmarks.items.filter( { if folder != nil { return $0.folder == folder } else { return true } } )
        
        if searchText.isEmpty {
            return allBookmarks
        } else {
            return allBookmarks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.notes.localizedCaseInsensitiveContains(searchText) || $0.host.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func share(url: URL) {
        let activityView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
    
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarksView(bookmarks: Bookmarks(), folders: Folders())
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



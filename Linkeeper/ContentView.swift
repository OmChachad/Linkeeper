//
//  ContentView.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI


struct MainOption: Hashable {
    var id = UUID()
    var title: String
    var symbol: String
    var color: Color
    var favorites: Bool
}

struct ContentView: View {
    @ObservedObject var bookmarks = Bookmarks()
    @ObservedObject var folders = Folders()
    
    @State private var showingNewBookmarkView = false
    
    @State private var showingNewFolderView = false
    
    @State var mode: EditMode = .inactive
    
    @State private var selection = Set<MainOption>()
    
    @State private var deleteConfirmation = false
    
    @AppStorage("showingAll") var showingAll: Bool = true
    @AppStorage("showingFavorites") var showingFavorites: Bool = true
    
    @State private var mainOptions: [MainOption] = [
        MainOption(title: "All", symbol: "tray.fill", color: Color(UIColor.darkGray), favorites: false),
        MainOption(title: "Favorites", symbol: "heart.fill", color: Color.pink, favorites: true)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                List {
                    ForEach(mainOptions, id: \.self) { option in
                        NavigationLink {
                            BookmarksView(favorites: option.favorites, bookmarks: bookmarks, folders: folders)
                        } label : {
                            HStack {
                                
                                Image(systemName: option.symbol)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .padding(10)
                                    .background(option.color)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                Text(option.title)
                                    .bold()
                                Spacer()
                                Text("\(option.favorites == true ? bookmarks.items.filter{$0.favorited == true}.count : bookmarks.items.count)")
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 70)
                        }
                    }
                    
                    
                    Section(header: Text("My Folders")) {
                        ForEach(folders.items, id: \.self) { folder in
                            NavigationLink {
                                BookmarksView(folder: folder, bookmarks: self.bookmarks, folders: folders)
                            } label: {
                                FolderItemView(bookmarks: bookmarks, folders: folders, folder: folder, deleteConfirmation: $deleteConfirmation)
                                    .confirmationDialog("Do you want to delete \(bookmarksInside(folder).count) \(bookmarksInside(folder).count == 1 ? "bookmark" : "bookmarks") inside \(folder.title) too?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                                        Button("Delete \(bookmarksInside(folder).count) \(bookmarksInside(folder).count == 1 ? "Bookmark" : "Bookmarks")", role: .destructive) {
                                            bookmarks.items.removeAll(where: { $0.folder == folder })
                                            folders.items.remove(at: folders.items.firstIndex(of: folder)!)
                                        }
                                        
                                        Button("Keep \(bookmarksInside(folder).count) \(bookmarksInside(folder).count == 1 ? "Bookmark" : "Bookmarks")") {
                                            for bookmark in bookmarksInside(folder) {
                                                var updatedBookmark = bookmarks.items.first(where: {$0.id == bookmark.id})
                                                updatedBookmark?.folder = nil
                                                
                                                if let index = bookmarks.items.firstIndex(of: bookmark) {
                                                    bookmarks.items.remove(at: index)
                                                    bookmarks.items.insert(updatedBookmark!, at: index)
                                                }
                                            }
                                            folders.items.remove(at: folders.items.firstIndex(of: folder)!)
                                        }
                                    } message: {
                                        Text("\(bookmarksInside(folder).count) \(bookmarksInside(folder).count == 1 ? "bookmark" : "bookmarks") will be deleted.")
                                    }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if bookmarks.items.filter({$0.folder == folder}).count == 0 {
                                        folders.items.remove(at: folders.items.firstIndex(where: {$0.id == folder.id})!)
                                    } else {
                                        deleteConfirmation = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if mode == .inactive {
                                    Button {
                                        // Edit Folder Actions
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                        .onMove { folders.items.move(fromOffsets: $0, toOffset: $1) }
                        
                        .onDelete { folders.items.remove(atOffsets: $0) }
                        
                    }
                    .headerProminence(.increased)
                }
                .listStyle(InsetGroupedListStyle())
                
            }
            .navigationBarTitle("Folders")
            .navigationViewStyle(.columns)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showingNewBookmarkView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Bookmark")
                        }
                        .font(.headline)
                    }
                    
                    Button("Add Folder") {
                        showingNewFolderView = true
                    }
                }
            }
            .environment(\.editMode, $mode)
            
            Text("No folder is selected")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingNewBookmarkView) {
            AddBookmarkView(bookmarks: bookmarks, folders: folders)
        }
        .sheet(isPresented: $showingNewFolderView) {
            AddFolderView(folders: folders)
        }
        .animation(.default, value: folders.items)
        
        
    }
    
    func bookmarkGramaticalNumberFor(_ folder: Folder) -> String {
        if bookmarksInside(folder).count > 1 {
            return "Bookmarks"
        } else {
            return "Bookmark"
        }
    }
    
    func bookmarksInside(_ folder: Folder) -> [Bookmark] {
        return bookmarks.items.filter({$0.folder == folder})
    }
    
    func nothing(atOffsets: IndexSet) -> Void {
        
    }
}


struct FolderItemView: View {
    @ObservedObject var bookmarks: Bookmarks
    @ObservedObject var folders: Folders
    var folder: Folder
    
    @Binding var deleteConfirmation: Bool
    
    var body: some View {
        HStack {
            Image(systemName: folder.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(10)
                .foregroundColor(.white)
                .background(FolderColorOptions.values[folder.accentColor])
                .clipShape(Circle())
                .padding([.top, .bottom, .trailing], 4)
            
            Text(folder.title)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(bookmarks.items.filter({$0.folder == folder}).count)")
                .foregroundColor(.secondary)
        }
        
        .contextMenu {
            Button {
                // Code to Edit Bookmark
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                
                if bookmarks.items.filter({$0.folder == folder}).count == 0 {
                    folders.items.remove(at: folders.items.firstIndex(where: {$0.id == folder.id})!)
                } else {
                    deleteConfirmation = true
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

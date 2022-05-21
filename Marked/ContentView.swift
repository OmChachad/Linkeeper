//
//  ContentView.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bookmarks = Bookmarks()
    @ObservedObject var folders = Folders()
    
    @State private var showingNewBookmarkView = false
    
    @State private var showingNewFolderView = false
    
    @State var mode: EditMode = .inactive
    
    
    @State private var deleteConfirmation = false
    @State private var toBeDeletedFolder: Folder?
    
    var body: some View {
        NavigationView {
            Group {
                List {
                    NavigationLink {
                        BookmarksView(bookmarks: self.bookmarks, folders: folders)
                    } label: {
                        HStack {
                            Image(systemName: "tray.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color(UIColor.darkGray))
                                .clipShape(Circle())
                            Text("All")
                                .bold()
                            Spacer()
                            Text("\(bookmarks.items.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 70)
                    
                    Section(header: Text("My Folders")) {
                        ForEach($folders.items, id: \.self) { folder in
                            NavigationLink {
                                BookmarksView(folder: folder.wrappedValue, bookmarks: self.bookmarks, folders: folders)
                            } label: {
                                FolderItemView(folder: folder.wrappedValue)
                                    .transition(.opacity)
                                    .contextMenu {
                                        Button {
                                            // Code to Edit Bookmark 
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            if bookmarks.items.filter({$0.folder == folder.wrappedValue}).count == 0 {
                                            folders.items.remove(at: folders.items.firstIndex(where: {$0.id == folder.id})!)
                                            } else {
                                                toBeDeletedFolder = folder.wrappedValue
                                                deleteConfirmation = true
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if bookmarks.items.filter({$0.folder == folder.wrappedValue}).count == 0 {
                                    folders.items.remove(at: folders.items.firstIndex(where: {$0.id == folder.id})!)
                                    } else {
                                        toBeDeletedFolder = folder.wrappedValue
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
                        .onDelete { folders.items.remove(atOffsets: $0) }
                        .onMove { folders.items.move(fromOffsets: $0, toOffset: $1) }
                        
                    }
                    .headerProminence(.increased)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Bookmarks")
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
                    HStack {
                        Button {
                        showingNewBookmarkView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Bookmark")
                        }
                        .font(.headline)
                    }
                        Spacer()
                    
                    Button("Add Folder") {
                        showingNewFolderView = true
                    }
                    }
                    .padding(.bottom)
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
        .confirmationDialog("Do you want to delete \(bookmarksInsideFolder.count) \(bookmarksInsideFolder.count == 1 ? "bookmark" : "bookmarks") inside \(toBeDeletedFolder != nil ? toBeDeletedFolder!.title : "") too?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Delete \(bookmarksInsideFolder.count) \(bookmarksInsideFolder.count == 1 ? "Bookmark" : "Bookmarks")", role: .destructive) {
                bookmarks.items.removeAll(where: { $0.folder == toBeDeletedFolder })
                folders.items.remove(at: folders.items.firstIndex(of: toBeDeletedFolder!)!)
            }
            
            Button("Keep \(bookmarksInsideFolder.count) \(bookmarksInsideFolder.count == 1 ? "Bookmark" : "Bookmarks")") {
                for bookmark in bookmarksInsideFolder {
                    var updatedBookmark = bookmarks.items.first(where: {$0.id == bookmark.id})
                    updatedBookmark?.folder = nil
                    
                    if let index = bookmarks.items.firstIndex(of: bookmark) {
                        bookmarks.items.remove(at: index)
                        bookmarks.items.insert(updatedBookmark!, at: index)
                    }
                }
                folders.items.remove(at: folders.items.firstIndex(of: toBeDeletedFolder!)!)
                
                
            }
        } message: {
            Text("\(bookmarksInsideFolder.count) \(bookmarksInsideFolder.count == 1 ? "bookmark" : "bookmarks") will be deleted.")
        }

    }
    
    var bookmarksInsideFolder: [Bookmark] {
        return bookmarks.items.filter({$0.folder == toBeDeletedFolder})
    }
}


struct FolderItemView: View {
    @ObservedObject var bookmarks = Bookmarks()
    
    var folder: Folder
    
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
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

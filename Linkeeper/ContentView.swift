//
//  ContentView.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true")) var favoriteBookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var allBookmarks: FetchedResults<Bookmark>
    
    @State private var showingAll = false
    @State private var showingNewBookmarkView = false
    @State private var showingNewFolderView = false
    @State private var showingSettings = false
    
    @State var mode: EditMode = .inactive
    
    @State private var currentFolder: Folder?
    
    var body: some View {
        NavigationView  {
            Group {
                List {
                    Group {
                        NavigationLink(destination: BookmarksView(), isActive: $showingAll) {
                            ListItem(markdown: "**All**", systemName: "tray.fill", color: Color(UIColor.darkGray), subItemsCount: allBookmarks.count)
                        }
                        NavigationLink(destination: BookmarksView(onlyFavorites: true)) {
                            ListItem(markdown: "**Favorites**", systemName: "heart.fill", color: .pink, subItemsCount: favoriteBookmarks.count)
                        }
                    }
                    .frame(height: 60)
                    .materialRowBackgroundForMac()
                    
                    
                    Section(header: Text("My Folders")) {
                        ForEach(folders) { folder in
                            NavigationLink(tag: folder, selection: $currentFolder) {
                                BookmarksView(folder: folder)
                            } label: {
                                FolderItemView(folder: folder)
                            }
                        }
                        .onMove(perform: moveItem)
                        .onDelete(perform: delete)
                    }
                    .headerProminence(.increased)
                }
                .sideBarForMac()
            }
            .navigationBarTitle("Folders")
            .navigationViewStyle(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    .buttonStyle(.borderless)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                        .buttonStyle(.borderless)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                        Button {
                            showingNewBookmarkView = true
                        } label: {
                            Label("New Bookmark", systemImage: "plus.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.headline)
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        
                        Spacer()
                        
                        Button("Add Folder") {
                            showingNewFolderView = true
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .environment(\.editMode, $mode)
            
            Text("No folder is selected.")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingSettings, content: Settings.init)
        .sheet(isPresented: $showingNewBookmarkView) {
            AddBookmarkView(folderPreset: currentFolder)
        }
        .sheet(isPresented: $showingNewFolderView, content: AddFolderView.init)
        .onAppear {
            // Makes "All Bookmarks" the default view, when Linkeeper is opened on macOS.
            #if targetEnvironment(macCatalyst)
                showingAll = true
            #endif
        }
    }
    
    func bookmarksCount(excludeFavourites: Bool) -> Int {
        if excludeFavourites {
            if let count = try? moc.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")) {
                return count
            }
        } else {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
            fetchRequest.predicate = NSPredicate(format: "isFavorited == true")
            if let count = try? moc.count(for: fetchRequest) {
                return count
            }
        }
        
        return 0
    }
    
    func delete(at offset: IndexSet) {
        offset.map { folders[$0] }.forEach(moc.delete)

        try? moc.save()
    }
    
    private func moveItem(at sets:IndexSet,destination:Int) {
        // Source: https://github.com/recoding-io/swiftui-videos/blob/main/Core_Data_Order_List/Shared/ContentView.swift
        let itemToMove = sets.first!
        
        if itemToMove < destination{
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = folders[itemToMove].index
            while startIndex <= endIndex{
                folders[startIndex].index = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            folders[itemToMove].index = startOrder
        }
        else if destination < itemToMove{
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = folders[destination].index + 1
            let newOrder = folders[destination].index
            while startIndex <= endIndex{
                folders[startIndex].index = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            folders[itemToMove].index = newOrder
        }
        
        do{
            try moc.save()
        }
        catch{
            print(error.localizedDescription)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

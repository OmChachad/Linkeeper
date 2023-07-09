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
    
    // CoreData FetchRequests
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true")) var favoriteBookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var allBookmarks: FetchedResults<Bookmark>
    
    // NavigationLink States
    @State private var showingAll = false
    @State private var showingFavorites = false
    @State private var showingPinnedFolder: [Bool] = []
    
    // Toolbar Button Variables
    @State private var showingSettings = false
    @State var mode: EditMode = .inactive
    @State private var showingNewBookmarkView = false
    @State private var showingNewFolderView = false
    
    @State private var currentFolder: Folder?
    
    var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
    
    var spacing: CGFloat { isMacCatalyst ? 10 : 15 }
    
    var body: some View {
        NavigationView  {
            VStack(spacing: 0) {
                VStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2), spacing: spacing) {
                        PinnedItemView(destination: BookmarksView(), title: "All", symbolName: "tray.fill", tint: Color(UIColor.darkGray), count: allBookmarks.count)
                            .buttonStyle(.plain)
                        
                        
                        PinnedItemView(destination: BookmarksView(onlyFavorites: true), title: "Favorites", symbolName: "heart.fill", tint: .pink, count:   favoriteBookmarks.count)
                            .buttonStyle(.plain)
                        
                        ForEach(pinnedFolders) { folder in
                            PinnedItemView(destination: BookmarksView(folder: folder), title: folder.wrappedTitle, symbolName: folder.wrappedSymbol, tint: folder.wrappedColor, count: folder.bookmarksArray.count)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(isMacCatalyst ? 12.5 : 20)
                }
                .background(isMacCatalyst ? .clear : Color(uiColor: .systemGroupedBackground))
                
                List {
                    Section(header: Text("My Folders")) {
                        ForEach(folders.filter { !$0.isPinned } ) { folder in
                            NavigationLink(tag: folder, selection: $currentFolder) {
                                BookmarksView(folder: folder)
                            } label: {
                                FolderItemView(folder: folder)
                            }
                            .dropDestination { bookmark, url in
                                if let bookmark {
                                    bookmark.folder = folder
                                    try? moc.save()
                                } else {
                                    BookmarksManager.shared.addDroppedURL(url, to: folder)
                                }
                            }
                        }
                        .onMove(perform: moveItem)
                        .onDelete(perform: delete)
                    }
                    .headerProminence(.increased)
                }
            }
            .sideBarForMac()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    .borderlessMacCatalystButton()
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                        .borderlessMacCatalystButton()
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
                        .keyboardShortcut("n", modifiers: [.shift, .command])
                    }
                    .borderlessMacCatalystButton()
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
        .animation(.default, value: pinnedFolders)
        .onAppear {
            // Makes "All Bookmarks" the default view, when Linkeeper is opened on macOS.
            #if targetEnvironment(macCatalyst)
                showingAll = true
            #endif
        }
    }
    
    var pinnedFolders: [Folder] {
        folders.filter { $0.isPinned }
    }
    
    private func delete(at offset: IndexSet) {
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

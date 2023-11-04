//
//  ContentView.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI
import CoreData
import SimpleToast

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    
    // CoreData FetchRequests
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true")) var favoriteBookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var allBookmarks: FetchedResults<Bookmark>
    
    // Toolbar Button Variables
    @State private var showingSettings = false
    @State var mode: EditMode = .inactive
    @State private var showingNewBookmarkView = false
    @State private var showingNewFolderView = false
    
    @State private var addedBookmark = false
    @State private var addedFolder = false
    private let toastOptions = SimpleToastOptions(alignment: .bottom, hideAfter: 1.5, backdrop: .clear, animation: .spring(), modifierType: .slide, dismissOnTap: true)
    
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
                        PinnedItemView(destination: BookmarksView(), title: "All", symbolName: "tray.fill", tint: Color("AllBookmarksColor"), count: allBookmarks.count, isActiveByDefault: isMacCatalyst)
                            .buttonStyle(.plain)
                            .dropDestination { bookmark, url in
                                if let bookmark {
                                    bookmark.folder = nil
                                    try? moc.save()
                                } else {
                                    BookmarksManager.shared.addDroppedURL(url)
                                }
                            }
                        
                        
                        PinnedItemView(destination: BookmarksView(onlyFavorites: true), title: "Favorites", symbolName: "heart.fill", tint: .pink, count:   favoriteBookmarks.count)
                            .buttonStyle(.plain)
                            .dropDestination { bookmark, url in
                                if let bookmark {
                                    bookmark.isFavorited = true
                                } else {
                                    let bookmark = BookmarksManager.shared.addDroppedURL(url)
                                    bookmark?.isFavorited = true
                                }
                                try? moc.save()
                            }
                        
                        ForEach(pinnedFolders) { folder in
                            PinnedItemView(destination: BookmarksView(folder: folder), title: folder.wrappedTitle, symbolName: folder.wrappedSymbol, tint: folder.wrappedColor, count: folder.bookmarksArray.count)
                                .contextMenu {
                                    Button {
                                        folder.isPinned.toggle()
                                        folder.index = (folders.last?.index ?? 0) + 1
                                        try? moc.save()
                                    } label: {
                                        Label("Unpin", systemImage: "pin.slash")
                                    }
                                }
                                .dropDestination { bookmark, url in
                                    addDroppedBookmarkToFolder(bookmark: bookmark, url: url, folder: folder)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(isMacCatalyst ? 12.5 : UIDevice.current.userInterfaceIdiom == .pad ? 15 : 20)
                }
                .background(isMacCatalyst ? .clear : Color(uiColor: .systemGroupedBackground))
                
                if !folders.filter({!$0.isPinned }).isEmpty {
                    List {
                        Section(header: Text("My Folders")) {
                            ForEach(folders.filter { !$0.isPinned } ) { folder in
                                NavigationLink(tag: folder, selection: $currentFolder) {
                                    BookmarksView(folder: folder)
                                } label: {
                                    FolderItemView(folder: folder)
                                }
                                .dropDestination { bookmark, url in
                                    addDroppedBookmarkToFolder(bookmark: bookmark, url: url, folder: folder)
                                }
                            }
                            .onMove(perform: moveItem)
                            .onDelete(perform: delete)
                        }
                        .headerProminence(.increased)
                    }
                } else {
                    Group {
                        if folders.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 50))
                                Text("""
You don't have any folders.
Click **Add Folder** to get started.
""")
                                .multilineTextAlignment(.center)
                            }
                        } else {
                            VStack {}
                        }
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(isMacCatalyst ? .clear : Color(uiColor: .systemGroupedBackground))
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
                    #if targetEnvironment(macCatalyst)
                        Button(mode == .active ? "Done" : "Edit") {
                            withAnimation {
                                if mode == .active {
                                    mode = .inactive
                                } else {
                                    mode = .active
                                }
                            }
                        }
                        .borderlessMacCatalystButton()
                    #else
                        EditButton()
                            .borderlessMacCatalystButton()
                    #endif
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
            AddBookmarkView(folderPreset: currentFolder, onComplete: { didAddBookmark in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    addedBookmark = didAddBookmark
                }
            })
        }
        .sheet(isPresented: $showingNewFolderView) {
            AddFolderView { didAddFolder in
                addedFolder = didAddFolder
            }
        }
        .animation(.default, value: pinnedFolders)
        .animation(.default, value: folders.count)
        .onChange(of: mode, perform: { _ in
            reOrderIndexes()
        })
        .onChange(of: pinnedFolders, perform: { _ in
            reOrderIndexes()
        })
        .simpleToast(isPresented: $addedBookmark, options: toastOptions, content: {
            AlertView(icon: "bookmark.fill", title: "Added Bookmark")
                .padding(.bottom, 50)
        })
        .simpleToast(isPresented: $addedFolder, options: toastOptions, content: {
            AlertView(icon: "folder.fill", title: "Added Folder")
                .padding(.bottom, 50)
        })
    }
    
    var pinnedFolders: [Folder] {
        folders.filter { $0.isPinned }
    }
    
    private func delete(at offset: IndexSet) {
        offset.map { folders[$0] }.forEach(moc.delete)
        try? moc.save()
    }
    
    func addDroppedBookmarkToFolder(bookmark: Bookmark?, url: URL, folder: Folder) {
        if let bookmark {
            bookmark.folder = folder
            try? moc.save()
        } else {
            BookmarksManager.shared.addDroppedURL(url, to: folder)
        }
    }
    
    private func moveItem(at sets:IndexSet,destination:Int) {
        // Source: https://github.com/recoding-io/swiftui-videos/blob/main/Core_Data_Order_List/Shared/ContentView.swift
        
        let itemToMove = sets.first!
        let destination = destination

        if itemToMove < destination{
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = folders.filter({!$0.isPinned})[itemToMove].index
            while startIndex <= endIndex{
                folders.filter({!$0.isPinned})[startIndex].index = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            folders.filter({!$0.isPinned})[itemToMove].index = startOrder
        } else if destination < itemToMove{
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = folders.filter({!$0.isPinned})[destination].index + 1
            let newOrder = folders.filter({!$0.isPinned})[destination].index
            while startIndex <= endIndex{
                folders.filter({!$0.isPinned})[startIndex].index = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            folders.filter({!$0.isPinned})[itemToMove].index = newOrder
        }
        
        try? moc.save()
    }
    
    private func reOrderIndexes() {
        let pinnedFolders = pinnedFolders.sorted { $0.index < $1.index }
        pinnedFolders.enumerated().forEach { (index, folder) in
            folder.index = Int16(index)
        }
        
        let folders = folders.filter { !$0.isPinned }.sorted { $0.index < $1.index }
        folders.enumerated().forEach { (index, folder) in
            folder.index = Int16(index)
        }
        try? moc.save()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

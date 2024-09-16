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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.openURL) var openURL
    
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
    
    @State private var showingAllBookmarks = false
    @State private var showingFavorites = false
    @State private var showingPinnedFolder = false
    @State private var currentFolder: Folder?
    
    var spacing: CGFloat { (isMac || isVisionOS) ? 10 : 15 }
    
    var inSideBarMode: Bool {
        #if os(macOS)
            return true
        #else
            return horizontalSizeClass == .regular
        #endif
    }
    
    var body: some View {
        Group {
                #if os(macOS)
                if #available(macOS 13.0, *) {
                    NavigationSplitView {
                        sideBar
                            .frame(minWidth: 300, idealWidth: 350)
                    } detail: {
                        Text("No folder is selected.")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                } else {
                    NavigationView  {
                        sideBar
                        
                        Text("No folder is selected.")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                #else
                NavigationView  {
                    sideBar
                        .navigationBarTitleDisplayMode(.inline)
                    
                    Text("No folder is selected.")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                #if os(iOS)
                .stackModeOniPhone()
                #endif
                #endif
        }
        .sheet(isPresented: $showingSettings, content: SettingsView.init)
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
        .onChange(of: allBookmarks.count) { _ in
            if #available(iOS 16.0, macOS 13.0, *) {
                LinkeeperShortcuts.updateAppShortcutParameters()
            }
            reloadAllWidgets()
        }
        .onChange(of: folders.count) { _ in
            if #available(iOS 16.0, macOS 13.0, *) {
                LinkeeperShortcuts.updateAppShortcutParameters()
            }
            reloadAllWidgets()
        }
        .simpleToast(isPresented: $addedBookmark, options: toastOptions, content: {
            AlertView(icon: "bookmark.fill", title: "Added Bookmark")
                .padding(.bottom, 50)
        })
        .simpleToast(isPresented: $addedFolder, options: toastOptions, content: {
            AlertView(icon: "folder.fill", title: "Added Folder")
                .padding(.bottom, 50)
        })
        .onOpenURL { url in
            
            if url.absoluteString.contains("openURL") {
                if let bookmarkID = UUID(uuidString: url.lastPathComponent) {
                    let bookmark = BookmarksManager.shared.findBookmark(withId: bookmarkID)
                    openURL(bookmark.wrappedURL)
                }
            } else if url.absoluteString.contains("openFolder") {
                if let folderID = UUID(uuidString: url.lastPathComponent) {
                    let folder = FoldersManager.shared.findFolder(withId: folderID)
                    currentFolder = folder
                }
            }
            
            reloadAllWidgets()
        }
    }
    
    var sideBar: some View {
        Group {
            VStack(spacing: 0) {
                    VStack {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2), spacing: spacing) {
                            PinnedItemView(destination: BookmarksView(), title: "All", symbolName: "tray.fill", tint: Color("AllBookmarksColor"), count: allBookmarks.count, isActiveByDefault: inSideBarMode, isActiveStatus: $showingAllBookmarks) { bookmark, url in
                                withAnimation {
                                    if let bookmark {
                                        bookmark.folder = nil
                                        try? moc.save()
                                    } else {
                                        BookmarksManager.shared.addDroppedURL(url)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            
                            PinnedItemView(destination: BookmarksView(onlyFavorites: true), title: "Favorites", symbolName: "heart.fill", tint: .pink, count:   favoriteBookmarks.count, isActiveStatus: $showingFavorites) { bookmark, url in
                                withAnimation {
                                    if let bookmark {
                                        bookmark.isFavorited = true
                                    } else {
                                        let bookmark = BookmarksManager.shared.addDroppedURL(url)
                                        bookmark?.isFavorited = true
                                    }
                                    try? moc.save()
                                }
                            }
                            .buttonStyle(.plain)
                            
                            ForEach(pinnedFolders) { folder in
                                PinnedItemView(destination: BookmarksView(folder: folder), title: folder.wrappedTitle, symbolName: folder.wrappedSymbol, tint: folder.wrappedColor, count: folder.countOfBookmarks, isActiveStatus: $showingPinnedFolder) { bookmark, url in
                                    withAnimation {
                                        addDroppedBookmarkToFolder(bookmark: bookmark, url: url, folder: folder)
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        folder.isPinned.toggle()
                                        folder.index = (folders.last?.index ?? 0) + 1
                                        try? moc.save()
                                    } label: {
                                        Label("Unpin", systemImage: "pin.slash")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        #if os(macOS)
                        .padding(12.5)
                        #else
                        .padding(UIDevice.current.userInterfaceIdiom == .pad ? 15 : 20)
                        #endif
                    }
                    #if os(macOS)
                    .background(.clear)
                    #else
                    .background(Color(uiColor: .systemGroupedBackground))
                    #endif
                
                
                if !folders.filter({!$0.isPinned }).isEmpty {
                    List {
                        if #available(macOS 13.0, *) {
                            
                        } else {
                            Section {
                                NavigationLink(destination: BookmarksView.init) {
                                    ListItem(title: "All", systemName: "tray.fill", color: Color("AllBookmarksColor"), subItemsCount: allBookmarks.count)
                                }
                                
                                NavigationLink(destination: BookmarksView.init(onlyFavorites: true)) {
                                    ListItem(title: "Favorites", systemName: "heart.fill", color: .pink, subItemsCount: favoriteBookmarks.count)
                                }
                                
                                ForEach(folders.filter { $0.isPinned } ) { folder in
                                    NavigationLink(tag: folder, selection: $currentFolder) {
                                        BookmarksView(folder: folder)
                                    } label: {
                                        FolderItemView(folder: folder)
                                    }
                                    .contextMenu {
                                        Button {
                                            folder.isPinned.toggle()
                                            folder.index = (folders.last?.index ?? 0) + 1
                                            try? moc.save()
                                        } label: {
                                            Label("Unpin", systemImage: "pin.slash")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("My Folders")) {
                            ForEach(folders.filter { !$0.isPinned } ) { folder in
                                Group {
                                    #if os(macOS)
                                    NavigationLink {
                                        BookmarksView(folder: folder)
                                    } label: {
                                        FolderItemView(folder: folder)
                                    }
                                    #else
                                    NavigationLink(tag: folder, selection: $currentFolder) {
                                        BookmarksView(folder: folder)
                                    } label: {
                                        FolderItemView(folder: folder)
                                    }
                                    #endif
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
#if os(macOS)
                    .background(.clear)
#else
                    .background(Color(uiColor: .systemGroupedBackground))
#endif
                }
            }
            //.sideBarForMac()
#if os(macOS)
            .safeAreaInset(edge: .bottom, content: {
                HStack {
                    Spacer()
                    
                    Button("Add Folder") {
                        showingNewFolderView = true
                    }
                    .keyboardShortcut("n", modifiers: [.shift, .command])
                }
                .padding([.horizontal, .bottom])
                .padding(.top, 5)
                .buttonStyle(.borderless)
            })
#endif
            .toolbar {
#if !os(macOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
#if os(visionOS)
                        Button {
                            showingNewBookmarkView = true
                        } label: {
                            Label("Bookmark", systemImage: "plus.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.headline)
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button {
                            showingNewFolderView = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .keyboardShortcut("n", modifiers: [.shift, .command])
                        .buttonStyle(.bordered)
                        
#else
                        if !inSideBarMode || showingFavorites {
                            Button {
                                showingNewBookmarkView = true
                            } label: {
                                Label("New Bookmark", systemImage: "plus.circle.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(.headline)
                            }
                            .keyboardShortcut("n", modifiers: .command)
                        }
                        
                        Spacer()
                        
                        Button("Add Folder") {
                            showingNewFolderView = true
                        }
                        .keyboardShortcut("n", modifiers: [.shift, .command])
#endif
                    }
                }
#endif
            }
        }
        #if os(macOS)
        .environment(\.editMode, mode)
        #else
        .environment(\.editMode, $mode)
        #endif
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

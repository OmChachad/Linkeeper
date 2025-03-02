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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)], predicate: NSPredicate(format: "parentFolder == nil")) var folders: FetchedResults<Folder>
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
                    
                .background(Color(uiColor: .systemGroupedBackground))
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
        .onReceive(NotificationCenter.default.publisher(for: .addBookmark)) { _ in
            showingNewBookmarkView = true
        }
        .onOpenURL { url in
            if url.absoluteString.contains("addBookmark") {
                showingNewBookmarkView = true
            } else if url.absoluteString.contains("openURL") {
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
    
    @State private var sideBarListHeight: CGFloat = 0.0
    
    var sideBar: some View {
        GeometryReader { geo in
            ScrollView {
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
                                    Button("Unpin", systemImage: "pin.slash") {
                                        folder.isPinned.toggle()
                                        folder.index = (folders.last?.index ?? 0) + 1
                                        try? moc.save()
                                    }
                                    .labelStyle(.titleAndIcon)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        #if os(macOS)
                        .padding(12.5)
                        #else
                        .padding(UIDevice.current.userInterfaceIdiom == .pad ? 15 : 20)
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 0 : -20)
                        #endif
                    }
                    
                    
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
                                            Button("Unpin", systemImage: "pin.slash") {
                                                folder.isPinned.toggle()
                                                folder.index = (folders.last?.index ?? 0) + 1
                                                try? moc.save()
                                            }
                                            .labelStyle(.titleAndIcon)
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
                        .listStyle(.sidebar)
                        .frame(height: sideBarListHeight, alignment: .top)
                        .onChange(of: folders.count) { _ in updateListHeight() }
                        .onAppear(perform: updateListHeight)
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
                                .frame(height: 400, alignment: .center)
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
            }
            .forceHiddenScrollIndicators()
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
            #elseif os(iOS)
            .safeAreaInset(edge: .top) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    HStack {
                        Button {
                            showingSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .imageScale(.large)
                        }
                        .keyboardShortcut(",", modifiers: .command)
                        
                        Spacer()
                        
                        EditButton()
                    }
                    .padding()
                    .background {
                        VariableBlurView(maxBlurRadius: 20, direction: .blurredTopClearBottom, startOffset: 0)
                            .ignoresSafeArea()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, content: {
                HStack {
                    if !inSideBarMode || showingFavorites {
                        Button {
                            showingNewBookmarkView = true
                        } label: {
                            Label("New Bookmark", systemImage: "plus.circle.fill")
                                .imageScale(.large)
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
                }
                .padding([.top, .horizontal])
                .padding(.bottom, 10)
                .background {
                    VariableBlurView(maxBlurRadius: 20, direction: .blurredBottomClearTop, startOffset: 0)
                        .ignoresSafeArea()
                }
                #warning("Must be tested on home button iPhone.")
            })
            #endif
            .toolbar {
                #if !os(macOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Button {
                                showingSettings.toggle()
                            } label: {
                                Image(systemName: "gear")
                            }
                            .keyboardShortcut(",", modifiers: .command)
                        }
                    }
                
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            EditButton()
                        }
                    }
                #if !os(iOS)
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
    
    func updateListHeight() {
        #warning("Test on fresh install before shipping.")
        self.sideBarListHeight = CGFloat(Double(folders.filter({!$0.isPinned }).count) * (isMac ? 50.5 : 80) + (folders.filter({!$0.isPinned }).count > 4 ? 0 : 200))
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

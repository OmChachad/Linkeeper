//
//  ContentView.swift
//  Marked
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI
import CoreData

struct MainOption: Hashable {
    var id = UUID()
    var title: String
    var symbol: String
    var color: Color
    var onlyFavorites: Bool
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)], predicate: NSPredicate(format: "isFavorited == true")) var favoriteBookmarks: FetchedResults<Bookmark>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var allBookmarks: FetchedResults<Bookmark>
    
    @State private var showingNewBookmarkView = false
    @State private var showingNewFolderView = false
    @State private var showingSettings = false
    
    @State var mode: EditMode = .inactive
    
    
    @State private var currentFolder: Folder?
    @State private var showingAll = false
    
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

struct FolderItemView: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var bookmarksInFolder = bookmarksCountFetcher()
    var folder: Folder
    
    @State private var editingFolder = false
    
    @Environment(\.editMode) var editMode
    
    @State private var deleteConfirmation: Bool = false
    
    var body: some View {
        ListItem(title: folder.wrappedTitle, systemName: folder.wrappedSymbol, color: folder.wrappedColor, subItemsCount: bookmarksInFolder.count(context: moc, folder: folder))
        .contextMenu {
            Button {
                editingFolder = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                if folder.bookmarksArray.count == 0 {
                    withAnimation {
                        moc.delete(folder)
                        try? moc.save()
                    }
                } else {
                    deleteConfirmation = true
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Do you want to delete ^[\(folder.countOfBookmarks) Bookmarks](inflect: true) inside \(folder.wrappedTitle) too?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Delete ^[\(folder.countOfBookmarks) Bookmarks](inflect: true)", role: .destructive) {
                withAnimation {
                    for i in 0...(folder.bookmarksArray.count - 1) {
                        moc.delete(folder.bookmarksArray[i])
                    }
                    moc.delete(folder)
                    try? moc.save()
                }
            }
            
            Button("Keep ^[\(folder.countOfBookmarks) Bookmarks](inflect: true)") {
                withAnimation {
                    moc.delete(folder)
                    try? moc.save()
                }
            }
        } message: {
            Text("^[\(folder.countOfBookmarks) Bookmarks](inflect: true) will be deleted.")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if folder.bookmarksArray.count == 0 {
                    withAnimation {
                        moc.delete(folder)
                        try? moc.save()
                    }
                } else {
                    deleteConfirmation = true
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .trailing) {
            if editMode?.wrappedValue == .inactive {
                Button {
                    editingFolder = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $editingFolder) {
            AddFolderView(existingFolder: folder)
        }
    }
    
    class bookmarksCountFetcher: ObservableObject {
        func count(context: NSManagedObjectContext, folder: Folder) -> Int {
            let itemFetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
            itemFetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
            
            return try! context.count(for: itemFetchRequest)
        }
    }
}

struct ListItem: View {
    var title: AttributedString
    var systemName: String
    var color: Color
    var subItemsCount: Int
    
    init(title: String, systemName: String, color: Color, subItemsCount: Int) {
        self.title = AttributedString(title)
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
    }
    
    init(markdown: String, systemName: String, color: Color, subItemsCount: Int) {
        if let data = markdown.data(using: .utf8) {
            self.title = try! AttributedString(markdown: data)
        } else {
            self.title = AttributedString(markdown)
        }
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .lineLimit(1)
                    .padding(.leading, 5)
            } icon: {
                icon()
            }
            
            Spacer()
            
            Text(String(subItemsCount))
                .foregroundColor(.secondary)
                .frame(minWidth: 15, alignment: .center)
        }
    }
    
    func icon() -> some View {
        Group {
        #if targetEnvironment(macCatalyst)
            Image(systemName: systemName)
                .imageScale(.medium)
                .padding(5)
                .frame(width: 27.5, height: 27.5)
        #else
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(10)
        #endif
        }
        .foregroundColor(.white)
        .background(color, in: Circle())
        .padding(5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

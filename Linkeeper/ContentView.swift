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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    @State private var showingNewBookmarkView = false
    
    @State private var showingNewFolderView = false
    
    @State var mode: EditMode = .inactive
    
    @State private var selection = Set<MainOption>()
    
    @State private var deleteConfirmation = false
    
    @AppStorage("showingAll") var showingAll: Bool = true
    @AppStorage("showingFavorites") var showingFavorites: Bool = true
    
    @State private var mainOptions: [MainOption] = [
        MainOption(title: "All", symbol: "tray.fill", color: Color(UIColor.darkGray), onlyFavorites: false),
        MainOption(title: "Favorites", symbol: "heart.fill", color: Color.pink, onlyFavorites: true)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                List {
                    ForEach(mainOptions, id: \.self) { option in
                        NavigationLink {
                            BookmarksView(folder: nil, onlyFavorites: option.onlyFavorites)
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
                                
                                if let count = try? moc.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")) {
                                        Text(String(count))
                                            .foregroundColor(.secondary)
                                
                                }
                            }
                            .frame(height: 70)
                        }
                    }
                    
                    
                    Section(header: Text("My Folders")) {
                        ForEach(folders) { folder in
                            NavigationLink {
                                BookmarksView(folder: folder, onlyFavorites: false)
                            } label: {
                                FolderItemView(folder: folder, deleteConfirmation: $deleteConfirmation)
                                    .confirmationDialog("Do you want to delete \(pluralizedBookmark(folder)) inside \(folder.wrappedTitle) too?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                                        Button("Delete \(pluralizedBookmark(folder))", role: .destructive) {
                                            withAnimation {
                                                for i in 0...(folder.bookmarksArray.count - 1) {
                                                    moc.delete(folder.bookmarksArray[i])
                                                }
                                                moc.delete(folder)
                                                try? moc.save()
                                            }
                                        }
                                        
                                        Button("Keep \(pluralizedBookmark(folder))") {
                                            withAnimation {
                                                moc.delete(folder)
                                                try? moc.save()
                                            }
                                        }
                                    } message: {
                                        Text("\(pluralizedBookmark(folder)) will be deleted.")
                                    }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                        .onMove(perform: moveItem)
                        .onDelete(perform: delete)
                        
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
            AddBookmarkView()
        }
        .sheet(isPresented: $showingNewFolderView) {
            AddFolderView()
        }
        //.animation(.default, value: folders.count)
        
        
    }
    
    func delete(at offset: IndexSet) {
        offset.map { folders[$0] }.forEach(moc.delete)
        
        try? moc.save()
    }
    private func moveItem(at sets:IndexSet,destination:Int){
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
    
    func pluralizedBookmark(_ folder: Folder) -> String {
        if folder.bookmarksArray.count > 1 {
            return "Bookmarks"
        } else {
            return "Bookmark"
        }
    }
}


struct FolderItemView: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var bookmarksInFolder = bookmarksCountFetcher()
    var folder: Folder
    
    @Binding var deleteConfirmation: Bool
    
    var body: some View {
        HStack {
            Label {
                Text(folder.wrappedTitle)
                    .lineLimit(1)
            } icon: {
                Image(systemName: folder.wrappedSymbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(folder.wrappedColor)
                    .clipShape(Circle())
                    .padding([.top, .bottom, .trailing], 4)
            }
            
            Spacer()
            
            Text("\(bookmarksInFolder.count(context: moc, folder: folder))")
                        .foregroundColor(.secondary)

            
        }
        
        .contextMenu {
            Button {
                // Code to Edit Bookmark
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
    }
    
    class bookmarksCountFetcher: ObservableObject {
        func count(context: NSManagedObjectContext, folder: Folder) -> Int {
            let itemFetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
            itemFetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
            
            return try! context.count(for: itemFetchRequest)
        }
    }
    
    var getBookmarksCount: Int {
      var countOfItems: Int = 0
      let context = moc
      
      let itemFetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
      itemFetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
      
    countOfItems = try! context.count(for: itemFetchRequest)
        
      return countOfItems
   }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

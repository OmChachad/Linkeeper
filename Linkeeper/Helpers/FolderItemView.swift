//
//  FolderItemView.swift
//  Linkeeper
//
//  Created by Om Chachad on 04/06/23.
//

import SwiftUI
import CoreData

struct FolderItemView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var bookmarksInFolder = bookmarksCountFetcher()
    var folder: Folder
    
    @State private var editingFolder = false
    
    @Environment(\.editMode) var editMode
    
    @State private var deleteConfirmation: Bool = false
    
    var isEditing: Bool {
        #if os(macOS)
        return self._editMode.wrappedValue == .active
        #else
        return self.editMode?.wrappedValue == .active
        #endif
    }
    
    var body: some View {
        ListItem(title: folder.wrappedTitle, systemName: folder.wrappedSymbol, color: folder.wrappedColor, subItemsCount: bookmarksInFolder.count(context: moc, folder: folder))
        .contextMenu {
            Button {
                editingFolder = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                folder.isPinned.toggle()
                try? moc.save()
            } label: {
                Label("Pin", systemImage: "pin")
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
            #if os(macOS)
            if !isEditing {
                Button {
                    editingFolder = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
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
            #else
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
            
            if !isEditing {
                Button {
                    editingFolder = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            #endif
        }
        .swipeActions(edge: .leading) {
            if !isEditing {
                Button {
                    folder.isPinned.toggle()
                    try? moc.save()
                } label: {
                    Label("Pin", systemImage: "pin.fill")
                }
                .tint(.yellow)
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

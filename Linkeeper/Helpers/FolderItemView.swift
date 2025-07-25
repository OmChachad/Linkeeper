//
//  FolderItemView.swift
//  Linkeeper
//
//  Created by Om Chachad on 04/06/23.
//

import SwiftUI
import CoreData

struct FolderItemView: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var bookmarksInFolder = bookmarksCountFetcher()
    var folder: Folder
    var style: ListItem.Style = .sidebar
    
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
    
    var requiresAdditionalPadding: Bool {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        #endif
        
        return false
    }
    
    @State private var isTargeted = false
    
    var body: some View {
        ListItem(title: folder.wrappedTitle, systemName: folder.wrappedSymbol, color: folder.wrappedColor, subItemsCount: folder.countOfBookmarks, style: style)
            .folderActions(folder: folder, isEditing: isEditing)
            .dropDestination(isTargeted: $isTargeted) { bookmark, url in
                addDroppedBookmarkToFolder(bookmark: bookmark, url: url, folder: folder)
            }
            .opacity(isTargeted ? 0.1 : 1)
            .padding(.leading, requiresAdditionalPadding ? 5 : 0)
            .frame(height: 40)
    }

    func addDroppedBookmarkToFolder(bookmark: Bookmark?, url: URL, folder: Folder) {
        if let bookmark {
            bookmark.folder = folder
            try? moc.save()
        } else {
            BookmarksManager.shared.addDroppedURL(url, to: folder)
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

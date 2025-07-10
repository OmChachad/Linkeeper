//
//  FolderActionsModifier.swift
//  Linkeeper
//
//  Created by Om Chachad on 12/06/24.
//

import Foundation
import SwiftUI
import CoreData

struct FolderActionsModifier: ViewModifier {
    @Environment(\.managedObjectContext) var moc
    @State private var editingFolder: Bool = false
    @State private var movingFolder: Bool = false
    @State private var deleteConfirmation: Bool = false
    @ObservedObject var folder: Folder
    var isEditing: Bool

    func body(content: Content) -> some View {
        content
            .contextMenu {
                editButton()
                
                pinButton()
                
                moveButton()
                
                deleteButton()
            }
            .confirmationDialog("Do you want to delete \(inflectedBookmarksAndFoldersCount) too?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                Button("Delete \(inflectedBookmarksAndFoldersCount)", role: .destructive) {
                    delete(action: .delete)
                }
                
                Button("Keep \(inflectedBookmarksAndFoldersCount)") {
                    delete(action: .keep)
                }
            } message: {
                Text("\(inflectedBookmarksAndFoldersCount) inside this folder will be deleted from all your iCloud devices.")
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if #available(iOS 15.0, macOS 15.0, *) {
                    Button(action: confirmDeletion) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                    
                    if !isEditing {
                        editButton()
                    }
                } else {
                    if !isEditing {
                        editButton()
                    }
                    
                    Button(action: confirmDeletion) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .swipeActions(edge: .leading) {
                pinButton()
                    .tint(.yellow)
            }
            .sheet(isPresented: $editingFolder) {
                AddFolderView(existingFolder: folder)
                    .environment(\.managedObjectContext, DataController.shared.persistentCloudKitContainer.viewContext)
            }
            .sheet(isPresented: $movingFolder) {
                MoveFolderView(folder: folder) {}
                    .environment(\.managedObjectContext, DataController.shared.persistentCloudKitContainer.viewContext)
            }
    }
    
    var inflectedBookmarksAndFoldersCount: String {
        var result: AttributedString = AttributedString()
        
        if folder.countOfBookmarks > 0 {
            result.append(AttributedString(localized: "^[\(folder.countOfBookmarks) Bookmarks](inflect: true)"))
        }
        
        if folder.countOfChildFolders > 0 {
            if folder.countOfBookmarks > 0 {
                result.append(AttributedString(" and "))
            }
            result.append(AttributedString(localized: "^[\(folder.countOfChildFolders) sub-folders](inflect: true)"))
        }

        return NSAttributedString(result).string
    }

    
    func editButton() -> some View {
        Button("Edit", systemImage: "pencil", action: edit)
            .labelStyle(.titleAndIcon)
    }
    
    func edit() {
        editingFolder.toggle()
    }
    
    func moveButton() -> some View {
        Button("Move", systemImage: "plus.rectangle.on.folder") {
            movingFolder.toggle()
        }
        .labelStyle(.titleAndIcon)
    }
    
    func deleteButton() -> some View {
        Button("Delete", systemImage: "trash", role: .destructive, action: confirmDeletion)
        .labelStyle(.titleAndIcon)
    }
    
    func confirmDeletion() {
        if folder.bookmarksArray.isEmpty && folder.childFoldersArray == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    folder.parentFolder = nil
                    moc.delete(folder)
                    try? moc.save()
                }
            }
        } else {
            deleteConfirmation = true
        }
    }
    
    func delete(action: FoldersManager.DeletionAction) {
        withAnimation {
            FoldersManager.shared.delete(folder, action: action)
        }
    }
    
    func pinButton() -> some View {
        Group {
            if folder.parentFolder == nil {
                Button("Pin", systemImage: "pin") {
                    folder.isPinned.toggle()
                    try? moc.save()
                }
                .labelStyle(.titleAndIcon)
            }
        }
    }
}

extension View {
    func folderActions(folder: Folder, isEditing: Bool) -> some View {
        self.modifier(FolderActionsModifier(folder: folder, isEditing: isEditing))
    }
}

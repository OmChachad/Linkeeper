//
//  FoldersManager.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import CoreData

class FoldersManager {
    
    static let shared = FoldersManager()
    
    let context = DataController.shared.persistentCloudKitContainer.viewContext
    
    func getAllFolders() -> [Folder] {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        do {
            return try context.fetch(request).sorted(by: { $0.index < $1.index })
        } catch let error {
            print("Couldn't fetch all folders: \(error.localizedDescription)")
            return []
        }
    }
    
    func getFolders(with predicate: NSPredicate) -> [Folder] {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = predicate
        do {
            return try context.fetch(request).sorted(by: { $0.index < $1.index })
        } catch let error {
            print("Couldn't fetch all folders: \(error.localizedDescription)")
            return []
        }
    }

    func addFolder(title: String, accentColor: String, chosenSymbol: String, parentFolder: Folder? = nil) -> Folder {

        let newFolder = Folder(context: context)
        newFolder.id = UUID()
        newFolder.title = title
        newFolder.accentColor = accentColor
        newFolder.symbol = chosenSymbol
        newFolder.parentFolder = parentFolder
        if let parentFolder {
            newFolder.index = Int16((getFolders(with: NSPredicate(format: "parentFolder = %@", parentFolder)).last?.index ?? 0) + 1)
        } else {
            newFolder.index = Int16((getAllFolders().last?.index ?? 0) + 1)
        }

        saveContext()
        return newFolder
    }

    func findFolder(withId id: UUID) -> Folder {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        guard let foundFolder = try? context.fetch(request).first else {
            fatalError("Could not find bookmark with ID")
        }
        
        return foundFolder
    }
    
    func doesExist(withId id: UUID) -> Bool {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)
        
        guard (try? context.fetch(request).first) != nil else {
            return false
        }
        
        return true
    }
    
    enum DeletionAction {
        case keep
        case delete
    }
    
    func delete(_ folder: Folder, action: DeletionAction) {
        for bookmark in folder.bookmarksArray {
            switch(action) {
            case .keep:
                bookmark.folder = folder.parentFolder
            case .delete:
                context.delete(bookmark)
            }
        }
        
        for subFolder in folder.childFoldersArray ?? [] {
            switch(action) {
            case .keep:
                subFolder.parentFolder = folder.parentFolder
            case .delete:
                delete(subFolder, action: .delete)
            }
        }
        
        context.delete(folder)
        
        saveContext()
    }

    func delete(withId id: UUID, action: DeletionAction = .delete) {
        let matchingFolder = findFolder(withId: id)
        delete(matchingFolder, action: action)
    }

    func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
}


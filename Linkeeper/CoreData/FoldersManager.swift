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

    func addFolder(title: String, accentColor: String, chosenSymbol: String) -> Folder {

        let newFolder = Folder(context: context)
        newFolder.id = UUID()
        newFolder.title = title
        newFolder.accentColor = accentColor
        newFolder.symbol = chosenSymbol
        newFolder.index = Int16((getAllFolders().last?.index ?? 0) + 1)

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

    func deleteFolder(withId id: UUID) {
        let matchingBookmark = findFolder(withId: id)
        context.delete(matchingBookmark)
        saveContext()
    }

    func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
}


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

    func addFolder(title: String, accentColor: String, chosenSymbol: String) throws -> Folder {

        let newFolder = Folder(context: context)
        newFolder.id = UUID()
        newFolder.title = title
        newFolder.accentColor = accentColor
        newFolder.symbol = chosenSymbol
        newFolder.index = Int16((getAllFolders().last?.index ?? 0) + 1)

        saveContext()
        return newFolder
    }

    func findFolder(withId id: UUID) throws -> Folder {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        do {
            guard let foundFolder = try context.fetch(request).first else {
                fatalError("Could not fetch")
            }
            return foundFolder
        } catch {
            fatalError("Could not fetch")
        }
    }
//
//    // Mark a book as read or unread
//    func markBook(withId id: UUID, as status: BookStatus) throws {
//        do {
//            let matchingBook = try Self.shared.findBook(withId: id)
//            switch status {
//                case .read:
//                    matchingBook.isRead = true
//                case .unread:
//                    matchingBook.isRead = false
//            }
//            try saveContext()
//        } catch let error {
//            throw error
//        }
//    }
//
    func deleteFolder(withId id: UUID) throws {
        do {
            let matchingBookmark = try Self.shared.findFolder(withId: id)
            context.delete(matchingBookmark)
            saveContext()
        } catch let error {
            print("Couldn't delete folder with ID: \(id.uuidString): \(error.localizedDescription)")
        }
    }
//
    func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch let error {
            print("Couldn't save CoreData context: \(error.localizedDescription)")
        }
    }
    
}

//enum Error: Swift.Error, CustomLocalizedStringResourceConvertible {
//    case notFound,
//         coreDataSave,
//         unknownId(id: String),
//         unknownError(message: String),
//         deletionFailed,
//         addFailed(title: String)
//
//    var localizedStringResource: LocalizedStringResource {
//        switch self {
//            case .addFailed(let title): return "An error occurred trying to add '\(title)'"
//            case .deletionFailed: return "An error occured trying to delete the book"
//            case .unknownError(let message): return "An unknown error occurred: \(message)"
//            case .unknownId(let id): return "No books with an ID matching: \(id)"
//            case .notFound: return "Book not found"
//            case .coreDataSave: return "Couldn't save to CoreData"
//        }
//    }
//}


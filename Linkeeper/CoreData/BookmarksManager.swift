//
//  BookmarksManager.swift
//  Linkeeper
//
//  Created by Om Chachad on 28/05/23.
//

import Foundation
import CoreData
import LinkPresentation

class BookmarksManager {
    
    static let shared = BookmarksManager()
    
    let context = DataController.shared.persistentCloudKitContainer.viewContext
    
    func getAllBookmarks() -> [Bookmark] {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        do {
            return try context.fetch(request).sorted(by: { $0.wrappedDate > $1.wrappedDate })
        } catch let error {
            print("Couldn't fetch all bookmarks: \(error.localizedDescription)")
            return []
        }
    }

    func addBookmark(id: UUID?, title: String, url: String, host: String, notes: String, folder: Folder?) throws -> Bookmark {

        let sanitisedURL = URL(string: url)?.sanitise
        let bookmark = Bookmark(context: context)
        bookmark.id = id ?? UUID()
        bookmark.title = title
        bookmark.date = Date.now
        bookmark.host = host
        bookmark.notes = notes
        bookmark.url = sanitisedURL?.absoluteString
        bookmark.folder = folder

        try saveContext()
        return bookmark
    }

    func findBookmark(withId id: UUID) throws -> Bookmark {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        do {
            guard let foundBook = try context.fetch(request).first else {
                throw fatalError("Could not fetch")
            }
            return foundBook
        } catch {
            throw fatalError("Could not fetch")
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
    func deleteBookmark(withId id: UUID) throws {
        do {
            let matchingBookmark = try Self.shared.findBookmark(withId: id)
            context.delete(matchingBookmark)
            try saveContext()
        } catch let error {
            print("Couldn't delete bookmark with ID: \(id.uuidString): \(error.localizedDescription)")
            throw fatalError()
        }
    }
//
    func saveContext() throws {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch let error {
            print("Couldn't save CoreData context: \(error.localizedDescription)")
        }
    }
    
}

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
    
    func addDroppedURL(_ url: URL, to folder: Folder? = nil) -> Bookmark? {
        let bookmark = addBookmark(title: "Loading...", url: url.absoluteString, host: url.host ?? "Unknown Host", notes: "", folder: folder)
        
        Task {
            if let metadata = try await startFetchingMetadata(for: url, fetchSubresources: false, timeout: 10) {
                DispatchQueue.main.async {
                    if let URLTitle = metadata.title {
                        bookmark.title = URLTitle
                    } else {
                        bookmark.title = "Could not fetch title..."
                    }
                    self.saveContext()
                }
            }
            
            saveContext()
        }
        
        return bookmark
    }

    func addBookmark(id: UUID? = UUID(), title: String, url: String, host: String, notes: String, folder: Folder?) -> Bookmark {
        let urlString: String = {
            if UserDefaults.standard.bool(forKey: "removeTrackingParameters") == true && !url.contains("youtube.com/watch") {
                     return url.components(separatedBy: "?").first ?? url
            } else {
                return url
            }
        }()
        let bookmark = Bookmark(context: context)
        bookmark.id = id ?? UUID()
        bookmark.title = title
        bookmark.date = Date.now
        bookmark.host = host
        bookmark.notes = notes
        bookmark.url = urlString
        bookmark.folder = folder

        saveContext()
        return bookmark
    }

    func findBookmark(withId id: UUID) -> Bookmark {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        guard let foundBook = try? context.fetch(request).first else {
            fatalError("Could not find Bookmark with given ID")
        }
        return foundBook
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        context.delete(bookmark)
        
        let cacheManager = CacheManager.instance
        cacheManager.remove(for: bookmark)
        
        saveContext()
    }
    
    func deleteBookmark(withId id: UUID) {
        let matchingBookmark = findBookmark(withId: id)
        deleteBookmark(matchingBookmark)
    }

    func saveContext() {
        DispatchQueue.main.async {
            if self.context.hasChanges {
                try? self.context.save()
            }
        }
    }
    
}

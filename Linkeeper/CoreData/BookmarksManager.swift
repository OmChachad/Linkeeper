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
        let bookmark = makeBookmark(id: id, title: title, url: url, host: host, notes: notes, folder: folder)
        saveContext()
        return bookmark
    }

    /// Adds a bookmark and waits for its Core Data save to finish.
    ///
    /// App Intents use this path so they only report success after the bookmark
    /// is durably stored.
    @MainActor
    func addBookmarkAndSave(id: UUID? = UUID(), title: String, url: String, host: String, notes: String, folder: Folder?) throws -> Bookmark {
        let bookmark = makeBookmark(id: id, title: title, url: url, host: host, notes: notes, folder: folder)

        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.delete(bookmark)
            throw error
        }

        return bookmark
    }

    /// Replaces a generated fallback title when webpage metadata arrives.
    ///
    /// The equality check preserves a title the person may have edited while
    /// metadata was loading.
    @MainActor
    func enrichGeneratedTitle(for bookmarkID: UUID, from url: URL, replacing fallbackTitle: String) async -> Bool {
        guard let metadata = try? await startFetchingMetadata(
            for: url,
            fetchSubresources: false,
            timeout: 10
        ),
        let fetchedTitle = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines),
        !fetchedTitle.isEmpty,
        let bookmark = bookmark(withID: bookmarkID),
        bookmark.wrappedTitle == fallbackTitle else {
            return false
        }

        bookmark.title = fetchedTitle
        do {
            try saveContextImmediately()
            return true
        } catch {
            bookmark.title = fallbackTitle
            return false
        }
    }

    private func makeBookmark(id: UUID?, title: String, url: String, host: String, notes: String, folder: Folder?) -> Bookmark {
        let urlString: String = {
            if SharedUserDefaults.bool(forKey: "removeTrackingParameters") == true && !url.contains("youtube.com/watch") {
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
        return bookmark
    }

    func findBookmark(withId id: UUID) -> Bookmark {
        guard let foundBookmark = bookmark(withID: id) else {
            fatalError("Could not find Bookmark with given ID")
        }

        return foundBookmark
    }

    /// Returns the bookmark with the supplied stable identifier, if it still exists.
    func bookmark(withID id: UUID) -> Bookmark? {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        let bookmarkID = bookmark.id
        context.delete(bookmark)
        
        let cacheManager = CacheManager.instance
        cacheManager.remove(for: bookmark)
        
        saveContext()

        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *), let bookmarkID {
            Task {
                await LinkeeperIntentDonations.removeDonations(
                    for: LinkeeperBookmarkEntity.self,
                    identifier: bookmarkID
                )
            }
        }
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

    /// Saves pending changes immediately on the view context's actor.
    @MainActor
    func saveContextImmediately() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
}

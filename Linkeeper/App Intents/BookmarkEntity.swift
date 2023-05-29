//
//  BookmarkEntity.swift
//  Linkeeper
//
//  Created by Om Chachad on 28/05/23.
//

import Foundation
import AppIntents
import CoreData

@available(iOS 16.0, *)
struct BookmarkEntity: Identifiable, Hashable, Equatable, AppEntity {
  
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Bookmark")
    typealias DefaultQueryType = IntentsBookmarkQuery
    static var defaultQuery: IntentsBookmarkQuery = IntentsBookmarkQuery()
    
    var id: UUID
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "URL")
    var url: String
    
    @Property(title: "Host")
    var host: String
    
    @Property(title: "Notes")
    var notes: String
    
    //@Property(title: "Cover Image")
    //var coverImage: IntentFile?
    
    @Property(title: "Favorited")
    var isFavorited: Bool
    
    @Property(title: "Date Added")
    var dateAdded: Date
    
    init(id: UUID, title: String, url: String, host: String, notes: String, isFavorited: Bool, dateAdded: Date) {
        self.id = id
        self.title = title
        self.url = url
        self.host = host
        self.notes = notes
        self.isFavorited = isFavorited
        self.dateAdded = dateAdded
    }
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(url)",
            image: .init(systemName: "link")
        )
    }
}

@available(iOS 16.0, *)
extension BookmarkEntity {
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equtable conformance
    static func ==(lhs: BookmarkEntity, rhs: BookmarkEntity) -> Bool {
        return lhs.id == rhs.id
    }
    
}

@available(iOS 16.0, *)
struct IntentsBookmarkQuery: EntityPropertyQuery {

    // Find Bookmarks by ID
    // For example a user may have chosen a Bookmark from a list when tapping on a parameter that accepts Bookmarks. The ID of that Bookmark is now hardcoded into the Shortcut. When the shortcut is run, the ID will be matched against the database in Bookmark
    func entities(for identifiers: [UUID]) async throws -> [BookmarkEntity] {
        return identifiers.compactMap { identifier in
                if let match = try? BookmarksManager.shared.findBookmark(withId: identifier) {
                    return BookmarkEntity(id: match.id!, title: match.wrappedTitle, url: match.wrappedURL.absoluteString, host: match.wrappedHost, notes: match.wrappedNotes, isFavorited: match.isFavorited, dateAdded: match.wrappedDate)
                } else {
                    return nil
                }
        }
    }
    
    // Returns all Bookmarks in the Linkeeper database. This is what populates the list when you tap on a parameter that accepts a Bookmark
    func suggestedEntities() async throws -> [BookmarkEntity] {
        let allBookmarks = BookmarksManager.shared.getAllBookmarks()
        return allBookmarks.map {
            #warning("Make ID non optional in Core Data later")
            return BookmarkEntity(id: $0.id!, title: $0.wrappedTitle, url: $0.wrappedURL.absoluteString, host: $0.wrappedHost, notes: $0.wrappedNotes, isFavorited: $0.isFavorited, dateAdded: $0.wrappedDate)
        }
    }
    
    // Find Bookmarks matching the given query.
    func entities(matching query: String) async throws -> [BookmarkEntity] {
        
        // Allows the user to filter the list of Bookmarks by title or author when tapping on a param that accepts a 'Bookmark'
        let allBookmarks = BookmarksManager.shared.getAllBookmarks()
        let matchingBookmarks = allBookmarks.filter {
            return $0.doesMatch(query)
        }

        return matchingBookmarks.map {
            BookmarkEntity(id: $0.id!, title: $0.wrappedTitle, url: $0.wrappedURL.absoluteString, host: $0.wrappedHost, notes: $0.wrappedNotes, isFavorited: $0.isFavorited, dateAdded: $0.wrappedDate)
        }
    }
         
    static var properties = EntityQueryProperties<BookmarkEntity, NSPredicate> {
        Property(\BookmarkEntity.$title) {
            EqualToComparator { NSPredicate(format: "title = %@", $0) }
            ContainsComparator { NSPredicate(format: "title CONTAINS %@", $0) }

        }
        Property(\BookmarkEntity.$host) {
            EqualToComparator { NSPredicate(format: "host = %@", $0) }
            ContainsComparator { NSPredicate(format: "host CONTAINS %@", $0) }
        }
        Property(\BookmarkEntity.$isFavorited) {
            EqualToComparator { NSPredicate(format: "isFavorited = %@", $0) }
        }
        Property(\BookmarkEntity.$dateAdded) {
            LessThanComparator { NSPredicate(format: "date < %@", $0 as NSDate) }
            GreaterThanComparator { NSPredicate(format: "date > %@", $0 as NSDate) }
        }
    }
    
    static var sortingOptions = SortingOptions {
        SortableBy(\BookmarkEntity.$title)
        SortableBy(\BookmarkEntity.$host)
        SortableBy(\BookmarkEntity.$isFavorited)
        SortableBy(\BookmarkEntity.$dateAdded)
    }
    
    func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [Sort<BookmarkEntity>],
        limit: Int?
    ) async throws -> [BookmarkEntity] {
        print("Fetching Bookmarks")
        let context = DataController.shared.persistentCloudKitContainer.viewContext
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        let predicate = NSCompoundPredicate(type: mode == .and ? .and : .or, subpredicates: comparators)
        request.fetchLimit = limit ?? 5
        request.predicate = predicate
//        request.sortDescriptors = sortedBy.map({
//            NSSortDescriptor(key: $0.by, ascending: $0.order == .ascending)
//        })
        let matchingBookmarks = try context.fetch(request)
        return matchingBookmarks.map {
            BookmarkEntity(id: $0.id!, title: $0.wrappedTitle, url: $0.wrappedURL.absoluteString, host: $0.wrappedHost, notes: $0.wrappedNotes, isFavorited: $0.isFavorited, dateAdded: $0.wrappedDate)
        }
    }
}


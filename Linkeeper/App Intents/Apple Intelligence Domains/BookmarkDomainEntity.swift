//
//  BookmarkDomainEntity.swift
//  Linkeeper
//
//  Created by Om Chachad on 1/23/25.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, iOSApplicationExtension 18.0, *)
@AssistantEntity(schema: .browser.bookmark)
struct BookmarkEntity {
    struct BookmarkEntityQuery: EntityStringQuery {
        func entities(for identifiers: [BookmarkEntity.ID]) async throws -> [BookmarkEntity] {
            return identifiers.compactMap { identifier in
                let match = BookmarksManager.shared.findBookmark(withId: identifier)
                return BookmarkEntity(bookmark: match)
            }
        }
        
        func suggestedEntities() async throws -> [BookmarkEntity] {
            let allBookmarks = BookmarksManager.shared.getAllBookmarks()
            return allBookmarks.map { BookmarkEntity(bookmark: $0) }
        }
        
        func entities(matching string: String) async throws -> [BookmarkEntity] {
            // Allows the user to filter the list of Bookmarks by title or author when tapping on a param that accepts a 'Bookmark'
            let allBookmarks = BookmarksManager.shared.getAllBookmarks()
            let matchingBookmarks = allBookmarks.filter {
                return $0.doesMatch(string)
            }.map {
                BookmarkEntity(bookmark: $0)
            }
            
            return matchingBookmarks
        }
    }
    static var defaultQuery = BookmarkEntityQuery()
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Bookmark")
    
//    var displayRepresentation: AppIntents.DisplayRepresentation { DisplayRepresentation(stringLiteral: "BookmarkEntity") }
    
    var id = UUID()
    
    var name: String
    var url: URL
    
    @Property(title: "Host")
    var host: String?
    
    @Property(title: "Notes")
    var notes: String?
    
    @Property(title: "Favorited")
    var isFavorited: Bool?
    
    @Property(title: "Date Added")
    var dateAdded: Date?
    
    init(id: UUID, title: String, url: String, host: String, notes: String, isFavorited: Bool, dateAdded: Date) {
        self.id = id
        self.name = title
        self.url = URL(string: url) ?? URL(string: "")!
        self.host = host
        self.notes = notes
        self.isFavorited = isFavorited
        self.dateAdded = dateAdded
    }
    
    var displayRepresentation: AppIntents.DisplayRepresentation {
        let cachedPreview = CacheManager.instance.get(id: id)
        if let imageData = cachedPreview?.imageData {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(url.absoluteString)",
                image: .init(data: imageData)
            )
        } else {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(url.absoluteString)",
                image: .init(systemName: "link")
            )
        }
    }
    
    init(bookmark: Bookmark) {
        self.id = bookmark.id ?? UUID()
        self.name = bookmark.wrappedTitle
        self.url = bookmark.wrappedURL
        self.host = bookmark.host
        self.notes = bookmark.notes
        self.isFavorited = bookmark.isFavorited
        self.dateAdded = bookmark.wrappedDate
    }
    
    init(fromRegularEntity entity: LinkeeperBookmarkEntity) {
        self.id = entity.id
        self.name = entity.title
        self.url = URL(string: entity.url) ?? URL(string: "")!
        self.host = entity.host
        self.notes = entity.notes
        self.isFavorited = entity.isFavorited
        self.dateAdded = entity.dateAdded
    }
}


//@AssistantEntity(schema: .browser.bookmark)
//struct BookmarkEntity {
//    struct BookmarkEntityQuery: EntityStringQuery {
//        func entities(for identifiers: [BookmarkEntity.ID]) async throws -> [BookmarkEntity] { [] }
//        func entities(matching string: String) async throws -> [BookmarkEntity] { [] }
//    }
//    static var defaultQuery = BookmarkEntityQuery()
//    
//    var displayRepresentation: AppIntents.DisplayRepresentation { "BookmarkEntity" }
//    
//    let id = UUID()
//    
//    var name: String
//    var url: URL
//}

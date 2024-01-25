//
//  FolderEntity.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct FolderEntity: Identifiable, Hashable, Equatable, AppEntity {
  
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Folder")
    typealias DefaultQueryType = IntentsFolderQuery
    static var defaultQuery: IntentsFolderQuery = IntentsFolderQuery()
    
    var id: UUID
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "Bookmarks")
    var bookmarks: Set<BookmarkEntity>
    
    
    @Property(title: "Index")
    var index: Int
    
    var symbol: String
    var color: String
    
    var bookmarkscount: Int
    
    init(id: UUID, title: String, bookmarks: Set<BookmarkEntity>, index: Int, symbol: String, color: String) {
        self.id = id
        
        self.symbol = symbol
        self.color = color
        self.bookmarkscount = bookmarks.count
        
        self.title = title
        self.bookmarks = bookmarks
        self.index = index
    }
    
    var displayRepresentation: DisplayRepresentation {
        #if os(macOS)
        let image: Data? = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!.tinted(with: NSColor(ColorOption(rawValue: color)?.color ?? .gray)).tiffRepresentation
        #else
        let image: Data? = UIImage(systemName: symbol)?.withTintColor(UIColor(ColorOption(rawValue: color)?.color ?? .gray)).pngData()
        #endif
        let inflectedBookmark = bookmarks.count == 1 ? "Bookmark" : "Bookmarks"
        
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(bookmarks.count) \(inflectedBookmark)",
            image: .init(data: image ?? Data())
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension FolderEntity {
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equtable conformance
    static func ==(lhs: FolderEntity, rhs: FolderEntity) -> Bool {
        return lhs.id == rhs.id
    }
    
}

@available(iOS 16.0, macOS 13.0, *)
struct IntentsFolderQuery: EntityPropertyQuery {

    // Find Folders by ID
    // For example a user may have chosen a Folder from a list when tapping on a parameter that accepts Folders. The ID of that Folder is now hardcoded into the Shortcut. When the shortcut is run, the ID will be matched against the database in Linkeeper
    func entities(for identifiers: [UUID]) async throws -> [FolderEntity] {
        return identifiers.compactMap { identifier in
            if FoldersManager.shared.doesExist(withId: identifier) {
                let match = FoldersManager.shared.findFolder(withId: identifier)
                return match.toEntity()
            } else {
                return nil
            }
        }
    }
    
    // Returns all Folders in the Linkeeper database. This is what populates the list when you tap on a parameter that accepts a Folder
    func suggestedEntities() async throws -> [FolderEntity] {
        let allFolders = FoldersManager.shared.getAllFolders()
        return allFolders.toEntity()
    }
    
    // Find Folders matching the given query.
    func entities(matching query: String) async throws -> [FolderEntity] {
        
        // Allows the user to filter the list of Folders by title or author when tapping on a param that accepts a 'Folder'
        let allFolders = FoldersManager.shared.getAllFolders()
        let matchingFolders = allFolders.filter {
            return $0.wrappedTitle.localizedCaseInsensitiveContains(query)
        }

        return matchingFolders.toEntity()
    }
         
    static var properties = EntityQueryProperties<FolderEntity, NSPredicate> {
        Property(\FolderEntity.$title) {
            EqualToComparator { NSPredicate(format: "title = %@", $0) }
            ContainsComparator { NSPredicate(format: "title CONTAINS %@", $0) }
        }
        
        Property(\FolderEntity.$index) {
            EqualToComparator { NSPredicate(format: "index = %d", Int16($0)) }
            LessThanComparator { NSPredicate(format: "index < %d", Int16($0))}
            GreaterThanComparator { NSPredicate(format: "index > %d", Int16($0))}
        }
    }
    
    static var sortingOptions = SortingOptions {
        SortableBy(\FolderEntity.$title)
        SortableBy(\FolderEntity.$index)
    }
    
    func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [Sort<FolderEntity>],
        limit: Int?
    ) async throws -> [FolderEntity] {
        print("Fetching Folders")
        let context = DataController.shared.persistentCloudKitContainer.viewContext
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        let predicate = NSCompoundPredicate(type: mode == .and ? .and : .or, subpredicates: comparators)
        //request.fetchLimit = limit ?? 5
        request.predicate = predicate
        request.sortDescriptors = sortedBy.isEmpty ? [NSSortDescriptor(key: "index", ascending: true)] : sortedBy.map({
            let keys = [
                \FolderEntity.$title : "title",
                \FolderEntity.$index : "index"
            ]
            return NSSortDescriptor(key: keys[$0.by] ?? "index", ascending: $0.order == .ascending)
        })
        let matchingFolders = try context.fetch(request)
        return matchingFolders.toEntity()
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension Folder {
    func toEntity() -> FolderEntity {
        FolderEntity(id: self.id, title: self.wrappedTitle, bookmarks: Set<BookmarkEntity>(self.bookmarksArray.toEntity()), index: Int(self.index), symbol: self.wrappedSymbol, color: self.accentColor ?? "red")
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension [Folder] {
    func toEntity() -> [FolderEntity] {
        self.map { $0.toEntity() }
    }
}

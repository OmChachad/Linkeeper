//
//  Folder+CoreDataProperties.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/05/22.
//
//

import Foundation
import CoreData
import SwiftUI

extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var accentColor: String?
    @NSManaged public var id: UUID?
    @NSManaged public var index: Int16
    @NSManaged public var symbol: String?
    @NSManaged public var title: String?
    @NSManaged public var isPinned: Bool
    @NSManaged public var bookmark: NSSet?
    @NSManaged public var parentFolder: Folder?
    @NSManaged public var childFolders: NSSet?
    
    public var wrappedUUID: String {
        String(describing: id?.uuidString)
    }
    
    public var wrappedTitle: String {
        title ?? "Untitled folder"
    }
    
    public var wrappedSymbol: String {
        symbol ?? "questionmark.folder"
    }
    
    public var wrappedColor: Color {
        ColorOption(rawValue: accentColor ?? "gray")?.color ?? Color.gray
    }
    
    public var childFoldersArray: [Folder]? {
        if childFolders?.count == 0 {
            return nil
        }
        
        let set = childFolders as? Set<Folder> ?? []
        
        return set.sorted { $0.index < $1.index }
    }
    
    public var countOfChildFolders: Int {
        return childFoldersArray?.count ?? 0
    }
    
    public var bookmarksArray: [Bookmark] {
        let set = bookmark as? Set<Bookmark> ?? []
        
        return set.sorted { $0.wrappedDate < $1.wrappedDate }
    }
    
    public var countOfBookmarks: Int {
        return countTotalBookmarks(in: self)
    }
    
    private func countTotalBookmarks(in folder: Folder) -> Int {
        var totalBookmarks = folder.bookmark?.count ?? 0

        for childFolder in folder.childFoldersArray ?? [] {
            totalBookmarks += countTotalBookmarks(in: childFolder)
        }

        return totalBookmarks
    }
    
    var draggable: DraggableFolder {
        DraggableFolder(id: id ?? UUID(), title: title ?? "Untitled folder", symbol: symbol ?? "questionmark.folder", index: Int(index), isPinned: isPinned)
    }

}

// MARK: Generated accessors for bookmark
extension Folder {

    @objc(addBookmarkObject:)
    @NSManaged public func addToBookmark(_ value: Bookmark)

    @objc(removeBookmarkObject:)
    @NSManaged public func removeFromBookmark(_ value: Bookmark)

    @objc(addBookmark:)
    @NSManaged public func addToBookmark(_ values: NSSet)

    @objc(removeBookmark:)
    @NSManaged public func removeFromBookmark(_ values: NSSet)

}

extension Folder : Identifiable {

}

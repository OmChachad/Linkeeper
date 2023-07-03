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
    @NSManaged public var symbol: String?
    @NSManaged public var title: String?
    @NSManaged public var index: Int16
    @NSManaged public var bookmark: NSSet?
    
    public var wrappedTitle: String {
           title ?? "Untitled folder"
       }
       
       public var wrappedSymbol: String {
           symbol ?? "questionmark.folder"
       }
       
       public var wrappedColor: Color {
           ColorOption(rawValue: accentColor ?? "gray")?.color ?? Color.gray
       }
       
       public var bookmarksArray: [Bookmark] {
           let set = bookmark as? Set<Bookmark> ?? []
           
           return set.sorted { $0.wrappedDate < $1.wrappedDate }
       }
    
    public var countOfBookmarks: Int {
        bookmark?.count ?? 0
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

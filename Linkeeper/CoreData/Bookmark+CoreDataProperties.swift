//
//  Bookmark+CoreDataProperties.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/05/22.
//
//

import Foundation
import CoreData


extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var host: String?
    @NSManaged public var url: String?
    @NSManaged public var isFavorited: Bool
    @NSManaged public var folder: Folder?
    
    public var wrappedTitle: String {
        title ?? "Untitled folder"
    }
    
    public var wrappedNotes: String {
        notes ?? ""
    }
    
    public var wrappedHost: String {
        host ?? "Unknown Website"
    }
    
    public var wrappedURL: URL {
        URL(string: url!)!.sanitise
    }
    
    public var wrappedDate: Date {
        date ?? Date.now
    }
    
    
}

extension Bookmark : Identifiable {

}

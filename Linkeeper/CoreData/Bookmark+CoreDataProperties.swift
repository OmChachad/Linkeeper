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
        URL(string: url ?? "https://starlightapps.org")!.sanitise
    }
    
    public var wrappedDate: Date {
        date ?? Date.now
    }
    
    public var wrappedUUID: String {
        String(describing: id?.uuidString)
    }
    
    var draggable: DraggableBookmark {
        return DraggableBookmark(id: id ?? UUID(), title: wrappedTitle, url: wrappedURL, notes: wrappedNotes, dateAdded: wrappedDate, isFavorited: isFavorited)
    }
    
    func doesMatch(_ searchText: String) -> Bool {
        if let folder = self.folder {
            return (self.wrappedTitle + self.wrappedHost + self.wrappedNotes + folder.wrappedTitle).localizedCaseInsensitiveContains(searchText)
        } else {
            return (self.wrappedTitle + self.wrappedHost + self.wrappedNotes).localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func doesMatch(_ searchText: String, folder: Folder) -> Bool {
        return self.folder == folder && (self.wrappedTitle + self.wrappedHost + self.wrappedNotes + self.folder!.wrappedTitle).localizedCaseInsensitiveContains(searchText)
    }
}

extension Bookmark : Identifiable {

}

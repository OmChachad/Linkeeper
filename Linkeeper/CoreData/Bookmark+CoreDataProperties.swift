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
        date ?? .distantPast
    }
    
    public var wrappedUUID: String {
        String(describing: id?.uuidString)
    }
    
    public var wrappedFolderName: String {
        self.folder?.wrappedTitle ?? "None"
    }
    
    var draggable: DraggableBookmark {
        return DraggableBookmark(id: id ?? UUID(), title: wrappedTitle, url: wrappedURL, notes: wrappedNotes, dateAdded: wrappedDate, isFavorited: isFavorited)
    }
    
    func doesMatch(_ searchText: String) -> Bool {
        let searchableValues = [
            wrappedTitle,
            wrappedHost,
            wrappedNotes,
            url ?? "",
            folder?.wrappedTitle ?? ""
        ]

        return searchableValues.contains {
            $0.localizedStandardContains(searchText)
        }
    }
    
    func doesMatch(_ searchText: String, folder: Folder) -> Bool {
        return self.folder == folder && doesMatch(searchText)
    }
}

extension Bookmark : Identifiable {

}

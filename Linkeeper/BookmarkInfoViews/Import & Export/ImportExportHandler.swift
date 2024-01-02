//
//  ImportExportHandler.swift
//  Linkeeper
//
//  Created by Om Chachad on 02/01/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import SwiftSoup

class ImportExportHandler {
    var exportContents: MarkdownDocument {
        MarkdownDocument(markdownText: toBeExportedContents())
    }
    
    func importFromSafari(html htmlContents: String) throws -> (totalBookmarks: Int, failedImportCount: Int, importedBookmarks: Int) {
        var totalBookmarks = 0
        var failedImportCount = 0
        var importedBookmarks = 0
        
        do {
            // Parse the HTML content
            let doc = try SwiftSoup.parse(htmlContents)
            
            // Select all the <dt> elements that contain bookmarks
            let bookmarkElements = try doc.select("dt:has(a)")
            totalBookmarks = bookmarkElements.count
            // Iterate over each bookmark element
            for bookmarkElement in bookmarkElements {
                // Retrieve the parent folder name
                let parentFolder = try bookmarkElement.parent()?.previousElementSibling()?.text()
                
                // Retrieve the bookmark URL
                guard let url = try bookmarkElement.select("a").first()?.attr("href") else {
                    failedImportCount += 1
                    continue
                }
                
                // Retrieve the bookmark title
                guard let title = try bookmarkElement.select("a").first()?.text() else {
                    failedImportCount += 1
                    continue
                }
                
                importBookmark(url: url, title: title, folderName: parentFolder)
                importedBookmarks += 1
            }
        } catch {
            throw error
        }
        
        return (totalBookmarks, failedImportCount, importedBookmarks)

    }
    
    private func importBookmark(url: String, title: String, folderName: String?, dateAdded: Date = Date.now) {
        let bookmark = BookmarksManager.shared.addBookmark(title: title, url: url, host: URL(string: url)!.host ?? "", notes: "", folder: nil)
        bookmark.date = dateAdded
        
        if let folderName = folderName {
            if folderName == "Favorites" || folderName == "Favourites" {
                bookmark.isFavorited = true
            } else if folderName == "Bookmarks" {
                
            } else if let folder = FoldersManager.shared.getAllFolders().first(where: {$0.wrappedTitle == folderName}) {
                bookmark.folder = folder
            } else {
                let folder = FoldersManager.shared.addFolder(title: folderName, accentColor: "gray", chosenSymbol: "folder.fill")
                bookmark.folder = folder
                
            }
        }
        
        try? DataController.shared.persistentCloudKitContainer.viewContext.save()
    }
    
    private func toBeExportedContents() -> String {
        let bookmarks = BookmarksManager.shared.getAllBookmarks()
        let folders = FoldersManager.shared.getAllFolders()
        
        let ungroupedBookmarksText = """
                ## Ungrouped Bookmarks
                
                \(bookmarks.filter{ $0.folder == nil }.map { bookmark in
                    "\(bookmark.wrappedDate.formatted(date: .numeric, time: .standard) + " - ")[\(bookmark.wrappedTitle)](\(bookmark.wrappedURL.absoluteString)) \(bookmark.wrappedNotes.isEmpty ? "" : "(\(bookmark.wrappedNotes))")\(bookmark.isFavorited ? " - ❤️" : "")"
                }.joined(separator: "\n \n \n"))
                """
        
        let foldersText = folders.map { folder in
                """
                ## \(folder.wrappedTitle) (\(folder.wrappedSymbol), \(folder.accentColor ?? "gray"))
                
                \(folder.bookmarksArray.map({ bookmark in
                    "\(bookmark.wrappedDate.formatted(date: .numeric, time: .standard) + " - ")[\(bookmark.wrappedTitle)](\(bookmark.wrappedURL.absoluteString)) \(bookmark.wrappedNotes.isEmpty ? "" : "(\(bookmark.wrappedNotes))")\(bookmark.isFavorited ? " - ❤️" : "")"
                }).joined(separator: "\n \n"))
                """
        }.joined(separator: "\n \n \n")
        
        return ungroupedBookmarksText + "\n \n" + foldersText
    }
}

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var markdownText: String

    init(markdownText: String) {
        self.markdownText = markdownText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            markdownText = String(data: data, encoding: .utf8) ?? ""
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = markdownText.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

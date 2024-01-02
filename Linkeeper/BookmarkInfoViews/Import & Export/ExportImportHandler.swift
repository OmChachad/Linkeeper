//
//  ExportImportHandler.swift
//  Linkeeper
//
//  Created by Om Chachad on 02/01/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

class ExportImportHandler {
    var exportContents: MarkdownDocument {
        MarkdownDocument(markdownText: toBeExportedContents())
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

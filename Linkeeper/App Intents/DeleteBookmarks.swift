//
//  DeleteBookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import AppIntents

@available(iOS 16.0, *)
struct DeleteBookmark: AppIntent {
    
    // Title of the action in the Shortcuts app
    static var title: LocalizedStringResource = "Delete Bookmark"
    // Description of the action in the Shortcuts app
    static var description: IntentDescription = IntentDescription("""
    This action will delete the selected bookmark.
    
    By default you will be prompted for confirmation before the bookmark are deleted from your collection.
    """, categoryName: "Edit")
    
    @Parameter(title: "Bookmark", description: "The bookmark to be deleted from your collection.", requestValueDialog: IntentDialog("Which bookmark would you like to delete?"))
    var bookmark: BookmarkEntity
    
    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the books will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    static var parameterSummary: some ParameterSummary {
        When(\DeleteBookmark.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete \(\.$bookmark)") {
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete \(\.$bookmark)") {
                \.$confirmBeforeDeleting
            }
        })
    }
    
    func perform() async throws -> some IntentResult {
        do {
            if confirmBeforeDeleting {
                try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete the bookmark titled \"\(bookmark.title)\""))
            }
            
            
            try BookmarksManager.shared.deleteBookmark(withId: bookmark.id)
            return .result(value: "Deleted Bookmark")
        } catch let error {
            throw error
        }
    }
}

// MARK: **Functionality wise, this works, but the items provider for multiple bookmarks doesn't work and show "an internal error occured."**
//@available(iOS 16.0, *)
//struct DeleteBookmarks: AppIntent {
//
//    // Title of the action in the Shortcuts app
//    static var title: LocalizedStringResource = "Delete Bookmarks"
//    // Description of the action in the Shortcuts app
//    static var description: IntentDescription = IntentDescription("""
//    This action will delete the selected bookmarks.
//
//    By default you will be prompted for confirmation before the bookmarks are deleted from your collection.
//    """, categoryName: "Edit")
//
//    @Parameter(title: "Bookmarks", description: "The bookmarks to be deleted from your collection.", requestValueDialog: IntentDialog("Which bookmarks would you like to delete?"))
//    var bookmarks: [BookmarkEntity]
//
//    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the books will be deleted", default: true)
//    var confirmBeforeDeleting: Bool
//
//    static var parameterSummary: some ParameterSummary {
//        When(\DeleteBookmarks.$confirmBeforeDeleting, .equalTo, true, {
//            Summary("Delete \(\.$bookmarks)") {
//                \.$confirmBeforeDeleting
//            }
//        }, otherwise: {
//            Summary("Immediately delete \(\.$bookmarks)") {
//                \.$confirmBeforeDeleting
//            }
//        })
//    }
//
//    func perform() async throws -> some IntentResult {
//        do {
//            if confirmBeforeDeleting {
//                try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete \(bookmarks.count) \(bookmarks.count == 1 ? "Bookmark" : "Bookmarks")"))
//            }
//
//            for bookmark in bookmarks {
//                try BookmarksManager.shared.deleteBookmark(withId: bookmark.id)
//            }
//            return .result(value: "\(bookmarks.count) \(bookmarks.count == 1 ? "Bookmark" : "Bookmarks") Deleted")
//        } catch let error {
//            throw error
//        }
//    }
//}

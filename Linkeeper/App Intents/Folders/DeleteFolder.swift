//
//  DeleteFolder.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import Foundation
import AppIntents
import WidgetKit

@available(iOS 16.0, *)
struct DeleteFolder: AppIntent {
    static var title: LocalizedStringResource = "Delete Folder"
    
    static var description: IntentDescription = IntentDescription(
        "Permanently deletes the Folder from all iCloud Devices.", categoryName: "Edit")
    
    @Parameter(title: "Folders", requestValueDialog: IntentDialog("Which Folders would you like to delete?"))
    var folder: FolderEntity
    
    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the folder will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    @Parameter(title: "Keep Bookmarks inside Folder", description: "If toggled, the bookmarks inside the folder will not be deleted.", default: false)
    var keepBookmarks: Bool
    
    static var parameterSummary: some ParameterSummary {
        When(\DeleteFolder.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete \(\.$folder)") {
                \.$keepBookmarks
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete \(\.$folder)") {
                \.$keepBookmarks
                \.$confirmBeforeDeleting
            }
        })
    }
    
    func perform() async throws -> some IntentResult {
        do {
            if confirmBeforeDeleting {
                try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete this folder titled \(folder.title)?"))
            }
            
            for bookmark in folder.bookmarks {
                if keepBookmarks {
                    BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
                } else {
                    BookmarksManager.shared.deleteBookmark(withId: bookmark.id)
                }
            }
            
            FoldersManager.shared.deleteFolder(withId: folder.id)
            FoldersManager.shared.saveContext()
            WidgetCenter.shared.reloadAllTimelines()
            
            let messageSuffix = folder.bookmarks.count == 0 ? "" : ", \(keepBookmarks ? "keeping" : "alongside") \(folder.bookmarks.count) \(folder.bookmarks.count == 1 ? "Bookmark" : "Bookmarks")"
            return .result(value: "Deleted Folder\(messageSuffix)")
            
        } catch {
            throw error
        }
    }
}

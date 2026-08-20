//
//  DeleteFolder.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
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
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            if confirmBeforeDeleting {
                try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete this folder titled \(folder.title)?"))
            }

            let completionDialog: IntentDialog
            if folder.bookmarks.isEmpty {
                completionDialog = "Deleted the folder \(folder.title)."
            } else if keepBookmarks {
                completionDialog = "Deleted the folder \(folder.title). Its bookmarks remain in Linkeeper."
            } else {
                completionDialog = "Deleted the folder \(folder.title) and its bookmarks."
            }
            
            for bookmark in folder.bookmarks {
                if keepBookmarks {
                    BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
                } else {
                    BookmarksManager.shared.deleteBookmark(withId: bookmark.id)
                }
            }
            
            FoldersManager.shared.delete(withId: folder.id)
            await SpotlightIndexer.shared.synchronizeCurrentStore()
            reloadAllWidgets()

            return .result(dialog: completionDialog)
            
        } catch {
            throw error
        }
    }
}

//
//  MoveBookmarks.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct MoveBookmark: AppIntent, PredictableIntent {
    
    // Title of the action in the Shortcuts app
    static var title: LocalizedStringResource = "Move Bookmark"
    // Description of the action in the Shortcuts app
    static var description: IntentDescription = IntentDescription("""
    The selected bookmark will be moved to the provided folder.
    """, categoryName: "Edit")
    
    @Parameter(title: "Bookmark", description: "The bookmark to be moved.", requestValueDialog: IntentDialog("Which bookmark would you like to move?"))
    var bookmark: LinkeeperBookmarkEntity
    
    @Parameter(title: "Folder", description: "The folder to be moved to.", requestValueDialog: IntentDialog("Choose the folder you'd like to move your bookmark to."))
    var folder: FolderEntity?
    
    @Parameter(title: "Remove from Group", description: "If toggled, you will only be able to access this bookmark from the All Bookmarks section of the app.")
    var removeFromGroup: Bool
    
    static var parameterSummary: some ParameterSummary {
        When(\MoveBookmark.$removeFromGroup, .equalTo, false, {
            Summary("Move \(\.$bookmark) to \(\.$folder)") {
                \.$removeFromGroup
            }
        }, otherwise: {
            Summary("Remove \(\.$bookmark) from all groups.") {
                \.$removeFromGroup
            }
        })
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\Self.$bookmark, \Self.$folder)) { bookmark, folder in
            let destination = folder?.title ?? "a folder"
            return DisplayRepresentation(title: "Move \(bookmark.name) to \(destination)")
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<LinkeeperBookmarkEntity> & ProvidesDialog {
        do {
            let completionDialog: IntentDialog

            if removeFromGroup {
                BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
                bookmark.folderTitle = nil
                completionDialog = "Removed \(bookmark.name) from its folder."
            } else if let folderEntity = folder {
                let destinationFolder = FoldersManager.shared.findFolder(withId: folderEntity.id)
                BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = destinationFolder
                bookmark.folderTitle = folderEntity.title
                completionDialog = "Moved \(bookmark.name) to \(folderEntity.title)."
            } else {
                try await requestConfirmation(result: .result(dialog: "You have not provided a folder. Continuing will remove this bookmark from its folder."))
                BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
                bookmark.folderTitle = nil
                completionDialog = "Removed \(bookmark.name) from its folder."
            }
            try BookmarksManager.shared.context.save()
            await SpotlightIndexer.shared.synchronizeCurrentStore()
            reloadAllWidgets()

            return .result(value: bookmark, dialog: completionDialog)
        
        } catch let error {
            throw error
        }
    }
}

// MARK: **Functionality wise, this works, but the items provider for multiple bookmarks doesn't work and show "an internal error occured."**
//@available(iOS 16.0, *)
//struct MoveBookmarks: AppIntent {
//
//    // Title of the action in the Shortcuts app
//    static var title: LocalizedStringResource = "Move Bookmarks"
//    // Description of the action in the Shortcuts app
//    static var description: IntentDescription = IntentDescription("""
//    The selected bookmarks will be moved to the provided folder.
//    """, categoryName: "Edit")
//
//    @Parameter(title: "Bookmarks", description: "The bookmarks to be moved.", requestValueDialog: IntentDialog("Which bookmarks would you like to move?"))
//    var bookmarks: [LinkeeperBookmarkEntity]
//
//    @Parameter(title: "Folder", description: "The folder to be moved to.", requestValueDialog: IntentDialog("Choose the folder you'd like to move your bookmarks to."))
//    var folder: FolderEntity?
//
//    @Parameter(title: "Remove from Group", description: "If toggled, you will only be able to access these bookmarks from the All Bookmarks section of the app.")
//    var removeFromGroup: Bool
//
//    static var parameterSummary: some ParameterSummary {
//        When(\MoveBookmarks.$removeFromGroup, .equalTo, false, {
//            Summary("Move \(\.$bookmarks) to \(\.$folder)") {
//                \.$removeFromGroup
//            }
//        }, otherwise: {
//            Summary("Remove \(\.$bookmarks) from all groups.") {
//                \.$removeFromGroup
//            }
//        })
//    }
//
//    func perform() async throws -> some ReturnsValue<[LinkeeperBookmarkEntity]> {
//        do {
//
//            for bookmark in bookmarks {
//                if !removeFromGroup {
//                    if let folderEntity = folder {
//                        let folder = try FoldersManager.shared.findFolder(withId: folderEntity.id)
//                        try BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = folder
//                        try BookmarksManager.shared.context.save()
//                        continue
//                    } else {
//                        try await requestConfirmation(result: .result(dialog: "You have not provided a folder, proceeding will remove the given bookmarks from any folder."))
//                    }
//                }
//                try BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
//                try BookmarksManager.shared.context.save()
//            }
//
//            return .result(value: bookmarks)
//
//        } catch let error {
//            throw error
//        }
//    }
//}

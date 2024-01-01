//
//  MoveBookmarks.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import AppIntents
import WidgetKit

@available(iOS 16.0, *)
struct MoveBookmark: AppIntent {
    
    // Title of the action in the Shortcuts app
    static var title: LocalizedStringResource = "Move Bookmark"
    // Description of the action in the Shortcuts app
    static var description: IntentDescription = IntentDescription("""
    The selected bookmark will be moved to the provided folder.
    """, categoryName: "Edit")
    
    @Parameter(title: "Bookmark", description: "The bookmark to be moved.", requestValueDialog: IntentDialog("Which bookmark would you like to move?"))
    var bookmark: BookmarkEntity
    
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
    
    func perform() async throws -> some ReturnsValue<BookmarkEntity> {
        do {
            
            if !removeFromGroup {
                if let folderEntity = folder {
                    let folder = FoldersManager.shared.findFolder(withId: folderEntity.id)
                    BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = folder
                } else {
                    try await requestConfirmation(result: .result(dialog: "You have not provided a folder, proceeding will remove the given bookmarks from any folder."))
                    BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = nil
                }
            }
            try BookmarksManager.shared.context.save()
            WidgetCenter.shared.reloadAllTimelines()
            
            return .result(value: bookmark)
        
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
//    var bookmarks: [BookmarkEntity]
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
//    func perform() async throws -> some ReturnsValue<[BookmarkEntity]> {
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

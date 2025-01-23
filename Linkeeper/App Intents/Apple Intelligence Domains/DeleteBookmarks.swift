//
//  DeleteBookmarks.swift
//  Linkeeper
//
//  Created by Om Chachad on 1/23/25.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, *)
@AssistantIntent(schema: .browser.deleteBookmarks)
struct DeleteBookmarksIntent: DeleteIntent {
    var entities: [BookmarkEntity]
    
    static var isDiscoverable: Bool = false
    
    func perform() async throws -> some IntentResult {
        for entity in entities {
            BookmarksManager.shared.deleteBookmark(withId: entity.id)
        }
        
        reloadAllWidgets()
        return .result()
    }
}

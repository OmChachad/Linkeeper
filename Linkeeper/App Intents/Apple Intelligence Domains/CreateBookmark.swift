//
//  CreateBookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 1/23/25.
//

import Foundation
import AppIntents

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
@AssistantIntent(schema: .browser.bookmarkURL)
struct BookmarkURLIntent {
    @Parameter(title: "title")
    var name: String?
    @Parameter(
        title: "url",
        requestValueDialog: "What web address would you like to save?"
    )
    var url: URL
    
    func perform() async throws -> some IntentResult & ReturnsValue<LinkeeperBookmarkEntity> & ProvidesDialog {
        do {
            if let name {
                if let bookmarkEntity = try await AddBookmark(bookmarkTitle: name, url: url).perform().value {
                    return .result(
                        value: bookmarkEntity,
                        dialog: "Saved \(bookmarkEntity.name) to Linkeeper."
                    )
                }
            } else {
                if let bookmarkEntity = try await AddBookmark(autoTitle: true, url: url).perform().value {
                    return .result(
                        value: bookmarkEntity,
                        dialog: "Saved \(bookmarkEntity.name) to Linkeeper."
                    )
                }
            }
            
            throw CustomError.message("Could not create bookmark.")
        } catch {
            throw error
        }
    }
}

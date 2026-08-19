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
    @Parameter(title: "url")
    var url: URL
    
    func perform() async throws -> some ReturnsValue<LinkeeperBookmarkEntity> {
        do {
            if let name {
                if let bookmarkEntity = try await AddBookmark(bookmarkTitle: name, url: url).perform().value {
                    return .result(value: bookmarkEntity)
                }
            } else {
                if let bookmarkEntity = try await AddBookmark(autoTitle: true, url: url).perform().value {
                    return .result(value: bookmarkEntity)
                }
            }
            
            throw CustomError.message("Could not create bookmark.")
        } catch {
            throw error
        }
    }
}

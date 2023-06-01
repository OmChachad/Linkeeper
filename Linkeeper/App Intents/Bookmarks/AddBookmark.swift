//
//  AddBookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import AppIntents
import LinkPresentation

@available(iOS 16.0, *)
struct AddBookmark: AppIntent {
    static var title: LocalizedStringResource = "Add Bookmark"
    
    static var description: IntentDescription = IntentDescription("Add a new bookmark to your collection.", categoryName: "Create", searchKeywords: ["Create", "Link", "URL", "New"])
    
    @Parameter(title: "Auto-Generate Title", description: """
If enabled, the title of the bookmark will be generated based on the webpage's title. You can always change it later.
If disabled, you can add a title yourself.
""", default: true)
    var autoTitle: Bool
    
    @Parameter(title: "Title", description: "The title for the bookmark.", inputOptions: String.IntentInputOptions(capitalizationType: .words), requestValueDialog: "What would you like to title your bookmark?")
    var title: String?
    
    @Parameter(title: "URL", description: "The website to be bookmarked. Needs to start with \"https://\"", default: URL(string: "https://"))
    var url: URL
    
    @Parameter(title: "Notes", description: "The title for the bookmark.", inputOptions: String.IntentInputOptions(capitalizationType: .sentences), requestValueDialog: "Add notes to your Bookmark")
    var notes: String?
    
    static var parameterSummary: some ParameterSummary {
        When(\AddBookmark.$autoTitle, .equalTo, true, {
            Summary("Add Bookmark for \(\.$url)") {
                \.$autoTitle
                \.$notes
            }
        }, otherwise: {
            Summary("Add Bookmark for \(\.$url)") {
                \.$autoTitle
                \.$title
                \.$notes
            }
        })
    }
    
    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some ReturnsValue<BookmarkEntity> {
        guard url.sanitise.absoluteString.isValidURL == true else {
            throw CustomError.message("Invalid URL")
        }
        do {
            if !autoTitle && (title == nil || ((title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) != false)) {
                throw CustomError.message("Missing title")
            }
            let title: String = await {
                if autoTitle {
                    let metadataProvider = LPMetadataProvider()
                    metadataProvider.shouldFetchSubresources = false
                    metadataProvider.timeout = 15
                    
                    do {
                        return try await metadataProvider.startFetchingMetadata(for: url).title ?? url.host
                    } catch {
                        return nil
                    }
                } else {
                    return self.title
                }
            }() ?? "Unknown Title"
            //let title = autoTitle ? try await fetchMetadata(for: url.sanitise.absoluteString).title : self.title
            let bookmark = try BookmarksManager.shared.addBookmark(id: nil, title: title, url: url.sanitise.absoluteString, host: url.host ?? "", notes: notes ?? "", folder: nil)
            let entity = BookmarkEntity(id: bookmark.id!, title: bookmark.wrappedTitle, url: bookmark.wrappedURL.absoluteString, host: bookmark.wrappedHost, notes: bookmark.wrappedNotes, isFavorited: false, dateAdded: bookmark.wrappedDate)
                return .result(value: entity)
        } catch let error {
            throw CustomError.message(error.localizedDescription)
        }
    }
    
}

@available(iOS 16, *)
enum CustomError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case general
    case message(_ message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .message(message): return "Error: \(message)"
        case .general: return "My general error"
        }
    }
}

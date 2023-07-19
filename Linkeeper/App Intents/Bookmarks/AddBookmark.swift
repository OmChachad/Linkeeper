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
    var bookmarkTitle: String?
    
    @Parameter(title: "URL", description: "The website to be bookmarked. Needs to start with \"https://\", \"http://\" or any other URL scheme.")
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
                \.$bookmarkTitle
                \.$notes
            }
        })
    }
    
    func perform() async throws -> some ReturnsValue<BookmarkEntity> {
        do {
            let title: String = await {
                if autoTitle {
                    let metadataProvider = LPMetadataProvider()
                    metadataProvider.shouldFetchSubresources = false
                    metadataProvider.timeout = 15
                    
                    do {
                        return try await metadataProvider.startFetchingMetadata(for: url).title ?? url.host ?? "Unknown Title"
                    } catch {
                        do {
                            return try await $bookmarkTitle.requestValue("Failed to fetch title for \(url.host ?? "Bookmark"), please provide a title yourself.")
                        } catch {
                            return url.host ?? "Unknown Title"
                        }
                    }
                } else {
                    if let title = self.bookmarkTitle, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return title
                    } else {
                        do {
                            return try await $bookmarkTitle.requestValue("Missing Title: Please provide a valid bookmark title.")
                        } catch {
                            return url.host ?? "Unknown Title"
                        }
                    }
                }
            }().trimmingCharacters(in: .whitespacesAndNewlines)
            
            let urlString: String = {
                let url = url.absoluteString
                if UserDefaults.standard.bool(forKey: "removeTrackingParameters") == true {
                         return url.components(separatedBy: "?").first ?? url
                } else {
                    return url
                }
            }()
            
            let bookmark = try BookmarksManager.shared.addBookmark(id: nil, title: title, url: urlString, host: url.host ?? urlString, notes: notes ?? "", folder: nil)
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

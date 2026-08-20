//
//  AddBookmark.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import AppIntents

@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
struct AddBookmark: AppIntent, PredictableIntent {
    static var title: LocalizedStringResource = "Add Bookmark"
    
    static var description = IntentDescription(
        "Save a web link to Linkeeper.",
        categoryName: "Create",
        searchKeywords: ["Bookmark", "Create", "Link", "Save", "URL"]
    )
    
    @Parameter(
        title: "Use Website Title",
        description: "Use the webpage title when it becomes available.",
        default: true
    )
    var autoTitle: Bool
    
    @Parameter(
        title: "Title",
        description: "A custom name for the bookmark.",
        inputOptions: String.IntentInputOptions(capitalizationType: .words),
        requestValueDialog: "What would you like to call this bookmark?"
    )
    var bookmarkTitle: String?
    
    @Parameter(
        title: "URL",
        description: "The web address to save.",
        requestValueDialog: "What link would you like to save?"
    )
    var url: URL
    
    @Parameter(
        title: "Notes",
        description: "Optional details to remember about the bookmark.",
        inputOptions: String.IntentInputOptions(capitalizationType: .sentences)
    )
    var notes: String?

    @Parameter(
        title: "Folder",
        description: "The Linkeeper folder where the bookmark should be saved.",
        requestValueDialog: "Which folder should I save it to?"
    )
    var folder: FolderEntity?
    
    init(url: URL, notes: String? = nil, folder: FolderEntity? = nil) {
        self.autoTitle = true
        self.bookmarkTitle = nil
        self.url = url
        self.notes = notes
        self.folder = folder
    }
    
    init(bookmarkTitle: String, url: URL, notes: String? = nil, folder: FolderEntity? = nil) {
        self.autoTitle = false
        self.bookmarkTitle = bookmarkTitle
        self.url = url
        self.notes = notes
        self.folder = folder
    }
    
    init() {}
    
    static var parameterSummary: some ParameterSummary {
        When(\AddBookmark.$autoTitle, .equalTo, true, {
            Summary("Save \(\.$url)") {
                \.$autoTitle
                \.$folder
                \.$notes
            }
        }, otherwise: {
            Summary("Save \(\.$url) as \(\.$bookmarkTitle)") {
                \.$autoTitle
                \.$folder
                \.$notes
            }
        })
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\Self.$url)) { url in
            let website = url.host ?? url.absoluteString
            return DisplayRepresentation(title: "Save \(website) to Linkeeper")
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<LinkeeperBookmarkEntity> & ProvidesDialog {
        let fallbackTitle = titleFromURL
        let title: String

        if autoTitle {
            title = fallbackTitle
        } else if let bookmarkTitle = bookmarkTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !bookmarkTitle.isEmpty {
            title = bookmarkTitle
        } else {
            let requestedTitle = try await $bookmarkTitle.requestValue(
                "What would you like to call this bookmark?"
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !requestedTitle.isEmpty else {
                throw $bookmarkTitle.needsValueError("Give this bookmark a title.")
            }
            title = requestedTitle
        }

        let targetFolder: Folder?
        if let folder {
            guard FoldersManager.shared.doesExist(withId: folder.id) else {
                throw CustomError.message("The selected folder no longer exists.")
            }
            targetFolder = FoldersManager.shared.findFolder(withId: folder.id)
        } else {
            targetFolder = nil
        }

        SpotlightIndexer.shared.observeCurrentStore()
        let bookmark = try BookmarksManager.shared.addBookmarkAndSave(
            id: nil,
            title: title,
            url: url.sanitise.absoluteString,
            host: url.host ?? url.absoluteString,
            notes: notes ?? "",
            folder: targetFolder
        )
        reloadAllWidgets()
        let bookmarkEntity = bookmark.toEntity()
        let targetFolderID = targetFolder?.id
        SpotlightIndexer.shared.scheduleBookmarkUpdate(
            bookmarkEntity.id,
            inFolder: targetFolderID
        )

        if autoTitle {
            Task { @MainActor in
                let didUpdateTitle = await BookmarksManager.shared.enrichGeneratedTitle(
                    for: bookmarkEntity.id,
                    from: url,
                    replacing: fallbackTitle
                )

                if didUpdateTitle {
                    SpotlightIndexer.shared.scheduleBookmarkUpdate(
                        bookmarkEntity.id,
                        inFolder: targetFolderID
                    )
                    reloadAllWidgets()
                }
            }
        }

        let dialog: IntentDialog = if let folder {
            "Saved \(bookmarkEntity.name) to \(folder.title) in Linkeeper."
        } else {
            "Saved \(bookmarkEntity.name) to Linkeeper."
        }

        return .result(
            value: bookmarkEntity,
            dialog: dialog
        )
    }

    /// A useful title that doesn't require network access or delay Siri.
    private var titleFromURL: String {
        guard let host = url.host, !host.isEmpty else {
            return url.absoluteString
        }

        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
    
}

@available(iOS 16.0, macOS 13.0, *)
enum CustomError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case general
    case message(_ message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .message(message): return "\(message)"
        case .general: return "Linkeeper couldn't complete this action."
        }
    }
}

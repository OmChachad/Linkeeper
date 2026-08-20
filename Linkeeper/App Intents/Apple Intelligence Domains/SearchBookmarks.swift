//
//  SearchBookmarks.swift
//  Linkeeper
//

import AppIntents

/// Handles system-wide requests to search Linkeeper and opens the results in
/// the app's existing All Bookmarks search UI.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
// TODO(OS 27 SDK): Rename this schema to `.system.searchInApp` and migrate
// `@AssistantIntent` to `@AppIntent` when Linkeeper adopts the OS 27 SDK.
@AssistantIntent(schema: .system.search)
struct SearchBookmarksIntent {
    static var searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria

    @Dependency private var navigationModel: SpotlightNavigationModel

    init() {}

    init(criteria: StringSearchCriteria) {
        self.criteria = criteria
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let query = criteria.term.trimmingCharacters(in: .whitespacesAndNewlines)
        navigationModel.showBookmarkSearchResults(for: query)

        return .result(dialog: "Searching Linkeeper for \(query).")
    }
}

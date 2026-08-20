//
//  SpotlightNavigationModel.swift
//  Linkeeper
//

import Foundation
import Combine

/// The in-app destination requested by an entity-opening intent.
struct SpotlightDestination: Equatable, Sendable {
    let kind: SpotlightDestinationKind
    let id: UUID
}

/// A request to show Linkeeper's bookmark search UI with a populated query.
struct BookmarkSearchDestination: Equatable, Identifiable, Sendable {
    let id: UUID
    let query: String

    init(query: String) {
        self.id = UUID()
        self.query = query
    }
}

/// Routes entity-opening intents on systems before iOS 26.
@MainActor
final class SpotlightNavigationModel: ObservableObject {
    static let shared = SpotlightNavigationModel()

    @Published var destination: SpotlightDestination?
    @Published var bookmarkSearchDestination: BookmarkSearchDestination?

    private init() {}

    func open(_ kind: SpotlightDestinationKind, id: UUID) {
        destination = SpotlightDestination(kind: kind, id: id)
    }

    func showBookmarkSearchResults(for query: String) {
        bookmarkSearchDestination = BookmarkSearchDestination(
            query: query.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

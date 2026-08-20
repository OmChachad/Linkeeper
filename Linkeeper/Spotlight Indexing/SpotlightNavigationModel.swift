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

/// Routes entity-opening intents on systems before iOS 26.
@MainActor
final class SpotlightNavigationModel: ObservableObject {
    static let shared = SpotlightNavigationModel()

    @Published var destination: SpotlightDestination?

    private init() {}

    func open(_ kind: SpotlightDestinationKind, id: UUID) {
        destination = SpotlightDestination(kind: kind, id: id)
    }
}

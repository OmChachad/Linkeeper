//
//  LinkeeperIntentDonations.swift
//  Linkeeper
//
//  Created by Om Chachad on 20/08/26.
//

import AppIntents
import LinkPresentation

@available(iOS 18.0, macOS 15.0, visionOS 2.0, iOSApplicationExtension 18.0, *)
enum LinkeeperIntentDonations {
    /// Donates an action initiated in Linkeeper after the action finishes successfully.
    static func donate<Intent: AppIntent, Result: IntentResult>(
        _ intent: Intent,
        result: Result
    ) async {
        do {
            try await IntentDonationManager.shared.donate(intent: intent, result: result)
        } catch {
            #if DEBUG
            print("Could not donate \(Intent.self): \(error.localizedDescription)")
            #endif
        }
    }

    /// Removes donations associated with an entity that no longer exists.
    static func removeDonations<Entity: AppEntity>(
        for entityType: Entity.Type,
        identifier: Entity.ID
    ) async {
        let entityIdentifier = EntityIdentifier(for: entityType, identifier: identifier)

        do {
            try await IntentDonationManager.shared.deleteDonations(
                matching: .entityIdentifier(entityIdentifier)
            )
        } catch {
            #if DEBUG
            print("Could not remove donations for \(entityIdentifier): \(error.localizedDescription)")
            #endif
        }
    }
}

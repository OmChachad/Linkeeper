//
//  SpotlightIntentExecutionModifier.swift
//  Linkeeper
//

import SwiftUI

struct SpotlightIntentExecutionModifier: ViewModifier {
    let openBookmark: @MainActor (UUID) -> Void
    let openFolder: @MainActor (UUID) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content
                .onAppIntentExecution(OpenBookmarkIntent.self) { intent in
                    openBookmark(intent.target.id)
                }
                .onAppIntentExecution(OpenFolderIntent.self) { intent in
                    openFolder(intent.target.id)
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

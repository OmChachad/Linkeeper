//
//  OpenFolderIntent.swift
//  Linkeeper
//

import AppIntents

/// Opens a folder selected from Spotlight or Siri.
@available(iOS 18.0, macOS 15.0, visionOS 2.0, iOSApplicationExtension 18.0, *)
struct OpenFolderIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Folder"

    // TODO(iOS 27 SDK): Add
    // `@available(iOS 27.0, *)`
    // `static var allowedExecutionTargets: IntentExecutionTargets { .main }`
    // so the intent is explicitly constrained to Linkeeper's foreground app.
    // Until iOS 27 is supported, iOS 26 presentation is handled by
    // `onAppIntentExecution`, and older systems use `SpotlightNavigationModel`.

    @Parameter(title: "Folder", requestValueDialog: "Which folder?")
    var target: FolderEntity

    @Dependency private var navigationModel: SpotlightNavigationModel

    @MainActor
    func perform() async throws -> some IntentResult {
        #if os(iOS)
        if #unavailable(iOS 26.0) {
            navigationModel.open(.folder, id: target.id)
        }
        #else
        navigationModel.open(.folder, id: target.id)
        #endif

        return .result()
    }
}

#if os(iOS)
@available(iOS 26.0, *)
extension OpenFolderIntent: TargetContentProvidingIntent {}
#endif

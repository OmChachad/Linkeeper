//
//  AppIntent.swift
//  BookmarksWidget
//
//  Created by Om Chachad on 21/12/23.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Folder"
    static var description = IntentDescription("Get quick access to one of your folders.")

    // An example configurable parameter.
    @Parameter(title: "Folder", default: nil)
    var folder: FolderEntity?
}

extension ConfigurationAppIntent {
    static var allBookmarks: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.folder = nil
        return intent
    }
}

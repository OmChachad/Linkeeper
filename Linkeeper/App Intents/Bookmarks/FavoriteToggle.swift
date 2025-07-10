//
//  Add/Remove from Favorites.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/05/23.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
struct FavoriteToggle: AppIntent {
    
    // Title of the action in the Shortcuts app
    static var title: LocalizedStringResource = "Set Favorite Status"
    // Description of the action in the Shortcuts app
    static var description: IntentDescription = IntentDescription("Change the favorite status for a Bookmark", categoryName: "Edit")
    
    @Parameter(title: "Set or Toggle", default: ToggleOrSet.set)
    var toggleTask: ToggleOrSet
    
    @Parameter(title: "Favorite Status", default: YesOrNo.yes)
    var OnOrOff: YesOrNo
    
    @Parameter(title: "Bookmark", description: "The bookmark of which the favorite status will change", requestValueDialog: IntentDialog("Choose a bookmark"))
    var bookmark: LinkeeperBookmarkEntity
    
    static var parameterSummary: some ParameterSummary {
        When(\FavoriteToggle.$toggleTask, .equalTo, .toggle, {
            Summary("\(\.$toggleTask) Favorite status for \(\.$bookmark)")
        }, otherwise: {
            Summary("\(\.$toggleTask) Favorite status for \(\.$bookmark) to \(\.$OnOrOff)")
        })
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<LinkeeperBookmarkEntity> {
        if toggleTask == .toggle {
            bookmark.isFavorited.toggle()
            BookmarksManager.shared.findBookmark(withId: bookmark.id).isFavorited.toggle()
        } else {
            BookmarksManager.shared.findBookmark(withId: bookmark.id).isFavorited = (OnOrOff == .yes ? true : false)
            bookmark.isFavorited = (OnOrOff == .yes ? true : false)
        }
        BookmarksManager.shared.saveContext()

        return .result(value: bookmark)
    }
}

//@available(iOS 16.0, *)
//enum ToggleTask: String, AppEnum {
//    case add = "Add"
//    case remove = "Remove"
//    case toggle = "Toggle"
//
//    // This will be displayed as the title of the menu shown when picking from the options
//    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")
//
//    // The strings that will be shown for each item in the menu
//    static var caseDisplayRepresentations: [ToggleTask: DisplayRepresentation] = [
//        .add: "Add",
//        .remove: "Remove",
//        .toggle: "Toggle"
//    ]
//}

@available(iOS 16.0, macOS 13.0, *)
enum ToggleOrSet: String, AppEnum {
    case set
    case toggle

    // This will be displayed as the title of the menu shown when picking from the options
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "ToggleOrSet")
    
    // The strings that will be shown for each item in the menu
    static var caseDisplayRepresentations: [ToggleOrSet: DisplayRepresentation] = [
        .set: "Set",
        .toggle: "Toggle"
    ]
}

@available(iOS 16.0, macOS 13.0, *)
enum YesOrNo: String, AppEnum {
    case yes
    case no

    // This will be displayed as the title of the menu shown when picking from the options
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "YesOrNo")
    
    // The strings that will be shown for each item in the menu
    static var caseDisplayRepresentations: [YesOrNo: DisplayRepresentation] = [
        .yes: "Yes",
        .no: "No"
    ]
}

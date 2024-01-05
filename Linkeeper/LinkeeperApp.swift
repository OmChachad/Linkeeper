//
//  LinkeeperApp.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct LinkeeperApp: App {
    @StateObject private var dataController = DataController.shared
    @AppStorage("showIntroduction") var showIntroduction = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.persistentCloudKitContainer.viewContext)
                .sheet(isPresented: $showIntroduction, onDismiss: {
                    showIntroduction = false
                }, content: IntroductionView.init)
                .task {
                    if #available(iOS 16.0, *) {
                        LinkeeperShortcuts.updateAppShortcutParameters()
                    }
                    reloadAllWidgets()
                    CacheManager.instance.clearOutOld()
                }
        }
    }
}

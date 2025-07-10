//
//  LinkeeperApp.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI
import CoreData
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct LinkeeperApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @StateObject private var dataController = DataController.shared
    @AppStorage("showIntroduction") var showIntroduction = true
    @AppStorage("showWhatsNewv3.0") var showWhatsNew = true
    
    @ObservedObject var storeKit = Store.shared
    @AppStorage("tipPromptCompleted") var tipPromptCompleted = false
    @State private var showTipPrompt = false
    
    var body: some Scene {
        WindowGroup("Linkeeper") {
            ContentView()
                .environment(\.managedObjectContext, dataController.persistentCloudKitContainer.viewContext)
                .sheet(isPresented: $showIntroduction, onDismiss: {
                    showIntroduction = false
                }, content: IntroductionView.init)
                .sheet(isPresented: $showWhatsNew, content: {
                    WhatsNew()
                })
                .task {
                    if #available(iOS 16.0, macOS 13.0, *) {
                        LinkeeperShortcuts.updateAppShortcutParameters()
                    }
                    reloadAllWidgets()
                    CacheManager.instance.clearOutOld()
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay to ensure the app is fully loaded before checking for tip prompt.
                    
                    if !tipPromptCompleted && !storeKit.userHasTipped && (try! dataController.persistentCloudKitContainer.viewContext.count(for: NSFetchRequest(entityName: "Bookmark"))) > 20 {
                        showTipPrompt = true
                    }
                }
                .onAppear {
                    if showIntroduction {
                        showWhatsNew = false // Dismiss What's New if Introduction is shown
                    }
                }
                .sheet(isPresented: $showTipPrompt, onDismiss: {
                    tipPromptCompleted = true
                }) {
                    TipRequestView()
                        .frame(minHeight: 400)
                        .environmentObject(storeKit)
                }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .frame(idealWidth: 500)
        }
        #endif
    }
}

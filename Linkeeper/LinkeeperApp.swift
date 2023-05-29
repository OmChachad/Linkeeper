//
//  LinkeeperApp.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI

@main
struct LinkeeperApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.persistentCloudKitContainer.viewContext)
        }
    }
}

//
//  LinkeeperApp.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/04/22.
//

import SwiftUI

@main
struct LinkeeperApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}

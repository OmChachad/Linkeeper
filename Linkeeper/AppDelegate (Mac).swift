//
//  AppDelegate (Mac).swift
//  Linkeeper
//
//  Created by Om Chachad on 3/2/25.
//

import Foundation
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        let item1 = NSMenuItem(title: "Add Bookmark", action: #selector(addBookmark), keyEquivalent: "")
        item1.target = self

        menu.addItem(item1)

        return menu
    }

    @objc func addBookmark() {
        if NSApplication.shared.windows.first?.title.isEmpty != false {
            let url = URL(string: "linkeeper://addBookmark")!
            NSWorkspace.shared.open(url)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .addBookmark, object: nil)
        }
    }
}

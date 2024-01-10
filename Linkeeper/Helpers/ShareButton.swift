//
//  ShareButton.swift
//  Linkeeper
//
//  Created by Om Chachad on 07/07/23.
//

import Foundation
import SwiftUI

struct ShareButton<Content: View>: View {
    var url: URL
    var label: () -> Content
    
    var body: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                ShareLink(item: url) {
                    label()
                }
            } else {
                Button {
                    share(url: url)
                } label: {
                    label()
                }
            }
        }
    }
    
    func share(url: URL) {
        #if os(macOS)
        if let contentView = NSApp.mainWindow?.contentView {
                let sharingPicker = NSSharingServicePicker(items: [url])
                sharingPicker.show(relativeTo: NSZeroRect, of: contentView, preferredEdge: .minY)
            }
        #else
        let activityView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
        #endif
    }
}

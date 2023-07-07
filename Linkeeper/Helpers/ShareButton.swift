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
            if #available(iOS 16.0, *) {
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
        let activityView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
}

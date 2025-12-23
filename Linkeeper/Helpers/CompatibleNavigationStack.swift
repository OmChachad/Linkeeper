//
//  CompatibleNavigationStack.swift
//  Linkeeper
//
//  Created by Om Chachad on 23/12/25.
//

import SwiftUI

struct CompatibleNavigationStack<Content: View>: View {
    
    @ViewBuilder
    var content: () -> Content
    
    var body: some View {
        if #available(macOS 13.0, iOS 16.0, visionOS 1.0,  *) {
            NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
                    #if !os(macOS)
                    .navigationViewStyle(.stack)
                    #endif
            }
        }
    }
}

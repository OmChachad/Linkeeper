//
//  View.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension View {
    func navigationTitle(for folder: Folder?, folderTitle: Binding<String>, onlyFavorites: Bool) -> some View {
        Group {
            if #available(iOS 16.0, *), folder != nil {
                self
                    .navigationTitle(folderTitle)
            } else {
                self
                    .navigationTitle(folder?.wrappedTitle ?? (onlyFavorites == true ? "Favorites" : "All Bookmarks"))
            }
        }
    }
    
    func glow() -> some View {
        self
            .background(self.blur(radius: 5))
    }
    
    func sideBarForMac() -> some View {
        #if targetEnvironment(macCatalyst)
            return self
            .listStyle(.sidebar)
        #else
            return self
            .listStyle(.insetGrouped)
        #endif
    }
    
    func borderlessMacCatalystButton() -> some View {
        #if targetEnvironment(macCatalyst)
            return self
            .buttonStyle(.borderless)
        #else
            return self
        #endif
    }
    
    func cornerRadius(_ radius: CGFloat, style: RoundedCornerStyle) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: radius, style: style))
    }
}

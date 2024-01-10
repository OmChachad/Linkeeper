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
            #if os(macOS)
            self
                .navigationTitle(folder?.wrappedTitle ?? (onlyFavorites == true ? "Favorites" : "All Bookmarks"))
            #else
            if #available(iOS 16.0, macOS 13.0, *), folder != nil {
                self
                    .navigationTitle(folderTitle)
            } else {
                self
                    .navigationTitle(folder?.wrappedTitle ?? (onlyFavorites == true ? "Favorites" : "All Bookmarks"))
            }
            #endif
        }
    }
    
    func groupedFormStyle() -> some View {
        Group {
            #if os(macOS)
            if #available(macOS 13.0, *) {
                self
                    .formStyle(.grouped)
            } else {
                self.padding()
            }
            #else
            self
            #endif
        }
    }
    
    func glow() -> some View {
        self
            .background(self.blur(radius: 5))
    }
    
    func sideBarForMac() -> some View {
        #if os(macOS)
            return self
            .listStyle(.sidebar)
        #else
            return self
            .listStyle(.insetGrouped)
        #endif
    }
    
    func cornerRadius(_ radius: CGFloat, style: RoundedCornerStyle) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: radius, style: style))
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func contentUnavailabilityView<Content: View>(for content: any Collection, @ViewBuilder unavailabilityView: () -> Content) -> some View {
        Group {
            if content.isEmpty {
                unavailabilityView()
            } else {
                self
            }
        }
    }
    
    func scrollContentBackground(visibility: Visibility) -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            return self.scrollContentBackground(visibility)
        } else {
            return self
        }
    }
}

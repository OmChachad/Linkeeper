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
    
    func bottomOrnament<Content: View>(
        visibility: Visibility = .automatic,
        //attachmentAnchor: OrnamentAttachmentAnchor,
        contentAlignment: Alignment = .center,
        @ViewBuilder ornament: () -> Content
    ) -> some View where Content : View {
        #if os(visionOS)
            self
            .ornament(visibility: visibility, attachmentAnchor: .scene(.bottom), contentAlignment: contentAlignment, ornament: ornament)
        #else
            self
        #endif
    }
    
    func trailingOrnament<Content: View>(
        visibility: Visibility = .automatic,
        //attachmentAnchor: OrnamentAttachmentAnchor,
        contentAlignment: Alignment = .center,
        @ViewBuilder ornament: () -> Content
    ) -> some View where Content : View {
        #if os(visionOS)
            self
            .ornament(visibility: visibility, attachmentAnchor: .scene(.trailing), contentAlignment: contentAlignment, ornament: ornament)
        #else
            self
        #endif
    }
    
    func visionGlassBackgroundEffect<S>(
        in shape: S
    ) -> some View where S : InsettableShape {
        Group {
        #if os(visionOS)
            self
                .glassBackgroundEffect(in: shape)
        #else
            self
        #endif
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
}

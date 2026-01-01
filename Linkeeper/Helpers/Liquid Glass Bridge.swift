//
//  Liquid Glass Bridge.swift
//  Linkeeper
//
//  Created by Om Chachad on 23/12/25.
//

import SwiftUI

struct CompatibleGlassEffectContainer<Content: View>: View {
    @ViewBuilder
    var content: Content
    
    var body: some View {
#if !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
#else
        content
#endif
    }
}

enum CompatibleGlass {
    case clear, identity, regular, interactive
}

extension View {
    @ViewBuilder
    func compatibleGlassEffect(_ glass: CompatibleGlass = .regular, in shape: some InsettableShape = Capsule(), glassFallBackMaterial: Material? = nil) -> some View {
        #if !os(visionOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch(glass) {
            case .clear:
                self
                    .glassEffect(.clear, in: shape)
            case .identity:
                self
                    .glassEffect(.identity, in: shape)
            case .interactive:
                self
                    .glassEffect(.regular.interactive(), in: shape)
            case .regular:
                self
                    .glassEffect(.regular, in: shape)
            }
        } else if let glassFallBackMaterial {
            self
                .background(glassFallBackMaterial, in: shape)
                .background {
                    shape
                        .foregroundColor(.white.opacity(0.1))
                        .shadow(radius: 5)
                }
        } else {
            self
        }
        #else
        self
            .glassBackgroundEffect(in: shape)
        #endif
    }
}

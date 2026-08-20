//
//  WhatsNew.swift
//  Linkeeper
//
//  Created by Om Chachad on 7/10/25.
//

import SwiftUI

struct WhatsNew: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedFeatures: Int = 0
    
    private struct Feature {
        let systemImage: String
        let tint: Color
        let title: String
        let description: String
    }
    
    private let features: [Feature] = [
        Feature(
            systemImage: "magnifyingglass.circle.fill",
            tint: .blue,
            title: "Search with Spotlight",
            description: "Find bookmarks and folders directly from Spotlight."
        ),
        Feature(
            systemImage: "doc.text.magnifyingglass",
            tint: .indigo,
            title: "More Complete Search",
            description: "In-app search now matches full URLs alongside titles, websites, notes, and folder names."
        ),
        Feature(
            systemImage: "wand.and.sparkles",
            tint: .purple,
            title: "Smarter Siri and Shortcuts",
            description: "Save links to a chosen folder, search or open Linkeeper content, and hear clear confirmations when actions finish."
        ),
        Feature(
            systemImage: "lightbulb.fill",
            tint: .orange,
            title: "More Relevant Actions",
            description: "Linkeeper can surface relevant bookmark and folder actions across the system based on how you use the app."
        ),
        Feature(
            systemImage: "square.and.arrow.up.fill",
            tint: .green,
            title: "Improved Share Extension",
            description: "Fixed an issue where some types of links might not be accepted by the Linkeeper Share Extension."
        ),
        Feature(
            systemImage: "speedometer",
            tint: .cyan,
            title: "Performance and Reliability",
            description: "Improvements throughout, especially when browsing, sorting, and selecting larger bookmark collections."
        )
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("Welcome to **Linkeeper 3.3**")
                    .font(.title)
                    .bold()
            }
            .multilineTextAlignment(.center)
            .padding()
            
            Spacer()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: features[index].systemImage)
                                .foregroundStyle(features[index].tint)
                                .font(.title)
                                .frame(width: 55)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading) {
                                Text(features[index].title)
                                    .font(.headline)
                                Text(features[index].description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .transition(.opacity)
                        .opacity(index < revealedFeatures ? 1 : 0.1)
                        .blur(radius: index < revealedFeatures ? 0 : 5)
                    }
                }
                .padding()
                .task {
                    if reduceMotion {
                        revealedFeatures = features.count
                    } else {
                        for _ in 0..<features.count {
                            withAnimation(.smooth) {
                                revealedFeatures += 1
                            }

                            do {
                                try await Task.sleep(nanoseconds: 300_000_000)
                            } catch {
                                return
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(revealedFeatures == features.count ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(.capsule)
                    .compatibleGlassEffect(.interactive, in: .capsule)
            }
            .padding()
            .buttonStyle(.plain)
            .disabled(!(revealedFeatures == features.count))
        }
    }
}

#Preview {
    WhatsNew()
}

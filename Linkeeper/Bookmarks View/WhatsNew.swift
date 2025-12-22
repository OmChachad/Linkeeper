//
//  WhatsNew.swift
//  Linkeeper
//
//  Created by Om Chachad on 7/10/25.
//

import SwiftUI

struct WhatsNew: View {
    @Environment(\.dismiss) var dismiss
    @State private var revealedFeatures: Int = 0
    
    struct Feature {
        var systemImage: String
        var title: String
        var description: String
        var isVisible: Bool = true
    }
    
    let features: [Feature] = [
        Feature(
            systemImage: "hand.tap.fill",
            title: "Tap to Open Links",
            description: "In list or table view, simply tap a bookmark to open it instantly in your browser."
        ),
        Feature(
            systemImage: "text.bubble",
            title: "Confirm Before Opening",
            description: "Avoid accidental opens by getting a quick confirmation before any link launches."
        ),
        Feature(
            systemImage: "tablecells.badge.ellipsis",
            title: "Customizable Columns",
            description: "Show or hide table view columns to match your workflow."
        ),
        Feature(
            systemImage: "checkmark.circle.fill",
            title: "Select All",
            description: "Select all your bookmarks at once to move or delete them together."
        ),
        Feature(
            systemImage: "command",
            title: "Command-Click Selection",
            description: "Hold the Command key to start selecting multiple bookmarks quickly.",
            isVisible: isMac
        ),
        Feature(
            systemImage: "square.and.arrow.up",
            title: "Enhanced Share Extension",
            description: "Improved Share Extension compatibility with App Store and other links."
        ),
        Feature(
            systemImage: "hammer.fill",
            title: "Bug fixes and improvements.",
            description: "General performance improvements and bug fixes based on user feedback."
        ),
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("Welcome to **Linkeeper 3.1**")
                    .font(.title)
                    .bold()
            }
            .multilineTextAlignment(.center)
            .padding()
            
            Spacer()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features.filter { $0.isVisible }.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: features[index].systemImage)
                                    .foregroundColor(.blue)
                                    .font(.title)
                                    .frame(width: 55)
                                
                                VStack(alignment: .leading) {
                                    Text(features[index].title)
                                        .font(.headline)
                                    Text(features[index].description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .transition(.opacity)
                            .opacity(index < revealedFeatures ? 1 : 0.1)
                            .blur(radius: index < revealedFeatures ? 0 : 5)
                    }
                }
                .padding()
                .onAppear {
                    Task {
                        for _ in 0..<features.count {
                            withAnimation(.smooth) {
                                revealedFeatures += 1
                            }
                            
                            try await Task.sleep(nanoseconds: 300_000_000)
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

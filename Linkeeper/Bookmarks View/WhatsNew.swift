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
            systemImage: "wand.and.sparkles.inverse",
            title: "Redesigned for Liquid Glass",
            description: "Bringing a carefully reconsidered yet subtle design refresh for OS 26's Liquid Glass. Stunning, yet instantly familiar."
        ),
        Feature(
            systemImage: "globe",
            title: "In-App Browser",
            description: "Break free from cluttered Safari windows with Linkeeper's in-app browser. Control behavior from Settings."
        ),
        Feature(
            systemImage: "ladybug.fill",
            title: "Bug Fixes & Improvements",
            description: "We're continuing to refine the Linkeeper experience by squashing more of those pesky bugs."
        )
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("Welcome to **Linkeeper 3.2**")
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

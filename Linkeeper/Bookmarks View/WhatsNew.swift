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
    }
    
    let features: [Feature] = [
        Feature(systemImage: "folder.fill", title: "Nested Folders", description: "You can now organize your bookmarks into nested folders."),
        Feature(systemImage: "sparkles.square.filled.on.square", title: "Refreshed UI", description: "Linkeeper's interface has now been refreshed with a more modern look and feel."),
        Feature(systemImage: "rectangle.and.pencil.and.ellipsis.rtl", title: "Custom Titles", description: "Yep, you can now set the titles of your bookmarks during creation."),
        Feature(systemImage: "apple.intelligence", title: "Ready for Apple Intelligence", description: "Linkeeper is ready for Apple Intelligence and Personal Context."),
        Feature(systemImage: "hammer.fill", title: "Bug fixes & Improvements", description: "We've listened to your feedback and made several bug fixes and improvements to the app."),
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("The biggest update to Linkeeper—yet.")
                    .font(.title)
                    .bold()
                
                Text("Welcome to **Linkeeper 3.0**")
            }
            .multilineTextAlignment(.center)
            .padding()
            
            Spacer()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features.indices, id: \.self) { index in
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

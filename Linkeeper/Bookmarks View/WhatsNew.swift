//
//  WhatsNew.swift
//  Linkeeper
//
//  Created by Om Chachad on 7/10/25.
//

import SwiftUI

struct WhatsNew: View {
    @Environment(\.dismiss) var dismiss
    
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
                    ForEach(features, id: \.title) { feature in
                        HStack {
                            Image(systemName: feature.systemImage)
                                .foregroundColor(.blue)
                                .font(.title)
                                .frame(width: 55)
                            
                            VStack(alignment: .leading) {
                                Text(feature.title)
                                    .font(.headline)
                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(.capsule)
            }
            .padding()
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    WhatsNew()
}

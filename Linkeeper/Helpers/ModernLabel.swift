//
//  ModernLabel.swift
//  Linkeeper
//
//  Created by Om Chachad on 2/18/25.
//

import SwiftUI

struct ModernLabel: View {
    var title: String
    var subtitle: String?
    var systemImage: String?
    
    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
    
    var body: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                Text(title)
                
                if let subtitle {
                    Text(subtitle)
                }
                
                if let systemImage {
                    Image(systemName: systemImage)
                }
            } else {
                if let subtitle {
                    if let systemImage {
                        Label("\(title)\n\(subtitle)", systemImage: systemImage)
                    } else {
                        Text("\(title)\n\(subtitle)")
                    }
                } else if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
        }
    }
}

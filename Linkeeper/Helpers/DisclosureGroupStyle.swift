//
//  DisclosureGroupStyle.swift
//  Linkeeper
//
//  Created by Om Chachad on 17/05/23.
//

import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct ExpandedByDefault: DisclosureGroupStyle {
    var expandByDefault: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onAppear {
                // To expand by default
                if expandByDefault {
                    configuration.isExpanded = true
                }
            }
            .onTapGesture {
                withAnimation(.default.speed(1.5)) {
                    configuration.isExpanded.toggle()
                }
            }
            if configuration.isExpanded {
                configuration.content
                    .disclosureGroupStyle(self)
                    .transition(.opacity)
            }
        }
    }
}

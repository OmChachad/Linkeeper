//
//  TextEditor.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension TextEditor {
    func placeholder(_ text: String, contents: String) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            self
                .padding(EdgeInsets(top: -8, leading: -4, bottom: -7, trailing: -4))
            if contents.isEmpty {
                HStack {
                    Text(text)
                    #if !os(macOS)
                        .foregroundColor(Color(UIColor.placeholderText))
                    #else
                        .foregroundColor(.secondary)
                    #endif
                    .allowsHitTesting(false)
                    Spacer()
                }
            }
        }
        .padding(.top, 7)
    }
}

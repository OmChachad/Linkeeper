//
//  Button + glassButtonStyle.swift
//  Linkeeper
//
//  Created by Om Chachad on 22/12/25.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func glassButtonStyle(isProminent: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if isProminent {
                self
                    .buttonStyle(.glassProminent)
            } else {
                self
                    .buttonStyle(.glass)
            }
        } else {
            self
        }
    }
}

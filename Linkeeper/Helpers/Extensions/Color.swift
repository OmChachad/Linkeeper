//
//  Color.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension Color {
    func gradientify(colorScheme: ColorScheme = .light) -> LinearGradient {
        let lightModeGradient = LinearGradient(colors: [self.opacity(0.7), self], startPoint: .top, endPoint: .bottom)
        let darkModeGradient = LinearGradient(colors: [self.opacity(1.2), self.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        
        // Return the appropriate gradient based on the color scheme
        return colorScheme == .dark ? darkModeGradient : lightModeGradient
    }
}

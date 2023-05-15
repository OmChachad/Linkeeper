//
//  Color.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension Color {
    func gradientify() -> LinearGradient {
        return LinearGradient(colors: [self.opacity(0.9), self], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
}

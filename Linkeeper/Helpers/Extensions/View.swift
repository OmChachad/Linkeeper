//
//  View.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension View {
    func glow() -> some View {
            self
                .background(self.blur(radius: 5))
    }
}

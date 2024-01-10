//
//  Shape.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import Foundation
import SwiftUI

extension Shape {
    func gradientify(with color: Color) -> some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                self
                    .fill(color.gradient)
            } else {
                self
                    .fill(color.gradientify())
            }
        }
    }
}

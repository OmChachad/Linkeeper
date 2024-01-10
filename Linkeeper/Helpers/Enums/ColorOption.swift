//
//  ColorOption.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import Foundation
import SwiftUI

enum ColorOption: String, CaseIterable {
    case gray
    case purple
    case brown
    case indigo
    case pink
    case blurple
    case orange
    case blue
    case yellow
    case cyan
    case green
    case mint
    
    #if os(macOS)
    private static var values: [ColorOption : Color] = [
        .gray : Color(.systemGray),
        .purple : Color.purple,
        .orange : Color.orange,
        .pink : Color.red,
        .yellow : Color.yellow,
        .mint : Color.mint,
        .indigo : Color.indigo,
        .green : Color.green,
        .cyan : Color.cyan,
        .brown : Color.brown,
        .blue : Color.blue,
        .blurple : Color(red: 0.5294117647, green: 0.4823529412, blue: 0.9019607843)
    ]
    #else
    private static var values: [ColorOption : Color] = [
        .gray : Color(uiColor: .systemGray),
        .purple : Color.purple,
        .orange : Color.orange,
        .pink : Color.red,
        .yellow : Color.yellow,
        .mint : Color.mint,
        .indigo : Color.indigo,
        .green : Color.green,
        .cyan : Color.cyan,
        .brown : Color.brown,
        .blue : Color.blue,
        .blurple : Color(red: 0.5294117647, green: 0.4823529412, blue: 0.9019607843)
    ]
    #endif
    
    var color: Color {
        return ColorOption.values[self] ?? .gray
    }
}

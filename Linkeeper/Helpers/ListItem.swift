//
//  ListItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 04/06/23.
//

import SwiftUI

struct ListItem: View {
    @Environment(\.colorScheme) var colorScheme
    
    var title: AttributedString
    var systemName: String
    var color: Color
    var subItemsCount: Int
    var style: Style
    
    init(title: String, systemName: String, color: Color, subItemsCount: Int, style: Style = .sidebar) {
        self.title = AttributedString(title)
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
        self.style = style
    }
    
    init(markdown: String, systemName: String, color: Color, subItemsCount: Int, style: Style = .sidebar) {
        if let data = markdown.data(using: .utf8) {
            self.title = try! AttributedString(markdown: data)
        } else {
            self.title = AttributedString(markdown)
        }
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
        self.style = style
    }
    
    enum Style {
        case sidebar
        case large
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .lineLimit(1)
                    .padding(.leading, 5)
                    #if os(macOS)
                    .padding(.leading, style == .large ? 10 : 0)
                    #endif
            } icon: {
                icon()
            }
            #if os(macOS)
            .padding(.leading, 5)
            #endif
            .padding(style == .large ? 15 : 0)
            
            Spacer()
            
            Text(String(subItemsCount))
                .foregroundColor(.secondary)
                .frame(minWidth: 15, alignment: .center)
        }
    }
    
    func icon() -> some View {
        Group {
            if style == .sidebar {
                #if os(macOS)
                Image(systemName: systemName)
                    .imageScale(.medium)
                    .padding(5)
                    .frame(width: 30, height: 30)
                #else
                Image(systemName: systemName)
                    .imageScale(.medium)
                    .padding(7.5)
                    .frame(width: 40, height: 40)
                #endif
            } else {
                Image(systemName: systemName)
                    .imageScale(.large)
                    .padding(5)
                    .frame(width: 44, height: 44)
            }
        }
        .foregroundColor(.white)
        .background(color.gradientify(colorScheme: colorScheme), in: Circle())
        .contentShape(.circle)
        .padding(5)
        .padding([.vertical, .trailing], style == .large ? 15 : 0)
        
    }
}

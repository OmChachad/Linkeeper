//
//  ListItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 04/06/23.
//

import SwiftUI

struct ListItem: View {
    var title: AttributedString
    var systemName: String
    var color: Color
    var subItemsCount: Int
    
    init(title: String, systemName: String, color: Color, subItemsCount: Int) {
        self.title = AttributedString(title)
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
    }
    
    init(markdown: String, systemName: String, color: Color, subItemsCount: Int) {
        if let data = markdown.data(using: .utf8) {
            self.title = try! AttributedString(markdown: data)
        } else {
            self.title = AttributedString(markdown)
        }
        self.systemName = systemName
        self.color = color
        self.subItemsCount = subItemsCount
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .lineLimit(1)
                    .padding(.leading, 5)
            } icon: {
                icon()
            }
            #if os(macOS)
            .padding(.leading, 5)
            #endif
            
            Spacer()
            
            Text(String(subItemsCount))
                .foregroundColor(.secondary)
                .frame(minWidth: 15, alignment: .center)
        }
    }
    
    func icon() -> some View {
        Group {
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
        }
        .foregroundColor(.white)
        .background(color, in: Circle())
        .padding(5)
    }
}

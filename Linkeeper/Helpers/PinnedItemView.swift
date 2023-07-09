//
//  PinnedItemView.swift
//  Linkeeper
//
//  Created by Om Chachad on 09/07/23.
//

import SwiftUI

struct PinnedItemView<Content: View>: View {
    var destination: Content
    var title: String
    var symbolName: String
    var tint: Color
    var count: Int
    
    @State private var isActive = false
    
    var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
    
    init(destination: Content, title: String, symbolName: String, tint: Color, count: Int) {
        self.destination = destination
        self.title = title
        self.symbolName = symbolName
        self.tint = tint
        self.count = count
    }
    
    init(destination: Content, title: String, symbolName: String, tint: Color, count: Int, isActiveByDefault: Bool) {
        self.destination = destination
        self.title = title
        self.symbolName = symbolName
        self.tint = tint
        self.count = count
        _isActive = State(initialValue: isActiveByDefault)
    }
    
    var body: some View {
        NavigationLink(destination: destination, isActive: $isActive) {
            VStack(alignment: .leading) {
                HStack {
                    icon()
                    
                    Spacer()
                    
                    Text(String(count))
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(isActive ? .white : .primary)
                }
                
                Text(title)
                    .bold()
                    .foregroundColor(isActive ? .white : .primary.opacity(0.5))
            }
            .padding(10)
            .background(isActive ? .accentColor : isMacCatalyst ? Color(uiColor: .systemGray).opacity(0.25) : Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10, style: .continuous)
        }
    }
    
    func icon() -> some View {
        Group {
            #if targetEnvironment(macCatalyst)
                Image(systemName: symbolName)
                    .imageScale(.medium)
                    .padding(5)
                    .frame(width: 27.5, height: 27.5)
            #else
                Image(systemName: symbolName)
                    .imageScale(.medium)
                    .padding(7.5)
                    .frame(width: 35, height: 35)
            #endif
        }
        .foregroundColor(.white)
        .background(tint, in: Circle())
    }
}

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
    
    var isMacCatalystOriPad: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
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
                        .foregroundColor(isMacCatalystOriPad ? (isActive ? .white : .primary) : .primary)
                }
                
                Text(title)
                    .bold()
                    .foregroundColor(isMacCatalystOriPad ? isActive ? .white : .primary.opacity(0.5) : .secondary)
            }
            .padding(10)
            .background(isMacCatalystOriPad ? (isActive ? .accentColor : Color(uiColor: .systemGray).opacity(0.25)) : Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10, style: .continuous)
        }
        .onAppear {print(isMacCatalystOriPad) }
    }
    
    func icon() -> some View {
        Image(systemName: symbolName)
            .imageScale(.medium)
            .padding(isMacCatalyst ? 5 : 7.5)
            .frame(width: isMacCatalyst ? 27.5 : 35, height: isMacCatalyst ? 27.5 : 35)
            .foregroundColor(.white)
            .background(tint, in: Circle())
    }
}

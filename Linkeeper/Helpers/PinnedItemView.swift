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
    
    var backgroundColor: Color {
        #if os(visionOS)
        return Color.clear
        #else
        if isMacCatalystOriPad {
            if isActive {
                return tint
            } else {
                return Color(uiColor: isMacCatalyst ? .systemGray : .secondarySystemGroupedBackground).opacity(isMacCatalyst ? 0.25 : 1)
            }
        } else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }
        #endif
    }
    
    var titleColor: Color {
        if isMacCatalystOriPad {
            return isActive ? .white : .primary.opacity(isMacCatalyst ? 0.75 : 0.5)
        } else {
            return .secondary
        }
    }
    
    var body: some View {
        NavigationLink(destination: destination, isActive: $isActive) {
            #if os(visionOS)
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: symbolName)
                        .imageScale(.medium)
                        .padding(7.5)
                        .frame(width: 35, height: 35)
                        .foregroundColor(isActive ? tint : .white)
                        .background(isActive ? .white : tint, in: Circle())
                    
                    Spacer()
                    
                    Text(String(count))
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(15)
            .background(isActive ? tint : .clear)
            .background(.ultraThinMaterial.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            #else
            VStack(alignment: .leading) {
                HStack {
                    icon()
                    
                    Spacer()
                    
                    Text(String(count))
                        .lineLimit(1)
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(isMacCatalystOriPad && isActive ? .white : .primary)
                }
                
                Text(title)
                    .bold()
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            }
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(10, style: .continuous)
            #endif
        }
        .buttonBorderShape(.roundedRectangle(radius: 25))
    }
    
    func icon() -> some View {
        Image(systemName: symbolName)
            .imageScale(.medium)
            .padding(isMacCatalyst ? 5 : 7.5)
            .frame(width: isMacCatalyst ? 27.5 : 35, height: isMacCatalyst ? 27.5 : 35)
            .foregroundColor(isMacCatalystOriPad && isActive ? tint : .white)
            .background(isMacCatalystOriPad && isActive ? .white : tint, in: Circle())
    }
}

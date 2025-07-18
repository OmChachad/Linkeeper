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
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isActive = false
    @Binding var isActiveStatus: Bool
    
    @State private var isTargeted = false
    
    var isMacOriPad: Bool {
        #if os(macOS)
            return true
        #else
            return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    var dropAction: (Bookmark?, URL) -> Void
    
    init(destination: Content, title: String, symbolName: String, tint: Color, count: Int, isActiveStatus: Binding<Bool> = .constant(true), onDrop dropAction: @escaping (Bookmark?, URL) -> Void = { _, _ in } ) {
        self.destination = destination
        self.title = title
        self.symbolName = symbolName
        self.tint = tint
        self.count = count
        self._isActiveStatus = isActiveStatus
        self._isActive = State(initialValue: isActiveStatus.wrappedValue)
        self.dropAction = dropAction
    }
    
    var backgroundColor: Color {
        #if os(visionOS)
        return Color.clear
        #elseif os(macOS)
        if isActive {
            return tint
        } else {
            return Color(.systemGray).opacity(0.25)
        }
        #else
        if isMacOriPad && isActive {
            return tint
        } else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }
        #endif
    }
    
    var titleColor: Color {
        if isMacOriPad {
            return isActive ? .white : .primary.opacity(isMac ? 0.75 : 0.5)
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
                        .foregroundColor(isMacOriPad && isActive ? .white : .primary)
                }
                
                Text(title)
                    .bold()
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            }
            .padding(10)
            .background(backgroundColor.gradientify(colorScheme: colorScheme))
            .cornerRadius(10, style: .continuous)
            #endif
        }
        .opacity(isTargeted ? 0.2 : 1)
        #if os(macOS)
        .buttonBorderShape(.roundedRectangle)
        #else
        .buttonBorderShape(.roundedRectangle(radius: 25))
        #endif
        .onChange(of: isActive) { new in
            isActiveStatus = isActive
        }
        .dropDestination(isTargeted: $isTargeted, onDrop: dropAction)
    }
    
    func icon() -> some View {
        Image(systemName: symbolName)
            .imageScale(.medium)
            .padding(isMac ? 5 : 7.5)
            .frame(width: isMac ? 27.5 : 35, height: isMac ? 27.5 : 35)
            .foregroundColor(isMacOriPad && isActive ? tint : .white)
            .background((isMacOriPad && isActive ? .white : tint).gradientify(colorScheme: colorScheme), in: Circle())
    }
}

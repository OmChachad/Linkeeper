//
//  CommandKeyObserver.swift
//  Linkeeper
//
//  Created by Om Chachad on 7/15/25.
//

import SwiftUI

struct CommandKeyObserver: ViewModifier {
    
    @Binding var isCommandKeyPressed: Bool
    
    func body(content: Content) -> some View {
            content
                #if os(macOS)
                .onAppear(perform: {
                    NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                        self.isCommandKeyPressed = event.modifierFlags.contains(.command)
                        return event
                    }
                })
                #endif
    }
}

extension View {
    func commandKeyObserver(isCommandKeyPressed: Binding<Bool>) -> some View {
        self
            .modifier(CommandKeyObserver(isCommandKeyPressed: isCommandKeyPressed))
    }
}

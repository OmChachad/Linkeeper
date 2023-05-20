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
    
    func miniAlert(isPresented: Binding<Bool>, icon: String, title: String) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .overlay {
                self.overlay {
                    if isPresented.wrappedValue {
                        AlertView(icon: icon, title: title)
                            .shadow(color: .black.opacity(0.25), radius: 3)
                            .padding(.bottom)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .task {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isPresented.wrappedValue = false
                                }
                            }
                    }
                }
            }
            .animation(.default, value: isPresented.wrappedValue)
    }
}

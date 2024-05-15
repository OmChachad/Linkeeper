//
//  TipRequestView.swift
//  Linkeeper
//
//  Created by Om Chachad on 11/05/24.
//

import SwiftUI

struct TipRequestView: View {
    @State private var randomMessage = "Enjoying Linkeeper's magic? A tip would be the ultimate spell of appreciation! 🪄"
    @EnvironmentObject var storeKit: Store
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
       init() {
           let messages = ["Enjoying Linkeeper's magic? A tip would be the ultimate spell of appreciation! 🪄", "A tip would be the cherry on top! 🙏🏻", "Your love for Linkeeper is clear! How about showing some love to the developer too?\nTips appreciated! ❤️", "If you're feeling appreciative, a tip would be the icing on the virtual cake (and would keep the developer happy) 😉"]
           if let message = messages.randomElement() {
               self._randomMessage = State(initialValue: message)
           }
       }
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .imageScale(.large)
            }
            .tint(.secondary)
            #if !os(macOS)
            .hoverEffect(.highlight)
            #endif
            #if os(visionOS)
            .glassBackgroundEffect(in: Circle())
            #else
            .buttonStyle(.borderless)
            .padding(5)
            .background(.thickMaterial)
            .contentShape(Circle())
            .clipShape(.circle)
            #endif
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("Looks like you are enjoying Linkeeper! 👀")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            Text(randomMessage)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            Spacer()
            
            if storeKit.tippableProducts.isEmpty {
                ProgressView()
            } else {
                VStack {
                    ForEach(storeKit.tippableProducts) { product in
                        TipItem(product: product)
                            .environmentObject(storeKit)
                    }
                }
                .padding(10)
                #if os(visionOS)
                .background(.thickMaterial)
                .cornerRadius(15, style: .continuous)
                #else
                .background(.thinMaterial)
                .cornerRadius(10, style: .continuous)
                #endif
            }
            
            Spacer()
            
            Text("OR")
                .font(.system(size: 12, weight: .thin))
                .foregroundStyle(.secondary)
            Spacer()
            
            Button {
                openURL(URL(string:"https://apps.apple.com/app/id6449708232?mt=8&action=write-review")!)
            } label: {
                Text("Write a review")
                    .foregroundColor(.white)
                    .bold()
                    .padding(isMac ? 10 : 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
            }
            .buttonStyle(.borderless)
            #if os(visionOS)
            .background(.blue)
            .clipShape(.capsule)
            .buttonBorderShape(.capsule)
            #else
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            #endif
        }.padding()
        #if os(visionOS)
        .frame(maxWidth: 600, idealHeight: 550)
        #endif
    }
}

#Preview {
    TipRequestView()
        .environmentObject(Store())
}

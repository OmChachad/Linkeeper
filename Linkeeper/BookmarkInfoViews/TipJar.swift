//
//  TipJar.swift
//  Linkeeper
//
//  Created by Om Chachad on 28/06/23.
//

import SwiftUI
import StoreKit

struct TipJar: View {
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var storeKit: Store
    
    var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
    
    var adaptedInsets: EdgeInsets? {
        isMacCatalyst ? EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10) : nil
    }
    
    var body: some View {
        Form {
            Section {
                GroupBox {
                    Text("Tipping lets me, the sole developer of Linkeeper, know that you're enjoying the app, helps sustain development and lets me keep the app 100% free for all users. Enjoy additional perks as a thank you for your support!")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("🤔 Why should I tip?")
                        .font(.title3.bold())
                        .padding(.bottom, 0.5)
                }
                
                GroupBox {
                    VStack(spacing: 5) {
                        bulletLine("Appreciate the App", systemImage: "star.fill", tint: .yellow)
                        bulletLine("Support Indie Development", systemImage: "wrench.and.screwdriver.fill", tint: .purple)
                        bulletLine("Unlock More App Icons\(isMacCatalyst ? "on iOS/iPadOS" : "")", systemImage: "square.fill", tint: .mint)
                    }
                } label: {
                    Text("All Perks")
                        .bold()
                        .padding(.bottom, 1)
                }
                .groupBoxStyle(DefaultGroupBoxStyle())
            }
            .listRowInsets(isMacCatalyst ? adaptedInsets : EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if storeKit.tippableProducts.isEmpty {
                ProgressView()
            } else {
                Section {
                    List(storeKit.tippableProducts) { product in
                        TipItem(product: product)
                            .environmentObject(storeKit)
                            .listRowInsets(adaptedInsets)
                    }
                } footer: {
                    Text("*All tips matter equally,* Thank you so much!")
                }
            }
            
            Section {
                Button {
                    openURL(URL(string:"https://apps.apple.com/app/id6449708232?mt=8&action=write-review")!)
                } label: {
                    Label("Write a Review", systemImage: "square.and.pencil")
                }
            } header: {
                Text("Can't tip? Other ways to support")
            }
        }
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func bulletLine(_ textContent: String, systemImage: String, tint: Color) -> some View {
        Label {
            Text(textContent)
        } icon: {
            Image(systemName: systemImage)
                .foregroundColor(tint)
                .frame(width: 20, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TipItem: View {
    @EnvironmentObject var storeKit: Store
    var product: Product
    
    @State private var isPurchasing = false
    
    var body: some View {
        HStack {
            Text(storeKit.emoji(for: product.id))
                .font(.largeTitle)
            
            Text(" \(product.displayName)")
                .bold()
            
            Spacer()
            
            if storeKit.isPurchased(product) {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .frame(width: 70)
            } else if isPurchasing {
                ProgressView()
            } else {
                Button(product.displayPrice) {
                    Task {
                        try? await storeKit.purchase(product)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct TipJar_Previews: PreviewProvider {
    static var previews: some View {
        TipJar()
    }
}

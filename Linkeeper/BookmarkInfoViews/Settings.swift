//
//  Settings.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("ShadowsEnabled") var shadowsEnabled = true
    @AppStorage("removeTrackingParameters") var removeTrackingParameters = false
    
    @ObservedObject var storeKit = Store.shared
    
    @State private var showingTipSheet = false
    
    var body: some View {
        #if os(macOS)
        FormContent()
            .groupedFormStyle()
        #else
        NavigationView {
            FormContent()
            .navigationTitle("Settings")
            .toolbar {
                Button("Close", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
            }
        }
        #endif
    }
    
    func FormContent() -> some View {
        Form {
            Group {
                Section("About") {
                    VStack {
                        Image("Om")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                        
                        VStack(alignment: .center) {
                            Text("Hi, I'm Om Chachad! 👋🏻")
                                .font(.title3.bold())
                            Text("I'm the developer behind Linkeeper, thanks for checking out my app. I hope you are enjoying using it!")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.secondary)
                            HStack {
                                socialLink(url: "https://www.youtube.com/TheiTE")
                                socialLink(url: "https://itecheverything.com")
                                socialLink(url: "https://twitter.com/TheOriginaliTE")
                            }
                        }
                        .multilineTextAlignment(.center)
                    }
                    
                    #if os(macOS)
                    Button {
                        showingTipSheet.toggle()
                    } label: {
                        HStack {
                            Text("🤩")
                                .font(.title)
                            Text("""
                        **Enjoying the app?**
                        Please consider tipping!
                        """)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .sheet(isPresented: $showingTipSheet) {
                        TipJar()
                            .tint(.accentColor)
                            .buttonStyle(.borderless)
                            .groupedFormStyle()
                            .environmentObject(storeKit)
                            .frame(maxWidth: 500)
                    }
                    #else
                    NavigationLink {
                        TipJar()
                            .environmentObject(storeKit)
                    } label: {
                        HStack {
                            Text("🤩")
                                .font(.title)
                            Text("""
                        **Enjoying the app?**
                        Please consider tipping!
                        """)
                        }
                    }
                    #endif
                }
                
                Section("Customisation") {
                    Toggle("Enable Shadows around Bookmarks", isOn: $shadowsEnabled)
                        .toggleStyle(.switch)
                }
                
                Section {
                    Toggle("Remove tracking parameters from URLs (Beta)", isOn: $removeTrackingParameters)
                        .toggleStyle(.switch)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Removing tracking parameters enhances privacy by reducing online tracking by stripping parameters after **?** in an URL, but it may affect website personalization on some websites.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                #if !os(macOS)
                if storeKit.userHasTipped && !isVisionOS {
                    Section {
                        NavigationLink(destination: ChangeIconsView()) {
                            Label("Change App Icon", systemImage: "square.fill")
                        }
                    } header: {
                        Text("Tipping Perks")
                    }
                }
                #endif
                
                ImportExportView()
                    .buttonStyle(.borderless)
                    .tint(.accentColor)
                
                Section("Linkeeper") {
                    HStack {
                        Text("Get in touch")
                        Spacer()
                        Text("contact@starlightapps.org")
                    }
                    
                    HStack {
                        Button("Privacy Policy") {
                            openURL(URL(string: "https://www.starlightapps.org/privacy-policy")!)
                        }
                        
                        Spacer()
                        
                        Button("Our Website") {
                            openURL(URL(string: "https://starlightapps.org")!)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .tint(.accentColor)
            }
        }
    }
    
    private func socialLink(url: String) -> some View {
        let url: URL = URL(string: url) ?? URL(string: "https://starlightapps.org")!
        
        return VStack {
            symbol(for: url)
                .padding(5)
                .padding(.horizontal, 10)
                .background(.secondary.opacity(0.15))
                .cornerRadius(20)
        }.onTapGesture {
            openURL(url)
        }
    }
    
    private func symbol(for url: URL) -> some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                switch url.host() {
                case "www.youtube.com":
                    YouTube()
                        .foregroundColor(.red)
                case "twitter.com":
                    Twitter()
                        .foregroundColor(Color(red: 0.0, green: 0.6745, blue: 0.9333))
                default:
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                }
            } else {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
            }
        }
        .frame(width: isMac ? 17.5 : 22.5, height: isMac ? 17.5 : 22.5)
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

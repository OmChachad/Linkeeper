//
//  Settings.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import SwiftUI

struct Settings: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("ShadowsEnabled") var shadowsEnabled = true
    @AppStorage("removeTrackingParameters") var removeTrackingParameters = false
    
    @ObservedObject var storeKit = Store.shared
    
    @State private var isImportingFromSafari = false
    @State private var showingImporter = false
    @State private var htmlContent = ""
    
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
        NavigationView {
            Form {
                Section("About") {
                    VStack{
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
                    .listRowInsets(adaptedInsets)
                    
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
                    .listRowInsets(adaptedInsets)
                }
                
#if targetEnvironment(macCatalyst)
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .imageScale(.large)
                            .foregroundColor(.yellow)
                        Text("**Known Issue:** To view toolbar items when inside a folder, you may need to hide the sidebar by clicking \(Image(systemName: "sidebar.leading")). This is a Mac Catalyst bug.")
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
                .listRowInsets(adaptedInsets)
#endif
                
                Section("Customisation") {
                    Toggle("Enable Shadows around Bookmarks", isOn: $shadowsEnabled)
                        .toggleStyle(.switch)
                }
                .listRowInsets(adaptedInsets)
                
                Section {
                    Toggle("Remove tracking parameters from URLs (Beta)", isOn: $removeTrackingParameters)
                        .toggleStyle(.switch)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Removing tracking parameters enhances privacy by reducing online tracking by stripping parameters after **?** in an URL, but it may affect website personalization on some websites.")
                }
                .listRowInsets(adaptedInsets)
            
                if storeKit.userHasTipped && !isMacCatalyst && !isVisionOS {
                    Section {
                        NavigationLink(destination: ChangeIconsView()) {
                            Label("Change App Icon", systemImage: "square.fill")
                        }
                    } header: {
                        Text("Tipping Perks")
                    }
                }
                
                Section("Import Bookmarks") {
                    Button("Import from Safari") {
                        isImportingFromSafari.toggle()
                    }
                    .listRowInsets(adaptedInsets)
                }
                
                
                Section("Linkeeper") {
                    HStack {
                        Text("Get in touch")
                        Spacer()
                        Text("contact@starlightapps.org")
                    }
                    .listRowInsets(adaptedInsets)
                    
                    HStack {
                        Button("Privacy Policy") {
                            openURL(URL(string: "https://www.starlightapps.org/privacy-policy")!)
                        }
                        
                        Spacer()
                        
                        Button("Our Website") {
                            openURL(URL(string: "https://starlightapps.org")!)
                        }
                    }
                    .listRowInsets(adaptedInsets)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Close", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .fileImporter(isPresented: $isImportingFromSafari, allowedContentTypes: [.html]) { result in
            do {
                let fileURL = try result.get()
                self.htmlContent = try String(contentsOf: fileURL)
                showingImporter.toggle()
            } catch {
                print("File import error: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showingImporter) {
            ImportView(htmlContents: htmlContent)
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
            if #available(iOS 16.0, *) {
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
        .frame(width: isMacCatalyst ? 17.5 : 22.5, height: isMacCatalyst ? 17.5 : 22.5)
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}

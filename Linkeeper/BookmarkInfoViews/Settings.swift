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
    
    var body: some View {
        NavigationView {
            Form {
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
                #endif
                Section("Customisation") {
                    Toggle("Enable Shadows around Bookmarks", isOn: $shadowsEnabled)
                        .toggleStyle(.switch)
                }
                
                Section("About") {
                    HStack {
                        Image("Om")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                        
                        VStack(alignment: .leading) {
                            Text("Hi, I'm Om Chachad! 👋🏻")
                                .font(.title3.bold())
                            Text("I'm the developer behind Linkeeper, thanks for checking out my app. I hope you are enjoying using it!")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    HStack {
                        Text("Get in touch")
                        Spacer()
                        Text("contact@starlightapps.org")
                    }
                }
                
                Section("Linkeeper") {
                    HStack {
                        Button("Privacy Policy") {
                            openURL(URL(string: "")!)
                        }
                        
                        Spacer()
                        
                        Button("Developer's Website") {
                            openURL(URL(string: "https://starlightapps.org")!)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Close", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}

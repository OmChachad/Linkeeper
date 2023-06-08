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
                
                Section {
                    Toggle("Remove tracking parameters from URLs", isOn: $removeTrackingParameters)
                        .toggleStyle(.switch)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Removing tracking parameters enhances privacy by reducing online tracking by stripping parameters after **?** in an URL, but it may affect website personalization on some websites.")
                }

                
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
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
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
                            openURL(URL(string: "https://www.termsfeed.com/live/1e93b5c3-6583-4028-b032-56ba480a1cf0")!)
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

//
//  ChangeIconsView.swift
//  Linkeeper
//
//  Created by Om Chachad on 28/06/23.
//

import SwiftUI

#if !os(macOS)
@available(iOS 15.0, *)
struct ChangeIconsView: View {
    let icons = ["DarkIcon"]
    let displayNames = [
        "DarkIcon": "Dark"
    ]
    
    @State private var initialised = false
    @State private var chosenIcon: String? = "AppIcon"
    @State private var showErrorAlert = false
    @State private var errorMessage = "An unknown error occured."
    
    var body: some View {
        Form {
            Picker("Choose an icon", selection: $chosenIcon) {
                iconRow("ClassicIconImage", displayName: "Classic", tag: nil)
                
                ForEach(icons, id: \.self) { icon in
                    iconRow("\(icon)Image", displayName: displayNames[icon]!, tag: icon)
                }
            }
            .pickerStyle(.inline)
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            chosenIcon = UIApplication.shared.alternateIconName ?? "AppIcon"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                initialised.toggle()
            }
        }
        .onChange(of: chosenIcon ?? "") { _ in
            setIcon(chosenIcon)
        }
        .navigationTitle("Change App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func iconRow(_ iconName: String, displayName: String, tag: String?) -> some View {
        HStack {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 65, height: 65)
                #if os(visionOS)
                .clipShape(.circle)
                #else
                .cornerRadius(13, style: .continuous)
                #endif
                .padding([.trailing, .top, .bottom], 5)
            
            Text(displayName)
            
            Spacer()
        }
        .tag(tag)
    }
    
    func setIcon(_ iconName: String?) {
        if initialised {
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error?.localizedDescription {
                    errorMessage = error
                    showErrorAlert.toggle()
                } else {
                    return
                }
            }
        }
    }
}

struct ChangeIconsView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeIconsView()
    }
}
#endif

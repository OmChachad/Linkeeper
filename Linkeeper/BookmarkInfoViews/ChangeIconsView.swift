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
    let icons = ["ClassicIcon", "DarkIcon"]
    let displayNames = [
        "ClassicIcon": "Classic",
        "DarkIcon": "Dark"
    ]
    
    @State private var initialised = false
    @State private var chosenIcon = "AppIcon"
    @State private var showErrorAlert = false
    @State private var errorMessage = "An unknown error occured."
    
    var body: some View {
        Form {
            Picker("Choose an icon", selection: $chosenIcon) {
                ForEach(icons, id: \.self) { icon in
                    HStack {
                        Image("\(icon)Image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 65, height: 65)
                            .cornerRadius(13, style: .continuous)
                            .padding([.trailing, .top, .bottom], 5)
                        
                        Text(displayNames[icon]!)
                        
                        Spacer()
                    }
                    .tag(icon)
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
        .onChange(of: chosenIcon) { newIcon in
            setIcon(newIcon)
        }
        .navigationTitle("Change App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func setIcon(_ iconName: String) {
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

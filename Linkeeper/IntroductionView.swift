//
//  IntroductionView.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import SwiftUI
import Shiny

struct IntroductionView: View {
    @Environment(\.dismiss) var dismiss
    
    var deviceOS: String {
        #if targetEnvironment(macCatalyst)
        return "macOS"
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        #endif
    }
    
    var body: some View {
        VStack {
            Spacer()
            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 5)
            Spacer()
            Text("Welcome to Linkeeper")
                .font(.system(.title))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .expandedFont()
            Text("Linkeeper is the best URL bookmarking app out there, with deep integration into \(deviceOS), iCloud Sync, extensive Siri Shortcuts actions, and a stunning user interface that makes it a joy to use and feels like home. Oh, and, it's *100% free!*")
                .multilineTextAlignment(.center)
            
            Button {
                dismiss()
            } label: {
                Text("Start Using")
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        #if !targetEnvironment(macCatalyst)
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .shiny(Gradient(colors: [
                                Color(red: 67/255, green: 183/255, blue: 253/255),
                                Color(red: 183/255, green: 33/255, blue: 223/255),
                                Color(red: 239/255, green: 169/255, blue: 40/255)
                            ]))
                        #else
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .foregroundColor(.accentColor)
                        #endif
                    }
            }
            .buttonStyle(.borderless)
            .padding()
        }
        .padding()
    }
}

private extension View {
    func expandedFont() -> some View {
        if #available(iOS 16.0, *) {
            return self
                .fontWidth(.expanded)
        } else {
            return self
        }
    }
}

struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView()
    }
}

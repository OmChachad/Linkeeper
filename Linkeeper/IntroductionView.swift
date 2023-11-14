//
//  IntroductionView.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import SwiftUI

struct IntroductionView: View {
    @Environment(\.dismiss) var dismiss
    
    var deviceOS: String {
        #if targetEnvironment(macCatalyst)
        return "macOS"
        #elseif os(visionOS)
        return "visionOS"
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        #endif
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            #if os(visionOS)
            Image("ClassicIconImage")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 100, height: 100)
                .frame(depth: 20)
                .shadow(radius: 15)
            #else
            Image("ClassicIconImage")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 5)
            #endif
            
            Spacer()
            
            Text("Welcome to Linkeeper")
                .font(.system(.title))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .expandedFont()
            
            Text("Linkeeper is the best URL bookmarking app out there, with deep integration into \(deviceOS), iCloud Sync, extensive Siri Shortcuts actions, and a stunning user interface that makes it a joy to use and feels like home. Oh, and, it's *100% free!*")
                .multilineTextAlignment(.center)
                .lineLimit(10)
                .frame(maxHeight: .infinity)
            
            Button {
                dismiss()
            } label: {
                Text("Start Using")
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        #if os(visionOS)
                        Capsule(style: .continuous)
                            .fill(LinearGradient(colors: [
                                Color(red: 67/255, green: 183/255, blue: 253/255),
                                Color(red: 183/255, green: 33/255, blue: 223/255),
                                Color(red: 239/255, green: 169/255, blue: 40/255)
                            ], startPoint: .topTrailing, endPoint: .bottomLeading))
                        #else
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(LinearGradient(colors: [
                                Color(red: 67/255, green: 183/255, blue: 253/255),
                                Color(red: 183/255, green: 33/255, blue: 223/255),
                                Color(red: 239/255, green: 169/255, blue: 40/255)
                            ], startPoint: .topTrailing, endPoint: .bottomLeading))
                        #endif
                    }
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(isVisionOS ? .capsule : .roundedRectangle(radius: 15))
        }
        .padding(30)
        .interactiveDismissDisabled()
        .frame(maxWidth: isVisionOS ? 800 : .infinity)
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
        VStack {}
            .sheet(isPresented: .constant(true), content: {
                IntroductionView()
            })
    }
}

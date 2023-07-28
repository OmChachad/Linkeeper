//
//  AlertView.swift
//  Linkeeper
//
//  Created by Om Chachad on 20/05/23.
//
import SwiftUI

struct AlertView: View {
    var icon: String
    var title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .padding()
        .background(.thickMaterial.opacity(0.9))
        .clipShape(Capsule())
        .background {
            Capsule()
                .stroke(.secondary.opacity(0.2), lineWidth: 2)
        }
        .shadow(color: .secondary.opacity(0.3), radius: 10)
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(icon: "list.and.film", title: "Playing Next")
    }
}

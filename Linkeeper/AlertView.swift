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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(icon: "list.and.film", title: "Playing Next")
    }
}

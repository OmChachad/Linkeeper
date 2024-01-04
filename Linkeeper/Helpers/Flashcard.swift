//
//  Flashcard.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import SwiftUI

struct Flashcard<Front, Back>: View where Front: View, Back: View {
    var front: () -> Front
    var back: () -> Back

    @State var flipped = false
    @Binding var editing: Bool

    @State var flashcardRotation = 0
    @State var contentRotation = 0

    init(editing: Binding<Bool>, @ViewBuilder front: @escaping () -> Front, @ViewBuilder back: @escaping () -> Back) {
        self.front = front
        self.back = back
        self._editing = editing
    }

    var body: some View {
        Group {
            if flipped {
                back()
            } else {
                front()
            }
        }
        .frame(maxWidth: 500)
        .rotation3DEffect(.degrees(Double(contentRotation)), axis: (x: 0, y: 1, z: 0))
        .padding(10)
        .rotation3DEffect(.degrees(Double(flashcardRotation)), axis: (x: 0, y: 1, z: 0))
        .onChange(of: editing) { newValue in
            flipFlashcard()
        }
    }

    func flipFlashcard() {
        let animationDuration = 0.5
        withAnimation(Animation.linear(duration: animationDuration/2)) {
            flashcardRotation += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration/2) {
            flipped.toggle()
            contentRotation += 180
            withAnimation(Animation.linear(duration: animationDuration/2)) {
                flashcardRotation += 90
            }
        }
    }
}

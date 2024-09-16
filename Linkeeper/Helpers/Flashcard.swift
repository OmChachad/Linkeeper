//
//  Flashcard.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import SwiftUI
/// Custom Flip Transition Effect: https://www.youtube.com/watch?v=hwmDFxvUCRY
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
        ZStack {
            if editing {
                back()
                    .transition(.reverseFlip)
            } else {
                front()
                    .transition(.flip)
            }
        }
        .animation(.bouncy, value: editing)
        .frame(maxWidth: 500)
        .padding(10)
    }
}

struct FlipTransition: ViewModifier, Animatable {
    var progress: CGFloat = 0
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .opacity(progress < 0 ? (-progress < 0.5 ? 1 : 0) : (progress < 0.5 ? 1 : 0))
            .rotation3DEffect(.init(degrees: progress * 180), axis: (x: 0.0, y: 1.0, z: 0.0))
    }
    
}

extension AnyTransition {
    static let flip: AnyTransition = modifier(
        active: FlipTransition (progress: -1), identity: FlipTransition()
    )
    static let reverseFlip: AnyTransition = modifier(
        active: FlipTransition (progress: 1), identity: FlipTransition())
}

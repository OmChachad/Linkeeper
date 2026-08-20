//
//  Flashcard.swift
//  Linkeeper
//
//  Created by Om Chachad on 16/05/23.
//

import SwiftUI

struct Flashcard<Front: View, Back: View>: View {
    private let front: Front
    private let back: Back

    @Binding private var editing: Bool

    init(editing: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.front = front()
        self.back = back()
        self._editing = editing
    }

    var body: some View {
        FlipAnimation(
            front: front,
            back: back,
            progress: editing ? 1 : 0
        )
        .animation(.bouncy, value: editing)
        .frame(maxWidth: 500)
        .padding(10)
    }
}

private struct FlipAnimation<Front: View, Back: View>: View, Animatable {
    let front: Front
    let back: Back
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            back
                .opacity(progress >= 0.5 ? 1 : 0)
                .rotation3DEffect(.degrees((1 - progress) * 180), axis: (x: 0, y: 1, z: 0))
                .allowsHitTesting(progress >= 0.5)
                .accessibilityHidden(progress < 0.5)

            front
                .opacity(progress < 0.5 ? 1 : 0)
                .rotation3DEffect(.degrees(progress * -180), axis: (x: 0, y: 1, z: 0))
                .allowsHitTesting(progress < 0.5)
                .accessibilityHidden(progress >= 0.5)
        }
    }
}

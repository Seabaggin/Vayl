//
//  CuriosityFlipCard.swift
//  Open Lightly
//
//  3D flip container for the curiosity picker cards.
//  Back face: CuriosityCardBack (maze + orbit).
//  Front face: caller-supplied content (pill grid).
//
//  isFlipped = false → back face visible, orbit animating
//  isFlipped = true  → front face visible, orbit stopped
//

import SwiftUI

struct CuriosityFlipCard<Content: View>: View {
    let isFlipped: Bool
    let content:   () -> Content

    var body: some View {
        ZStack {

            // ── Back face ─────────────────────────────────────────────
            // isActive stops TileOrbitView's TimelineView when face-up
            // so the Canvas does not bleed through the front face.
            CuriosityCardBack(isActive: !isFlipped)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .opacity(isFlipped ? 0 : 1)

            // ── Front face ────────────────────────────────────────────
            content()
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(AppAnimation.spring, value: isFlipped)
    }
}

// MARK: - Previews

#Preview("Back face") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityFlipCard(isFlipped: false) {
            Color.clear
        }
        .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("Front face") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityFlipCard(isFlipped: true) {
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .fill(Color(red: 0.051, green: 0.043, blue: 0.122))
                .overlay(
                    Text("Front content")
                        .foregroundStyle(AppColors.textPrimary)
                )
        }
        .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

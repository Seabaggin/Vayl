//
//  AtmosphericGhostDeck.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//


import SwiftUI

struct AtmosphericGhostDeck: View {

    // Static offsets — the two ghost cards behind the main card
    private let ghosts: [(offset: CGSize, rotation: Double, opacity: Double)] = [
        (CGSize(width: 8,  height: -10), -3.5, 0.75),
        (CGSize(width: 16, height: -20), -7.0, 0.55),
    ]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    let cardSize: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Ghost 1 — furthest back, slower drift
            ghostCard
                .offset(ghosts[0].offset)
                .offset(
                    x: drifting ? 5 : 0,
                    y: drifting ? -6 : 0
                )
                .rotationEffect(.degrees(ghosts[0].rotation + (drifting ? 1.5 : 0)))
                .opacity(colorScheme == .light ? 0.90 : ghosts[0].opacity)
                .ambientAnimation(
                    .easeInOut(duration: 8.0).repeatForever(autoreverses: true),
                    value: drifting
                )

            // Ghost 2 — closer, slightly faster drift
            ghostCard
                .offset(ghosts[1].offset)
                .offset(
                    x: drifting ? -4 : 0,
                    y: drifting ? -4 : 0
                )
                .rotationEffect(.degrees(ghosts[1].rotation + (drifting ? -1.5 : 0)))
                .opacity(colorScheme == .light ? 0.75 : ghosts[1].opacity)
                .ambientAnimation(
                    .easeInOut(duration: 9.5).repeatForever(autoreverses: true),
                    value: drifting
                )
        }
        .onAppear {
            guard !reduceMotion else { return }
            drifting = true
        }
    }

    private var ghostCard: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            Color(hex: "E8DFD0"),  // warm off-white, clear tan presence
                            Color(hex: "DEDAD0"),  // deeper, closer to the cream background
                          ]
                        : [
                            Color(red: 0.10, green: 0.09, blue: 0.23),  // deep indigo
                            Color(red: 0.07, green: 0.06, blue: 0.18),  // darker indigo
                          ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                )
            )
            .frame(width: cardSize.width, height: cardSize.height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .light
                            ? AppColors.accentSecondary.opacity(0.12)  // barely-there border, same family as card border
                            : AppColors.accentSecondary.opacity(0.38), // strong on dark
                        lineWidth: 2.5
                    )
            )
    }
}

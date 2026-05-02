//
//  CuriosityCardBack.swift
//  Open Lightly
//
//  The face-down side of each curiosity picker card.
//  Shows a laser-engraved maze texture with an embedded orbit animation.
//
//  The orbit is rendered inside MazePatternView's GeometryReader so it
//  shares the identical cx/cy coordinate origin as the maze rings.
//
//  isActive: false when the card is face-up — stops TileOrbitView's
//  TimelineView from rendering and prevents bleed-through on the front face.
//

import SwiftUI

struct CuriosityCardBack: View {
    var isActive: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {

            // ── Base fill ─────────────────────────────────────────────
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [
                                Color(red: 0.98, green: 0.97, blue: 0.96),
                                Color(red: 0.95, green: 0.93, blue: 0.91),
                              ]
                            : [
                                Color(red: 0.051, green: 0.043, blue: 0.122),
                                Color(red: 0.031, green: 0.024, blue: 0.094),
                              ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                )

            // ── Ambient center glow ───────────────────────────────────
            RadialGradient(
                colors: [
                    (isLight ? AppColors.progressBarLeading : AppColors.accentSecondary).opacity(
                        isLight ? 0.08 : 0.09
                    ),
                    Color.clear,
                ],
                center:      .center,
                startRadius: 0,
                endRadius:   44
            )
            .clipShape(RoundedRectangle(cornerRadius: CardLayout.cornerRadius))

            // ── Maze + embedded orbit ─────────────────────────────────
            // TileOrbitView lives inside MazePatternView's GeometryReader
            // so both share the exact same cx/cy — guaranteed co-centered.
            MazePatternView(
                color:         isLight ? AppColors.progressBarLeading : AppColors.accentTertiary,
                opacity:       isLight ? 0.14 : 0.16,
                glowColor:     isLight ? AppColors.progressBarLeading : .clear,
                glowOpacity:   isLight ? 0.10 : 0.0,
                orbitCount:    3,
                isOrbitActive: isActive
            )
            .padding(AppSpacing.sm)

            // ── Corner marks ──────────────────────────────────────────
            VStack {
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
                Spacer()
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
            }
            .padding(AppSpacing.md)

        } // ZStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: CardLayout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: isLight
                            ? [
                                AppColors.accentSecondary.opacity(0.40),
                                AppColors.progressBarLeading,
                                AppColors.safetyAccent,
                              ]
                            : [
                                AppColors.accentSecondary,
                                AppColors.accentPrimary,
                                AppColors.accentTertiary,
                              ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .opacity(0.65)
        )
        .shadow(
            color: isLight
                ? AppColors.progressBarLeading.opacity(0.14)
                : AppColors.accentSecondary.opacity(0.20),
            radius: 20
        )
        .shadow(color: Color.black.opacity(0.20), radius: 12, y: 6)
    }

    // MARK: - Corner mark

    private var cornerMark: some View {
        Text("✦")
            .font(AppFonts.overline)
            .foregroundStyle(
                (isLight ? AppColors.progressBarLeading : AppColors.accentSecondary)
                    .opacity(isLight ? 0.55 : 0.45)
            )
    }
}

// MARK: - Previews

#Preview("Dark — active") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityCardBack(isActive: true)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — active") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityCardBack(isActive: true)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — inactive (flipped)") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CuriosityCardBack(isActive: false)
            .frame(width: 340, height: 480)
    }
    .preferredColorScheme(.dark)
}

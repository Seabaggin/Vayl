//
//  CuriosityStatusStrip.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/30/26.
//


//
//  CuriosityStatusStrip.swift
//  Open Lightly
//
//  Panel indicator dots + selection count.
//  Sits between the card strip and the reassurance text.
//

import SwiftUI

struct CuriosityStatusStrip: View {
    let currentPanel:  Int
    let totalSelected: Int
    let isLight:       Bool
    let totalPanels:   Int = 2

    var body: some View {
        HStack(spacing: 10) {

            Spacer()

            // ── Page dots ─────────────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    let isActive = i == currentPanel
                    let dotW: CGFloat = isActive ? 28 : 8
                    let dotH: CGFloat = 8

                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                isActive
                                    ? Color.clear
                                    : (isLight
                                        ? Color.black.opacity(0.12)
                                        : Color.white.opacity(0.15))
                            )
                            .frame(width: dotW, height: dotH)

                        if isActive {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.clear)
                                .frame(width: dotW, height: dotH)
                                .overlay(
                                    Group {
                                        if isLight {
                                            LightModeShimmer(duration: 4, usePillColors: true)
                                        } else {
                                            HolographicShimmer(duration: 4)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 100))
                                )
                                .shadow(
                                    color: isLight
                                        ? AppColors.magenta.opacity(0.35)
                                        : AppColors.cyan.opacity(0.55),
                                    radius: 6
                                )
                        }
                    }
                    .frame(width: dotW, height: dotH)
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.80),
                        value: currentPanel
                    )
                }
            }

            // ── Selection count ───────────────────────────────────────
            if totalSelected > 0 {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(isLight
                            ? Color.black.opacity(0.10)
                            : Color.white.opacity(0.12))
                        .frame(width: 1, height: 10)

                    Text("\(totalSelected) selected")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightCardTitle.opacity(0.40)
                                : Color(white: 0.90)
                        )
                }
                .transition(
                    .asymmetric(
                        insertion: .offset(x: 8).combined(with: .opacity),
                        removal:   .offset(x: 8).combined(with: .opacity)
                    )
                )
            }

            Spacer()
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: totalSelected > 0)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

#Preview("Dark — panel 0, 3 selected") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CuriosityStatusStrip(currentPanel: 0, totalSelected: 3, isLight: false)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — panel 1, 0 selected") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        CuriosityStatusStrip(currentPanel: 1, totalSelected: 0, isLight: true)
    }
    .preferredColorScheme(.light)
}

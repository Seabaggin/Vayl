//
//  TabContentWrapper.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Design/Components/Navigation/TabContentWrapper.swift
// Open Lightly
//
// Wraps every tab's content with:
//   1. Bottom content inset — last item scrolls clear of the bar
//   2. Gradient fade mask — Linear-style dissolve before the bar
//   3. Scroll indicator inset — indicator doesn't run under bar
//
// Usage:
//   TabContentWrapper { YourView() }
//
// Every tab gets this automatically. No per-tab configuration needed.
// The wrapper reads safeAreaInsets from the environment — injected
// once at AppShell, available to all children without GeometryReader.

import SwiftUI

struct TabContentWrapper<Content: View>: View {
    
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let bottomInset    = geo.safeAreaInsets.bottom
            let barHeight:     CGFloat = 62
            let barOffset:     CGFloat = bottomInset + 8
            let totalClearance: CGFloat = barHeight + barOffset + 16
            let fadeHeight:    CGFloat = 120

            content
                .contentMargins(
                    .bottom,
                    totalClearance,
                    for: .scrollContent
                )
                .contentMargins(
                    .bottom,
                    barHeight + barOffset,
                    for: .scrollIndicators
                )
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(AppColors.pageBg)
                        LinearGradient(
                            stops: [
                                .init(color: .black,              location: 0.00),
                                .init(color: .black,              location: 0.15),
                                .init(color: .black.opacity(0.85), location: 0.40),
                                .init(color: .black.opacity(0.40), location: 0.70),
                                .init(color: .clear,              location: 1.00),
                            ],
                            startPoint: .top,
                            endPoint:   .bottom
                        )
                        .frame(height: fadeHeight)
                    }
                    .ignoresSafeArea()
                )
        }
    }
}

// MARK: - Preview

#Preview("Dark — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.pageBg.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBg)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15))
                                    .foregroundStyle(AppColors.textSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppColors.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }

        // Simulated bar so the fade target is visible
        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, 8)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.lightPageBg.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.lightFrostCard)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15))
                                    .foregroundStyle(AppColors.lightTextSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(AppColors.lightBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }

        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, 8)
    }
    .preferredColorScheme(.light)
}

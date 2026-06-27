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

import SwiftUI

struct TabContentWrapper<Content: View>: View {

    let content: Content

    /// Linear-style bottom dissolve where content meets the bar. ON for scrolling-list tabs
    /// so items don't hard-cut at the bar. OFF for Home, whose Lexicon is anchored at the
    /// bottom of the screen and must stay fully visible (a fade would eat its CTA).
    var fade: Bool = true

    init(fade: Bool = true, @ViewBuilder content: () -> Content) {
        self.fade = fade
        self.content = content()
    }

    // Effect-surface value: how far the dissolve rises before the bar.
    private let fadeHeight: CGFloat = 110

    @ViewBuilder
    var body: some View {
        // Bottom CLEARANCE is owned by AppShell's `.safeAreaInset(edge: .bottom)` (the bar
        // reserves its own measured height for every tab). This wrapper only adds the
        // optional dissolve. No `.ignoresSafeArea()` on the mask — it must match the inset
        // content frame so the fade lands ABOVE the bar, not behind it at the physical edge.
        if fade {
            content.mask(fadeMask)
        } else {
            content
        }
    }

    private var fadeMask: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.black)   // content above the fade: fully visible
            LinearGradient(
                stops: [
                    .init(color: .black,               location: 0.00),
                    .init(color: .black.opacity(0.85), location: 0.35),
                    .init(color: .black.opacity(0.40), location: 0.70),
                    .init(color: .clear,               location: 1.00),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: fadeHeight)
        }
    }
}

// MARK: - Preview

#Preview("Dark — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.pageBackground.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                                    .foregroundStyle(AppColors.textSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
        }

        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, AppSpacing.sm)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Scroll Test") {
    ZStack(alignment: .bottom) {
        AppColors.pageBackground.ignoresSafeArea()

        TabContentWrapper {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(AppColors.glassFrostCard)
                            .overlay(
                                Text("Item \(i + 1)")
                                    .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                                    .foregroundStyle(AppColors.textSecondary)
                            )
                            .frame(height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
        }

        RacetrackTabBar(selection: .constant(.home))
            .padding(.bottom, AppSpacing.sm)
    }
    .preferredColorScheme(.light)
}

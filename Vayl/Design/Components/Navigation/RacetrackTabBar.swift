// Design/Components/Navigation/RacetrackTabBar.swift
// Open Lightly

import SwiftUI

// MARK: - RacetrackTabBar

struct RacetrackTabBar: View {

    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme

    // ── Animation state — lifted up so bar coordinates the sequence ──────
    // Keyed by tab. Bar owns all trimEnd values so it can sequence
    // reverse (old) → forward (new) without the pills fighting each other.
    @State private var trimValues: [AppTab: CGFloat] = {
        var d = [AppTab: CGFloat]()
        AppTab.allCases.forEach { d[$0] = 0 }
        return d
    }()

    // Which tab is currently mid-animation — prevents interruption
    @State private var isAnimating: Bool = false

  var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                RacetrackTabPill(
                    tab:        tab,
                    isSelected: selection == tab,
                    trimEnd:    trimValues[tab] ?? 0
                ) {
                    guard selection != tab, !isAnimating else { return }
                    let previous = selection
                    selection = tab
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    runSequence(from: previous, to: tab)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(barBackground)
        .padding(.horizontal, 30)
        .onAppear {
            trimValues[selection] = 1.0
        }
    }

    // MARK: - Sequential animation
    
    private func runSequence(from old: AppTab, to new: AppTab) {
        let undoDuration = 0.35
        let drawDuration = 0.35
        
        // 🛠️ FIX: Instead of waiting the full 0.32s, we only wait 0.1s.
        // This means the new circle starts drawing while the old one is still erasing!
        let handoffDelay = 0.10

        isAnimating = true

        // 1. Reverse old
        withAnimation(.linear(duration: undoDuration)) {
            trimValues[old] = 0
        }

        // 2. Start the new draw ALMOST immediately, overlapping the animations
        DispatchQueue.main.asyncAfter(deadline: .now() + handoffDelay) {
            trimValues[new] = 0
            
            withAnimation(.linear(duration: drawDuration)) {
                trimValues[new] = 1.0
            }
            
            // 3. Unlock interactions once the draw is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + drawDuration) {
                isAnimating = false
            }
        }
    }

    // MARK: - Bar background

  private var barBackground: some View {
        ZStack {
            // Base fill
            Capsule()
                .fill(
                    colorScheme == .light
                        ? AnyShapeStyle(AppColors.lightFrostCard)
                        : AnyShapeStyle(AppColors.surfaceBg.opacity(0.97))
                )

            // Shimmer — more opaque so it reads on the bar
            if colorScheme == .light {
                LightModeShimmer(duration: 6.0, usePillColors: true)
                    .opacity(0.15)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            } else {
                HolographicShimmer(duration: 6.0)
                    .opacity(0.10)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            }

            // Border on top of shimmer
            Capsule()
                .strokeBorder(
                    colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.borderHover,
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.shadowDeep,
            radius: 24,
            y: -4
        )
    }
}

// MARK: - RacetrackTabPill

private struct RacetrackTabPill: View {

    let tab:        AppTab
    let isSelected: Bool
    let trimEnd:    CGFloat   // owned by bar, not pill
    let onTap:      () -> Void

    @State private var isPressed: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: onTap) {
            Image(systemName: tab.icon)
                .font(.system(size: 24, weight: .light))
                .frame(width: 24, height: 24) // Forces uniform size so circles match perfectly
                .foregroundStyle(iconColor)
                .padding(12)
                .background(pillBackground)
                .clipShape(Capsule())
                .overlay(racetrackBorder)   // outside clip so stroke isn't cut
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isSelected else { return }
                    isPressed = true
                }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(tab.label)
        .accessibilityHint(isSelected ? "Selected" : "Switch to \(tab.label)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Visual layers

    private var iconColor: Color {
        if isSelected { return isLight ? AppColors.lightCardTitle : .white }
        if isPressed  {
            return isLight
                ? AppColors.lightCardTitle
                : AppColors.textSecondary
        }
        return isLight ? AppColors.lightCardTitle.opacity(0.85) : AppColors.textPrimary
    }

    private var pillBackground: some View {
        Capsule()
            .fill(pillFill)
            .animation(.easeOut(duration: 0.25), value: isSelected)
            .animation(.easeOut(duration: 0.25), value: isPressed)
    }

    private var pillFill: Color {
        if isSelected {
            return isLight ? AppColors.lightFrostPillSel : AppColors.surfaceBg
        }
        if isPressed {
            return isLight
                ? AppColors.lightFrostPill
                : Color(red: 0.086, green: 0.079, blue: 0.141) // ~#161424 — intentional offset from cardBg (#12111A), reviewed
        }
        return .clear
    }

    private var racetrackBorder: some View {
        Capsule()
            .trim(from: 0, to: trimEnd)
            .stroke(
                AngularGradient(
                    colors: isLight
                        ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold, AppColors.magenta]
                        : [AppColors.cyan, AppColors.purple, AppColors.magenta, AppColors.pink, AppColors.cyan],
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: 3.5,     // ← was 2, now clearly visible
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            // Glow — makes the stroke pop off the dark background
            .shadow(color: isLight
                ? AppColors.magenta.opacity(0.55)
                : AppColors.cyan.opacity(0.70),
                    radius: 4, x: 0, y: 0)
    }
}
// MARK: - Previews

#Preview("Dark — Interactive") {
    @Previewable @State var selection: AppTab = .home
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack {
            Text(selection.label)
                .font(AppFonts.heroTitle)
                .foregroundStyle(AppColors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: selection)
            Spacer()
        }
        .padding(.top, 120)
        VStack {
            Spacer()
            RacetrackTabBar(selection: $selection)
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Interactive") {
    @Previewable @State var selection: AppTab = .home
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack {
            Text(selection.label)
                .font(AppFonts.heroTitle)
                .foregroundStyle(AppColors.lightTextSecondary)
                .animation(.easeInOut(duration: 0.2), value: selection)
            Spacer()
        }
        .padding(.top, 120)
        VStack {
            Spacer()
            RacetrackTabBar(selection: $selection)
                .padding(.bottom, 20)
        }
    }
    .preferredColorScheme(.light)
}

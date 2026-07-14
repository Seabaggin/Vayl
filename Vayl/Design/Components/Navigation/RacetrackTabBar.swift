// Design/Components/Navigation/RacetrackTabBar.swift
// Open Lightly

import SwiftUI

// MARK: - RacetrackTabBar

struct RacetrackTabBar: View {

    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                RacetrackTabPill(
                    tab: tab,
                    isSelected: selection == tab
                ) {
                    guard selection != tab else { return }
                    selection = tab
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(maxWidth: .infinity)
            }
        }
        // Sliding selection pill — sits behind the icons.
        // Uses .animation(_:value:) (implicit, not a withAnimation transaction).
        .background {
            GeometryReader { proxy in
                let count: CGFloat = CGFloat(AppTab.allCases.count)
                let tabW: CGFloat = proxy.size.width / count
                let idx: CGFloat = CGFloat(AppTab.allCases.firstIndex(of: selection) ?? 0)
                let pillW: CGFloat = AppSpacing.md * 2 + 26   // 58 pt
                let pillH: CGFloat = AppSpacing.sm * 2 + 26   // 42 pt
                // Selection indicator = ONE fill + ONE metal ring that GLIDE
                // together to the selected tab. Replaces four per-tab rings
                // cross-fading — one TimelineView total, and the ring travels
                // with the pill instead of dissolving/reappearing.
                ZStack {
                    Capsule()
                        .fill(AppColors.tabSelectionFill)
                    if colorScheme != .light {
                        MetalRing(
                            cornerRadius: pillH / 2,
                            lineWidth: 2.0,
                            glowOpacity: 0.28,
                            glowLineWidth: 3.5,
                            glowBlur: 4,
                            isActive: true,
                            sweepOnAppear: true,
                            // tab switch → one-shot sweep as the ring glides
                            sweepToken: AppTab.allCases.firstIndex(of: selection) ?? 0
                        )
                    }
                }
                .frame(width: pillW, height: pillH)
                .offset(
                    x: tabW * idx + (tabW - pillW) / 2,
                    y: (proxy.size.height - pillH) / 2
                )
                .animation(AppAnimation.tabSwitch, value: selection)
            }
            .allowsHitTesting(false)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.sm)
        .background(barBackground)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Bar background

    private var barBackground: some View {
        ZStack {
            // Base fill — a touch darker than the surface so the selected chip lifts.
            Capsule()
                .fill(
                    colorScheme == .light
                        ? AnyShapeStyle(AppColors.glassFrostCard)
                        : AnyShapeStyle(AppColors.tabBarFill)
                )

            // Shimmer
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
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1.5)
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.shadowPurple
                : AppColors.shadowDeep,
            radius: 24,
            y: -4
        )
    }
}

// MARK: - RacetrackTabPill

private struct RacetrackTabPill: View {

    let tab: AppTab
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        Button(action: onTap) {
            Image(systemName: tab.icon)
                .font(AppFonts.body(24, weight: .regular, relativeTo: .title3))
                .frame(width: 26, height: 26)
                .foregroundStyle(iconColor)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(pillBackground)
                .clipShape(Capsule())
                .overlay(racetrackBorder)
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
        if isSelected { return isLight ? AppColors.textBody : .white }
        if isPressed { return isLight ? AppColors.textBody : AppColors.textSecondary }
        return isLight ? AppColors.textBody.opacity(0.85) : AppColors.textPrimary
    }

    private var pillBackground: some View {
        Capsule()
            .fill(pillFill)
            .animation(AppAnimation.fast, value: isPressed)
    }

    private var pillFill: Color {
        if isPressed {
            return isLight
                ? AppColors.glassFrostPill
                : AppColors.tabSelectionFill.opacity(0.7)
        }
        return .clear
    }

    private var racetrackBorder: some View {
        // Dark (V1): the selection ring is a single sliding MetalRing in the bar
        // background, so there is no per-tab ring here (it would double up and
        // cross-fade). Light retains the warm arc per-tab (metal light deferred).
        Group {
            if isLight {
                TopAnchoredCapsule()
                    .trim(from: 0, to: 1)
                    .stroke(arcGradient, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .opacity(isSelected ? 1 : 0)
                    .animation(AppAnimation.fast, value: isSelected)
                    .shadow(color: AppColors.accentTertiary.opacity(0.55), radius: 4)
            }
        }
    }

    private var arcGradient: AngularGradient {
        AngularGradient(
            colors: isLight
                ? [
                    AppColors.accentTertiary,
                    AppColors.progressBarLeading,
                    AppColors.safetyAccent,
                    AppColors.accentTertiary
                  ]
                : [
                    AppColors.accentPrimary,
                    AppColors.accentSecondary,
                    AppColors.accentTertiary,
                    AppColors.accentTertiary,
                    AppColors.accentPrimary
                  ],
            center: .center
        )
    }
}

// MARK: - TopAnchoredCapsule

// Capsule whose path starts at top-center and sweeps clockwise.
// This lets .trim(from:0, to:trimEnd) draw CW from 12 o'clock on any
// aspect-ratio pill without rotationEffect distortion or multi-layer hacks.
private struct TopAnchoredCapsule: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        // 12 o'clock (top-center) → CW: right cap → bottom edge → left cap → close
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.midY),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: r, y: rect.maxY))
        p.addArc(
            center: CGPoint(x: r, y: rect.midY),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Previews

#Preview("Dark — Interactive") {
    @Previewable @State var selection: AppTab = .home
    GeometryReader { geo in
        let layout = AppLayout.from(geo)
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack {
                Text(selection.label)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textSecondary)
                    .animation(AppAnimation.fast, value: selection)
                Spacer()
            }
            .topClearance(layout)
            VStack {
                Spacer()
                RacetrackTabBar(selection: $selection)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Interactive") {
    @Previewable @State var selection: AppTab = .home
    GeometryReader { geo in
        let layout = AppLayout.from(geo)
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack {
                Text(selection.label)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textSecondary)
                    .animation(AppAnimation.fast, value: selection)
                Spacer()
            }
            .topClearance(layout)
            VStack {
                Spacer()
                RacetrackTabBar(selection: $selection)
                    .padding(.bottom, AppSpacing.lg)
            }
        }
    }
    .preferredColorScheme(.light)
}

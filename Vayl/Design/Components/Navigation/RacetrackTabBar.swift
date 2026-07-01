// Design/Components/Navigation/RacetrackTabBar.swift

import SwiftUI

// MARK: - RacetrackTabBar

struct RacetrackTabBar: View {

    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                OrbTabButton(
                    tab:        tab,
                    isSelected: selection == tab
                ) {
                    guard selection != tab else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = tab
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 48)
        .padding(.horizontal, AppSpacing.sm)
        .background(orbLayer)
        .background(barChrome)
        .clipShape(Capsule())
        .shadow(
            color: AppColors.shadowDeep,
            radius: 24, y: -4
        )
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Orb (clipped by Capsule above — cannot bleed outside the bar)
    // Sized to the button tap target (~slotW), not the full slot, so it reads as
    // a deliberate halo rather than a diffuse bleed into neighbouring icons.

    private var orbLayer: some View {
        GeometryReader { geo in
            let count = CGFloat(AppTab.allCases.count)
            let slotW = geo.size.width / count
            let idx   = CGFloat(AppTab.allCases.firstIndex(of: selection) ?? 0)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.accentSecondary.opacity(0.60),
                            AppColors.accentSecondary.opacity(0.22),
                            .clear
                        ],
                        center:      .center,
                        startRadius: 0,
                        endRadius:   slotW * 0.48   // soft falloff — reads as halo, not bleed
                    )
                )
                .frame(width: slotW * 1.5, height: geo.size.height * 2.2)
                .blur(radius: 10)
                .position(x: slotW * (idx + 0.5), y: geo.size.height / 2)
                .animation(AppAnimation.spring, value: selection)
        }
    }

    // MARK: - Bar chrome

    private var barChrome: some View {
        ZStack {
            Capsule()
                .fill(AppColors.modalBackground.opacity(0.97))

            if colorScheme == .dark {
                HolographicShimmer(duration: 6.0)
                    .opacity(0.10)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            } else {
                LightModeShimmer(duration: 6.0, usePillColors: true)
                    .opacity(0.15)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            }

            Capsule()
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1.5)
        }
    }
}

// MARK: - OrbTabButton

private struct OrbTabButton: View {

    let tab:        AppTab
    let isSelected: Bool
    let onTap:      () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            iconView.padding(AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in guard !isSelected else { return }; isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(AppAnimation.fast, value: isPressed)
        .accessibilityLabel(tab.label)
        .accessibilityHint(isSelected ? "Selected" : "Switch to \(tab.label)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    @ViewBuilder
    private var iconView: some View {
        if isSelected {
            Image(systemName: tab.icon)
                .font(Font.custom("Switzer-Regular", size: 22, relativeTo: .title3))
                .frame(width: 22, height: 22)
                .foregroundStyle(AppColors.textBody)
                .shadow(color: AppColors.accentSecondary.opacity(0.80), radius: 8)
        } else {
            Image(systemName: tab.icon)
                .font(Font.custom("Switzer-Regular", size: 22, relativeTo: .title3))
                .frame(width: 22, height: 22)
                .foregroundStyle(isPressed ? AppColors.textSecondary : AppColors.textTertiary)
        }
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

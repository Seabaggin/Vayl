import SwiftUI

struct ContextCard: View {
    let option: ContextOption
    let isFront: Bool
    let isConfirmed: Bool
    var index: Int = 0
    var total: Int = 3

    @State private var detailVisible = false
    @State private var isBreathing   = false
    @State private var breathTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var intensity: ContextIntensity { option.intensity }
    private var isLight:   Bool             { colorScheme == .light }

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            // Dark: cardBg flat or intensity gradient — unchanged.
            // Light: lightFrostCard (white 58%) + ultraThinMaterial so the
            //        aurora blobs bleed through the card intentionally.
            if isLight {
                RoundedRectangle(cornerRadius: AppRadius.container)
                    .fill(AppColors.glassFrostCard)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: AppRadius.container)
                    )
            } else {
                if intensity.bgTintStart < 1.0 {
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.cardBackground,           location: intensity.bgTintStart),
                            .init(color: intensity.bgTintColor,      location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                } else {
                    AppColors.cardBackground
                }
            }

            // ── Internal glow ─────────────────────────────────────────────
            // Light: opacity halved — the aurora behind the card already
            //        provides atmosphere; the internal glow would fight it.
            // Dark:  unchanged.
            if intensity.internalGlowSize > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Ellipse()
                            .fill(intensity.internalGlowColor)
                            .frame(
                                width:  intensity.internalGlowSize,
                                height: intensity.internalGlowSize
                            )
                            .blur(radius: intensity.internalGlowBlur)
                            .opacity(isLight
                                ? (isBreathing ? 0.65 : 0.50)  // halved from dark values
                                : (isBreathing ? 1.30 : 1.00)) // dark — unchanged
                            .offset(x: 20, y: -20)
                    }
                    Spacer()
                }
            }

            // ── Watermark ─────────────────────────────────────────────────
            // Replaced with TileOrbitView + position number in top-right.
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: AppSpacing.xxs) {
                        TileOrbitView(
                            orbitCount: min(index + 1, 3),
                            isActive:   isFront,
                            speed:      1.0,
                            size:       36
                        )
                        .frame(width: 36, height: 36)
                        Text(String(format: "%02d", index + 1))
                            .font(AppFonts.overline)
                            .foregroundColor(isLight
                                ? .black.opacity(isFront ? 0.85 : 0.45)
                                : .white.opacity(isFront ? 0.85 : 0.45))
                            .animation(AppAnimation.standard, value: isFront)
                    }
                    .padding(AppSpacing.md)
                }
                Spacer()
            }

            // ── Content ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(option.title)
                    .font(AppFonts.display(22, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(isLight
                        ? AppColors.textPrimary
                        : intensity.rawValue >= 4
                            ? Color.white
                            : AppColors.textPrimary)
                    Text(option.subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.textSecondary
                            : intensity.rawValue >= 4
                                ? Color.white.opacity(0.75)
                                : AppColors.textSecondary)
                }

                Spacer()

                Text(option.detail)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.textSecondary
                        : intensity.rawValue >= 4
                            ? Color.white.opacity(0.65)
                            : AppColors.textSecondary)
                    .lineSpacing(13 * 0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(detailVisible ? 1 : 0)
            }
            .padding(AppSpacing.xl)
            .frame(width: 300, height: 340, alignment: .topLeading)
        }
        .frame(width: 300, height: 340)
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.container))
        // ── Border overlay ────────────────────────────────────────────────
        // Dark:  spectrum gradient (cyan→purple→magenta).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        // Light: warmAuroraBorder (purple→magenta→gold).
        //        At rest: intensity.borderOpacity. Confirmed: full opacity.
        //        No blur overlay — blur is invisible on cream.
        .overlay(
            Group {
                if isLight {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.container)
                            .strokeBorder(
                                AppColors.spectrumBorder,
                                lineWidth: isConfirmed ? 2.5 : 2.0
                            )
                            .opacity(isConfirmed ? 1.0 : max(intensity.borderOpacity, 0.65))
                        RoundedRectangle(cornerRadius: AppRadius.container)
                            .strokeBorder(
                                AppColors.spectrumBorder,
                                lineWidth: isConfirmed ? 3.5 : 3.0
                            )
                            .blur(radius: 6)
                            .opacity(isConfirmed ? 0.35 : 0.25)
                    }
                    .shadow(color: AppColors.shadowMagenta, radius: 8,  x: 0, y: 3)
                    .shadow(color: AppColors.shadowPurple,  radius: 16, x: 0, y: 5)
                    .shadow(color: AppColors.shadowGold,    radius: 6,  x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.container)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isConfirmed ? 2 : 1.5
                        )
                        .opacity(isConfirmed ? 1.0 : intensity.borderOpacity)
                }
            }
        )
        // ── Shadows ───────────────────────────────────────────────────────
        // Dark:  intensity.shadowColor + cyan/magenta confirmed glow.
        // Light: lightShadowMagenta/Purple spread. intensity.shadowColor
        //        is a dark token so it's skipped on cream — the warm aurora
        //        shadow spread provides equivalent depth.
        .shadow(
            color: isLight
                ? AppColors.shadowMagenta.opacity(0.12)
                : intensity.shadowColor,
            radius: isLight ? 12 : intensity.shadowRadius
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.shadowMagenta
                    : AppColors.accentPrimary.opacity(isBreathing ? 0.36 : 0.30))
                : .clear,
            radius: 8
        )
        .shadow(
            color: isConfirmed
                ? (isLight
                    ? AppColors.shadowPurple
                    : AppColors.accentTertiary.opacity(isBreathing ? 0.24 : 0.20))
                : .clear,
            radius: 12
        )
        .onChange(of: isFront) { _, newFront in
            if newFront {
                withAnimation(AppAnimation.standard.delay(0.2)) { detailVisible = true }
            } else {
                withAnimation(AppAnimation.fast) { detailVisible = false }
            }
        }
        .onChange(of: isConfirmed) { _, confirmed in
            if confirmed { startBreathing() } else { stopBreathing() }
        }
        .onAppear {
            if isFront {
                withAnimation(AppAnimation.standard.delay(0.5)) { detailVisible = true }
            }
            if isConfirmed { startBreathing() }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        breathTask?.cancel()
        breathTask = Task {
            isBreathing = false
            withAnimation(AppAnimation.fast) {
                isBreathing = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.fast) {
                isBreathing = false
            }
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.fast) {
                isBreathing = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.fast) {
                isBreathing = false
            }
        }
    }

    private func stopBreathing() {
        breathTask?.cancel()
        breathTask = nil
        withAnimation(AppAnimation.fast) {
            isBreathing = false
        }
    }
}

// MARK: - Previews

private let previewOptions: [ContextOption] = [
    ContextOption(id: "single",           emotionalRegister: .flexible, intensity: .ember,   title: "I'm single",              subtitle: "No partner in the picture",       detail: "Your journey is yours alone."),
    ContextOption(id: "partnered_open",   emotionalRegister: .excited,  intensity: .spark,   title: "I have a partner",        subtitle: "They know I'm exploring",         detail: "We'll include prompts for transparency."),
    ContextOption(id: "partnered_hidden", emotionalRegister: .anxious,  intensity: .blaze,   title: "It's complicated",        subtitle: "I'm not sure how to bring it up", detail: "No pressure. We'll start with self-understanding."),
    ContextOption(id: "not_talked",       emotionalRegister: .flexible, intensity: .flame,   title: "Haven't talked about it", subtitle: "One or both of us is curious",    detail: "We'll start with the basics."),
    ContextOption(id: "some_experience",  emotionalRegister: .excited,  intensity: .inferno, title: "We've tried some things", subtitle: "Good, bad, or in between",        detail: "We'll help you process what happened."),
    ContextOption(id: "needs_reset",      emotionalRegister: .anxious,  intensity: .nova,    title: "We need a reset",         subtitle: "Something's off",                 detail: "Let's rebuild with structure and care."),
]

#Preview("All Intensities — dark") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.lg) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(AppSpacing.xxl)
    }
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("All Intensities — light") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.lg) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { i, option in
                ContextCard(
                    option:      option,
                    isFront:     true,
                    isConfirmed: false,
                    index:       i,
                    total:       previewOptions.count
                )
            }
        }
        .padding(AppSpacing.xxl)
    }
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Confirmed — dark") {
    let option = previewOptions.last!
    HStack(spacing: AppSpacing.lg) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Confirmed — light") {
    let option = previewOptions.last!
    HStack(spacing: AppSpacing.lg) {
        ContextCard(option: option, isFront: true, isConfirmed: false, index: 0, total: 3)
        ContextCard(option: option, isFront: true, isConfirmed: true, index: 0, total: 3)
    }
    .padding(AppSpacing.xxl)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

import SwiftUI

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold, relativeTo: .title2)

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Gradient Stops
    //
    // Dark: clean three-stop directional gradient.
    // accentPrimary left → accentSecondary mid → accentTertiary right.
    //
    // Light: directional warm sweep.
    // accentTertiary left → progressBarLeading mid → progressBarTrailing right.

    private var gradientStops: [Color] {
        if colorScheme == .light {
            return [
                AppColors.accentTertiary,
                AppColors.progressBarLeading,
                AppColors.progressBarTrailing,
            ]
        } else {
            return [
                AppColors.accentPrimary,
                AppColors.accentSecondary,
                AppColors.accentTertiary,
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                staticText
            } else {
                animatedText
            }
        }
        .fixedSize()
        .accessibilityLabel(text)
    }

    // Static gradient — respects color scheme.
    private var staticText: some View {
        let stops: [Color] = colorScheme == .light
            ? [AppColors.accentTertiary, AppColors.progressBarLeading, AppColors.safetyAccent]
            : [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary]
        return Text(text)
            .font(font)
            .foregroundStyle(LinearGradient(colors: stops, startPoint: .leading, endPoint: .trailing))
    }

    // Animated tri-color breathing text. Per-frame math lives in `Frame` so the
    // TimelineView closure stays trivial to type-check (was 216ms inline).
    private var animatedText: some View {
        TimelineView(.animation) { timeline in
            let f = Frame(
                elapsed: timeline.date.timeIntervalSinceReferenceDate,
                isLight: colorScheme == .light
            )
            let baseGradient = LinearGradient(colors: f.stops, startPoint: .leading, endPoint: .trailing)

            ZStack {
                // Outer bloom — wide, atmospheric.
                Text(text)
                    .font(font)
                    .foregroundStyle(baseGradient)
                    .blur(radius: f.glowBlur * 1.6)
                    .opacity(f.glowOpacity * 0.40)
                    .accessibilityHidden(true)

                // Inner glow — tighter halo ring.
                Text(text)
                    .font(font)
                    .foregroundStyle(baseGradient)
                    .blur(radius: f.glowBlur * 0.45)
                    .opacity(f.glowOpacity * 0.80)
                    .accessibilityHidden(true)

                // Primary crisp layer — full opacity, no blur.
                // Scale breath applied here only so blur layers
                // do not scale (which would spread them too wide).
                Text(text)
                    .font(font)
                    .foregroundStyle(baseGradient)
                    .scaleEffect(f.breathScale)
            }
        }
    }
}

// MARK: - LivingText per-frame values

/// Precomputed per-frame animation values for `LivingText`. Every property is an
/// explicitly-typed stored value resolved in `init`, so the type-checker handles
/// each statement independently rather than as one giant closure.
private struct Frame {
    let stops:       [Color]
    let glowBlur:    CGFloat
    let glowOpacity: Double
    let breathScale: CGFloat

    init(elapsed: TimeInterval, isLight: Bool) {
        // Glow breath — 4.3s cycle. Drives all three bloom layers in unison.
        let glowCycle: Double  = 4.3
        let glowPhase: CGFloat = CGFloat(elapsed.truncatingRemainder(dividingBy: glowCycle) / glowCycle)
        let intensity: CGFloat = CGFloat(sin(glowPhase * .pi * 2) * 0.5 + 0.5)

        // Scale breath — 5.0s cycle, independent of glow.
        let scaleCycle: Double  = 5.0
        let scalePhase: CGFloat = CGFloat(elapsed.truncatingRemainder(dividingBy: scaleCycle) / scaleCycle)
        let scaleIntensity: CGFloat = CGFloat(sin(scalePhase * .pi * 2) * 0.5 + 0.5)

        // Tri-color glow — each color blooms at a different phase.
        let cyanPhase:    CGFloat = CGFloat(elapsed / 3.0).truncatingRemainder(dividingBy: 1.0)
        let magentaPhase: CGFloat = CGFloat(elapsed / 4.0).truncatingRemainder(dividingBy: 1.0)
        let midPhase:     CGFloat = CGFloat(elapsed / 5.0).truncatingRemainder(dividingBy: 1.0)

        let cyanGlow:    CGFloat = CGFloat(sin(cyanPhase    * .pi * 2) * 0.5 + 0.5)
        let magentaGlow: CGFloat = CGFloat(sin(magentaPhase * .pi * 2) * 0.5 + 0.5)
        let midGlow:     CGFloat = CGFloat(sin(midPhase     * .pi * 2) * 0.5 + 0.5)

        // Animated gradient stops — opacity of each color breathes independently.
        self.stops = isLight
            ? [
                AppColors.accentTertiary.opacity(0.75 + cyanGlow * 0.25),
                AppColors.progressBarLeading.opacity(0.75 + midGlow * 0.25),
                AppColors.progressBarTrailing.opacity(0.75 + magentaGlow * 0.25),
              ]
            : [
                AppColors.accentPrimary.opacity(0.70 + cyanGlow * 0.30),
                AppColors.accentSecondary.opacity(0.70 + midGlow * 0.30),
                AppColors.accentTertiary.opacity(0.70 + magentaGlow * 0.30),
              ]

        self.glowOpacity = isLight
            ? 0.20 + Double(intensity) * 0.22
            : 0.28 + Double(intensity) * 0.30

        self.glowBlur = isLight
            ? 5.0 + intensity * 4.0
            : 8.0 + intensity * 7.0

        // Scale breath — 1.000 → 1.008, barely perceptible.
        self.breathScale = isLight
            ? 1.0 + scaleIntensity * 0.008
            : 1.0 + scaleIntensity * 0.010
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold, relativeTo: .largeTitle))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
            LivingText(text: "Easier",
                       font: AppFonts.screenTitle)
            LivingText(text: "You're in good company.",
                       font: AppFonts.body(20, weight: .bold, relativeTo: .title3))
        }
        .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold, relativeTo: .largeTitle))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
        }
        .padding(AppSpacing.xl)
    }
    .preferredColorScheme(.light)
}

#Preview("Against atmosphere — Dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        Ellipse()
            .fill(RadialGradient(
                colors: [
                    AppColors.accentTertiary.opacity(0.30),
                    AppColors.accentSecondary.opacity(0.15),
                    Color.clear,
                ],
                center: .top,
                startRadius: 30,
                endRadius: 360
            ))
            .frame(width: 500, height: 400)
            .offset(y: -200)
            .blur(radius: 80)
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("How are you")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                LivingText(text: "exploring?", font: AppFonts.heroTitle)
            }
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold, relativeTo: .largeTitle))
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .preferredColorScheme(.dark)
}

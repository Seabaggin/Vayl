import SwiftUI

struct LivingText: View {
    let text: String
    var font: Font = AppFonts.display(28, weight: .semibold)

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Gradient Stops
    //
    // Dark: clean three-stop directional gradient.
    // cyan left → purpleVivid mid → magenta right.
    // purpleVivid (9333EA) is bright enough to read as a
    // distinct color beat without muddying the transition.
    //
    // Light: directional warm sweep.
    // magenta left → orangeHot mid → gold right.

    private var gradientStops: [Color] {
        if colorScheme == .light {
            return [
                AppColors.magenta,
                AppColors.orangeHot,
                AppColors.gold,
            ]
        } else {
            return [
                AppColors.cyan,
                AppColors.purpleVivid,
                AppColors.magenta,
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                // Static gradient — respects color scheme.
                Text(text)
                    .font(font)
                    .foregroundStyle(LinearGradient(
                        colors: colorScheme == .light
                            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
                            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate

                    // Glow breath — 4.3s cycle.
                    // Drives all three bloom layers in unison.
                    let glowCycle = 4.3
                    let glowPhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: glowCycle)
                        / glowCycle
                    )
                    let intensity = CGFloat(sin(glowPhase * .pi * 2) * 0.5 + 0.5)

                    // Scale breath — 5.0s cycle, independent of glow.
                    // Sub-perceptual as movement but adds physical presence.
                    let scaleCycle = 5.0
                    let scalePhase = CGFloat(
                        elapsed.truncatingRemainder(dividingBy: scaleCycle)
                        / scaleCycle
                    )
                    let scaleIntensity = CGFloat(sin(scalePhase * .pi * 2) * 0.5 + 0.5)

                    // Tri-color glow — each color blooms at a different phase.
                    // On dark: cyan peaks at 0°, magenta at 120°, purple at 240°.
                    // The three glows are never in the same state simultaneously
                    // so the text always feels alive without a visible loop point.
                    let cyanPhase    = CGFloat(elapsed / 3.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let magentaPhase = CGFloat(elapsed / 4.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let midPhase     = CGFloat(elapsed / 5.0)
                        .truncatingRemainder(dividingBy: 1.0)

                    let cyanGlow    = CGFloat(sin(cyanPhase    * .pi * 2) * 0.5 + 0.5)
                    let magentaGlow = CGFloat(sin(magentaPhase * .pi * 2) * 0.5 + 0.5)
                    let midGlow     = CGFloat(sin(midPhase     * .pi * 2) * 0.5 + 0.5)

                    // Animated gradient — static stops, opacity of each color
                    // breathes independently via tri-color phase offsets.
                    let animatedStops: [Color] = colorScheme == .light
                        ? [
                            AppColors.magenta.opacity(0.75 + cyanGlow * 0.25),
                            AppColors.orangeHot.opacity(0.75 + midGlow * 0.25),
                            AppColors.gold.opacity(0.75 + magentaGlow * 0.25),
                          ]
                        : [
                            AppColors.cyan.opacity(0.70 + cyanGlow * 0.30),
                            AppColors.purpleVivid.opacity(0.70 + midGlow * 0.30),
                            AppColors.magenta.opacity(0.70 + magentaGlow * 0.30),
                          ]

                    let baseGradient = LinearGradient(
                        colors: animatedStops,
                        startPoint: .leading,
                        endPoint:   .trailing
                    )

                    let glowOpacity = colorScheme == .light
                        ? 0.20 + Double(intensity) * 0.22
                        : 0.28 + Double(intensity) * 0.30

                    let glowBlur = colorScheme == .light
                        ? 5.0 + intensity * 4.0
                        : 8.0 + intensity * 7.0

                    // Scale breath — 1.000 → 1.008, barely perceptible.
                    let breathScale = colorScheme == .light
                        ? 1.0 + scaleIntensity * 0.008
                        : 1.0 + scaleIntensity * 0.010

                    ZStack {
                        // Outer bloom — wide, atmospheric.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 1.6)
                            .opacity(glowOpacity * 0.40)
                            .accessibilityHidden(true)

                        // Inner glow — tighter halo ring.
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .blur(radius: glowBlur * 0.45)
                            .opacity(glowOpacity * 0.80)
                            .accessibilityHidden(true)

                        // Primary crisp layer — full opacity, no blur.
                        // Scale breath applied here only so blur layers
                        // do not scale (which would spread them too wide).
                        Text(text)
                            .font(font)
                            .foregroundStyle(baseGradient)
                            .scaleEffect(breathScale)
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityLabel(text)
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
            LivingText(text: "Easier",
                       font: AppFonts.screenTitle)
            LivingText(text: "You're in good company.",
                       font: AppFonts.body(20, weight: .bold))
        }
        .padding(28)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 32) {
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
            LivingText(text: "exploring?",
                       font: AppFonts.heroTitle)
            LivingText(text: "Conversations",
                       font: AppFonts.screenTitle)
        }
        .padding(28)
    }
    .preferredColorScheme(.light)
}

#Preview("Against atmosphere — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        Ellipse()
            .fill(RadialGradient(
                colors: [
                    AppColors.magenta.opacity(0.30),
                    AppColors.purple.opacity(0.15),
                    Color.clear,
                ],
                center: .top,
                startRadius: 30,
                endRadius: 360
            ))
            .frame(width: 500, height: 400)
            .offset(y: -200)
            .blur(radius: 80)
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you")
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                LivingText(text: "exploring?", font: AppFonts.heroTitle)
            }
            LivingText(text: "acquainted.",
                       font: AppFonts.display(42, weight: .bold))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .preferredColorScheme(.dark)
}

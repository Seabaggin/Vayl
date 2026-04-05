//
//  StemConfig.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/23/26.
//


// PostMapReflectionView.swift
// Open Lightly
//
// Post-Desire-Map reflection — 3 sentence stems, one per screen.
// Private, on-device only. All skippable without guilt.
//
// Tonal progression:
//   Step 1 — cyan atmosphere   — grounded, certain
//   Step 2 — purple atmosphere — open, curious
//   Step 3 — magenta atmosphere — anticipatory, outward-facing
//
// The third stem is the most commercially important.
// It builds desire for the reveal before the partner has finished.

import SwiftUI

private struct StemConfig {
    let step: Int
    let overline: String
    let stem: String            // The "___" blank is appended in the view
    let placeholder: String
    let bloomColor: Color       // Dominant atmospheric tint
    let gradient: [Color]       // Headline gradient
    let hint: String            // Subtle copy below the field
}

private let stems: [StemConfig] = [
    StemConfig(
        step: 1,
        overline: "REFLECT · 1 OF 3",
        stem: "The item I felt most certain about was",
        placeholder: "what came to mind first...",
        bloomColor: AppColors.cyan,
        gradient: [AppColors.cyan, AppColors.purple],
        hint: "Certainty is data. It tells you something about yourself."
    ),
    StemConfig(
        step: 2,
        overline: "REFLECT · 2 OF 3",
        stem: "The one that surprised me was",
        placeholder: "I didn't expect to feel...",
        bloomColor: AppColors.purple,
        gradient: [AppColors.purple, AppColors.magenta],
        hint: "Surprise is where the interesting stuff lives."
    ),
    StemConfig(
        step: 3,
        overline: "REFLECT · 3 OF 3",
        stem: "What I'm most curious about my partner's answer to is",
        placeholder: "I wonder if they feel the same about...",
        bloomColor: AppColors.magenta,
        gradient: [AppColors.magenta, AppColors.purple],
        hint: "You'll find out soon."  // Intentional forward lean
    )
]

struct PostMapReflectionView: View {
    @Binding var step: Int      // 1, 2, 3
    let onComplete: () -> Void  // All 3 done (or skipped through)
    let onSkipAll: () -> Void   // User skips entire reflection

    @Environment(\.colorScheme) private var colorScheme

    @State private var inputText     = ""
    @State private var headerVisible = false
    @State private var stemVisible   = false
    @State private var fieldVisible  = false
    @State private var skipVisible   = false
    @State private var hasAnimated   = false
    @State private var isTransitioning = false
    @FocusState private var fieldFocused: Bool

    // Persisted responses (on-device only — never synced)
    @State private var responses: [Int: String] = [:]

    private var config: StemConfig {
        stems.first(where: { $0.step == step }) ?? stems[0]
    }

    private var isLastStep: Bool { step == 3 }
    private var canAdvance: Bool { !inputText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let topPad     = max(20.0, h * 0.05)
            let sectionGap = max(20.0, h * 0.034)

            ViewThatFits(in: .vertical) {
                VStack(spacing: 0) {
                    contentBlock(h: h, sectionGap: sectionGap, topPad: topPad)
                    Spacer(minLength: 0)
                    ctaBlock
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        contentBlock(h: h, sectionGap: sectionGap, topPad: topPad)
                    }
                    ctaBlock
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: w, height: h)
            .background { backgroundLayer(w: w, h: h) }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                runEntranceAnimations()
            }
            // Tap to dismiss keyboard on scroll
            .onTapGesture { fieldFocused = false }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        h: CGFloat,
        sectionGap: CGFloat,
        topPad: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionGap) {

            // ── Overline ───────────────────────────────────────────
            Text(config.overline)
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(
                    colorScheme == .light
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.gold],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(config.bloomColor.opacity(0.9))
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            // ── Stem ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(config.stem)
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // The blank — visually part of the sentence
                Text("___")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: config.gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .opacity(stemVisible ? 1 : 0)
            .offset(y: stemVisible ? 0 : 12)

            // ── Input field ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if inputText.isEmpty {
                        Text(config.placeholder)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $inputText)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .tint(config.bloomColor)
                        .focused($fieldFocused)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .light
                            ? AppColors.lightSurfaceBg
                            : Color.white.opacity(0.05))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            fieldFocused
                                ? AnyShapeStyle(LinearGradient(
                                    colors: config.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border),
                            lineWidth: fieldFocused ? 1.5 : 1
                        )
                }
                .animation(.easeOut(duration: 0.2), value: fieldFocused)

                // Hint text
                Text(config.hint)
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .padding(.horizontal, 4)
            }
            .opacity(fieldVisible ? 1 : 0)
            .offset(y: fieldVisible ? 0 : 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, topPad)
        .padding(.bottom, 16)
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 16) {

            // Primary CTA — changes on last step
            HoloCTAButton(
                title: isLastStep ? "See my waiting state" : "Next",
                isEnabled: canAdvance
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                saveAndAdvance()
            }
            .fixedSize(horizontal: false, vertical: true)

            // Skip this one
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                skipAndAdvance()
            } label: {
                Text(isLastStep ? "Skip for now" : "Skip this one")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(skipVisible ? 1 : 0)

            OnboardingFooter(text: "Only you see this. These never leave your device.")
        }
    }

    // MARK: - Background

    private func backgroundLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if colorScheme == .light {
                AppColors.lightPageBg
            } else {
                AppColors.pageBg
            }

            if colorScheme == .dark {
                // Bloom shifts with each step — tonal progression
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            config.bloomColor.opacity(0.22),
                            config.bloomColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 340
                    ))
                    .frame(width: w * 1.4, height: h * 0.50)
                    .offset(y: -h * 0.08)
                    .blur(radius: 80)
                    .animation(.easeInOut(duration: 0.8), value: step)
            }

            if colorScheme == .light {
                AuroraGlowField()
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation

    private func saveAndAdvance() {
        responses[step] = inputText.trimmingCharacters(in: .whitespaces)
        // TODO: persist to SwiftData SoloReflectionEntry or equivalent
        advance()
    }

    private func skipAndAdvance() {
        responses[step] = "" // Explicit skip — empty string not nil
        advance()
    }

    private func advance() {
        guard !isTransitioning else { return }
        isTransitioning = true
        fieldFocused = false

        if isLastStep {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onComplete()
            }
        } else {
            // Cross-fade to next stem
            withAnimation(.easeInOut(duration: 0.35)) {
                headerVisible = false
                stemVisible   = false
                fieldVisible  = false
                skipVisible   = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                step      += 1
                inputText  = ""
                hasAnimated = false
                isTransitioning = false
                runEntranceAnimations()
            }
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) { headerVisible = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { stemVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.40)) { fieldVisible  = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.60)) { skipVisible   = true }

        // Auto-focus field after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            fieldFocused = true
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Dark") {
    @Previewable @State var step = 1
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 2 — Dark") {
    @Previewable @State var step = 2
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 3 — Dark") {
    @Previewable @State var step = 3
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.dark)
}

#Preview("Step 1 — Light") {
    @Previewable @State var step = 1
    PostMapReflectionView(step: $step, onComplete: {}, onSkipAll: {})
        .preferredColorScheme(.light)
}

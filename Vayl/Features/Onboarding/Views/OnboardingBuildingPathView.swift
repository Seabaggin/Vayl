// Features/Onboarding/Views/OnboardingBuildingPathView.swift
//
// REVISION 3 — fixes persistent rightward layout offset.
//
// ROOT CAUSE (correct diagnosis):
//
// Revisions 1 and 2 correctly identified that .ignoresSafeArea() children
// were involved, but applied the wrong fix (.frame on the ZStack). The
// actual mechanism: when multiple children inside a ZStack use
// .ignoresSafeArea(), the ZStack computes its internal alignment origin
// from the UNION of all children's frames — including safe-area-extended
// frames. This shifts the alignment center rightward (and/or downward),
// dragging all content with it. .frame(width:height:) on the ZStack only
// constrains its external reported size; it does NOT override the internal
// alignment computation.
//
// FIX:
//
// All .ignoresSafeArea() layers (pageBg, atmosphere, OnboardingGlowField,
// fade overlay) are moved OUT of the ZStack into .background() and
// .overlay() modifiers. These modifiers render content behind/above the
// ZStack respectively but do NOT participate in the ZStack's alignment
// computation. The ZStack now contains ONLY non-ignoresSafeArea children
// (fragmentLayer, mainContent, skipAffordance, accessibility overlay),
// so its alignment origin is the true center of its frame.
//
// fragmentLayer()'s .ignoresSafeArea() is also removed — it was
// unnecessary since the parent ZStack already covers the full screen
// via the outer GeometryReader's .ignoresSafeArea().
//
// All BUG-1 through BUG-7 and R-BUG-1 through R-BUG-3 fixes from
// prior revisions are preserved where still applicable.

import SwiftUI

// MARK: - Supporting Types

private enum BPIndicatorState: Equatable {
    case pending
    case processing
    case complete
}

private struct BPBuildItem {
    let category: String
    let resolved: String
}

private struct BPFragmentState {
    var visible: Bool = false
    var fading:  Bool = false
}

// MARK: - Main View

struct OnboardingBuildingPathView: View {
    @Binding var data: OnboardingData
    var onFinished: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    @State private var hasAnimated        = false
    @State private var atmosphericVisible = false
    @State private var glowPeak           = false
    @State private var overlabelVisible   = false
    @State private var nameVisible        = false
    @State private var taglineVisible     = false

    @State private var indicatorStates: [BPIndicatorState] = [
        .pending, .pending, .pending, .pending
    ]
    @State private var fragmentStates: [BPFragmentState] = [
        BPFragmentState(), BPFragmentState(), BPFragmentState()
    ]

    @State private var itemsFadingOut   = false
    @State private var fadeOutVisible   = false
    @State private var autoAdvanceFired = false
    @State private var skipAvailable    = false
    @State private var skipVisible      = false

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Physical top safe-area inset (Dynamic Island / notch / status bar)
    /// read directly from the UIKit key window.
    ///
    /// geo.safeAreaInsets.top returns 0 in this view because the outer
    /// GeometryReader uses .ignoresSafeArea() — which zeroes the proxy's
    /// inset values. The UIKit window always reports the true physical
    /// insets regardless of SwiftUI's modifier chain.
    private var deviceTopInset: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })
                    as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.safeAreaInsets.top
    }

    /// Physical bottom safe-area inset (home indicator) read from UIKit
    /// key window. Same reasoning as deviceTopInset — geo.safeAreaInsets
    /// returns 0 in this view due to .ignoresSafeArea() on the outer reader.
    private var deviceBottomInset: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })
                    as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.safeAreaInsets.bottom
    }

    // MARK: - Computed: Build Items

    private var resolvedBuildItems: [BPBuildItem] {
        [
            BPBuildItem(category: "Starting point",     resolved: stageLabel),
            BPBuildItem(category: "Your situation",     resolved: contextLabel),
            BPBuildItem(category: "First to explore",   resolved: goalsLabel),
            BPBuildItem(category: "How you'll explore", resolved: modeLabel),
        ]
    }

    private var stageLabel: String {
        switch data.nmStage {
        case .curious:     return "Beginning from curiosity"
        case .exploring:   return "Building on what you've tried"
        case .experienced: return "Starting from experience"
        default:           return "Your starting point"
        }
    }

    private var contextLabel: String {
        "Your situation" // TODO: derive from emotionalRegister when OnboardingData field is added
    }

    private var goalsLabel: String {
        let source = data.communicationGoals.first(where: { !$0.isEmpty })
            ?? data.learningGoals.first(where: { !$0.isEmpty })
        guard let s = source else { return "What you want to explore" }
        let phrase = CuriosityScreenConfig.leadPhrase(for: s)
        return phrase.count > 32 ? String(phrase.prefix(32)) + "…" : phrase
    }

    private var modeLabel: String {
        switch data.appMode {
        case .solo:     return "At your own pace"
        case .together: return "Together, step by step"
        default:        return "Your conversation style"
        }
    }

    // MARK: - Computed: Fragments

    private var stageFragment: String {
        switch data.nmStage {
        case .curious:     return "Starting fresh"
        case .exploring:   return "Building on what you know"
        case .experienced: return "Going deeper"
        default:           return "Starting fresh"
        }
    }

    private var contextFragment: String? {
        nil // TODO: derive from emotionalRegister when OnboardingData field is added
    }

    // R-BUG-3 FIX: Fragment strings are kept short (≤20 chars) so they
    // never exceed their capped frame width and bleed off-screen.
    private var selectionFragment: String? {
        let source = data.communicationGoals.first(where: { !$0.isEmpty })
            ?? data.learningGoals.first(where: { !$0.isEmpty })
        guard let s = source else { return nil }
        let phrase = CuriosityScreenConfig.leadPhrase(for: s)
        return phrase.count > 20 ? String(phrase.prefix(20)) + "…" : phrase
    }

    // MARK: - Computed: Personalization

    private var trimmedName: String {
        data.displayName.trimmingCharacters(in: .whitespaces)
    }

    private var hasPersonalName: Bool { !trimmedName.isEmpty }

    private var exitLine: String {
        hasPersonalName
            ? "\(trimmedName), here's your first step."
            : "Here's where you begin."
    }

    // MARK: - Accessibility

    private var accessibilitySummary: String {
        let items = resolvedBuildItems
        let owner = hasPersonalName ? "\(trimmedName)'s" : "your"
        return "Building \(owner) path. " +
               "Assembling \(items[0].resolved), " +
               "\(items[1].resolved), " +
               "\(items[2].resolved), " +
               "and \(items[3].resolved). " +
               exitLine
    }

    // MARK: - Helpers

    private func cacheSize(_ size: CGSize) {
        guard screenW != size.width || screenH != size.height else { return }
        DispatchQueue.main.async {
            screenW = size.width
            screenH = size.height
        }
    }

    private func schedule(_ seconds: Double, _ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
    }

    private func deriveDefaultDifficulty() {
        // defaultDifficulty is now a computed property derived from nmStage.
        // This function is kept for future use if additional logic is needed.
    }

    private func completeAndAdvance() {
        guard !autoAdvanceFired else { return }
        autoAdvanceFired = true
        deriveDefaultDifficulty()
        #if DEBUG
        assert(
            onFinished != nil,
            "OnboardingBuildingPathView: onFinished not injected."
        )
        #endif
        onFinished?()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let _ = cacheSize(geo.size)
            // geo.safeAreaInsets.top is ZERO here because
            // .ignoresSafeArea() on the GeometryReader zeroes the
            // proxy's inset values. Read the real physical inset
            // from the UIKit key window instead.
            let topInset = deviceTopInset

            ZStack {
                // ── Floating fragments ───────────────────────────
                fragmentLayer(topInset: topInset)

                // ── Main content ─────────────────────────────────
                mainContent(topInset: topInset)

                // ── Skip affordance ──────────────────────────────
                skipAffordance()

                // ── VoiceOver overlay ────────────────────────────
                Text(accessibilitySummary)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityLabel(accessibilitySummary)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // LAYOUT FIX: Atmospheric layers (.ignoresSafeArea()) are
            // moved to .background() so they cannot distort the ZStack's
            // internal alignment origin.
            .background(
                ZStack {
                    (colorScheme == .dark
                        ? AppColors.pageBackground
                        : AppColors.pageBackground)
                    atmosphere()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    OnboardingGlowField()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea()
            )
            // LAYOUT FIX: Fade overlay isolated via .overlay() for the
            // same reason — its .ignoresSafeArea() must not participate
            // in ZStack alignment.
            .overlay(
                (colorScheme == .dark
                    ? AppColors.pageBackground
                    : AppColors.pageBackground)
                    .opacity(fadeOutVisible ? 1 : 0)
                    .animation(AppAnimation.enter, value: fadeOutVisible)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            )
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { handleSkip() }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAnimation()
        }
    }

    // MARK: - Skip

    private func handleSkip() {
        guard skipAvailable, !autoAdvanceFired else { return }
        autoAdvanceFired = true
        deriveDefaultDifficulty()
        withAnimation(AppAnimation.fast) { fadeOutVisible = true }
        schedule(0.30) { onFinished?() }
    }

    @ViewBuilder
    private func skipAffordance() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if skipVisible {
                    Text("Continue →")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .dark
                            ? AppColors.textTertiary
                            : AppColors.textTertiary)
                        .opacity(0.55)
                        .padding(.trailing, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                        .transition(.opacity)
                        .accessibilityLabel("Skip loading and continue")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
        .animation(AppAnimation.enter, value: skipVisible)
        .allowsHitTesting(skipAvailable)
    }

    // MARK: - Fragment Layer
    //
    // topInset: the physical top safe-area inset from UIKit's key window.
    //
    // fullH = geo.size.height + topInset reconstructs the physical screen
    // height from live geometry on every frame (unlike the @State screenH
    // which may hold its initial value of 852 on the first render frame).

    @ViewBuilder
    private func fragmentLayer(topInset: CGFloat) -> some View {
        GeometryReader { geo in
            let fullH        = geo.size.height + topInset
            let midX         = geo.size.width / 2
            let midY         = (fullH / 2) - topInset
            let fragmentMaxW = geo.size.width / 2 - 24

            ZStack {
                // Fragment 0 — stage — upper left of center
                BPFloatingFragment(
                    text:          stageFragment,
                    targetOpacity: 0.60,
                    isVisible:     fragmentStates[0].visible,
                    isFading:      fragmentStates[0].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX - screenW * 0.22,
                    y: midY - fullH * 0.28 + topInset
                )

                // Fragment 1 — context — upper right of center
                if let f1 = contextFragment {
                    BPFloatingFragment(
                        text:          f1,
                        targetOpacity: 0.55,
                        isVisible:     fragmentStates[1].visible,
                        isFading:      fragmentStates[1].fading
                    )
                    .frame(maxWidth: fragmentMaxW)
                    .position(
                        x: midX + screenW * 0.22,
                        y: midY - fullH * 0.32 + topInset
                    )
                }

                // Fragment 2 — selection — centered above name
                if let f2 = selectionFragment {
                    BPFloatingFragment(
                        text:          f2,
                        targetOpacity: 0.50,
                        isVisible:     fragmentStates[2].visible,
                        isFading:      fragmentStates[2].fading
                    )
                    .frame(maxWidth: fragmentMaxW)
                    .position(
                        x: midX,
                        y: midY - fullH * 0.38 + topInset
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Main Content
    //
    // topInset: physical top safe-area inset from UIKit key window.
    // See deviceTopInset / deviceBottomInset for why UIKit is used
    // instead of geo.safeAreaInsets.

    @ViewBuilder
    private func mainContent(topInset: CGFloat) -> some View {
        let completeCount = indicatorStates.filter { $0 == .complete }.count

        VStack(alignment: .center, spacing: 0) {

            OnboardingProgressBar(
                currentStep: completeCount,
                totalSteps:  5
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, topInset + OL.progressTop(screenH))
            .padding(.bottom, OL.progressBottom(screenH))
            .accessibilityHidden(true)

            Spacer()

            // Overline — BUG-3 FIX retained
            // Duration 1.0s — intentional above-ceiling exception.
            // This is a cinematic sequence reveal, not a UI response animation.
            Text("BUILDING YOUR PATH")
                .font(AppFonts.overline)
                .foregroundStyle(colorScheme == .dark
                    ? LinearGradient(
                        colors: [AppColors.accentSecondary, AppColors.accentTertiary],
                        startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(stops: [
                        .init(color: AppColors.accentTertiary, location: 0.00),
                        .init(color: AppColors.accentTertiary, location: 0.45),
                        .init(color: AppColors.safetyAccent,   location: 1.00),
                      ],
                      startPoint: .leading, endPoint: .trailing))
                .tracking(2.5)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(overlabelVisible ? 1 : 0)
                .offset(y: overlabelVisible ? 0 : 8)
                .animation(.easeOut(duration: 1.0), value: overlabelVisible)
                .padding(.bottom, AppSpacing.sm)
                .accessibilityHidden(true)

            // Name headline — BUG-1 downstream fix retained
            // Duration 1.2s — intentional above-ceiling exception.
            // Name reveal has ceremony — slower than AppAnimation.slow (0.5s).
            nameHeadline
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(nameVisible ? 1 : 0)
                .offset(y: nameVisible ? 0 : 14)
                .animation(.easeOut(duration: AppAnimation.cinematic), value: nameVisible)
                .padding(.bottom, OL.loose(screenH))
                .accessibilityHidden(true)

            // Build item list — BUG-1 FIX retained: no .fixedSize(horizontal:)
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(Array(resolvedBuildItems.enumerated()), id: \.offset) { i, item in
                    BPBuildItemRow(
                        item:           item,
                        indicatorState: indicatorStates[i],
                        isVisible:      indicatorStates[i] != .pending && !itemsFadingOut,
                        isComplete:     indicatorStates[i] == .complete && !itemsFadingOut
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityHidden(true)

            // Exit tagline — BUG-5 FIX retained
            // Duration 1.2s — intentional above-ceiling exception.
            // Exit line reveal matches name reveal weight intentionally.
            Text(exitLine)
                .font(AppFonts.body(18, weight: .medium, relativeTo: .body))
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.textBody)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(taglineVisible ? 1 : 0)
                .offset(y: taglineVisible ? 0 : 10)
                .animation(.easeOut(duration: AppAnimation.cinematic), value: taglineVisible)
                .padding(.top, OL.loose(screenH))
                .accessibilityHidden(true)

            // BUG-7 FIX retained: home indicator clearance.
            // deviceBottomInset reads UIKit window safe area — same
            // pattern as deviceTopInset. geo.safeAreaInsets.bottom is
            // zeroed here due to .ignoresSafeArea() on the outer reader.
            Spacer(minLength: deviceBottomInset + AppSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // BUG-6 FIX retained: single source of horizontal inset.
        // AppSpacing.xl (32pt) replaces hardcoded 36pt — nearest token.
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Name Headline

    @ViewBuilder
    private var nameHeadline: some View {
        if hasPersonalName {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(trimmedName)
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.textPrimary
                        : AppColors.textBody)
                Text(".")
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.spectrumBorder
                        : AppColors.spectrumBorder)
            }
            .font(AppFonts.heroTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        } else {
            Text("Your path.")
                .font(AppFonts.heroTitle)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.textBody)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    // MARK: - Atmospheric Layer
    //
    // Dark:  cool spectrum — purple / cyan / magenta orbs
    // Light: warm aurora  — purple / gold / magenta orbs (no cyan)
    //
    // All .easeInOut(duration: 2.0) transitions are one-time state reveals
    // triggered from the animation sequence — not ambient loops.
    // AppAnimation.slow (0.5s) is the nearest token but 2.0s is intentionally
    // slower to give the atmosphere weight. Documented as intentional exception.

    private var atmosAccent: Color {
        colorScheme == .dark ? AppColors.accentPrimary : AppColors.safetyAccent
    }

    private func atmosphere() -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.accentSecondary.opacity(0.40),
                             atmosAccent.opacity(0.20),
                             Color.clear],
                    center: .top, startRadius: 30, endRadius: 380))
                .frame(width: OL.atmosW(screenW), height: OL.atmosH(screenH))
                .offset(y: -screenH * 0.42)
                .blur(radius: 90)
                .opacity(atmosphericVisible ? 1 : 0)
                // 2.0s — intentional atmospheric weight, above AppAnimation.slow ceiling.
                .animation(.easeInOut(duration: 2.0), value: atmosphericVisible)

            Ellipse()
                .fill(atmosAccent.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 55)
                .offset(x: -screenW * 0.32, y: -screenH * 0.22)
                .opacity(glowPeak ? 0.90 : 0.40)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Ellipse()
                .fill(AppColors.accentTertiary.opacity(0.10))
                .frame(width: 140, height: 140)
                .blur(radius: 50)
                .offset(x: screenW * 0.32, y: -screenH * 0.26)
                .opacity(glowPeak ? 0.85 : 0.28)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Ellipse()
                .fill(AppColors.accentSecondary.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .opacity(glowPeak ? 1.00 : 0.45)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Ellipse()
                .fill(atmosAccent.opacity(0.08))
                .frame(width: 110, height: 110)
                .blur(radius: 42)
                .offset(x: -screenW * 0.38, y: screenH * 0.22)
                .opacity(glowPeak ? 0.75 : 0.18)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Ellipse()
                .fill(AppColors.accentTertiary.opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 60)
                .offset(x: screenW * 0.38, y: screenH * 0.18)
                .opacity(glowPeak ? 0.85 : 0.22)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.accentSecondary.opacity(0.18),
                             atmosAccent.opacity(0.10),
                             Color.clear],
                    center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .scaleEffect(glowPeak ? 1.0 : 0.36)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)

            Rectangle()
                .fill(LinearGradient(
                    colors: [AppColors.accentSecondary.opacity(0.10), Color.clear],
                    startPoint: .bottom, endPoint: .top))
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(glowPeak ? 1.0 : 0)
                .animation(.easeInOut(duration: 2.0), value: glowPeak)
        }
        .drawingGroup()
    }

    // MARK: - Animation
    //
    // SEQUENCE TIMING ARCHITECTURE — read before modifying:
    //
    // All withAnimation durations inside startFullAnimation are part of a
    // precisely timed choreographed build sequence. They are NOT UI response
    // animations and must NOT be migrated to AppAnimation tokens.
    //
    // The `k` multiplier in the #if DEBUG preview path is the reduce-motion
    // and preview-speed mechanism. k=0.4 maps the 0s–4.6s device sequence
    // into ~0s–1.85s in the preview canvas. The multiplier applies to both
    // schedule() offsets and withAnimation() durations — preserving the
    // relative timing ratios exactly.
    //
    // Documented intentional exceptions in this function:
    // - All easeOut/easeIn/easeInOut durations: 0.4, 0.7, 0.8, 0.9, 1.2, 1.4, 1.6
    // - These are sequence timing values, not token candidates

    private func startAnimation() {
        if reduceMotion { startReducedMotionAnimation(); return }
        schedule(0.15) { startFullAnimation() }
    }

    private func startReducedMotionAnimation() {
        overlabelVisible = true
        nameVisible      = true
        indicatorStates  = [.complete, .complete, .complete, .complete]
        taglineVisible   = true
        schedule(2.00) { completeAndAdvance() }
    }

    private func startFullAnimation() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview-fast path: same sequence as below at 0.4× wall-clock time.
            // k multiplier applies to both schedule() offsets and withAnimation()
            // durations — preserving relative timing ratios exactly.
            // Do NOT replace any duration with an AppAnimation token here —
            // the k multiplication is the mechanism that makes previews legible.
            let k = 0.4
            schedule(0.00 * k) {
                withAnimation(.easeInOut(duration: 1.6 * k)) { atmosphericVisible = true }
            }
            schedule(0.00 * k) {
                withAnimation(.easeOut(duration: 0.8 * k)) { overlabelVisible = true }
            }
            schedule(0.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[0].visible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { nameVisible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[0] = .processing }
            }
            schedule(0.70 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[1] = .processing }
            }
            schedule(1.00 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[2] = .processing }
            }
            schedule(1.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[1].visible = true }
            }
            schedule(1.30 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[3] = .processing }
            }
            schedule(1.50 * k) { skipAvailable = true }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.4 * k)) { skipVisible = true }
            }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[0].fading = true }
            }
            schedule(1.90 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[0] = .complete }
            }
            schedule(2.00 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[2].visible = true }
            }
            schedule(2.20 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[1] = .complete }
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[1].fading = true }
            }
            schedule(2.50 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[2] = .complete }
            }
            schedule(2.80 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[3] = .complete }
                withAnimation(.easeInOut(duration: 1.4 * k)) { glowPeak = true }
            }
            schedule(2.90 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[2].fading = true }
            }
            schedule(3.20 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { taglineVisible = true }
            }
            // Do NOT auto-advance in preview — leave the final state on screen.
            return
        }
        #endif

        // ── Real-device timing ────────────────────────────────────────────
        // All durations below are choreographed sequence timing values.
        // They are intentional exceptions — do not migrate to AppAnimation tokens.
        schedule(0.00) {
            withAnimation(.easeInOut(duration: 1.6)) { atmosphericVisible = true }
        }
        schedule(0.00) {
            withAnimation(.easeOut(duration: 0.8)) { overlabelVisible = true }
        }
        schedule(0.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[0].visible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.9)) { nameVisible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[0] = .processing }
        }
        schedule(0.70) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[1] = .processing }
        }
        schedule(1.00) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[2] = .processing }
        }
        schedule(1.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[1].visible = true }
        }
        schedule(1.30) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[3] = .processing }
        }
        schedule(1.50) { skipAvailable = true }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.4)) { skipVisible = true }
        }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[0].fading = true }
        }
        schedule(1.90) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[0] = .complete }
        }
        schedule(2.00) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[2].visible = true }
        }
        schedule(2.20) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[1] = .complete }
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[1].fading = true }
        }
        schedule(2.50) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[2] = .complete }
        }
        schedule(2.80) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[3] = .complete }
            withAnimation(.easeInOut(duration: 1.4)) { glowPeak = true }
        }
        schedule(2.90) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[2].fading = true }
        }
        schedule(3.20) {
            withAnimation(.easeOut(duration: 0.9)) { taglineVisible = true }
        }
        schedule(3.80) {
            withAnimation(.easeIn(duration: 0.4)) {
                overlabelVisible = false
                nameVisible      = false
                itemsFadingOut   = true
            }
        }
        schedule(3.90) {
            withAnimation(.easeIn(duration: 0.4)) { taglineVisible = false }
        }
        schedule(4.20) {
            withAnimation(.easeIn(duration: 0.3)) { fadeOutVisible = true }
        }
        schedule(4.60) { completeAndAdvance() }
    }
}

// MARK: - BPBuildItemRow
// BUG-4 + BUG-6 fixes retained.

private struct BPBuildItemRow: View {
    let item:           BPBuildItem
    let indicatorState: BPIndicatorState
    let isVisible:      Bool
    let isComplete:     Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Fixed-size indicator — never grows
            BPOrbitIndicator(state: indicatorState)
                .fixedSize()

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.category.uppercased())
                    .font(AppFonts.overline)
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.textTertiary
                        : AppColors.textBody.opacity(0.40))
                    .tracking(1.5)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(item.resolved)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isComplete
                        ? (colorScheme == .dark ? AppColors.textPrimary : AppColors.textBody)
                        : (colorScheme == .dark ? AppColors.textSecondary : AppColors.textBody.opacity(0.55)))
                    .animation(AppAnimation.slow, value: isComplete)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(AppAnimation.slow, value: isVisible)
    }
}

// MARK: - BPOrbitIndicator

private struct BPOrbitIndicator: View {
    let state: BPIndicatorState
    private let size: CGFloat = 22

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1.5)
                .opacity(state == .pending ? 1 : 0)
                .animation(AppAnimation.standard, value: state == .pending)

            if state == .processing {
                BPOrbitCanvas(size: size, colorScheme: colorScheme)
                    .transition(.opacity)
            }

            Circle()
                .fill(LinearGradient(
                    colors: colorScheme == .dark
                        ? [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary]
                        : [AppColors.accentSecondary, AppColors.accentTertiary, AppColors.safetyAccent],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .opacity(state == .complete ? 1 : 0)
                .animation(AppAnimation.slow, value: state == .complete)
                .shadow(
                    color: colorScheme == .dark
                        ? AppColors.accentPrimary : AppColors.shadowPurple,
                    radius: colorScheme == .dark ? 12 : 7)
                .shadow(
                    color: colorScheme == .dark
                        ? AppColors.accentTertiary : AppColors.shadowMagenta,
                    radius: colorScheme == .dark ? 24 : 14)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - BPOrbitCanvas (unchanged — Canvas drawing math)

private struct BPOrbitCanvas: View {
    let size: CGFloat
    let colorScheme: ColorScheme
    private let revolutionDuration: TimeInterval = 1.4

    private var primaryRGB:   (r: Double, g: Double, b: Double) {
        components(of: colorScheme == .dark ? AppColors.accentPrimary : AppColors.accentSecondary)
    }
    private var secondaryRGB: (r: Double, g: Double, b: Double) {
        components(of: colorScheme == .dark ? AppColors.accentSecondary : AppColors.accentTertiary)
    }
    private var tertiaryRGB:  (r: Double, g: Double, b: Double) {
        components(of: colorScheme == .dark ? AppColors.accentTertiary : AppColors.safetyAccent)
    }

    var body: some View {
        let pRGB = primaryRGB
        let sRGB = secondaryRGB
        let tRGB = tertiaryRGB
        let borderColor: Color = colorScheme == .dark
            ? AppColors.borderDefault
            : AppColors.borderDefault
        let sparkOuter = AppColors.accentTertiary
        let sparkInner: Color = colorScheme == .dark
            ? AppColors.accentPrimary
            : AppColors.accentSecondary

        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: revolutionDuration)
                let progress = elapsed / revolutionDuration
                drawOrbit(
                    context: context, size: canvasSize, progress: progress,
                    pRGB: pRGB, sRGB: sRGB, tRGB: tRGB,
                    sparkOuter: sparkOuter, sparkInner: sparkInner,
                    borderColor: borderColor
                )
            }
            .frame(width: size, height: size)
        }
    }

    private func drawOrbit(
        context:     GraphicsContext,
        size:        CGSize,
        progress:    Double,
        pRGB:        (r: Double, g: Double, b: Double),
        sRGB:        (r: Double, g: Double, b: Double),
        tRGB:        (r: Double, g: Double, b: Double),
        sparkOuter:  Color,
        sparkInner:  Color,
        borderColor: Color
    ) {
        let cx     = size.width  / 2
        let cy     = size.height / 2
        let radius = size.width  / 2 - 2.0
        let steps  = 28

        let headAngle = progress * .pi * 2 - .pi / 2
        let tailArc   = Double.pi * 0.88

        var borderPath = Path()
        borderPath.addEllipse(in: CGRect(
            x: cx - radius, y: cy - radius,
            width: radius * 2, height: radius * 2))
        context.stroke(borderPath, with: .color(borderColor), lineWidth: 1.5)

        for i in 0..<steps {
            let t         = Double(i) / Double(steps - 1)
            let dotAngle  = headAngle - tailArc * (1.0 - t)
            let x         = cx + cos(dotAngle) * radius
            let y         = cy + sin(dotAngle) * radius
            let alpha     = t * 0.58
            let dotRadius = 0.9 + t * 0.65

            let color: Color
            if t < 0.4 {
                let blend = t / 0.4
                color = Color(
                    red:   lerp(pRGB.r, sRGB.r, blend),
                    green: lerp(pRGB.g, sRGB.g, blend),
                    blue:  lerp(pRGB.b, sRGB.b, blend))
            } else {
                let blend = (t - 0.4) / 0.6
                color = Color(
                    red:   lerp(sRGB.r, tRGB.r, blend),
                    green: lerp(sRGB.g, tRGB.g, blend),
                    blue:  lerp(sRGB.b, tRGB.b, blend))
            }

            var dotPath = Path()
            dotPath.addEllipse(in: CGRect(
                x: x - dotRadius, y: y - dotRadius,
                width: dotRadius * 2, height: dotRadius * 2))
            context.fill(dotPath, with: .color(color.opacity(alpha)))
        }

        let hx = cx + cos(headAngle) * radius
        let hy = cy + sin(headAngle) * radius

        var outerPath = Path()
        outerPath.addEllipse(in: CGRect(
            x: hx - 5.5, y: hy - 5.5, width: 11, height: 11))
        context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(
            x: hx - 3, y: hy - 3, width: 6, height: 6))
        context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

        var corePath = Path()
        corePath.addEllipse(in: CGRect(
            x: hx - 1.8, y: hy - 1.8, width: 3.6, height: 3.6))
        context.fill(corePath, with: .color(.white.opacity(0.96)))
    }

    private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }
}

// MARK: - BPFloatingFragment
// R-BUG-3 FIX: .fixedSize() removed. Width is capped by caller.
// Duration 1.0s on isVisible — intentional above-ceiling exception.
// Fragment drift has ceremony — slower than AppAnimation.slow (0.5s).

private struct BPFloatingFragment: View {
    let text:          String
    let targetOpacity: Double
    let isVisible:     Bool
    let isFading:      Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textSecondary
                : AppColors.textSecondary)
            .tracking(2.5)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .truncationMode(.tail)
            .opacity(isVisible && !isFading ? targetOpacity : 0)
            .offset(y: isVisible && !isFading ? -4 : 0)
            // 1.0s — intentional above-ceiling exception. Fragment drift
            // is a cinematic sequence reveal, not a UI response animation.
            .animation(.easeInOut(duration: 1.0), value: isVisible)
            .animation(AppAnimation.slow, value: isFading)
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Dark Mode") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName        = "Jordan"
        d.appMode            = .together
        d.nmStage            = .curious
        d.communicationGoals = ["Talking about fantasies"]
        return d
    }()
    @Previewable @State var instanceID = UUID()
    ZStack(alignment: .bottomTrailing) {
        OnboardingBuildingPathView(data: $data, onFinished: {})
            .id(instanceID)
        Button("↺ Reset") { instanceID = UUID() }
            // .caption scales with Dynamic Type — correct for debug buttons.
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(AppSpacing.md)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName        = "Alex"
        d.appMode            = .solo
        d.nmStage            = .experienced
        d.communicationGoals = ["Rebuilding intimacy"]
        return d
    }()
    @Previewable @State var instanceID = UUID()
    ZStack(alignment: .bottomTrailing) {
        OnboardingBuildingPathView(data: $data, onFinished: {})
            .id(instanceID)
        Button("↺ Reset") { instanceID = UUID() }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(AppSpacing.md)
    }
    .preferredColorScheme(.light)
}

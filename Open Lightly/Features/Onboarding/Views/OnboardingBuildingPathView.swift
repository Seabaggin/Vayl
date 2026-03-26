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

@State private var hasAnimated = false
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

// MARK: - Computed: Build Items

private var resolvedBuildItems: [BPBuildItem] {
    [        BPBuildItem(category: "Starting point",     resolved: stageLabel),        BPBuildItem(category: "Your situation",     resolved: contextLabel),        BPBuildItem(category: "First to explore",   resolved: goalsLabel),        BPBuildItem(category: "How you'll explore", resolved: modeLabel),    ]
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
    switch data.relationshipContext {
    case .partneredOpen:   return "Navigating openness together"
    case .partneredHidden: return "Finding words for the unspoken"
    case .notTalked:       return "Opening the conversation"
    case .talking:         return "Growing shared curiosity"
    case .single:          return "Your journey, your pace"
    case .someExperience:  return "Processing what's happened"
    case .needsReset:      return "Rebuilding from here"
    default:               return "Your situation"
    }
}

private var goalsLabel: String {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return "What you want to explore" }
    return s.count > 32 ? String(s.prefix(32)) + "…" : s
}

private var modeLabel: String {
    switch data.explorationMode {
    case .solo:   return "At your own pace"
    case .couple: return "Together, step by step"
    default:      return "Your conversation style"
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
    switch data.relationshipContext {
    case .single:          return "Your journey"
    case .partneredOpen:   return "With transparency"
    case .partneredHidden: return "Finding the words"
    case .notTalked:       return "Starting together"
    case .talking:         return "Shared curiosity"
    case .someExperience:  return "Processing this"
    case .needsReset:      return "Rebuilding"
    default:               return nil
    }
}

// R-BUG-3 FIX: Fragment strings are kept short (≤20 chars) so they
// never exceed their capped frame width and bleed off-screen.

private var selectionFragment: String? {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return nil }
    // Cap at 20 chars for fragment display — full string is in the list row
    return s.count > 20 ? String(s.prefix(20)) + "…" : s
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
    switch data.nmStage {
    case .curious:     data.defaultDifficulty = "warm"
    case .exploring:   data.defaultDifficulty = "medium"
    case .experienced: data.defaultDifficulty = "hot"
    default:           data.defaultDifficulty = "warm"
    }
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
        // internal alignment origin. When .ignoresSafeArea() children
        // sit inside a ZStack, the ZStack computes its alignment
        // center from the union of all children's frames — including
        // safe-area-extended frames — which shifts the origin
        // rightward and drags all content with it.
        .background(
            ZStack {
                // Dark: near-black | Light: warm cream
                (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                atmosphere()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                OnboardingGlowField()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        )
        // LAYOUT FIX: Fade overlay also isolated via .overlay()
        // for the same reason — its .ignoresSafeArea() must not
        // participate in ZStack alignment.
        .overlay(
            (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                .opacity(fadeOutVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: fadeOutVisible)
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
    withAnimation(.easeIn(duration: 0.25)) { fadeOutVisible = true }
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
                        : AppColors.lightTextTertiary)
                    .opacity(0.55)
                    .padding(.trailing, 28)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .accessibilityLabel("Skip loading and continue")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
    .animation(.easeIn(duration: 0.4), value: skipVisible)
    .allowsHitTesting(skipAvailable)
}

// MARK: - Fragment Layer
//
// topInset: the physical top safe-area inset from UIKit's key window.
//
// The inner GeometryReader does NOT use .ignoresSafeArea() (removed
// in Rev 3 to fix the layout origin). Its geo.size.height is the
// safe-area-inset region — shorter than the physical screen by topInset.
//
// fullH = geo.size.height + topInset reconstructs the physical screen
// height from live geometry on every frame (unlike the @State screenH
// which may hold its initial value of 852 on the first render frame).
// midY is computed in inset-region coordinates, then each position
// adds topInset back for the correct physical screen position.

@ViewBuilder
private func fragmentLayer(topInset: CGFloat) -> some View {
    GeometryReader { geo in
        // fullH reconstructs the physical screen height from live geometry.
        // geo.size.height excludes topInset (no .ignoresSafeArea here).
        // screenH is cached and may hold its initial value of 852 on the
        // first render frame — using it caused fragments to jump position.
        // geo.size.height + topInset is always accurate on every frame.
        let fullH        = geo.size.height + topInset
        let midX         = geo.size.width / 2
        // midY in inset-region coordinates:
        //   physical center = fullH / 2
        //   inset-region y  = physical y − topInset
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
// topInset: the physical top safe-area inset (Dynamic Island / notch /
// status bar height) read from UIKit's key window.
//
// WHY geo.safeAreaInsets.top DOES NOT WORK HERE:
//
// The outer GeometryReader uses .ignoresSafeArea(). When a view opts
// out of safe areas, SwiftUI zeroes the GeometryProxy's safeAreaInsets
// — the proxy reports 0 for all edges because the view has declared it
// doesn't care about safe areas. Every prior attempt that captured
// geo.safeAreaInsets.top was capturing 0, producing padding equal to
// just OL.progressTop (~24pt) — well within the ~59pt Dynamic Island.
//
// The fix: deviceTopInset reads UIApplication → UIWindowScene →
// UIWindow.safeAreaInsets.top, which always reports the real physical
// inset regardless of SwiftUI's modifier chain. This value is passed
// as topInset to mainContent and fragmentLayer.

@ViewBuilder
private func mainContent(topInset: CGFloat) -> some View {
    let completeCount = indicatorStates.filter { $0 == .complete }.count

    VStack(alignment: .center, spacing: 0) {

        // Progress bar
        //
        // .padding(.top) = topInset (Dynamic Island / notch clearance,
        //                   from UIKit key window — NOT geo.safeAreaInsets)
        //                 + OL.progressTop (design spacing below island).
        OnboardingProgressBar(
            currentStep:          completeCount,
            totalSteps:           5
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, topInset + OL.progressTop(screenH))
        .padding(.bottom, OL.progressBottom(screenH))
        .accessibilityHidden(true)

        Spacer()

        // Overline — BUG-3 FIX retained
        Text("BUILDING YOUR PATH")
            .font(AppFonts.overline)
            .foregroundStyle(colorScheme == .dark
                ? LinearGradient(
                    colors: [AppColors.purple, AppColors.magenta],
                    startPoint: .leading, endPoint: .trailing)
                : LinearGradient(stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.pink,    location: 0.45),
                    .init(color: AppColors.gold,    location: 1.00),
                  ],
                  startPoint: .leading, endPoint: .trailing))
            .tracking(2.5)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(overlabelVisible ? 1 : 0)
            .offset(y: overlabelVisible ? 0 : 8)
            .animation(.easeOut(duration: 1.0), value: overlabelVisible)
            .padding(.bottom, 10)
            .accessibilityHidden(true)

        // Name headline — BUG-1 downstream fix retained
        nameHeadline
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(nameVisible ? 1 : 0)
            .offset(y: nameVisible ? 0 : 14)
            .animation(.easeOut(duration: 1.2), value: nameVisible)
            .padding(.bottom, OL.loose(screenH))
            .accessibilityHidden(true)

        // Build item list — BUG-1 FIX retained: no .fixedSize(horizontal:)
        VStack(alignment: .leading, spacing: 20) {
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
        Text(exitLine)
            .font(AppFonts.body(18, weight: .medium))
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(taglineVisible ? 1 : 0)
            .offset(y: taglineVisible ? 0 : 10)
            .animation(.easeOut(duration: 1.2), value: taglineVisible)
            .padding(.top, OL.loose(screenH))
            .accessibilityHidden(true)

        // BUG-7 FIX retained
        Spacer(minLength: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // BUG-6 FIX retained: single source of horizontal inset.
    .padding(.horizontal, 36)
    // BUG-7 FIX retained: home indicator clearance
    .padding(.bottom, 34)
}

// MARK: - Name Headline

@ViewBuilder
private var nameHeadline: some View {
    if hasPersonalName {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(trimmedName)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.lightCardTitle)
            Text(".")
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.spectrumBorder
                    : AppColors.warmAuroraBorder)
        }
        .font(AppFonts.heroTitle)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    } else {
        Text("Your path.")
            .font(AppFonts.heroTitle)
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

// MARK: - Atmospheric Layer
// Unchanged — atmosphere() renders correctly once the ZStack frame
// is pinned (R-BUG-1 fix). Orb offsets are screen-relative and correct.

// Dark:  cool spectrum — purple / cyan / magenta orbs
// Light: warm aurora  — purple / gold / magenta orbs (no cyan)
private var atmosAccent: Color {
    colorScheme == .dark ? AppColors.cyan : AppColors.gold
}

private func atmosphere() -> some View {
    ZStack {
        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.40),
                         atmosAccent.opacity(0.20),
                         Color.clear],
                center: .top, startRadius: 30, endRadius: 380))
            .frame(width: OL.atmosW(screenW), height: OL.atmosH(screenH))
            .offset(y: -screenH * 0.42)
            .blur(radius: 90)
            .opacity(atmosphericVisible ? 1 : 0)
            .animation(.easeInOut(duration: 2.0), value: atmosphericVisible)

        Ellipse()
            .fill(atmosAccent.opacity(0.12))
            .frame(width: 180, height: 180)
            .blur(radius: 55)
            .offset(x: -screenW * 0.32, y: -screenH * 0.22)
            .opacity(glowPeak ? 0.90 : 0.40)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.10))
            .frame(width: 140, height: 140)
            .blur(radius: 50)
            .offset(x: screenW * 0.32, y: -screenH * 0.26)
            .opacity(glowPeak ? 0.85 : 0.28)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.purple.opacity(0.14))
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
            .fill(AppColors.magenta.opacity(0.08))
            .frame(width: 150, height: 150)
            .blur(radius: 60)
            .offset(x: screenW * 0.38, y: screenH * 0.18)
            .opacity(glowPeak ? 0.85 : 0.22)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.18),
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
                colors: [AppColors.purple.opacity(0.10), Color.clear],
                startPoint: .bottom, endPoint: .top))
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)
    }
    .drawingGroup()
}

    // MARK: - Animation (startFullAnimation replacement)
    //
    // BUG-1 FIX: the #if DEBUG / XCODE_RUNNING_FOR_PREVIEWS block
    // previously hard-jumped to indicatorStates = [.complete × 4] and
    // returned early. This meant BPOrbitCanvas was NEVER mounted in any
    // preview — the .processing state was skipped entirely, so the comet
    // orbit was invisible.
    //
    // BUG-2 FIX (downstream): BPBuildItemRow.isVisible is computed as
    // indicatorStates[i] != .pending. When the DEBUG block set states to
    // .complete before the animation sequence ran, the rows started
    // invisible (opacity 0) and stayed there because no animation ever
    // fired to transition them in.
    //
    // FIX: the preview path now runs a real but fast (0.4× speed) animation
    // sequence using the same schedule() calls as the device path. This
    // ensures every state — pending → processing → complete — is visited,
    // all rows animate in, and the comet orbit is visible.
    //
    // The instanceID UUID toggle in the preview re-creates the view from
    // scratch on each Reset tap, which resets hasAnimated = false and
    // replays the sequence.
    
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
            // Preview-fast path: same sequence as below but at 0.4× wall-clock
            // time so the full pending → processing → complete flow is visible
            // without waiting 4+ seconds per canvas reload.
            //
            // Multiplier 0.4 maps the real-device schedule (0s–4.6s) into
            // approximately 0s–1.85s in the preview canvas.
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

        // ── Real-device timing (unchanged) ───────────────────────────────
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
// BUG-4 + BUG-6 fixes retained: .frame(maxWidth: .infinity) on both
// the label VStack and the outer HStack. lineLimit + truncationMode on
// both Text nodes. fixedSize(horizontal: false, vertical: true) on
// the resolved text for graceful two-line wrap.

private struct BPBuildItemRow: View {
let item:           BPBuildItem
let indicatorState: BPIndicatorState
let isVisible:      Bool
let isComplete:     Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    HStack(spacing: 14) {
        // Fixed-size indicator — never grows
        BPOrbitIndicator(state: indicatorState)
            .fixedSize()

        VStack(alignment: .leading, spacing: 2) {
            Text(item.category.uppercased())
                .font(AppFonts.overline)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textTertiary
                    : AppColors.lightCardTitle.opacity(0.40))
                .tracking(1.5)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(item.resolved)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(isComplete
                    ? (colorScheme == .dark ? AppColors.textPrimary : AppColors.lightCardTitle)
                    : (colorScheme == .dark ? AppColors.textSecondary : AppColors.lightCardTitle.opacity(0.55)))
                .animation(.easeOut(duration: 0.7), value: isComplete)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Fill remaining width after the indicator + spacing
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    // Fill the padded column width
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 10)
    .animation(.easeOut(duration: 0.8), value: isVisible)
}
}

// MARK: - BPOrbitIndicator (unchanged)

private struct BPOrbitIndicator: View {
let state: BPIndicatorState
private let size: CGFloat = 22



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    ZStack {
        Circle()
            .strokeBorder(
                colorScheme == .dark ? AppColors.border : AppColors.lightBorder,
                lineWidth: 1.5)
            .opacity(state == .pending ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: state == .pending)

        if state == .processing {
            BPOrbitCanvas(size: size, colorScheme: colorScheme)
                .transition(.opacity)
        }

        Circle()
            .fill(LinearGradient(
                colors: colorScheme == .dark
                    ? [AppColors.cyan, AppColors.purple, AppColors.magenta]
                    : [AppColors.purple, AppColors.magenta, AppColors.gold],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .opacity(state == .complete ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: state == .complete)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowCyan : AppColors.lightShadowPurple,
                radius: colorScheme == .dark ? 12 : 7)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowMagenta : AppColors.lightShadowMagenta,
                radius: colorScheme == .dark ? 24 : 14)
    }
    .frame(width: size, height: size)
}
}

// MARK: - BPOrbitCanvas (unchanged)

private struct BPOrbitCanvas: View {
let size: CGFloat
let colorScheme: ColorScheme
private let revolutionDuration: TimeInterval = 1.4



// RGB triples resolved from AppColors tokens per colorScheme.
// Dark:  cyan → purple → magenta
// Light: purple → magenta → gold
private var primaryRGB:   (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.cyan : AppColors.purple)
}
private var secondaryRGB: (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.purple : AppColors.magenta)
}
private var tertiaryRGB:  (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.magenta : AppColors.gold)
}

var body: some View {
    let pRGB = primaryRGB
    let sRGB = secondaryRGB
    let tRGB = tertiaryRGB
    let borderColor: Color = colorScheme == .dark
        ? AppColors.borderHover
        : AppColors.lightBorderHover
    let sparkOuter = AppColors.magenta
    let sparkInner: Color = colorScheme == .dark ? AppColors.cyan : AppColors.purple

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
    context.stroke(
        borderPath,
        with: .color(borderColor),
        lineWidth: 1.5)

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
// R-BUG-3 FIX: .fixedSize() removed from inside the component.
// Width is now controlled by the .frame(maxWidth: fragmentMaxW) applied
// by the caller in fragmentLayer(). Removing .fixedSize() here means the
// Text respects the width cap and wraps rather than overflowing right.
// .lineLimit(1) ensures it stays single-line and truncates cleanly.

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
            : AppColors.lightTextSecondary)
        .tracking(2.5)
        .multilineTextAlignment(.center)
        // R-BUG-3 FIX: .fixedSize() removed. Width is capped by caller.
        // .lineLimit(1) ensures single-line with clean truncation.
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(isVisible && !isFading ? targetOpacity : 0)
        .offset(y: isVisible && !isFading ? -4 : 0)
        .animation(.easeInOut(duration: 1.0), value: isVisible)
        .animation(.easeIn(duration: 0.8), value: isFading)
        .allowsHitTesting(false)
}
}

// MARK: - Previews
//
// Each preview uses a @Previewable UUID that is toggled by a Reset button.
// Changing the id re-creates the view from scratch — hasAnimated resets to
// false — so the full entrance animation replays on every canvas reset.

#Preview("Dark Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Jordan"
d.explorationMode     = .couple
d.nmStage             = .curious
d.relationshipContext = .notTalked
d.communicationGoals  = ["Talking about fantasies"]
return d
}()
// Changing this id destroys and recreates the view, restarting animation.
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.white)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.dark)
}

#Preview("Light Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Alex"
d.explorationMode     = .solo
d.nmStage             = .experienced
d.relationshipContext = .needsReset
d.communicationGoals  = ["Rebuilding intimacy"]
return d
}()
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.primary)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.light)
}

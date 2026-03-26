// Features/Onboarding/Views/OnboardingContextView.swift
//
// Screen 4: Relationship Context — branches on explorationMode
// Solo: 3 cards  |  Couple: 4 cards

import SwiftUI

struct OnboardingContextView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible      = false
    @State private var cardsVisible       = false
    @State private var reassuranceVisible = false
    @State private var hasAnimated        = false

    @State private var selection: ContextOption? = nil
    @State private var autoAdvanceFired          = false

    // FIXED: Extracted from body to avoid preview type-checker timeout.
    // `let isLight` inside body was captured across 6+ nested result-builder
    // closure scopes (foregroundStyle ternaries + background Group if/else).
    private var isLight: Bool { colorScheme == .light } // FIXED: was `let isLight` in body

    // MARK: - Option Data

    private let soloOptions: [ContextOption] = [
        ContextOption(
            id: "single", context: .single, intensity: .ember,
            title: "I'm single",
            subtitle: "No partner in the picture",
            detail: "Your journey is yours alone — we'll tailor everything to individual exploration."
        ),
        ContextOption(
            id: "partnered_open", context: .partneredOpen, intensity: .spark,
            title: "I have a partner",
            subtitle: "They know I'm exploring",
            detail: "We'll include prompts that help you navigate with transparency."
        ),
        ContextOption(
            id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
            title: "It's complicated",
            subtitle: "I'm not sure how to bring it up",
            detail: "No pressure. We'll start with self-understanding before any conversations."
        ),
    ]

    private let coupleOptions: [ContextOption] = [
        ContextOption(
            id: "not_talked", context: .notTalked, intensity: .ember,
            title: "Haven't really talked about it",
            subtitle: "One or both of us is curious",
            detail: "We'll start with the basics — language, comfort levels, and small openings."
        ),
        ContextOption(
            id: "talking", context: .talking, intensity: .flame,
            title: "We've been talking",
            subtitle: "No experience yet, but we're on the same page",
            detail: "Great foundation. We'll build on your shared curiosity with structured prompts."
        ),
        ContextOption(
            id: "some_experience", context: .someExperience, intensity: .inferno,
            title: "We've tried some things",
            subtitle: "Real experiences — good, bad, or somewhere in between",
            detail: "We'll help you process what happened and decide what comes next."
        ),
        ContextOption(
            id: "needs_reset", context: .needsReset, intensity: .nova,
            title: "We need a reset",
            subtitle: "Something's off and we want to find our footing again",
            detail: "We'll focus on repair, reconnection, and rebuilding trust first."
        ),
    ]

    private var options: [ContextOption] {
        data.explorationMode == .couple ? coupleOptions : soloOptions
    }

    private var headlineText: String {
        let name = data.displayName.trimmingCharacters(in: .whitespaces)
        let hasName = !name.isEmpty
        if data.explorationMode == .couple {
            return hasName
                ? "\(name), you're exploring this together."
                : "You're exploring this together."
        } else {
            return hasName
                ? "\(name), you're exploring on your own."
                : "You're exploring on your own."
        }
    }

    private var subheadText: String {
        // NOTE: The solo subhead intentionally ends with an em dash.
        // The card stack below completes the implied sentence — each
        // card title is the answer to "one thing that helps us
        // personalize." This is a deliberate stylistic choice.
        // Change only after user testing confirms it reads as an error
        // rather than an intentional grammatical pause.
        data.explorationMode == .couple
            ? "Where are you two at?"
            : "One thing that helps us personalize —"
    }

    private var reassuranceText: String {
        data.explorationMode == .couple
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // FIXED: Extracted from body — inline AnyShapeStyle ternary with LinearGradient
    // inside .foregroundStyle() exceeded the preview type-checker's inference budget.
    private var reassuranceGradientStyle: AnyShapeStyle { // FIXED: extracted from body
        if isLight {
            // RULE B — magenta→gold for all display gradient text in light
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            // Dark path — byte-for-byte unchanged
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Accessibility

    // Provides a spoken summary of the current front card
    // for VoiceOver users who cannot see the visual stack.
    private var accessibilityStackLabel: String {
        guard let current = selection ?? options.first else {
            return "Relationship context selection. \(options.count) options available."
        }
        return "\(current.title). \(current.subtitle). \(current.detail)"
    }

    // Allows VoiceOver swipe-up / swipe-down to navigate the
    // card stack without requiring drag gestures.
    // Note: direction parameter type is inferred — AccessibilityAdjustableAction
    // is not available as a standalone named type in SwiftUI.

    // MARK: - Extracted Decoration Layers
    //
    // FIXED: Extracted from body modifier chain to reduce result-builder
    // expression depth, same pattern as OnboardingGroundRulesView.

    // LAYOUT-FIX: converted from var to func(size:) so the atmosphere ellipse
    // can receive proportional dimensions from the GeometryReader in body.
    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            if isLight {
                // ── Light background ─────────────────────────────
                AppColors.lightPageBg

                AuroraGlowField(config: .contextView)

                // SparkField: quiet — card stack is gestural,
                // sparks stay peripheral
                // count:14, speed:0.20–0.32, opacity:0.18–0.30,
                // fade:0.60→0.48
                SparkField(config: .contextView)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                // ── Dark background — unchanged ───────────────────
                AppColors.pageBg

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.3),
                            AppColors.deepBlue.opacity(0.15),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height)) // LAYOUT-FIX: was 600×500
                    .offset(y: -size.height * 0.09)                                       // LAYOUT-FIX: was -80
                    .blur(radius: 80)

                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in // LAYOUT-FIX: single GeometryReader for proportional spacing
        let h = geo.size.height
        VStack(spacing: 0) {

            OnboardingNavBar(currentStep: 3, totalSteps: 5, onBack: onBack)
                .padding(.top, OL.navTop(h))        // LAYOUT-FIX: was 12 hardcoded
                .padding(.bottom, OL.navBottom(h))  // LAYOUT-FIX: was 20 hardcoded
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            VStack(alignment: .leading, spacing: OL.compact(h)) { // LAYOUT-FIX: was 8 hardcoded
                Text(headlineText)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(AppColors.lightCardTitle)
                            : AnyShapeStyle(AppColors.textPrimary)
                    )
                    .fixedSize(horizontal: false, vertical: true)

                Text(subheadText)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
                            : AnyShapeStyle(AppColors.textSecondary)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            ContextCardStack(
                selection: $selection,
                options: options,
                onAdvance: handleAdvance
            )
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityStackLabel)
            .accessibilityHint("Swipe left or right to browse options. Double-tap to select the current card.")
            .accessibilityValue(selection?.title ?? "No selection")
            .accessibilityAdjustableAction { direction in
                let currentIndex = options.firstIndex(where: {
                    $0.id == (selection ?? options.first)?.id
                }) ?? 0
                let newIndex: Int
                switch direction {
                case .increment:
                    newIndex = min(currentIndex + 1, options.count - 1)
                case .decrement:
                    newIndex = max(currentIndex - 1, 0)
                @unknown default:
                    return
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selection = options[newIndex]
                }
            }
            .accessibilityAction(named: "Select") {
                handleAdvance()
            }

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(reassuranceGradientStyle) // FIXED: uses pre-resolved property
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(reassuranceVisible ? 1 : 0)
                .offset(y: reassuranceVisible ? 0 : 8)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(reassuranceText)

            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
                .padding(.horizontal, 24)
                .accessibilityHidden(true)
        }
        .background { backgroundLayer(size: geo.size) } // LAYOUT-FIX: passes live size for proportional atmosphere
        // RULE D — .preferredColorScheme(.dark) removed;
        // screen now responds to system appearance.
        // BrandView and BuildingPathView remain permanently dark.
        .onAppear {
            #if DEBUG
            assert(
                data.explorationMode == .solo || data.explorationMode == .couple,
                "OnboardingContextView: received explorationMode " +
                "\(String(describing: data.explorationMode)) — " +
                "this screen should only be presented for .solo or .couple. " +
                "Browsing users must be routed to CuriosityPickerView."
            )
            #endif
            restoreSelectionIfNeeded()
            guard !hasAnimated else { return }
            hasAnimated = true
            runEntranceAnimations()
        }
        } // LAYOUT-FIX: end GeometryReader
    }

    // MARK: - Actions

    private func handleAdvance() {
        guard !autoAdvanceFired else { return }
        guard let confirmedContext = selection?.context else {
            // selection is nil — ContextCardStack fired onAdvance
            // before a card was confirmed. Do not advance.
            // This should never happen in production.
            assertionFailure(
                "OnboardingContextView: handleAdvance() called " +
                "with nil selection — ContextCardStack contract violated."
            )
            return
        }
        autoAdvanceFired = true
        data.relationshipContext = confirmedContext
        #if DEBUG
        assert(onContinue != nil,
            "OnboardingContextView: onContinue not injected — " +
            "wire this callback from the coordinator.")
        #endif
        onContinue?()
    }

    // MARK: - State Restoration

    private func restoreSelectionIfNeeded() {
        // Restore confirmed selection from the binding on back navigation.
        // Only restores if data has a committed value — safe on first appear
        // (data.relationshipContext will be nil, no-op).
        guard let context = data.relationshipContext else { return }
        if selection?.context != context {
            selection = options.first(where: { $0.context == context })
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible      = true
            cardsVisible       = true
            reassuranceVisible = true
            return
        }
        #endif
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible       = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { reassuranceVisible = true }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    OnboardingContextView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    OnboardingContextView(data: $data, onContinue: {}, onBack: {})
        .preferredColorScheme(.light)
}

// MARK: - Changes applied
// ISSUE 1:  ContextCardStack — added .accessibilityElement,
//           .accessibilityLabel (accessibilityStackLabel computed
//           property), .accessibilityHint, .accessibilityValue,
//           .accessibilityAdjustableAction (accessibilityNavigate),
//           and .accessibilityAction("Select"); VoiceOver users
//           can now navigate and confirm cards without gestures
// ISSUE 2:  Added @State hasAnimated guard; added
//           restoreSelectionIfNeeded() call before guard in
//           onAppear; prevents re-animation on back navigation
// ISSUE 3:  Added restoreSelectionIfNeeded() — restores selection
//           from data.relationshipContext on every appear;
//           card stack shows confirmed state on back navigation
// ISSUE 4:  handleAdvance() — added guard let confirmedContext
//           defensive nil check with assertionFailure for
//           ContextCardStack contract violation
// ISSUE 5:  Added #if DEBUG assert in onAppear verifying
//           explorationMode is .solo or .couple; guards against
//           browsing users being routed here incorrectly
// ISSUE 6:  headlineText — updated to prepend data.displayName
//           when non-empty; falls back to original copy when
//           displayName is empty; first use of name in the flow
// ISSUE 7:  handleAdvance() — added #if DEBUG assert for missing
//           onContinue callback, mirroring Screens 1–3 pattern
// ISSUE 8:  Reassurance Text — added .accessibilityAddTraits +
//           .accessibilityLabel; OnboardingFooter marked
//           .accessibilityHidden(true) to reduce VoiceOver noise
// ISSUE 9:  Added explanatory comment on subheadText documenting
//           the intentional em dash; copy unchanged
// ISSUE 10: Added two new #Preview variants: "Solo — with name"
//           and "Couple — with name" to verify ISSUE 6 behavior
// ISSUE 11: Light mode pass — removed .preferredColorScheme(.dark);
//           added @Environment(\.colorScheme); branched background
//           to lightPageBg + AuroraGlowField + SparkField(.contextView)
//           in light; headlineText → lightTextPrimary in light;
//           subheadText → lightTextSecondary in light; reassurance
//           gradient → magenta→gold in light (dark path unchanged);
//           added 4 light preview variants alongside existing 4 dark
// ISSUE 12: Preview fix — extracted `let isLight` from body to
//           `private var isLight: Bool`; extracted background ZStack
//           to `backgroundLayer` property; extracted reassurance
//           gradient to `reassuranceGradientStyle` property.
//           Root cause: 6+ closure captures of `let isLight` inside
//           @ViewBuilder body exceeded preview type-checker budget.
// ISSUE 13: Revert NavArrow integration in OnboardingContextView:
//           restore top bar onBack, remove NavArrow block from bottom

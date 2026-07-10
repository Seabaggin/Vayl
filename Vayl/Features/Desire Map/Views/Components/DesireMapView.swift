import SwiftUI
import SwiftData

// MARK: - DesireMapView
// Two-track card rater (View layer — reads DesireMapStore, forwards taps; no DB/Service).
// One desire per card; the four answers + which items appear are cohort-driven (store.track).
// Only the WEIGHT (DesireRatingValue) is stored — the displayed string is cohort copy.
//
// RaterPhase drives the visual state machine:
//   .start   — invitation screen + spectrum-bloom entrance (S2.1)
//   .rating  — void layout, pills, growing star sky (S2.2)
//   .charted — hesitant constellation lines + "Your map is charted." (S2.3)
//   .mirror  — solo wait: grouped private answers, no progress race (S2.4)
//   .ready   — first finisher re-entry: same mirror + "partner finished" bar (S2.4)

struct DesireMapView: View {

    let store: DesireMapStore
    /// Display name for the partner — shown in charted + mirror copy.
    var partnerName: String = "your partner"
    /// True when the partner has also completed their map. Drives the ready bar in mirror.
    /// Passed live from HomeStore (@Observable) so a partner finishing WHILE the mirror is
    /// open re-renders here (review 2026-07-09, decision #5).
    var partnerComplete: Bool = false
    /// One-shot status refetch fired when the mirror appears, so a partner who finished
    /// while this device was away is noticed without waiting for the next Home load
    /// (review 2026-07-09, decision #5). Owned by the router — the view never calls a
    /// Service itself.
    var onMirrorAppeared: (() async -> Void)?

    @Environment(\.vaylDismiss) private var vaylDismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Presentation phase

    private enum RaterPhase { case start, rating, charted, mirror, ready }
    @State private var raterPhase: RaterPhase = .start

    // MARK: - Rating navigation

    @State private var index: Int = 0

    // MARK: - Bloom entrance (S2.1)

    @State private var bloomScale: CGFloat  = 0.01
    @State private var bloomOpacity: Double = 0.0
    @State private var startVisible: Bool   = true
    @State private var ratingVisible: Bool  = false

    // MARK: - Charted beat (S2.3)

    @State private var chartedStarsVisible: Bool = false
    @State private var chartedLinesActive: Bool  = false
    @State private var chartedTitleVisible: Bool = false

    /// The charted-finish ceremony, held so a tap (skip) or disappear can cancel it.
    @State private var chartedTask: Task<Void, Never>?

    // MARK: - Star-rise sync (S2.2)
    // Bumped on every answer commit so the accumulating sky animates the new star
    // rising on desireStarRise, synced to the question receding on desireDepthExit.
    @State private var starRiseTick: Int = 0
    @State private var sparkBreath: Bool = false

    // MARK: - Haptics

    @State private var hapticTick: Int = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: atmosphereConfig).ignoresSafeArea()
            DesireStarfield().ignoresSafeArea()

            content

            GlowOrb(color: AppColors.spectrumMagenta, size: 300)
                .scaleEffect(bloomScale)
                .opacity(bloomOpacity)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .onAppear {
            store.load()
            // Resume + greeting decisions are store-owned (Blueprint C); the view
            // just maps the destination onto its presentation phases.
            if let firstUnrated = store.firstUnratedIndex {
                index = firstUnrated
            }
            if !store.items.isEmpty, store.ratedCount > 0 {
                raterPhase = store.isComplete
                    ? postRatingPhase
                    : .rating
                ratingVisible = true
            }
        }
        .onChange(of: index) { _, newValue in
            guard newValue >= store.items.count, raterPhase == .rating else { return }
            withAnimation(AppAnimation.desireFinishFade) { raterPhase = .charted }
            runChartedSequence()
        }
        .onChange(of: partnerComplete) { _, done in
            // Live upgrade: the partner finished while the mirror is open — materialize the
            // ready bar in place (review 2026-07-09, decision #5). Only the mirror phase
            // upgrades; every other phase already routes via postRatingPhase.
            if done, raterPhase == .mirror {
                withAnimation(AppAnimation.enter) { raterPhase = .ready }
            }
        }
        .onDisappear {
            // Don't let the charted ceremony outlive the view.
            chartedTask?.cancel()
            chartedTask = nil
        }
    }

    // MARK: - Atmosphere config

    private var atmosphereConfig: AtmosphereConfig {
        raterPhase == .start ? .modeSelect : .cardReveal
    }

    // MARK: - Phase routing

    @ViewBuilder
    private var content: some View {
        if let error = store.loadError {
            emptyState(error)
        } else if store.items.isEmpty {
            emptyState("No desire items to show.")
        } else {
            switch raterPhase {
            case .start:
                startScreen
                    .opacity(startVisible ? 1 : 0)
                    .animation(AppAnimation.desireFinishFade.reduceMotionSafe, value: startVisible)
                    .transition(.opacity)

            case .rating:
                raterContent
                    .opacity(ratingVisible ? 1 : 0)
                    .animation(AppAnimation.desireStarIgnite.reduceMotionSafe, value: ratingVisible)
                    .transition(.opacity)

            case .charted:
                chartedScreen
                    // Tap anywhere during the charted hold skips the ceremony and proceeds.
                    .contentShape(Rectangle())
                    .onTapGesture { skipChartedSequence() }
                    .transition(.opacity)

            case .mirror, .ready:
                mirrorScreen
                    .transition(.opacity)
                    // One-shot on mirror entry (shared branch, so a mirror → ready upgrade
                    // doesn't refire it): refetch the couple status so a partner who finished
                    // while we were away flips partnerComplete → the ready bar, live.
                    .task { await onMirrorAppeared?() }
            }
        }
    }

    // MARK: - Start screen (S2.1)

    private var startScreen: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                Text("Desire Map")
                    .font(AppFonts.overline)
                    .tracking(1.5)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.bottom, AppSpacing.lg)

                VStack(spacing: AppSpacing.xxs) {   // was 2 → xxs, exact
                    Text("See where your desires")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    LivingText(text: "meet", font: AppFonts.heroTitle)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)

                Text("Opening up usually waits on a conversation no one wants to start. So you each answer in private, and only the desires you **both** want are ever revealed. You begin already knowing where you agree.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.bottom, AppSpacing.md)

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Text("◇")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Text("If only one of you wants it, it stays private. Your no is never shown to your partner.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, AppSpacing.xxl)

                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    VaylButton(label: "Begin", style: .primary, size: .fullWidth) { beginTapped() }
                        .frame(height: VaylButtonSize.fullWidth.height)

                    let count = store.totalCount > 0 ? store.totalCount : 17
                    Text("\(count) questions · about 3 minutes")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                        Image(systemName: AppIcons.close)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                            .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(_RaterPressStyle())
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bloom entrance

    private func beginTapped() {
        hapticTick += 1
        guard !reduceMotion else {
            startVisible = false; raterPhase = .rating; ratingVisible = true
            return
        }
        // Sleep beats are expressed as fractions of the bloom token's duration, not
        // free magic numbers: the fade-out begins as the bloom nears its peak (~80%),
        // and the orb resets once the fade has largely cleared. bloomDuration mirrors
        // AppAnimation.desireRevealBloom (0.80s) so the timing stays tied to that token.
        let bloomDuration: Double = 0.80
        withAnimation(AppAnimation.desireRevealBloom) {
            bloomScale = 20; bloomOpacity = 0.65; startVisible = false
        }
        Task {
            try? await Task.sleep(for: .seconds(bloomDuration * 0.80))
            withAnimation(AppAnimation.standard) { bloomOpacity = 0 }
            raterPhase = .rating
            withAnimation(AppAnimation.desireStarIgnite.reduceMotionSafe) { ratingVisible = true }
            try? await Task.sleep(for: .seconds(bloomDuration * 0.62))
            bloomScale = 0.01
        }
    }

    // MARK: - Rater (S2.2)

    @ViewBuilder
    private var raterContent: some View {
        if index < store.items.count {
            rater(item: store.items[index])
        }
    }

    private func rater(item: DesireItem) -> some View {
        let answers = store.answers(for: item)
        return ZStack(alignment: .top) {
            // Stars only appear for excited + open answers (stars mark desire, not avoidance)
            _StarAccum(ratings: store.positiveRatings, riseTrigger: starRiseTick)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xs)

                // Space for stars to be visible
                Spacer(minLength: 140)

                // Question — transitions on each answer
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(item.category.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.spectrumMagenta.opacity(0.85))

                    Text(item.name)
                        .font(AppFonts.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .id(index)
                // Two-phase depth: the incoming question emerges from depth on
                // desireDepthEnter; the outgoing one recedes on desireDepthExit.
                // Carrying the animation on each side of the transition lets the
                // single index change drive both phases at their own pace.
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 1.04))
                        .animation(AppAnimation.desireDepthEnter.reduceMotionSafe),
                    removal: .opacity
                        .combined(with: .scale(scale: 0.90))
                        .animation(AppAnimation.desireDepthExit.reduceMotionSafe)
                ))

                Spacer(minLength: AppSpacing.lg)

                // Answer area
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("How do you feel about this?")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.lg)

                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { idx, label in
                            if idx < DesireRatingValue.allCases.count {
                                let weight = DesireRatingValue.allCases[idx]
                                DesireAnswerPill(
                                    label: label,
                                    hint: pillHint(for: weight),
                                    weight: weight,
                                    isSelected: store.existingRating(for: item.id) == weight
                                ) { choose(weight, for: item) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                // Privacy footer
                Text("Private — only your mutual matches are ever revealed.")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBar: some View {
        HStack(spacing: AppSpacing.md) {
            Button { back() } label: {
                Image(systemName: AppIcons.chevronLeft)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(_RaterPressStyle())
            .opacity(index == 0 ? 0.25 : 1)
            .disabled(index == 0)

            progressTrack

            Text("\(index + 1) of \(store.totalCount)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)

            Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                Image(systemName: AppIcons.close)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(_RaterPressStyle())
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * progressRatio)
            }
        }
        .frame(height: 3)
        .animation(AppAnimation.standard, value: store.ratedCount)
    }

    private var progressRatio: CGFloat {
        guard store.totalCount > 0 else { return 0 }
        return CGFloat(store.ratedCount) / CGFloat(store.totalCount)
    }

    // MARK: - Charted beat (S2.3)

    private var chartedScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                // 6 nodes from the mockup (relative positions in 0-1 space)
                let nodes: [(CGFloat, CGFloat)] = [
                    (0.50, 0.30), (0.26, 0.22), (0.72, 0.26),
                    (0.34, 0.62), (0.68, 0.58), (0.48, 0.80)
                ]
                let connections: [(Int, Int, Double)] = [
                    (0, 1, 0.0), (0, 2, 0.6), (0, 3, 1.2), (2, 4, 0.9), (3, 5, 1.6)
                ]

                ZStack {
                    if chartedLinesActive {
                        ForEach(connections.indices, id: \.self) { i in
                            let c = connections[i]
                            _ChartedLine(
                                sx: nodes[c.0].0 * W, sy: nodes[c.0].1 * H,
                                ex: nodes[c.1].0 * W, ey: nodes[c.1].1 * H,
                                delay: c.2
                            )
                        }
                    }
                    ForEach(nodes.indices, id: \.self) { i in
                        _AccumStar()
                            .frame(width: 34, height: 34)
                            .position(x: nodes[i].0 * W, y: nodes[i].1 * H)
                            .opacity(chartedStarsVisible ? 1 : 0)
                            .animation(
                                AppAnimation.desireFinishFlair.delay(Double(i) * 0.06).reduceMotionSafe,
                                value: chartedStarsVisible
                            )
                    }
                }
            }
            .frame(maxWidth: 340, maxHeight: 200)
            .padding(.horizontal, AppSpacing.xl)

            Spacer().frame(height: AppSpacing.xl)

            VStack(spacing: AppSpacing.sm) {
                Text("Your map is charted.")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("All \(store.totalCount). The lines find \(partnerName)'s once they finish theirs.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xxl)
            .opacity(chartedTitleVisible ? 1 : 0)
            .animation(AppAnimation.desireChartedFadeIn.reduceMotionSafe, value: chartedTitleVisible)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Sleep beats for the charted ceremony. These mirror the documented durations of
    // the matching AppAnimation tokens (desireFinishFade 0.35, desireFinishFlair 0.80),
    // kept here as named Doubles because an Animation token can't report its own
    // duration to Task.sleep. The hold uses the raw-Double token directly.
    private static let chartedStarSettle: Double = 0.35   // desireFinishFade
    private static let chartedLinesDraw: Double = 0.80   // desireFinishFlair (line-draw wait)

    private func runChartedSequence() {
        chartedTask?.cancel()
        chartedTask = Task {
            if reduceMotion {
                chartedStarsVisible = true
                chartedTitleVisible = true
                try? await Task.sleep(for: .seconds(AppAnimation.desireChartedHold))
                guard !Task.isCancelled else { return }
                advancePastCharted()
                return
            }
            // Last star flair — the climactic ignite of the rating beat. The flair
            // animation rides on the chartedScreen star's .animation(value:) modifier.
            chartedStarsVisible = true
            try? await Task.sleep(for: .seconds(Self.chartedStarSettle))
            guard !Task.isCancelled else { return }
            // Lines activate (each handles own timing via onAppear)
            chartedLinesActive = true
            // Wait for all lines to finish drawing (~2.6s for last line to complete)
            try? await Task.sleep(for: .seconds(Self.chartedLinesDraw))
            guard !Task.isCancelled else { return }
            // Charted-text fades in once the flair settles (desireChartedFadeIn on the view).
            chartedTitleVisible = true
            // Hold long enough to read both lines (tap-anywhere skips).
            try? await Task.sleep(for: .seconds(AppAnimation.desireChartedHold))
            guard !Task.isCancelled else { return }
            advancePastCharted()
        }
    }

    /// The store-owned second-finisher branch, mapped onto this view's phases.
    /// Used by both the returning-user greeting (onAppear) and the charted exit.
    private var postRatingPhase: RaterPhase {
        switch store.postRatingDestination(partnerComplete: partnerComplete) {
        case .ready:  return .ready
        case .mirror: return .mirror
        }
    }

    /// Leaves the charted beat for its branch target. Shared by the timed auto-advance
    /// and the tap-to-skip path, so both land on the same destination.
    private func advancePastCharted() {
        withAnimation(AppAnimation.enter) {
            raterPhase = postRatingPhase
        }
    }

    /// Tap-anywhere during the charted hold cancels the ceremony and proceeds now.
    private func skipChartedSequence() {
        guard raterPhase == .charted else { return }
        chartedTask?.cancel()
        chartedTask = nil
        // Settle the visuals so the skip doesn't snap mid-draw, then advance.
        chartedStarsVisible = true
        chartedTitleVisible = true
        advancePastCharted()
    }

    // MARK: - Mirror screen (S2.4)
    // Matches flow-family screen 4/5: scrollable grouped list on the void.
    // topspark → heading → subtitle → .agroup rows → spacer → waitline

    private var mirrorScreen: some View {
        VStack(spacing: 0) {
            // Fixed close affordance. The mirror is a terminal waiting state inside a
            // .vaylCover (interactive-dismiss disabled), so it must always offer an explicit
            // exit — the readyBar only appears for the second-finisher (.ready), not here.
            HStack {
                Spacer()
                Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                    Image(systemName: AppIcons.close)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.cardBg.opacity(0.55)))
                        .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(_RaterPressStyle())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)

            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                if raterPhase == .ready {
                    readyBar
                        .padding(.bottom, AppSpacing.md)
                }

                // Overline label (the desire-map identity is the aperture mark, not a sparkle).
                HStack(spacing: AppSpacing.xs) {
                    Text("just for you")
                        .font(AppFonts.overline)
                        .tracking(1.4)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.bottom, AppSpacing.sm)

                Text("Everything you said")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.bottom, AppSpacing.xs)

                Text(raterPhase == .ready
                     ? "Still yours, still private. Tap above to see where you two meet."
                     : "Your full read, kept private. Where it meets \(partnerName)'s appears once they finish theirs.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, AppSpacing.lg)

                // Answer groups
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ForEach(Array(store.ratedItemsByGroup.enumerated()), id: \.element.0) { idx, pair in
                        _MirrorGroup(rating: pair.0, items: pair.1, index: idx)
                    }
                }

                if raterPhase != .ready {
                    Text("No rush, and no race. Your overlap with \(partnerName) appears whenever they finish.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xl)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var readyBar: some View {
        // A Button (not a bare onTapGesture) so it carries the press style + haptic,
        // matching every other tappable affordance in the rater.
        Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
            HStack(spacing: AppSpacing.sm) {
                Text("**\(partnerName) finished.** Your map is ready.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("→")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumMagenta)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumMagenta.opacity(0.12), AppColors.spectrumPurple.opacity(0.18)],
                        startPoint: .leading, endPoint: .trailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColors.spectrumPurple.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(_RaterPressStyle())
    }

    // MARK: - Empty / error

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: AppIcons.heartTextSquareOutline)
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textTertiary)
            Text("Desire Map unavailable")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            Button { hapticTick += 1; vaylDismiss(confirm: false) } label: {
                Text("Close").font(AppFonts.ctaLabel).foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Actions

    private func choose(_ weight: DesireRatingValue, for item: DesireItem) {
        store.rate(itemId: item.id, rating: weight)
        hapticTick += 1

        // Two-phase depth-push, synced with the rising star: the new answer star
        // lifts into the sky on desireStarRise, fired alongside the outgoing question
        // receding (desireDepthExit) while the incoming question emerges from depth
        // (desireDepthEnter). The per-phase depth animations ride on the question
        // transition itself; this withAnimation only triggers the index change.
        withAnimation(AppAnimation.desireStarRise.reduceMotionSafe) { starRiseTick += 1 }
        withAnimation(AppAnimation.desireDepthExit.reduceMotionSafe) { index += 1 }
    }

    private func back() {
        guard index > 0 else { return }
        // Snappier back read — the emerging question arrives on desireDepthEnter.
        withAnimation(AppAnimation.desireDepthEnter.reduceMotionSafe) { index -= 1 }
    }

    private func pillHint(for weight: DesireRatingValue) -> String {
        switch weight {
        case .excitedAboutIt: return "i want this"
        case .openToIt:       return "i'm curious"
        case .probablyNot:    return "not right now"
        case .notForMe:       return "stays private"
        }
    }
}

// MARK: - Press style

private struct _RaterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Star accumulation field (S2.2)

// Vogel phyllotaxis spiral, upper 38% of screen. Stars ONLY appear for excited/open answers.
// Excited stars are larger and brighter than open stars — the sky remembers your enthusiasm.
private struct _StarAccum: View {
    /// Ordered list of positive ratings (excited/open) in answer order.
    let ratings: [DesireRatingValue]
    /// Bumped on each answer commit so the newly added star rises in sync with the
    /// question receding (desireStarRise fired alongside desireDepthExit in choose()).
    var riseTrigger: Int = 0

    private static let positions: [(CGFloat, CGFloat)] = {
        let golden: Double = 2.399963229728653
        return (0..<17).map { i in
            let t   = Double(i + 1) / 20.0
            let r   = sqrt(t) * 0.36
            let ang = Double(i) * golden
            let x   = CGFloat(max(0.09, min(0.91, 0.50 + r * cos(ang))))
            let y   = CGFloat(max(0.04, min(0.40, 0.22 + r * sin(ang) * 0.72)))
            return (x, y)
        }
    }()

    var body: some View {
        GeometryReader { geo in
            let count = min(ratings.count, Self.positions.count)
            ForEach(0..<count, id: \.self) { i in
                let excited = ratings[i] == .excitedAboutIt
                let sz: CGFloat = excited ? 34 : 24
                _AccumStar(isExcited: excited)
                    .frame(width: sz, height: sz)
                    .position(
                        x: geo.size.width  * Self.positions[i].0,
                        y: geo.size.height * Self.positions[i].1
                    )
                    .transition(
                        .scale(scale: 0.1)
                        .combined(with: .opacity)
                        .combined(with: .offset(y: 28))
                    )
            }
        }
        // The accumulating star rises on desireStarRise, driven by the answer-tap
        // trigger so it lifts in sync with the question receding (desireDepthExit).
        .animation(AppAnimation.desireStarRise.reduceMotionSafe, value: riseTrigger)
    }
}

// Star node with cross-hair glow lines, matching the HTML reference.
// Excited: larger glow (34px), brighter core (4.5pt). Open: smaller (24px), dimmer (3.2pt).
private struct _AccumStar: View {
    var isExcited: Bool = false

    private var glowSize: CGFloat { isExcited ? 34 : 24 }
    private var coreSize: CGFloat { isExcited ? 4.5 : 3.2 }
    private var restOpacity: Double { isExcited ? 0.72 : 0.50 }

    var body: some View {
        ZStack {
            // Outer glow blob
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.55), AppColors.spectrumMagenta.opacity(0.32), .clear],
                    center: .center, startRadius: 0, endRadius: glowSize / 2
                ))
                .blur(radius: 5)

            // Horizontal cross line
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.50), .clear],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: glowSize, height: 1)

            // Vertical cross line
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.50), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 1, height: glowSize)

            // Bright core dot
            Circle()
                .fill(.white)
                .frame(width: coreSize, height: coreSize)
                .shadow(color: AppColors.spectrumMagenta.opacity(0.80), radius: 3)
                .shadow(color: AppColors.spectrumPurple.opacity(0.40), radius: 7)
        }
        .frame(width: glowSize, height: glowSize)
        .opacity(restOpacity)
    }
}

// MARK: - Charted line (S2.3 — hesitant sketch animation)

private struct _ChartedLine: View {
    let sx: CGFloat; let sy: CGFloat
    let ex: CGFloat; let ey: CGFloat
    let delay: Double

    @State private var trimTo: CGFloat  = 0
    @State private var lineOp: Double   = 0

    var body: some View {
        Path { p in p.move(to: CGPoint(x: sx, y: sy)); p.addLine(to: CGPoint(x: ex, y: ey)) }
            .trim(from: 0, to: trimTo)
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
            .opacity(lineOp)
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(delay))
                    // FLAG: no exact AppAnimation match for these two (0.45 ease-out, 0.35
                    // ease-in-out) — every 0.45/0.35 token in AppAnimation.swift is scoped
                    // "exclusive to Onboarding canvas / Splash / StatPhase, never elsewhere"
                    // by its section banner. Left raw per no-mint-authority rule; needs a
                    // Desire Map-scoped mint (or reuse sign-off) from the mint pass.
                    withAnimation(.easeOut(duration: 0.45)) { trimTo = 0.88; lineOp = 0.22 }
                    try? await Task.sleep(for: .seconds(0.45))
                    withAnimation(.easeInOut(duration: 0.35)) { trimTo = 0.52; lineOp = 0.12 }
                    try? await Task.sleep(for: .seconds(0.45))
                    withAnimation(AppAnimation.desireFinishFade) { trimTo = 0; lineOp = 0 }
                }
            }
    }
}

// MARK: - Mirror group (S2.4 — one per rating group, matches HTML .agroup/.arow pattern)
// Label: small uppercase in accent color. Rows: subtle dark bg + thin border, 3px accent bar.
// Positive rows get a "›" in purple; muted rows (probably not / not for me) get no bg fill.

private struct _MirrorGroup: View {
    let rating: DesireRatingValue
    let items: [DesireItem]
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var label: String {
        switch rating {
        case .excitedAboutIt: return "Excited about it"
        case .openToIt:       return "Open to it"
        case .probablyNot:    return "Probably not"
        case .notForMe:       return "Not for me"
        }
    }

    private var isMuted: Bool {
        rating == .probablyNot || rating == .notForMe
    }

    private var labelColor: Color {
        switch rating {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return AppColors.textTertiary
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    private var barColor: Color {
        switch rating {
        case .excitedAboutIt: return AppColors.spectrumCyan
        case .openToIt:       return AppColors.spectrumPurple
        case .probablyNot:    return Color.white.opacity(0.22)
        case .notForMe:       return AppColors.spectrumMagenta
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label.uppercased())
                .font(AppFonts.overline)
                .tracking(1.4)
                .foregroundStyle(labelColor)

            ForEach(items) { item in
                HStack(spacing: AppSpacing.md) {
                    // Lit accent chip — a soft same-colour glow gives each row its emotion's
                    // light (the star/core glow language in _AccumStar). Muted rows stay flat.
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .fill(barColor)
                        .frame(width: 3, height: 18)
                        .shadow(color: isMuted ? .clear : barColor.opacity(0.6), radius: 3)

                    Text(item.name)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(isMuted ? AppColors.textTertiary : AppColors.textPrimary)

                    Spacer(minLength: 0)

                    if !isMuted {
                        Text("›")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.spectrumPurple)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                // Canonical glass surface; positive rows carry their emotion in the hairline,
                // muted rows recede (neutral, dimmed). Replaces the near-invisible hand-rolled fill.
                .vaylGlassCard(accent: isMuted ? nil : barColor, radius: AppRadius.md)
                .opacity(isMuted ? 0.5 : 1)
            }
        }
        // Groups arrive with a soft staggered lift (reduce-motion: a clean fade, no travel).
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : (reduceMotion ? 0 : 10))
        .onAppear {
            withAnimation(
                AppAnimation.desireDepthEnter
                    .delay(Double(index) * AppAnimation.desireBeatStaggerStep)
                    .reduceMotionSafe
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Start screen") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Rating — mid-map") {
    let container = ModelContainer.previewContainer
    container.mainContext.insert(UserProfile(displayName: "Jordan", nmStage: .curious))
    try? container.mainContext.save()
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    return DesireMapView(store: store, partnerName: "Alex")
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Mirror — first finisher") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    // Pre-rate all items so the mirror screen shows
    DesireRatingValue.allCases.enumerated().forEach { idx, weight in
        if idx < store.items.count { store.rate(itemId: store.items[idx].id, rating: weight) }
    }
    return DesireMapView(store: store, partnerName: "Alex")
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Ready bar — partner done") {
    let container = ModelContainer.previewContainerWithProfile
    let appState = AppState()
    let store = DesireMapStore(modelContainer: container, appState: appState)
    store.load()
    DesireRatingValue.allCases.enumerated().forEach { idx, weight in
        if idx < store.items.count { store.rate(itemId: store.items[idx].id, rating: weight) }
    }
    return DesireMapView(store: store, partnerName: "Alex", partnerComplete: true)
        .environment(appState)
        .preferredColorScheme(.dark)
}

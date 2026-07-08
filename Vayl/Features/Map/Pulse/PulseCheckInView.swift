// Features/Pulse/PulseCheckInView.swift
//
// The check-in ceremony: a PulseField with a drifting aura + Q1-Q5 question/pill
// panels. Presented as a .vaylCover (full-screen, discrete task, not confirm-guarded)
// over Home or Map. Owns its own void + atmosphere background — the trail-in mask
// starts a little earlier than the app-wide default so the graph reads as sitting
// atop a rising warmth instead of a hard void/colour seam.
//
// Ceremony:
//   1. Aura appears centred in the field (neutral position).
//   2. Every answer shifts the running position; the aura slides to match and its colour
//      blends continuously across the field (bilinear — no quadrant snap).
//   3. After Q5 the space is classified:
//        · Uncharted (contradictory on both axes) → the field fades away, the orb dissolves
//          to Sage Deep and drifts, no bloom ring (drift IS the landing signal).
//        · Otherwise the aura blooms and the Space name is revealed.
//   4. "Done" writes the entry to the store and closes the cover.
//
// The step row (in place of a plain "N of 5" counter) doubles as navigation: any
// already-answered question can be tapped to revisit and change it; future questions
// stay dim and untappable — no skipping ahead, only revisiting what's behind you.

import SwiftUI

struct PulseCheckInView: View {

    let store: PulseStore
    var onClose: () -> Void

    // Q1-Q5 answers. Index matches PulseAnswers.all.
    @State private var answers: [String?] = Array(repeating: nil, count: 5)
    @State private var currentQ: Int       = 0
    @State private var revealed: Bool      = false   // reveal panel shown (space named)
    @State private var advancing: Bool      = false   // debounces rapid taps

    // Uncharted resolution state.
    @State private var unchartedFired: Bool   = false  // variance check passed on final answer
    @State private var unchartedDissolveT: Double = 0      // 0 = bilinear colour, 1 = full Sage Deep
    @State private var drifting: Bool   = false  // orb wander begins after the dissolve

    /// The trail-in mask starts well earlier than the app-wide 52% default — see
    /// OnboardingAtmosphere.maskStart. Lowered from 0.46: against the field's now much more
    /// vivid blob coverage, the void held that long read as a hard black band rather than a
    /// smooth trail-in. 🎚️ FEEL: confirm on device, tune further from here.
    private let atmosphereMaskStart: CGFloat = 0.30

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            // The field owns the top of the screen, running nearly edge-to-edge (capped at a
            // square by the screen width). 🎚️ FEEL: 0.50 of the height (was 0.42) — the field
            // read too small against its mockup on device; tune further from here so the five
            // pills always clear the bottom without the field shrinking.
            let fieldSize = min(layout.screenWidth, geo.size.height * 0.50)
            ZStack(alignment: .top) {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat, maskStart: atmosphereMaskStart)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    fieldSection(size: fieldSize)

                    if revealed {
                        spaceReveal
                            .padding(.horizontal, AppSpacing.lg)
                    } else {
                        questionSection
                            .padding(.horizontal, AppSpacing.lg)
                    }

                    Spacer(minLength: AppSpacing.sm)
                }
                .topClearance(layout, padding: AppSpacing.xs)
                .padding(.bottom, AppSpacing.xl)

                // Header chrome floats over the top edge of the field (per the mockup) — it
                // reclaims the row the enlarged field now occupies, so the graph can breathe.
                // Shrunk (back button 32->28, step dots 22/18->20/16) and pulled to the bare
                // safe-area clearance (no extra padding) so it recedes into a slimmer strip
                // instead of competing with the now-bigger field for vertical room.
                headerChrome
                    .padding(.horizontal, AppSpacing.lg)
                    .topClearance(layout, padding: 0)
            }
        }
        .screenshotProtected()
    }

    // MARK: - Back button

    /// Exit — a .vaylCover always disables interactive/swipe dismiss, and this cover
    /// has no confirm-on-exit sheet either, so without this the check-in had no way to
    /// leave early short of finishing all 5 questions.
    private var backButton: some View {
        Button { onClose() } label: {
            Image(systemName: "chevron.left")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppColors.cardBackground))
                .overlay(Circle().strokeBorder(AppColors.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leave check-in")
    }

    // MARK: - Header

    /// One overlaid row (mockup img2): back chevron leading, "Check in" centred, steps trailing.
    private var headerChrome: some View {
        ZStack {
            Text("Check in")
                .font(AppFonts.cardTitleCompact)
                .foregroundStyle(AppColors.textPrimary)
            HStack(spacing: AppSpacing.sm) {
                backButton
                Spacer()
                stepRow
            }
        }
    }

    /// Numbered steps, no prev/next arrows — the numbers themselves ARE the navigation
    /// (tap any answered one to revisit it); the corner arrow above is for leaving the
    /// check-in entirely, a separate concern.
    private var stepRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<PulseAnswers.all.count, id: \.self) { index in
                stepDot(index)
            }
        }
    }

    @ViewBuilder
    private func stepDot(_ index: Int) -> some View {
        let isDone   = index < currentQ || revealed
        let isNow    = index == currentQ && !revealed
        let isFuture = !isDone && !isNow

        Button {
            revisit(index)
        } label: {
            Text("\(index + 1)")
                .font(AppFonts.buttonLabelSmall)
                .fontWeight(isNow ? .bold : .medium)
                .foregroundStyle(isFuture ? AppColors.textTertiary : AppColors.textPrimary)
                .frame(width: isNow ? 20 : 16, height: isNow ? 20 : 16)
                .overlay(
                    Circle().strokeBorder(
                        isNow ? AppColors.textSectionLabel : Color.clear,
                        lineWidth: 2
                    )
                )
                .shadow(color: isNow ? AppColors.textSectionLabel.opacity(0.35) : .clear, radius: isNow ? 8 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel("Question \(index + 1)\(isDone ? ", answered" : isNow ? ", current" : "")")
        .accessibilityHint(isFuture ? "" : "Revisit this question")
    }

    // MARK: - Field

    private func fieldSection(size: CGFloat) -> some View {
        PulseField(
            entries: [
                PulseFieldEntry(
                    // Uncharted has no fixed coordinate — the orb glides to centre and drifts
                    // there on the emptied void, rather than sitting at its raw answer position.
                    position: unchartedFired ? PulsePosition(energy: 0.5, openness: 0.5) : currentPosition,
                    auraSize: size * 0.24,   // 🎚️ FEEL: orb ≈ 24% of field (mockup proportion)
                    isBloom: revealed && !unchartedFired,
                    rampOverride: currentRamp,
                    space: revealed ? currentSpace : nil,
                    isDrifting: drifting
                )
            ],
            size: size,
            isUncharted: unchartedFired
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Question + pills

    @ViewBuilder
    private var questionSection: some View {
        if currentQ < PulseAnswers.all.count {
            let q = PulseAnswers.all[currentQ]
            VStack(spacing: AppSpacing.md) {
                Text(q.text)
                    .font(AppFonts.prompt)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                VStack(spacing: AppSpacing.xs) {
                    ForEach(q.pills) { pill in
                        SelectablePill(
                            label: pill.label,
                            isSelected: answers[currentQ] == pill.label,
                            intensity: .warm,
                            showFlame: false
                        ) {
                            selectPill(pill.label, qIndex: currentQ)
                        }
                    }
                }
            }
            .padding(.top, AppSpacing.lg)
            .id(currentQ)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(x: 0, y: 6)),
                removal: .opacity.combined(with: .offset(x: 0, y: -6))
            ))
        }
    }

    // MARK: - Space reveal

    private var spaceReveal: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.xs) {
                Text(currentSpace.title(at: currentPosition))
                    .font(AppFonts.cardTitle)
                    // Matches the orb exactly — for Uncharted this dissolves to Sage Deep in
                    // lockstep with the orb instead of snapping ahead of it.
                    .foregroundStyle(currentRamp.core)
                    .multilineTextAlignment(.center)

                Text(currentSpace.descriptors(at: currentPosition))
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, AppSpacing.md)

            Spacer(minLength: AppSpacing.sm)

            Button(action: commitEntry) {
                Text("Done")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.pill)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: AppColors.accentPrimary, location: 0),
                                        .init(color: AppColors.accentSecondary, location: 0.5),
                                        .init(color: AppColors.accentTertiary, location: 1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Running position / colour / space

    /// The single source of truth for position — PulseAnswers.position over all 5 answers.
    /// Unanswered axes contribute a neutral baseline, so the aura starts near centre and
    /// slides as answers land.
    private var currentPosition: PulsePosition {
        PulseAnswers.position(answers)
    }

    /// The classified space once revealed — carries the Uncharted result of the variance check.
    private var currentSpace: PulseSpace {
        PulseSpace.resolve(currentPosition, isUncharted: unchartedFired)
    }

    /// Orb colour through the ceremony:
    ///   • Silver until the first answer lands.
    ///   • Uncharted: dissolves from the live bilinear colour to Sage Deep over the dissolve window.
    ///   • Revealed (non-uncharted): the landed space's ramp (lavender for Neutral, else bilinear).
    ///   • Mid-flow: a continuous bilinear blend of the current position.
    private var currentRamp: AuraColors {
        guard answers.contains(where: { $0 != nil }) else {
            return AuraColors(
                light: AppColors.auraLightStart,
                core: AppColors.auraCoreStart,
                deep: AppColors.auraDeepStart,
                glow: AppColors.auraGlowStart
            )
        }
        if unchartedFired {
            return AuraColors.lerp(
                AuraColors.bilinear(energy: currentPosition.energy, openness: currentPosition.openness),
                .uncharted,
                unchartedDissolveT
            )
        }
        if revealed {
            return currentSpace.ramp(at: currentPosition)
        }
        return AuraColors.bilinear(energy: currentPosition.energy, openness: currentPosition.openness)
    }

    // MARK: - Step navigation

    /// Jumps back to an already-answered question. Resets the reveal/Uncharted state so a
    /// changed answer re-runs the classification cleanly on the next pass.
    private func revisit(_ index: Int) {
        guard !advancing, index != currentQ || revealed else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(AppAnimation.standard) {
            revealed  = false
            currentQ  = index
        }
        resetUncharted()
    }

    private func resetUncharted() {
        unchartedFired     = false
        drifting           = false
        unchartedDissolveT = 0
    }

    // MARK: - Pill selection

    private func selectPill(_ label: String, qIndex: Int) {
        guard !advancing else { return }
        advancing = true

        // Drift the aura immediately when an answer is given.
        withAnimation(AppAnimation.pulseBallDrift) {
            answers[qIndex] = label
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            if qIndex == PulseAnswers.all.count - 1 {
                finishFinalAnswer()
            } else {
                withAnimation(AppAnimation.standard) { currentQ = qIndex + 1 }
            }
            advancing = false
        }
    }

    /// After the last answer: classify, then either reveal-with-bloom or run the Uncharted
    /// resolution sequence (field fades, colour dissolves to Sage Deep, then the orb drifts).
    private func finishFinalAnswer() {
        let fired = PulseAnswers.isUncharted(answers)

        withAnimation(AppAnimation.standard) { revealed = true }

        guard fired else { return }

        // Uncharted: fade the field + dissolve the orb colour simultaneously (PulseField owns
        // the field fade via isUncharted; the dissolve rides unchartedDissolveT here).
        unchartedFired = true
        withAnimation(AppAnimation.pulseUnchartedColorDissolve) { unchartedDissolveT = 1 }

        // Drift begins after the dissolve completes — kicked off detached (not awaited) so
        // `advancing` clears immediately and the step-dots stay tappable during the dissolve.
        // Guarded so a mid-dissolve revisit (which clears unchartedFired) cancels the drift.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard unchartedFired else { return }
            drifting = true
        }
    }

    // MARK: - Commit

    /// All 5 questions are required — `revealed` (which gates "Done") only becomes true after
    /// `selectPill` has walked through every question in order, so this should never fail in
    /// practice. It's a hard guard: a partial check-in must never commit.
    private func commitEntry() {
        guard
            let nervousSystem = answers[0],
            let focus         = answers[1],
            let feeling       = answers[2],
            let capacity      = answers[3],
            let speed         = answers[4]
        else {
            assertionFailure("PulseCheckInView.commitEntry called before all questions were answered")
            return
        }

        let pos = PulseAnswers.position(answers)

        let entry = PulseEntry(
            date: Date(),
            capacityScore: pos.capacityScore,
            glowColor: pos.quadrant.capacityColor,
            speed: speed,
            nervousSystem: nervousSystem,
            focus: focus,
            feeling: feeling,
            capacity: capacity,
            position: pos
        )
        store.add(entry)
        onClose()
    }
}

// MARK: - Preview

#Preview("Check-in — full screen") {
    PulseCheckInView(store: PulseStore(), onClose: {})
        .preferredColorScheme(.dark)
}

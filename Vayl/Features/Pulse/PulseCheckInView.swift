// Features/Pulse/PulseCheckInView.swift
//
// The check-in ceremony: a PulseField with a drifting aura + Q1-Q5 question/pill
// panels. Presented as a .vaylSheet (large detent) over Home or Map — not a cover,
// because this is a discrete task, not a protected immersive mode.
//
// Ceremony:
//   1. Aura appears centred in the field (neutral position).
//   2. Each Q1-Q3 answer shifts the running position and the aura drifts with a
//      spring animation to match.
//   3. Q4 (capacity tier) and Q5 (speed) are recorded but don't affect position.
//   4. After Q5, the aura blooms (ring expands) and the Space name is revealed.
//   5. "Done" writes the entry to the store and closes the sheet.

import SwiftUI

struct PulseCheckInView: View {

    let store:   PulseStore
    var onClose: () -> Void

    // Q1-Q5 answers. Index matches PulseAnswers.all.
    @State private var answers:    [String?]  = Array(repeating: nil, count: 5)
    @State private var currentQ:   Int        = 0
    @State private var bloomDone:  Bool       = false
    @State private var advancing:  Bool       = false   // debounces rapid taps

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, AppSpacing.md)

            fieldSection
                .padding(.bottom, AppSpacing.sm)

            if bloomDone {
                bloomReveal
            } else {
                questionSection
            }

            Spacer(minLength: AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Check in")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(bloomDone ? "Done" : "\(currentQ + 1) of 5")
                .font(AppFonts.caption)
                .foregroundStyle(bloomDone ? AppColors.accentPrimary : AppColors.textMuted)
                .animation(AppAnimation.fast, value: bloomDone)
        }
    }

    // MARK: - Field

    private var fieldSection: some View {
        PulseField(
            entries: [
                PulseFieldEntry(
                    position: currentPosition,
                    auraSize: 40,
                    isBloom:  bloomDone
                )
            ],
            size: 200
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Question + pills

    @ViewBuilder
    private var questionSection: some View {
        if currentQ < PulseAnswers.all.count {
            let q = PulseAnswers.all[currentQ]
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(q.text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.xs)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(q.pills) { pill in
                            SelectablePill(
                                label:      pill.label,
                                isSelected: answers[currentQ] == pill.label,
                                intensity:  .warm,
                                height:     38,
                                fontSize:   13,
                                showFlame:  false
                            ) {
                                selectPill(pill.label, qIndex: currentQ)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
            .id(currentQ)
            .transition(.asymmetric(
                insertion:  .opacity.combined(with: .offset(x: 0, y: 6)),
                removal:    .opacity.combined(with: .offset(x: 0, y: -6))
            ))
        }
    }

    // MARK: - Bloom reveal

    private var bloomReveal: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.xs) {
                Text(currentPosition.quadrant.spaceName)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(currentPosition.quadrant.capacityColor.auraCore)
                    .multilineTextAlignment(.center)

                Text(currentPosition.quadrant.sublabel)
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
                                        .init(color: AppColors.accentPrimary,   location: 0),
                                        .init(color: AppColors.accentSecondary, location: 0.5),
                                        .init(color: AppColors.accentTertiary,  location: 1),
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

    // MARK: - Running position

    /// Computes position incrementally from answered questions.
    /// Unanswered questions contribute no delta (aura starts centred).
    private var currentPosition: PulsePosition {
        var energy: Double = 0.5
        var openness: Double = 0.5

        // Q1 → energy axis
        if let ns = answers[0],
           let pill = PulseAnswers.nervousSystem.pills.first(where: { $0.label == ns }) {
            energy = 0.5 + pill.energyDelta * 0.5
        }

        // Q2 + Q3 → openness axis (blended; partial weight until both answered)
        let o2 = answers[1].flatMap { a in
            PulseAnswers.focus.pills.first(where: { $0.label == a })?.opennessDelta
        }
        let o3 = answers[2].flatMap { a in
            PulseAnswers.feeling.pills.first(where: { $0.label == a })?.opennessDelta
        }
        switch (o2, o3) {
        case let (.some(d2), .some(d3)): openness = 0.5 + (d2 * 0.6 + d3 * 0.4) * 0.5
        case let (.some(d2), nil):       openness = 0.5 + d2 * 0.6 * 0.5
        case let (nil, .some(d3)):       openness = 0.5 + d3 * 0.4 * 0.5
        case (nil, nil):                 break
        }

        return PulsePosition(energy: energy, openness: openness)
    }

    // MARK: - Pill selection

    private func selectPill(_ label: String, qIndex: Int) {
        guard !advancing else { return }
        advancing = true

        // Drift the aura immediately when an axis-affecting answer is given.
        withAnimation(AppAnimation.spring) {
            answers[qIndex] = label
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(AppAnimation.standard) {
                if qIndex == PulseAnswers.all.count - 1 {
                    bloomDone = true
                } else {
                    currentQ = qIndex + 1
                }
            }
            advancing = false
        }
    }

    // MARK: - Commit

    private func commitEntry() {
        let pos = currentPosition

        let glowColor = answers[3].flatMap { a in
            PulseAnswers.glowColor.pills.first(where: { $0.label == a })?.glowOverride
        } ?? pos.quadrant.capacityColor

        let entry = PulseEntry(
            date:          Date(),
            capacityScore: pos.capacityScore,
            glowColor:     glowColor,
            speed:         answers[4] ?? "Light Connection",
            nervousSystem: answers[0] ?? "Stable",
            focus:         answers[1] ?? "Balanced",
            feeling:       answers[2] ?? "Content",
            position:      pos
        )
        store.add(entry)
        onClose()
    }
}

// MARK: - Preview

#Preview("Check-in sheet") {
    GeometryReader { geo in
        ZStack(alignment: .bottom) {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()
            PulseCheckInView(store: PulseStore(), onClose: {})
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .padding(.horizontal, AppSpacing.sm)
                .frame(maxHeight: geo.size.height * 0.82)
        }
    }
    .preferredColorScheme(.dark)
}

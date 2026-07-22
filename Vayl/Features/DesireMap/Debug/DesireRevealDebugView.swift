//
//  DesireRevealDebugView.swift
//  Vayl
//
//  DEBUG-only harness for dialling the Desire Map reveal sequence on device.
//
//  The sequence: stars cascade into an empty sky hero-outward → hold → the lines DRAW outward
//  from the hero → hold → the match rows cascade in, all locked → hold → the free match opens,
//  its row and its star landing on the same frame.
//
//  Spec: plans/001-desire-reveal-constellation-sequence.md
//  Feel reference: docs/mockups/desire-reveal-sequence.html
//
//  This is where the numbers get decided. Everything on the panel writes to
//  `DesireSequenceTuning`; "Copy values" prints a paste-ready block for AppAnimation's literals.
//

#if DEBUG
import SwiftUI

struct DesireRevealDebugView: View {

    @Environment(AppState.self) private var appState
    @Environment(EntitlementStore.self) private var entitlements

    /// The live dial. `@Bindable` gives the sliders real two-way bindings, so the panel never has
    /// to invalidate itself by hand — an earlier version did, and remounting the `Slider` on every
    /// value change cancelled the drag gesture, making the sliders impossible to move.
    @Bindable private var tuning = DesireSequenceTuning.shared

    @State private var matchCount: Int = 5
    @State private var variant: CeremonyVariant = .gather
    /// Free reveal (locked stubs, beat-1 ceremony) vs post-unlock (all named, the variant's assemble
    /// ceremony). The gather/sweep/constellate variants ONLY play post-unlock — in the free reveal
    /// the cascade is variant-blind by design, so the picker does nothing there.
    @State private var postUnlock = false
    @State private var runID = UUID()
    @State private var showPanel = true
    @State private var exported: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            reveal
                // A fresh identity is the whole replay mechanism: the store rebuilds, the
                // constellation's `.task` restarts, and every entrance plays from the top.
                .id(runID)

            controlToggle
        }
        .overlay(alignment: .bottom) {
            if showPanel { panel.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .animation(AppAnimation.enter, value: showPanel)
    }

    // MARK: - The reveal under test

    private var reveal: some View {
        DesireRevealView(store: makeStore())
            .environment(appState)
            .environment(entitlements)
    }

    private static let sampleNames = ["New Relationship Energy", "Overnight Stays", "Meeting Partners",
        "Shared Space", "Deep Conversations", "Slow Mornings", "Being Introduced", "Travel Together",
        "Weeknight Rituals", "Quiet Weekends", "Long Drives", "Open Calendars"]

    /// A store preloaded with `matchCount` matches.
    /// - Free reveal (`postUnlock == false`): one free hero + server-shaped locked stubs (no name,
    ///   category teaser only) — the exact shape a free couple receives; runs the beat-1 ceremony.
    /// - Post-unlock (`postUnlock == true`): every match named + unlocked, so the store lands on
    ///   `.revealed` and plays the selected **variant's** assemble ceremony — the only place the
    ///   gather/sweep/constellate difference actually exists.
    private func makeStore() -> DesireRevealStore {
        var matches: [RevealMatch]
        if postUnlock {
            matches = (0..<matchCount).map { i in
                .sample(Self.sampleNames[i % Self.sampleNames.count],
                        i % 3 == 0 ? .adjacent : .mutual,
                        free: i == 0)
            }
        } else {
            matches = [.sample("New Relationship Energy", .mutual, free: true)]
            let categories: [String?] = ["logistics", "emotional", nil, "physical", "emotional",
                                         "logistics", nil, "emotional", "physical", nil, "logistics"]
            for i in 0..<max(matchCount - 1, 0) {
                matches.append(RevealMatch(
                    id: UUID(), itemName: nil, itemCategory: categories[i % categories.count],
                    alignment: nil, isLocked: true, bridgeCardId: nil))
            }
        }
        let store = DesireRevealStore.previewStore(matches: matches)
        store.debugVariantOverride = variant
        return store
    }

    // MARK: - Controls

    private var controlToggle: some View {
        Button {
            showPanel.toggle()
        } label: {
            Image(systemName: showPanel ? "slider.horizontal.3" : "slider.horizontal.below.rectangle")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(AppSpacing.sm)
                .background(Circle().fill(AppColors.cardBg.opacity(0.85)))
        }
        .padding(.trailing, AppSpacing.lg)
        .padding(.top, AppSpacing.xxl)
    }

    private var panel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {

                HStack {
                    Button("▶ Replay") { runID = UUID() }
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(AppColors.textBright)
                    Spacer()
                    Button("Reset") { tuning.reset(); runID = UUID() }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Button("Copy values") { exported = tuning.export }
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textAccent)
                }

                section("Fixture")
                stepperRow("matches", value: $matchCount, range: 1...12)
                Toggle("post-unlock (assemble)", isOn: $postUnlock)
                    .font(AppFonts.caption)
                    .tint(AppColors.spectrumMagenta)
                    .onChange(of: postUnlock) { _, _ in runID = UUID() }
                variantPicker
                Text(postUnlock
                     ? "Variant plays here. Compare gather / sweep / constellate."
                     : "Variant does nothing in the free reveal — flip on post-unlock to compare the three.")
                    .font(AppFonts.body(9, weight: .regular, relativeTo: .caption2))
                    .foregroundStyle(AppColors.textTertiary)

                section("0 · Star size")
                slider("size × base", $tuning.starSizeScale, 0.6...2.0, unit: "×")

                section("0b · Brightness hierarchy")
                slider("dormant core", $tuning.lockedCore, 0.2...0.9, unit: "")
                slider("dormant glow", $tuning.lockedGlow, 0.05...0.6, unit: "")
                slider("line opacity", $tuning.lineOpacity, 0.15...0.9, unit: "")
                slider("dormant size", $tuning.dormantSizeScale, 1.0...1.4, unit: "×")

                section("1 · Star cascade")
                slider("stagger step", $tuning.starCascadeStep, 0.02...0.30)
                slider("bloom duration", $tuning.starBloomDuration, 0.18...1.20)

                section("2 · Hold")
                slider("stars → lines", $tuning.holdStarsToLines, 0...1.20)

                section("3 · Line draw")
                slider("draw duration", $tuning.lineDrawDuration, 0.20...2.00)
                slider("per-line stagger", $tuning.lineDrawStep, 0...0.30)
                curvePicker

                section("4 · Rows cascade")
                slider("lines → rows", $tuning.holdLinesToRows, 0...1.60)
                slider("row stagger step", $tuning.rowStaggerStep, 0.02...0.26)
                slider("row enter duration", $tuning.rowEnterDuration, 0.14...0.90)

                section("5 · First reveal")
                slider("rows → reveal", $tuning.holdRowsToReveal, 0...2.00)

                section("Tail")
                slider("beat1 settle", $tuning.beatHold1, 0...1.50)

                if let exported {
                    Text(exported)
                        .font(AppFonts.body(10, weight: .regular, relativeTo: .caption2))
                        .monospaced()
                        .foregroundStyle(AppColors.textSecondary)
                        .textSelection(.enabled)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: AppRadius.sm).fill(AppColors.void.opacity(0.7)))
                }
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .padding(AppSpacing.sm)
    }

    // MARK: - Control atoms

    private func section(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.overline)
            .tracking(1.2)
            .foregroundStyle(AppColors.textTertiary)
            .padding(.top, AppSpacing.xs)
    }

    /// A labelled slider bound straight to the dial. Replays on *release* (not on every value
    /// change) so dragging doesn't restart the sequence each frame — and, critically, the view is
    /// NOT invalidated on change, so the drag gesture is never interrupted.
    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, unit: String = "s") -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.2f%@", value.wrappedValue, unit))
                    .font(AppFonts.caption)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textAccent)
            }
            Slider(value: value, in: range) { editing in
                if !editing { runID = UUID() }
            }
            .tint(AppColors.spectrumMagenta)
        }
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: range)
                .labelsHidden()
            Text("\(value.wrappedValue)")
                .font(AppFonts.caption).monospacedDigit()
                .foregroundStyle(AppColors.textAccent)
        }
        .onChange(of: value.wrappedValue) { _, _ in runID = UUID() }
    }

    private var variantPicker: some View {
        Picker("variant", selection: $variant) {
            Text("gather").tag(CeremonyVariant.gather)
            Text("sweep").tag(CeremonyVariant.sweep)
            Text("constellate").tag(CeremonyVariant.constellate)
        }
        .pickerStyle(.segmented)
        .onChange(of: variant) { _, _ in runID = UUID() }
    }

    private var curvePicker: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(Array(DesireSequenceTuning.curves.enumerated()), id: \.offset) { i, c in
                Button {
                    tuning.lineCurveIndex = i
                    runID = UUID()
                } label: {
                    Text(c.name)
                        .font(AppFonts.body(9, weight: .medium, relativeTo: .caption2))
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(tuning.lineCurveIndex == i
                                           ? AppColors.spectrumMagenta.opacity(0.35)
                                           : AppColors.cardBg.opacity(0.5)))
                        .foregroundStyle(tuning.lineCurveIndex == i
                                         ? AppColors.textBright : AppColors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Reveal sequence — tuning harness") {
    let appState = AppState()
    DesireRevealDebugView()
        .environment(appState)
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: appState))
        .preferredColorScheme(.dark)
}
#endif

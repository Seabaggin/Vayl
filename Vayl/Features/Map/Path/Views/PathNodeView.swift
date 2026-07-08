//
//  PathNodeView.swift
//  Vayl — Path
//
//  The stage-tap "Mission Brief"-equivalent sheet for a single landmark
//  (spec §9, docs/superpowers/specs/2026-07-07-path-node-state-redesign.md;
//  mockup docs/prototypes/path-node-state-redesign-suite.html §04). The old
//  binary ("We did this" / "Not yet") is replaced by a small, jumpable row of
//  stage taps — Curious · Discussed · Planning · Did it — any of which can be
//  tapped directly, in any order (spec §2: freeform, not order-gated). This is
//  the primary interaction now, not an edge case.
//
//  Curious carries the one privacy gate in this view (spec §4, mockup §05):
//  a first tap only marks it privately (PathStore.markCuriousPrivately) — a
//  quiet, local-only "only you" state — and a second tap shares it onto the
//  couple's map (PathStore.shareCurious). Discussed/Planning/Did it are always
//  unilateral and immediately live (spec §3): whichever partner taps sets the
//  state directly, no confirmation, no dispute flow.
//
//  Presentation is the caller's job (PathTrailView / PathLedgerView, Tasks
//  11-12) — this is content only, self-contained the way the mockup's `.sheet`
//  card is, so it can be dropped into whatever wraps it.
//

import SwiftUI

struct PathNodeView: View {
    @Bindable var store: PathStore
    let landmarkId: String

    /// The presenting screen's true height, threaded down from the caller's own
    /// `AppLayout` (PathTrailView / PathLedgerView, Tasks 11-12) — same
    /// `screenHeight: layout.screenHeight` pattern MapView.swift and
    /// SettingsView.swift already use when a `.vaylSheet` is nested under
    /// content that doesn't itself expand to fill its offered height.
    ///
    /// PathNodeView is content dropped inside another sheet/card, not a screen
    /// root, so its own root VStack sizes to its intrinsic content height
    /// rather than the true screen height. Without this, `dateEditorSheet`'s
    /// nested `.vaylSheet`'s internal GeometryReader would measure that small
    /// intrinsic height instead (VaylPresentation.swift's `screenHeight` doc
    /// comment), undersizing the graphical DatePicker. Optional and defaulted
    /// so this view stays independently previewable/buildable before Tasks
    /// 11-12 exist to supply the real value.
    var screenHeight: CGFloat?

    @State private var showOverflow = false
    @State private var showDatePicker = false
    @State private var pendingDidItDate = Date()

    private var landmark: PathLandmark? {
        store.landmarks.first { $0.id == landmarkId }
    }

    private var state: PathLandmarkState {
        store.state(for: landmarkId)
    }

    var body: some View {
        if let landmark {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header(landmark)

                Text(landmark.eventCopy)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)

                if let goldenRule = landmark.goldenRule {
                    goldenRuleBox(goldenRule)
                }

                stageRow

                if state == .didIt {
                    dateChip
                }
                if state == .discussed {
                    discussedSourceRow
                }

                note
            }
            .padding(AppSpacing.lg)
            .vaylSheet(isPresented: $showDatePicker, heightFraction: 0.62, screenHeight: screenHeight) {
                dateEditorSheet
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Header

    private func header(_ landmark: PathLandmark) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let phase = store.phases.first(where: { $0.id == landmark.phaseId }) {
                    Text("Phase \(phase.id) · \(phase.name)")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textSectionLabel)
                }
                Text(landmark.title)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                if landmarkId == store.nowLandmarkId {
                    nowTag
                }
            }
            Spacer(minLength: AppSpacing.sm)
            overflowButton
        }
    }

    /// The wayfinding anchor (spec §8) — the earliest landmark not yet Did it.
    /// Purely orientational; never a gate on interacting with any other landmark.
    private var nowTag: some View {
        HStack(spacing: AppSpacing.xxs) {
            Circle()
                .fill(AppColors.spectrumCyan)
                .frame(width: 6, height: 6)
            Text("Your current step")
        }
        .font(AppFonts.overline)
        .tracking(1.0)
        .textCase(.uppercase)
        .foregroundStyle(AppColors.spectrumCyan)
        .padding(.top, AppSpacing.xxs)
    }

    private var overflowButton: some View {
        Button {
            showOverflow = true
        } label: {
            Image(systemName: "ellipsis")
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.glassSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Manage this step")
        .confirmationDialog(
            "Manage this step",
            isPresented: $showOverflow,
            titleVisibility: .visible
        ) {
            Button("Edit this step") {
                // No per-landmark edit destination exists yet — Edit your path
                // (Task 13) only toggles landmarks on/off, it doesn't edit state.
                // Wired up once that surface (or a dedicated one) exists.
            }
            Button("Skip — not for us", role: .destructive) {
                Task { try? await store.skip(landmarkId) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Golden rule

    private func goldenRuleBox(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("The golden rule")
                .font(AppFonts.overline)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.spectrumMagenta)
            Text(text)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.spectrumMagenta.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColors.spectrumMagenta.opacity(0.32), lineWidth: 1)
        )
    }

    // MARK: - Stage row — the primary interaction (spec §9)
    //
    // A jumpable row, not a forced linear tap-through — tapping any stage sets
    // it directly. Curious is the one privacy-gated stage (spec §4); the other
    // three are always unilateral and immediately live (spec §3).

    private var stageRow: some View {
        HStack(spacing: AppSpacing.xs) {
            curiousTap
            stageTap(title: "Discussed", isOn: state == .discussed, color: AppColors.spectrumPurple) {
                Task { try? await store.setDiscussed(landmarkId, via: .manual) }
            }
            stageTap(title: "Planning", isOn: state == .planning, color: AppColors.spectrumCyan) {
                Task { try? await store.setPlanning(landmarkId) }
            }
            didItTap
        }
    }

    /// Curious — private until shared (spec §4, mockup §05). First tap marks it
    /// privately (only the tapping partner sees anything); a second tap shares
    /// it onto the couple's map. Once shared, tapping again is a no-op here —
    /// there's no un-share action in this view.
    ///
    /// Gated to `state == .untouched`: the stage row is jumpable (spec §9), so a
    /// landmark can reach Discussed/Planning/Did it without ever passing through
    /// a shared Curious. PathStore only clears a private mark inside
    /// `shareCurious(_:)` — nothing clears it when another stage is set directly
    /// — so once the real state has moved past Curious, a stale private mark
    /// must stop being read as live here, and tapping must stop being able to
    /// regress the landmark back down to `.curious` via `shareCurious`.
    private var curiousTap: some View {
        let shared = state == .curious
        let privateOnly = state == .untouched && store.isPrivatelyMarkedCurious(landmarkId)
        let isOn = shared || privateOnly
        let color = AppColors.spectrumMagenta

        return Button {
            // Only meaningful pre-Curious: `.untouched` covers both "shared
            // already" (state is `.curious`, not `.untouched`, so a repeat tap
            // no-ops) and "moved on to a later stage" (same no-op, instead of
            // regressing the landmark back to Curious).
            guard state == .untouched else { return }
            Task {
                if privateOnly {
                    try? await store.shareCurious(landmarkId)
                } else {
                    try? await store.markCuriousPrivately(landmarkId)
                }
            }
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                Text("Curious")
                    .font(AppFonts.buttonLabelSmall)
                if privateOnly {
                    Text("only you")
                        .font(AppFonts.meta)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .foregroundStyle(isOn ? color : AppColors.textSecondary)
            .opacity(privateOnly ? 0.6 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isOn ? color.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(isOn ? color : AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Guards against re-tapping a stage that's already active — `applyState`
    /// fully overwrites the progress row on every call, so a stray re-tap on an
    /// already-Discussed landmark would silently downgrade `discussedVia` from
    /// `.session` back to `.manual`, destroying the provenance spec §5 wants
    /// preserved. Same shape as `curiousTap`'s and `didItTap`'s own guards.
    private func stageTap(title: String, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            guard !isOn else { return }
            action()
        } label: {
            Text(title)
                .font(AppFonts.buttonLabelSmall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .foregroundStyle(isOn ? color : AppColors.textSecondary)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(isOn ? color.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(isOn ? color : AppColors.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Did it — the unified completion state (spec §2, §7). Same look regardless
    /// of how it was reached; carries the full spectrum, unlike the single-hue
    /// taps above, matching the trail's own `.didit` node treatment.
    ///
    /// Guarded against re-tap: `setDidIt` always stamps `date: Date()`, and
    /// `applyState` overwrites the row wholesale, so a re-tap on an
    /// already-Did-it landmark would silently reset a backdated `didItDate`
    /// (spec §7) to today. Editing the date afterward is the `dateChip`'s job,
    /// not this button's.
    private var didItTap: some View {
        let isOn = state == .didIt
        return Button {
            guard !isOn else { return }
            Task { try? await store.setDidIt(landmarkId, date: Date()) }
        } label: {
            Text("Did it")
                .font(AppFonts.buttonLabelSmall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .foregroundStyle(isOn ? Color.white : AppColors.textSecondary)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(isOn ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.28)) : AnyShapeStyle(Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(isOn ? AnyShapeStyle(AppColors.spectrumBorder) : AnyShapeStyle(AppColors.borderSubtle), lineWidth: 1)
                )
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Did it — date (spec §7: always dated, date is editable)

    private var dateChip: some View {
        HStack(spacing: AppSpacing.xs) {
            if let date = store.didItDate(for: landmarkId) {
                Text("Marked \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Button("Edit date") {
                pendingDidItDate = store.didItDate(for: landmarkId) ?? Date()
                showDatePicker = true
            }
            .font(AppFonts.buttonLabelSmall)
            .foregroundStyle(AppColors.spectrumCyan)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .overlay(
            Capsule().stroke(AppColors.borderSubtle, lineWidth: 1)
        )
    }

    private var dateEditorSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("When did this happen?")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("The date records when it was told to the app, not a claim about exact timing — change it any time to reflect reality.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                DatePicker("", selection: $pendingDidItDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .tint(AppColors.accentPrimary)
                saveDateButton
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var saveDateButton: some View {
        Button {
            Task {
                try? await store.editDidItDate(landmarkId, date: pendingDidItDate)
                showDatePicker = false
            }
        } label: {
            Text("Save")
                .font(AppFonts.buttonLabel)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Capsule().fill(AppColors.accentSecondary))
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Discussed — two distinguishable paths (spec §5)

    private var discussedSourceRow: some View {
        HStack(spacing: AppSpacing.xs) {
            sourcePill("via session", isOn: store.discussedVia(for: landmarkId) == .session)
            sourcePill("noted manually", isOn: store.discussedVia(for: landmarkId) == .manual)
        }
    }

    private func sourcePill(_ title: String, isOn: Bool) -> some View {
        Text(title)
            .font(AppFonts.buttonLabelSmall)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .foregroundStyle(isOn ? AppColors.spectrumPurple : AppColors.textTertiary)
            .overlay(
                Capsule().stroke(isOn ? AppColors.spectrumPurple : AppColors.borderSubtle, lineWidth: 1)
            )
    }

    // MARK: - Footer note

    private var note: some View {
        Text(
            state == .didIt
                ? "The date records when it was told to the app, not a claim about exact timing — change it any time to reflect reality."
                : "No timeline. Sit here as long as you need."
        )
        .font(AppFonts.meta)
        .foregroundStyle(AppColors.textTertiary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Previews

#if DEBUG
@MainActor
private struct PathNodePreviewHarness: View {
    private let store: PathStore

    init() {
        let coupleId = UUID()
        let profileId = UUID()
        let now = Date()
        let transport = MockPathTransport()
        transport.progress = [
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: "strip-club",
                state: .planning, discussedVia: nil, didItDate: nil, setBy: profileId, updatedAt: now
            ),
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: "virtual-hellos",
                state: .didIt, discussedVia: nil,
                didItDate: Calendar.current.date(byAdding: .day, value: -21, to: now) ?? now,
                setBy: profileId, updatedAt: now
            ),
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: "seen-as-couple",
                state: .discussed, discussedVia: .session, didItDate: nil, setBy: profileId, updatedAt: now
            )
        ]
        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                PathNodeView(store: store, landmarkId: "strip-club")
                    .themedCard()
                PathNodeView(store: store, landmarkId: "virtual-hellos")
                    .themedCard()
                PathNodeView(store: store, landmarkId: "seen-as-couple")
                    .themedCard()
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.void.ignoresSafeArea())
        .task { await store.load() }
    }
}

/// Curious's own two-step privacy gate (spec §4, mockup §05), isolated so it's
/// easy to check the "only you" dimmed state against the fully-shared one.
@MainActor
private struct PathNodeCuriousPreviewHarness: View {
    private let store: PathStore

    init() {
        let coupleId = UUID()
        let profileId = UUID()
        let transport = MockPathTransport()
        transport.privateMarks = [
            PathPrivateMark(id: UUID(), profileId: profileId, coupleId: coupleId, pathStyle: "swinging", landmarkId: "flirt-bar", markedAt: Date())
        ]
        transport.progress = [
            PathLandmarkProgress(
                id: UUID(), coupleId: coupleId, pathStyle: "swinging", landmarkId: "watch-together",
                state: .curious, discussedVia: nil, didItDate: nil, setBy: profileId, updatedAt: Date()
            )
        ]
        store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                PathNodeView(store: store, landmarkId: "flirt-bar")
                    .themedCard()
                PathNodeView(store: store, landmarkId: "watch-together")
                    .themedCard()
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.void.ignoresSafeArea())
        .task { await store.load() }
    }
}

#Preview("PathNodeView — Planning / Did it / Discussed via session") {
    PathNodePreviewHarness()
}

#Preview("PathNodeView — Curious, private vs. shared") {
    PathNodeCuriousPreviewHarness()
}
#endif

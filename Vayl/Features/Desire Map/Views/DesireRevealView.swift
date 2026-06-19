//
//  DesireRevealView.swift
//  Vayl
//
//  D4 — the Desire-Map reveal (the "magic moment"). View layer: reads DesireRevealStore,
//  forwards taps; no DB/Service. Celebrates where the couple ALIGNS — never a table of raw
//  answers (the read is alignment-only). Free couple sees the one free match + locked teasers
//  with an unlock CTA; core sees them all.
//
//  STUB STATUS (2026-06-17): structure + states wired to live data; FEEL/composition/motion is
//  Bryan's styling pass. Stubbed CTAs: unlock (→ M5), bridge nav, request (open decision).
//

import SwiftUI

struct DesireRevealView: View {

    let store: DesireRevealStore

    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hapticTick: Int = 0
    @State private var emblemPulse: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            content
        }
        .screenshotProtected()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .task { if case .loading = store.phase { await store.load() } }
        .onAppear { emblemPulse = true; triggerReveal() }
        .onChange(of: store.phase) { _, _ in triggerReveal() }
    }

    private func triggerReveal() {
        guard !appeared, case .ready = store.phase else { return }
        appeared = true
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            loadingView
        case .failed(let msg):
            emptyState(icon: "exclamationmark.triangle",
                       title: "Couldn't load your matches",
                       message: msg)
        case .empty:
            emptyState(icon: "sparkles",
                       title: "No shared matches yet",
                       message: "When you and your partner both finish your maps, what you share appears here.")
        case .ready:
            reveal
        }
    }

    // MARK: - Reveal

    private var reveal: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    header
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared || reduceMotion ? 0 : 16)
                        .animation(AppAnimation.enter.delay(0.05), value: appeared)

                    ForEach(Array(store.unlockedMatches.enumerated()), id: \.element.id) { idx, match in
                        MatchCardView(match: match) {
                            hapticTick += 1
                            // TODO(D4/companion): navigate to bridge card for match.bridgeCardId
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared || reduceMotion ? 0 : 20)
                        .animation(AppAnimation.enter.delay(0.15 + Double(idx) * 0.10), value: appeared)
                    }

                    if store.lockedCount > 0 {
                        lockedSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared || reduceMotion ? 0 : 20)
                            .animation(AppAnimation.enter.delay(0.15 + Double(store.unlockedMatches.count) * 0.10), value: appeared)
                    }

                    requestRow
                        .opacity(appeared ? 1 : 0)
                        .animation(AppAnimation.enter.delay(0.20 + Double(store.totalCount) * 0.08), value: appeared)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button { hapticTick += 1; dismiss() } label: {
                Image(systemName: "xmark")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.cardBg))
                    .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(_PressScaleStyle())
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Header (emblem + headline + count)

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {
            // Concentric-ring prism emblem — spectrum outer ring, void inner, ✦ center
            ZStack {
                // Glow layer
                Circle()
                    .fill(AppColors.spectrumCyan.opacity(emblemPulse ? 0.18 : 0.08))
                    .frame(width: 96, height: 96)
                    .blur(radius: 16)

                // Outer spectrum ring
                Circle()
                    .stroke(AppColors.spectrumBorder, lineWidth: 1.5)
                    .frame(width: 72, height: 72)

                // Inner void ring (creates concentric depth)
                Circle()
                    .fill(AppColors.void)
                    .frame(width: 60, height: 60)

                // Center mark
                Text("✦")
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.spectrumBorder)
            }
            .spectrumBorderGlow(intensity: emblemPulse ? 0.65 : 0.30)
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                value: emblemPulse
            )
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xs)

            Text("Where you align")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            if store.totalCount > 0 {
                Text(countLine)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppSpacing.sm)
    }

    private var countLine: String {
        let n = store.totalCount
        return "You share \(n) thing\(n == 1 ? "" : "s"). Here's where your desires meet."
    }

    // MARK: - Locked teasers + CTA

    private var lockedSection: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(store.lockedMatches) { LockedTeaserCard(match: $0) }
            unlockCTA
        }
    }

    private var unlockCTA: some View {
        VStack(spacing: AppSpacing.sm) {
            // Invitation header
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "sparkles")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumCyan)
                Text("You have \(store.lockedCount) more match\(store.lockedCount == 1 ? "" : "es")")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text("Unlock everything — yours, forever.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            // Price hint
            if let price = entitlements.corePriceText {
                Text(price)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Button {
                hapticTick += 1
                store.unlockAll()   // TODO(M5): StoreKit purchase → grant-entitlement → load()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text("Own your experience")
                        .font(AppFonts.ctaLabel)
                    Image(systemName: "chevron.right")
                        .font(AppFonts.caption)
                }
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    Capsule()
                        .stroke(AppColors.spectrumBorder, lineWidth: 1.5)
                )
            }
            .buttonStyle(_PressScaleStyle())
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: AppRadius.container).fill(AppColors.cardBg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(0.6)
        )
        .spectrumBorderGlow(intensity: 0.25)
    }

    // MARK: - Request row (subtle bottom row)

    private var requestRow: some View {
        Button {
            hapticTick += 1
            store.requestHiddenConversation()   // TODO(D4): define what a request DOES
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "questionmark.bubble")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                Text("Ask about something you didn't match on")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(AppColors.cardBg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(_PressScaleStyle())
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            // Pulsing emblem — same visual as the reveal header but in a waiting state
            ZStack {
                Circle()
                    .fill(AppColors.spectrumCyan.opacity(emblemPulse ? 0.15 : 0.06))
                    .frame(width: 96, height: 96)
                    .blur(radius: 20)
                Circle()
                    .stroke(AppColors.spectrumBorder, lineWidth: 1)
                    .frame(width: 72, height: 72)
                    .opacity(emblemPulse ? 0.7 : 0.3)
                Circle()
                    .fill(AppColors.void)
                    .frame(width: 60, height: 60)
                Text("✦")
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.textTertiary.opacity(emblemPulse ? 0.9 : 0.4))
            }
            .ambientAnimation(
                .easeInOut(duration: AppAnimation.ambientPulse).repeatForever(autoreverses: true),
                value: emblemPulse
            )

            Text("Finding where you align…")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty / error state

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textTertiary)
            Text(title)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            Button { hapticTick += 1; dismiss() } label: {
                Text("Close")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(_PressScaleStyle())
            .padding(.top, AppSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }

    // MARK: - Alignment color

    private func alignmentColor(_ alignment: DesireMatchType?) -> Color {
        switch alignment {
        case .mutual:   return AppColors.spectrumCyan
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }
}

// MARK: - Match card (unlocked)

private struct MatchCardView: View {
    let match: RevealMatch
    let onTalkTapped: () -> Void

    @State private var talkPressed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Alignment pip + label
            HStack(spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: AppRadius.pill)
                    .fill(alignmentColor)
                    .frame(width: 4, height: 18)
                Text(alignmentLabel.uppercased())
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
            }

            // Item name
            Text(match.itemName)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Celebration subtitle
            Text(match.celebration)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Bridge link — "Talk about this →"
            Button {
                onTalkTapped()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text("Talk about this")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(AppColors.spectrumCyan)
                    Image(systemName: "chevron.right")
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.spectrumCyan.opacity(0.7))
                }
                .padding(.top, AppSpacing.xs)
            }
            .buttonStyle(_PressScaleStyle())
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppRadius.container).fill(AppColors.cardBg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.container)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
        )
        .spectrumBorderGlow(intensity: 0.30)
    }

    private var alignmentLabel: String {
        match.alignment?.displayName ?? "Aligned"
    }

    private var alignmentColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumCyan
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }
}

// MARK: - Locked teaser card

private struct LockedTeaserCard: View {
    let match: RevealMatch

    @State private var shimmer: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.pill)
                .fill(alignmentColor.opacity(0.5))
                .frame(width: 4, height: 18)

            Text(match.itemName)
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .blur(radius: 6)
                .redacted(reason: .placeholder)

            Spacer(minLength: AppSpacing.sm)

            Image(systemName: "lock.fill")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary.opacity(shimmer ? 0.8 : 0.5))
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientShimmer).repeatForever(autoreverses: true),
                    value: shimmer
                )
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(AppColors.cardBg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(shimmer ? 0.30 : 0.12)
                .ambientAnimation(
                    .easeInOut(duration: AppAnimation.ambientShimmer).repeatForever(autoreverses: true),
                    value: shimmer
                )
        )
        .onAppear { shimmer = true }
    }

    private var alignmentColor: Color {
        switch match.alignment {
        case .mutual:   return AppColors.spectrumCyan
        case .adjacent: return AppColors.spectrumPurple
        case .none:     return AppColors.textTertiary
        }
    }
}

// MARK: - Press-scale button style (local)

private struct _PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Free reveal — 1 + 3 locked") {
    DesireRevealView(store: .previewStore(matches: [
        .sample("New Relationship Energy (NRE)", .mutual),
        .sample("Overnight Stays With Others", .adjacent, locked: true),
        .sample("Meeting Your Partner's Other Connections", .mutual, locked: true),
        .sample("Time and Attention", .adjacent, locked: true),
    ]))
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}

#Preview("Fully unlocked — core") {
    DesireRevealView(store: .previewStore(matches: [
        .sample("New Relationship Energy (NRE)", .mutual),
        .sample("Overnight Stays With Others", .adjacent),
        .sample("Meeting Your Partner's Other Connections", .mutual),
    ]))
    .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    DesireRevealView(store: .previewStore(matches: [], phase: .empty))
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    DesireRevealView(store: .previewStore(matches: [], phase: .loading))
        .environment(EntitlementStore(modelContainer: .previewContainer, appState: AppState()))
        .preferredColorScheme(.dark)
}
#endif

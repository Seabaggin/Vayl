//
//  DeckDetailView.swift
//  Vayl — Play
//
//  Float-in-space deck detail — the ONE place the 3D MetallicCaseView is used.
//  The case floats; info + CTA below. Locked / coming-soon decks show what the
//  deck is about but the cards stay sealed (the CTA differs).
//

import SwiftUI

struct DeckDetailView: View {
    let store: PlayStore
    let namespace: Namespace.ID

    private var deck: DeckSummary? { store.summary(store.detailID) }

    var body: some View {
        ZStack {
            if let deck {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .ignoresSafeArea()
                    .overlay(AppColors.void.opacity(0.6).ignoresSafeArea())
                    .onTapGesture { store.closeDetail() }

                VStack(spacing: AppSpacing.md) {
                    // The grid case zooms in here (matchedGeometry). The animated 3D
                    // MetallicCaseView is reserved for the Begin ceremony, so this stays a
                    // seamless static→static zoom.
                    DeckCaseView(summary: deck, style: store.style(for: deck))
                        .frame(width: 190)
                        .matchedGeometryEffect(id: deck.id, in: namespace, isSource: false)
                        .padding(.top, AppSpacing.xxl)

                    Text(deck.category.displayName)
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.textHint)
                    Text(deck.title)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 9) {
                        Circle().fill(store.style(for: deck).accent).frame(width: 8, height: 8)
                        Text(deck.intensity.difficultyLabel)
                        Text("·").foregroundStyle(AppColors.textMuted)
                        Text(deck.intensity.displayName)
                    }
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary)
                    Text(deck.subtitle)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)

                    if deck.isLocked { sealedNotice() }
                    cta(deck)
                }
                .padding(.horizontal, AppSpacing.lg)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.enter, value: store.detailID)
    }

    private func sealedNotice() -> some View {
        Label("The cards unlock with Core.", systemImage: "lock.fill")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.accentTertiary)
            .padding(.vertical, 12)
            .padding(.horizontal, AppSpacing.md)
            .background(RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.accentTertiary.opacity(0.08)))
    }

    @ViewBuilder
    private func cta(_ d: DeckSummary) -> some View {
        // Free vs Core: a Core deck offers the paywall; a free deck begins.
        // Canonical VaylButton — not a hand-rolled CTA.
        if d.isLocked {
            VaylButton(label: "Unlock with Core") { store.requestUnlock(d) }
        } else {
            VaylButton(label: "Begin") { store.beginCeremony(d.id) }
        }
    }

}

#if DEBUG
#Preview("Deck detail") {
    @Previewable @Namespace var ns
    let store = PlayStore.preview
    store.openDetail("the-opener")
    return ZStack {
        AppColors.void.ignoresSafeArea()
        DeckDetailView(store: store, namespace: ns)
    }
    .preferredColorScheme(.dark)
}
#endif

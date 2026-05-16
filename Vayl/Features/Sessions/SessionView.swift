//
//  SessionView.swift
//  Vayl
//
//  Thin view. Renders only.
//  All session logic lives in SessionStore.
//  Entered from Home (resume) or Play (new or resume).
//

import SwiftUI
import SwiftData

struct SessionView: View {

    @State var store: SessionStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()

            if store.sessionEnded {
                sessionCompleteView
                    .transition(.opacity)
            } else {
                sessionContent
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.standard, value: store.sessionEnded)
        .screenshotProtected()
    }

    // MARK: - Session Content

    private var sessionContent: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            VStack(spacing: 0) {
                topBar(layout: layout)

                Spacer(minLength: AppSpacing.md)

                cardArea
                    .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: AppSpacing.md)

                progressPips
                    .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: AppSpacing.md)

                bottomControls
                    .padding(.horizontal, AppSpacing.lg)
                    .bottomContentInset(layout)
            }
            .padding(.vertical, AppSpacing.md)
            .topClearance(layout)
        }
    }

    // MARK: - Top Bar

    private func topBar(layout: AppLayout) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: AppIcons.chevronLeft)
                    .font(Font.custom("Switzer-Semibold", size: 18, relativeTo: .body))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Back")
            .accessibilityAddTraits(.isButton)

            Spacer()

            VStack(spacing: AppSpacing.xxs) {
                Text("\(store.currentIndex + 1) of \(store.cards.count)")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)

                Text(store.deck.title)
                    .font(AppFonts.sectionLabelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Phantom mirror — keeps title centred
            Image(systemName: AppIcons.chevronLeft)
                .font(Font.custom("Switzer-Semibold", size: 18, relativeTo: .body))
                .foregroundStyle(.clear)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Card Area

    private var cardArea: some View {
        Text(store.currentCard?.text ?? "")
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .id(store.currentIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(AppAnimation.standard, value: store.currentIndex)
    }

    // MARK: - Progress Pips

    private var progressPips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<store.cards.count, id: \.self) { i in
                Capsule()
                    .fill(i == store.currentIndex
                          ? AppColors.accentPrimary
                          : AppColors.borderSubtle)
                    .frame(width: i == store.currentIndex ? 24 : 8, height: 8)
                    .animation(AppAnimation.fast, value: store.currentIndex)
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {

                // Skip
                Button {
                    withAnimation(AppAnimation.standard) {
                        store.recordAndAdvance(status: .skipped)
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: AppIcons.forwardFill)
                            .font(Font.custom("Switzer-Regular", size: 14, relativeTo: .callout))
                        Text("Not Ready")
                            .font(AppFonts.bodyMedium)
                    }
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, AppSpacing.md)
                    .cardStyle(cornerRadius: AppRadius.md)
                }
                .accessibilityLabel("Not Ready — skip this card")
                .accessibilityAddTraits(.isButton)

                // Bookmark
                Button {
                    withAnimation(AppAnimation.standard) {
                        store.recordAndAdvance(status: .bookmarked)
                    }
                } label: {
                    Image(systemName: AppIcons.bookmarkFill)
                        .font(Font.custom("Switzer-Regular", size: 18, relativeTo: .body))
                        .foregroundStyle(AppColors.accentPrimary)
                        .frame(width: 52, height: 48)
                        .cardStyle(cornerRadius: AppRadius.md)
                }
                .accessibilityLabel("Bookmark — save for later")
                .accessibilityAddTraits(.isButton)
            }

            // Discussed — primary action
            Button {
                withAnimation(AppAnimation.standard) {
                    store.recordAndAdvance(status: .discussed)
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: AppIcons.checkmarkCircle)
                        .font(Font.custom("Switzer-Regular", size: 18, relativeTo: .body))
                    Text("We Discussed This")
                        .font(AppFonts.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: [AppColors.accentTertiary, AppColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .accessibilityLabel("We Discussed This")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Image(systemName: AppIcons.sparkles)
                    .font(Font.custom("ClashDisplay-Bold", size: 48, relativeTo: .largeTitle))
                    .foregroundStyle(AppColors.spectrumText)
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.sm) {
                    Text("Session Complete")
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("You discussed \(store.discussedCount) of \(store.cards.count) cards")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)

                    if store.bookmarkedCount > 0 {
                        Text("\(store.bookmarkedCount) bookmarked for later")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.accentPrimary)
                    }

                    if store.skippedCount > 0 {
                        Text("\(store.skippedCount) skipped — no pressure")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .multilineTextAlignment(.center)

                VaylButton(label: "Done") {
                    dismiss()
                }
                .padding(.horizontal, AppSpacing.xxl)

                Spacer()
            }
            .padding(AppSpacing.lg)
            .topClearance(layout)
        }
    }
}

// MARK: - Previews

#Preview("Dark — In Progress") {
    SessionView(
        store: SessionStore(
            deck: Deck.previewWithCards,
            startIndex: 0,
            modelContainer: ModelContainer.previewContainer,
            appState: AppState()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Light — In Progress") {
    SessionView(
        store: SessionStore(
            deck: Deck.previewWithCards,
            startIndex: 0,
            modelContainer: ModelContainer.previewContainer,
            appState: AppState()
        )
    )
    .preferredColorScheme(.light)
}

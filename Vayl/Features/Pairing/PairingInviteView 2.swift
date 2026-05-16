//
//  PairingInviteView.swift
//  Vayl
//

// ⚠️ BEFORE BUILDING: add the following to AppIcons:
//   static let exclamationTriangle = "exclamationmark.triangle"
// AppIcons.docOnDoc and AppIcons.checkmarkCircle already exist.

import SwiftUI
import SwiftData

// MARK: - PairingInviteView
// Person A — generates a code and waits for partner to join.
// Display only — all logic lives in PairingStore.
// Under 300 lines.

struct PairingInviteView: View {

    // MARK: - Dependencies

    @State var store: PairingStore

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()
                content
                Spacer()
                footer
            }
            .padding(.horizontal, AppSpacing.lg)    // was 24 → lg, exact
            .padding(.vertical, AppSpacing.xl)      // was 32 → xl, exact
        }
        .task {
            await store.generateInvite()
        }
        .onDisappear {
            store.cancelPolling()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch store.linkState {
        case .idle, .generating:
            generatingState

        case .waitingForPartner(let code):
            waitingState(code: code)

        case .linked(let coupleId):
            linkedState(coupleId: coupleId)

        case .error(let message):
            errorState(message: message)

        case .joining:
            // Should not appear in invite flow
            generatingState
        }
    }

    // MARK: - Generating State

    private var generatingState: some View {
        VStack(spacing: AppSpacing.lg) {            // was 20 → lg (24), snap per handoff
            ProgressView()
                .tint(AppColors.accentPrimary)
                .scaleEffect(1.4)

            Text("Generating your code...")
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
        }
    }

    // MARK: - Waiting State

    private func waitingState(code: String) -> some View {
        VStack(spacing: AppSpacing.xl) {            // was 32 → xl, exact

            // Header
            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("Invite your partner")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)

                Text("Share this code with your partner.\nIt expires in 24 hours.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)
            }

            // Code display
            codeDisplay(code: code)

            // Waiting indicator
            HStack(spacing: AppSpacing.sm) {        // was 10 → sm (8), snap per handoff
                ProgressView()
                    .tint(AppColors.accentPrimary)
                Text("Waiting for your partner...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
            }
            .padding(.vertical, AppSpacing.sm)      // was 12 → sm (8), snap per handoff
            .padding(.horizontal, AppSpacing.lg)    // was 20 → lg (24), snap per handoff
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md) // was 12 → md, exact
                    .fill(isLight ? AppColors.cardBackground : AppColors.modalBackground)
            )
        }
    }

    // MARK: - Code Display

    private func codeDisplay(code: String) -> some View {
        VStack(spacing: AppSpacing.sm) {            // was 12 → sm (8), snap per handoff
            Text(code)
                .font(AppFonts.displayHero)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .kerning(8)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // Copy button
            Button {
                UIPasteboard.general.string = code
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                HStack(spacing: AppSpacing.sm) {    // was 8 → sm, exact
                    Image(AppIcons.docOnDoc)         // was "doc.on.doc"
                        .font(
                            Font.custom("Switzer-Medium", size: 14, relativeTo: .caption)
                        )                           // was .system(size: 14, weight: .medium)
                    Text("Copy code")
                        .font(AppFonts.buttonLabel)
                }
                .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                .padding(.vertical, AppSpacing.sm)  // was 8 → sm, exact
                .padding(.horizontal, AppSpacing.md) // was 16 → md, exact
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm) // was 8 → sm, exact
                        .fill(isLight ? AppColors.cardBackground : AppColors.modalBackground)
                )
            }
            .accessibilityLabel("Copy pairing code")
            .accessibilityAddTraits(.isButton)
        }
        .padding(AppSpacing.lg)                     // was 24 → lg, exact
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.container) // was 20 → container, exact
                .fill(isLight ? AppColors.cardBackground : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.container) // was 20 → container, exact
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AppColors.accentPrimary.opacity(0.3),
                                    AppColors.accentSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    // MARK: - Linked State

    private func linkedState(coupleId: UUID) -> some View {
        VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
            Image(AppIcons.checkmarkCircle)         // was "checkmark.circle.fill"
                .font(
                    Font.custom("ClashDisplay-Bold", size: 64, relativeTo: .largeTitle)
                )                                   // was .system(size: 64)
                .foregroundStyle(AppColors.accentPrimary)
                .accessibilityHidden(true)          // decorative — state is communicated by text

            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("You're linked!")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides

                Text("Your partner joined successfully.\nYou're ready to begin.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
            Image(AppIcons.exclamationTriangle)     // was "exclamationmark.triangle"
            // ⚠️ AppIcons.exclamationTriangle must be added to AppIcons before building
                .font(
                    Font.custom("ClashDisplay-Bold", size: 48, relativeTo: .largeTitle)
                )                                   // was .system(size: 48)
                .foregroundStyle(AppColors.accentTertiary)
                .accessibilityHidden(true)          // decorative — error communicated by text below

            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("Something went wrong")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides

                Text(message)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)
            }

            Button("Try Again") {
                store.reset()
                Task { await store.generateInvite() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accentPrimary)
            .accessibilityLabel("Try Again")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Your data is encrypted and always stays yours.")
            .font(AppFonts.caption)
            .foregroundStyle(isLight ? AppColors.textSecondary : AppColors.textTertiary)
            // isLight ternary retained — these ARE different tokens, intentional distinction
            .multilineTextAlignment(.center)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            AppColors.pageBackground                // was isLight ? x : x — same both sides
                .ignoresSafeArea()

            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.accentPrimary.opacity(isLight ? 0.08 : 0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                ))
                .frame(width: 400, height: 300)
                .blur(radius: 60)
                .offset(y: -100)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

#Preview("Generating") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(modelContainer: container, appState: appState)
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Waiting") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(
        modelContainer: container,
        appState: appState,
        initialState: .waitingForPartner(code: "A3K9BX")
    )
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Linked") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(
        modelContainer: container,
        appState: appState,
        initialState: .linked(coupleId: UUID())
    )
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Error") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(
        modelContainer: container,
        appState: appState,
        initialState: .error("Could not generate a code. Please try again.")
    )
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

//
//  PairingJoinView.swift
//  Vayl
//

// ⚠️ BEFORE BUILDING: confirm AppIcons.exclamationTriangle was added during
//    PairingInviteView migration: static let exclamationTriangle = "exclamationmark.triangle"
// AppIcons.checkmarkCircle already exists.

import SwiftUI
import SwiftData

// MARK: - PairingJoinView
// Person B — enters a code to join their partner.
// Display only — all logic lives in PairingStore.
// Under 300 lines.

struct PairingJoinView: View {

    // MARK: - Dependencies

    @State var store: PairingStore

    // MARK: - Local State

    @State private var codeInput: String = ""
    @FocusState private var isInputFocused: Bool

    // MARK: - Computed

    private var canSubmit: Bool {
        codeInput.trimmingCharacters(in: .whitespaces).count >= 6
    }

    private var isLoading: Bool {
        if case .joining = store.linkState { return true }
        return false
    }

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
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch store.linkState {
        case .idle, .joining:
            joinForm

        case .linked(let coupleId):
            linkedState(coupleId: coupleId)

        case .error(let message):
            errorState(message: message)

        case .generating, .waitingForPartner:
            // Should not appear in join flow
            joinForm
        }
    }

    // MARK: - Join Form

    private var joinForm: some View {
        VStack(spacing: AppSpacing.xl) {            // was 32 → xl, exact

            // Header
            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("Enter your partner's code")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)

                Text("Ask your partner for their 6-character code\nand enter it below.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)
            }

            // Code input
            codeInputField

            // Submit button
            VaylButton(
                label: isLoading ? "Linking..." : "Link with partner",
                isDisabled: !(canSubmit && !isLoading)
            ) {
                isInputFocused = false
                Task {
                    await store.joinWithCode(
                        codeInput.trimmingCharacters(in: .whitespaces).uppercased()
                    )
                }
            }
            .animation(AppAnimation.fast, value: canSubmit) // was .easeInOut(duration: 0.2) → fast
        }
    }

    // MARK: - Code Input Field

    private var codeInputField: some View {
        VStack(spacing: AppSpacing.sm) {            // was 8 → sm, exact
            TextField("", text: $codeInput)
                .font(AppFonts.displayHero)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .kerning(8)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .focused($isInputFocused)
                .onChange(of: codeInput) { _, newValue in
                    // Uppercase and limit to 6 characters
                    let filtered = newValue
                        .uppercased()
                        .filter { $0.isLetter || $0.isNumber }
                    codeInput = String(filtered.prefix(6))
                }
                .padding(AppSpacing.lg)             // was 24 → lg, exact
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.container) // was 20 → container, exact
                        .fill(AppColors.whisperFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.container) // was 20 → container, exact
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            AppColors.accentPrimary.opacity(
                                                codeInput.isEmpty ? 0.15 : 0.4
                                            ),
                                            AppColors.accentSecondary.opacity(
                                                codeInput.isEmpty ? 0.15 : 0.4
                                            )
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .accessibilityLabel("Partner code input")

            Text("\(codeInput.count) / 6 characters")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Linked State

    private func linkedState(coupleId: UUID) -> some View {
        VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
            Image(systemName: AppIcons.checkmarkCircle)         // was "checkmark.circle.fill"
                .font(
                    AppFonts.displayHero  // was Font.custom("ClashDisplay-Bold", 64, .largeTitle) → displayHero, exact
                )                                   // was .system(size: 64)
                .foregroundStyle(AppColors.accentPrimary)
                .accessibilityHidden(true)          // decorative — state communicated by text

            VStack(spacing: AppSpacing.sm) {        // was 8 → sm, exact
                Text("You're linked!")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides

                Text("\(store.partnerDisplayName) is ready to begin with you.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                    .multilineTextAlignment(.center)
            }

            if let proposal = store.compositionProposal {
                CompositionConfirmCard(
                    proposal: proposal,
                    showsError: store.compositionError != nil,
                    onConfirm: { Task { await store.confirmComposition() } },
                    onKeepFlexible: { store.dismissComposition() }
                )
                .transition(.opacity)
                .animation(AppAnimation.standard, value: store.compositionProposal)
            }
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
            Image(systemName: AppIcons.exclamationTriangle)     // was "exclamationmark.triangle"
            // ⚠️ confirm AppIcons.exclamationTriangle was added during PairingInviteView pass
                .font(
                    AppFonts.display(48, weight: .bold, relativeTo: .largeTitle)  // was Font.custom("ClashDisplay-Bold", 48, .largeTitle) → AppFonts.display, exact
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

            VaylButton(
                label: "Try Again"
            ) {
                store.reset()
                codeInput     = ""
                isInputFocused = true
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Your data is encrypted and always stays yours.")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            AppColors.pageBackground                // was isLight ? x : x — same both sides
                .ignoresSafeArea()

            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.accentSecondary.opacity(0.15), .clear],
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

#Preview("Empty") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(modelContainer: container, appState: appState)
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Joining") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.joining
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Linked") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.linked(coupleId: UUID())
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Error") {
    let container = ModelContainer.previewContainer
    let appState  = AppState()
    let store     = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.error("Code not found. Check and try again.")
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

//
//  PairingJoinView.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/29/26.
//


//
//  PairingJoinView.swift
//  Vayl
//

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

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

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
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
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
        VStack(spacing: 32) {

            // Header
            VStack(spacing: 8) {
                Text("Enter your partner's code")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Ask your partner for their 6-character code\nand enter it below.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Code input
            codeInputField

            // Submit button
            HoloCTAButton(
                title: isLoading ? "Linking..." : "Link with partner",
                isEnabled: canSubmit && !isLoading
            ) {
                isInputFocused = false
                Task {
                    await store.joinWithCode(codeInput.trimmingCharacters(in: .whitespaces).uppercased())
                }
            }
            .animation(.easeInOut(duration: 0.2), value: canSubmit)
        }
    }

    // MARK: - Code Input Field

    private var codeInputField: some View {
        VStack(spacing: 8) {
            TextField("", text: $codeInput)
                .font(AppFonts.displayHero)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
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
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight ? AppColors.lightCardFill : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            AppColors.cyan.opacity(codeInput.isEmpty ? 0.15 : 0.4),
                                            AppColors.purple.opacity(codeInput.isEmpty ? 0.15 : 0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )

            Text("\(codeInput.count) / 6 characters")
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textTertiary)
        }
    }

    // MARK: - Linked State

    private func linkedState(coupleId: UUID) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.cyan)

            VStack(spacing: 8) {
                Text("You're linked!")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)

                Text("You've successfully connected\nwith your partner.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.magenta)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)

                Text(message)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HoloCTAButton(
                title: "Try Again",
                isEnabled: true
            ) {
                store.reset()
                codeInput = ""
                isInputFocused = true
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Your data is encrypted and always stays yours.")
            .font(AppFonts.caption)
            .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textTertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            (isLight ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.purple.opacity(isLight ? 0.08 : 0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                ))
                .frame(width: 400, height: 300)
                .blur(radius: 60)
                .offset(y: -100)
                .allowsHitTesting(false)
        }
    }
}

#Preview("Empty") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(modelContainer: container, appState: appState)
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Joining") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.joining
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Linked") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.linked(coupleId: UUID())
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Error") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(modelContainer: container, appState: appState)
    store.linkState = PairingLinkState.error("Code not found. Check and try again.")
    return PairingJoinView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

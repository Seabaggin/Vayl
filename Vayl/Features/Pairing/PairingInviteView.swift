//
//  PairingInviteView.swift
//  Vayl
//
//  Created by Bryan Jorden on 4/28/26.
//


//
//  PairingInviteView.swift
//  Vayl
//

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
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
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
        VStack(spacing: 20) {
            ProgressView()
                .tint(AppColors.cyan)
                .scaleEffect(1.4)

            Text("Generating your code...")
                .font(AppFonts.bodyText)
                .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
        }
    }

    // MARK: - Waiting State

    private func waitingState(code: String) -> some View {
        VStack(spacing: 32) {

            // Header
            VStack(spacing: 8) {
                Text("Invite your partner")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Share this code with your partner.\nIt expires in 24 hours.")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Code display
            codeDisplay(code: code)

            // Waiting indicator
            HStack(spacing: 10) {
                ProgressView()
                    .tint(AppColors.cyan)
                Text("Waiting for your partner...")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLight ? AppColors.lightCardFill : AppColors.surfaceBg)
            )
        }
    }

    // MARK: - Code Display

    private func codeDisplay(code: String) -> some View {
        VStack(spacing: 12) {
            Text(code)
                .font(AppFonts.displayHero)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
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
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                    Text("Copy code")
                        .font(AppFonts.buttonLabel)
                }
                .foregroundStyle(isLight ? AppColors.lightTextSecondary : AppColors.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isLight ? AppColors.lightCardFill : AppColors.surfaceBg)
                )
            }
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
                                    AppColors.cyan.opacity(0.3),
                                    AppColors.purple.opacity(0.3)
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
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.cyan)

            VStack(spacing: 8) {
                Text("You're linked!")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(isLight ? AppColors.lightTextPrimary : AppColors.textPrimary)

                Text("Your partner joined successfully.\nYou're ready to begin.")
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

            Button("Try Again") {
                store.reset()
                Task { await store.generateInvite() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.cyan)
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
                    colors: [AppColors.cyan.opacity(isLight ? 0.08 : 0.15), .clear],
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

// MARK: - Previews

#Preview("Generating") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(
        modelContainer: container,
        appState: appState
    )
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

#Preview("Waiting") {
    let container = ModelContainer.previewContainer
    let appState = AppState()
    let store = PairingStore(
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
    let appState = AppState()
    let store = PairingStore(
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
    let appState = AppState()
    let store = PairingStore(
        modelContainer: container,
        appState: appState,
        initialState: .error("Could not generate a code. Please try again.")
    )
    PairingInviteView(store: store)
        .environment(appState)
        .preferredColorScheme(.dark)
}

//
//  PairingSettingsView.swift
//  Vayl
//

// ⚠️ BEFORE BUILDING: add the following to AppIcons:
//   static let link = "link"
// AppIcons.personBadgePlus and AppIcons.chevronRight already exist.

import SwiftUI
import SwiftData

struct PairingSettingsView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Navigation

    @State private var showInviteView: Bool = false
    @State private var showJoinView: Bool = false

    // MARK: - Partner Identity (P3)

    @State private var partnerName: String? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground            // was isLight ? x : x — same both sides
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) { // was 24 → lg, exact

                        // ── Current link state ────────────────────────
                        linkStateSection

                        // ── Actions ───────────────────────────────────
                        if appState.linkState == .unlinked {
                            actionsSection
                        }

                        Spacer(minLength: AppSpacing.xxl) // was 40 → xxl (48), snap per handoff
                    }
                    .padding(AppSpacing.lg)         // was 24 → lg, exact
                }
            }
            .navigationTitle("Partner Linking")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // P3: if already linked, push our own identity + read the partner's
                // name so the status line shows who, not a generic label. A
                // transient store keeps this View → Store → Service compliant.
                guard appState.linkState == .linked else { return }
                let store = PairingStore(modelContainer: modelContext.container, appState: appState)
                await store.refreshPartner()
                partnerName = store.partnerName
            }
            .sheet(isPresented: $showInviteView) {
                PairingInviteView(
                    store: PairingStore(
                        modelContainer: modelContext.container,
                        appState: appState
                    )
                )
                .environment(appState)
            }
            .sheet(isPresented: $showJoinView) {
                PairingJoinView(
                    store: PairingStore(
                        modelContainer: modelContext.container,
                        appState: appState
                    )
                )
                .environment(appState)
            }
        }
    }

    // MARK: - Link State Section

    @ViewBuilder
    private var linkStateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) { // was 12 → sm (8), snap per handoff
            Text("STATUS")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides

            HStack(spacing: AppSpacing.sm) {        // was 12 → sm (8), snap per handoff
                Circle()
                    .fill(
                        appState.linkState == .linked
                            ? AppColors.accentPrimary
                            : AppColors.textTertiary
                    )
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)      // status communicated by adjacent text

                Text(appState.linkState == .linked
                        ? "Linked with \(partnerName ?? "partner")"
                        : "Not linked")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides

                Spacer()
            }
            .padding(AppSpacing.md)                 // was 16 → md, exact
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md) // was 14 → md (12), snap per handoff
                    .fill(isLight ? AppColors.cardBackground : AppColors.modalBackground)
                // isLight ternary retained — different tokens on each branch
            )

            if let coupleId = appState.coupleId {
                Text("Couple ID: \(coupleId.uuidString.prefix(8))...")
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight ? AppColors.textSecondary : AppColors.textTertiary)
                // isLight ternary retained — different tokens on each branch
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) { // was 16 → md, exact
            Text("LINK WITH PARTNER")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides

            // Invite — Person A
            actionCard(
                icon: AppIcons.personBadgePlus,     // was "person.badge.plus"
                title: "Generate an invite code",
                subtitle: "Share a code with your partner so they can link their app to yours.",
                action: { showInviteView = true }
            )

            // Join — Person B
            actionCard(
                icon: AppIcons.link,                // was "link"
                // ⚠️ AppIcons.link must be added to AppIcons before building
                title: "Enter a partner's code",
                subtitle: "Your partner has a code — enter it here to link your accounts.",
                action: { showJoinView = true }
            )
        }
    }

    // MARK: - Action Card

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {        // was 16 → md, exact
                Image(systemName: icon)             // icon param — raw string moved to call sites
                    .font(
                        AppFonts.body(20, weight: .medium, relativeTo: .body)  // was Font.custom("Switzer-Medium", 20, .body) → AppFonts.body, exact
                    )                               // was .system(size: 20, weight: .medium)
                    .foregroundStyle(AppColors.accentPrimary)
                    .frame(width: 36, height: 44)   // height: 44 for A11y min hit target
                    .accessibilityHidden(true)      // decorative — title describes the action

                VStack(alignment: .leading, spacing: AppSpacing.xs) { // was 4 → xs, exact
                    Text(title)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary) // was isLight ? x : x — same both sides

                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary) // was isLight ? x : x — same both sides
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(AppIcons.chevronRight)        // was "chevron.right"
                    .font(
                        AppFonts.body(12, weight: .medium, relativeTo: .caption)  // was Font.custom("Switzer-Medium", 12, .caption) → AppFonts.body, exact
                    )                               // was .system(size: 12, weight: .medium)
                    .foregroundStyle(isLight ? AppColors.textSecondary : AppColors.textTertiary)
                // isLight ternary retained — different tokens on each branch
            }
            .padding(AppSpacing.md)                 // was 16 → md, exact
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md) // was 14 → md (12), snap per handoff
                    .fill(isLight ? AppColors.cardBackground : AppColors.modalBackground)
                // isLight ternary retained — different tokens on each branch
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Unlinked") {
    let state = AppState()
    state.linkState = .unlinked
    return PairingSettingsView()
        .environment(state)
        .preferredColorScheme(.dark)
}

#Preview("Linked") {
    let state = AppState()
    state.linkState = .linked
    state.coupleId  = UUID()
    return PairingSettingsView()
        .environment(state)
        .preferredColorScheme(.dark)
}

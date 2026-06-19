//
//  PlayView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Play/PlayView.swift
// Open Lightly

import SwiftUI

struct PlayView: View {

    #if DEBUG
    @Environment(AppState.self) private var appState
    @Environment(AuthService.self) private var authService
    @State private var debugStatus = ""
    @State private var debugBusy = false
    #endif

    var body: some View {
        ZStack {
            AppColors.pageBackground.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                Text("Play")
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(AppColors.textSecondary)

                #if DEBUG
                debugSession
                #endif
            }
        }
    }

    #if DEBUG
    // TEMPORARY — Phase A3 runtime check (auth + RLS + insert reach curated_sessions).
    // Remove when Phase C1 builds the real session entry on Home / Deck Library.
    @ViewBuilder
    private var debugSession: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                Task { await openStubSession() }
            } label: {
                Text(debugBusy ? "Opening…" : "DEBUG: Open stub session")
                    .font(AppFonts.buttonLabel)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .disabled(debugBusy)

            if !debugStatus.isEmpty {
                Text(debugStatus)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    @MainActor
    private func openStubSession() async {
        debugBusy = true
        debugStatus = ""
        defer { debugBusy = false }

        guard let authId = authService.userId else {
            debugStatus = "Not signed in (no auth user)."
            return
        }
        let service = RealtimeSessionService()
        do {
            let initiatorId = try await ProfileService().ensureProfileExists(authId: authId)

            // Resolve the couple: prefer linked state, else look it up in Supabase
            // so a manually-seeded test couple works without going through pairing.
            let coupleId: UUID
            if let linked = appState.coupleId {
                coupleId = linked
            } else if let found = try await service.fetchCoupleId(forProfileId: initiatorId) {
                coupleId = found
            } else {
                debugStatus = "No couple for your profile. Seed a test couple in Supabase, then retry."
                return
            }

            if let existing = try await service.fetchOpenSession(coupleId: coupleId) {
                debugStatus = "ℹ️ Open session exists: \(existing.id.uuidString.prefix(8))… status=\(existing.status). Delete it in Supabase to test a fresh insert."
                return
            }
            let draft = CuratedSessionDraft(
                deckId: "the-opener",
                deckVariant: nil,
                cardIds: ["opener-01", "opener-02", "opener-03"],
                perCardTimer: [:],
                globalTimerSeconds: nil
            )
            let dto = try await service.openSession(
                coupleId: coupleId,
                initiatorId: initiatorId,
                draft: draft
            )
            debugStatus = "✅ Opened \(dto.id.uuidString.prefix(8))… status=\(dto.status). Check curated_sessions in Supabase."
        } catch {
            debugStatus = "❌ \(error.localizedDescription)"
        }
    }
    #endif
}

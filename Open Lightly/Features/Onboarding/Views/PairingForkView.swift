//
//  PairingForkView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/10/26.
//


//
//  PairingForkView.swift
//  Open Lightly
//
//  Created in Batch 10 — Onboarding Pairing Decision
//
//  PURPOSE:
//  Shown ONLY to users who selected "Couple" mode in ModeSelectionView.
//  Gives them two choices:
//    1. "Pair Now" → Opens PairingForkView (built in Batch 9) inline in onboarding
//    2. "Pair Later" → Skips pairing, continues onboarding, can pair from Settings
//
//  DESIGN RATIONALE:
//  We don't force pairing during onboarding because:
//    - The partner might not have the app yet
//    - The user might be setting up on a plane/subway (no internet)
//    - Reducing friction in onboarding improves completion rates
//    - Pairing is always available in Settings (wired in Batch 9)
//
//  This view doesn't do any data saving — it just captures the user's choice
//  via the two closures and lets the parent navigate accordingly.
//

import SwiftUI

struct PairingForkView: View {

    /// Called when the user taps "Pair Now".
    /// The parent view should navigate to PairingForkView.
    let onPairNow: () -> Void

    /// Called when the user taps "I'll do this later".
    /// The parent view should skip ahead to Experience Level or Desire Map.
    let onPairLater: () -> Void

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            // ── Icon ──
            // Visual indicator — a link symbol with a plus badge
            // to communicate "connect with someone."
            Image(systemName: "link.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            // ── Title ──
            Text("Connect with\nyour partner")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // ── Description ──
            // Explains WHY they should pair — unlocks shared features.
            Text("Share a code to link your accounts.\nYou'll unlock shared features like\ncompatibility matching.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // ── Action Buttons ──
            VStack(spacing: 12) {

                // Primary action: Pair Now
                // Uses accent color to draw attention — this is the preferred path.
                Button(action: onPairNow) {
                    Text("Pair Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                // Secondary action: Pair Later
                // Subtle styling (no fill, just text) so it doesn't compete
                // with the primary button, but is still easy to find.
                Button(action: onPairLater) {
                    Text("I'll do this later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }
}

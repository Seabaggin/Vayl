# Legal Links + Restore Wiring (Technical Pass) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the paywall footer's Restore · Terms · Privacy controls (and the sign-in legal line) so every tap genuinely routes — Restore runs the real backend; Terms/Privacy open an in-app Safari sheet over live placeholder URLs.

**Architecture:** A single `LegalLinks` source-of-truth + `LegalDoc` enum feed a thin `SafariView` (`SFSafariViewController` wrapper), presented via raw native `.sheet(item:)` (the app's real convention — `.vaylSheet` does not exist). Restore calls the already-built `EntitlementStore.restore()`. No new dependencies; `SafariServices` is a system framework.

**Tech Stack:** SwiftUI, Swift 6, StoreKit 2 (already wired in the Store/Service layers), SafariServices, iOS 16+ baseline.

**Spec:** `docs/superpowers/specs/2026-06-20-legal-pages-restore-wiring-design.md`

> **⚠️ Exact-match note (verified 2026-06-20):** All find/replace blocks below were checked against the CURRENT files. `PaywallSheet.swift` was recently refactored (`body` → `sizedSheet` → `ViewThatFits` → `sheetStack`); the body modifier chain is lines 73-79. If the file shifts again before execution, match by the quoted code, not line numbers.

---

## Verification Philosophy (read first)

This is SwiftUI **UI wiring**, not testable business logic, and the project's standing discipline is: **Claude build-verifies (compiles) only; Bryan runs on device** (memory: no-sim-runs; CLAUDE.md Build Protocol = "Feel is correct is done"). There is therefore **no unit-test step** — forcing one would mean trivial constant assertions or fragile UI tests plus manual `VaylTests` pbxproj wiring for ~zero value. Each task's gate is:

1. **Compile** (Claude runs `xcodebuild … build`), and
2. **On-device check by Bryan** (the "Done" condition).

Build-verify command (every task):

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -25
```

Expected: ends with `** BUILD SUCCEEDED **`. (If the scheme name errors, run `xcodebuild -list -project Vayl.xcodeproj` and use the listed app scheme. Type-checking can be slow — a long pause is not a failure. No `.metal` files change here, so incremental build is reliable.)

---

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `Vayl/Core/Services/LegalLinks.swift` | **Create** | The two placeholder legal URLs + `LegalDoc` Identifiable enum. One place to swap during the App Store pass. |
| `Vayl/Design/Components/Navigation/SafariView.swift` | **Create** | `UIViewControllerRepresentable` over `SFSafariViewController`, tinted to Vayl colors. |
| `Vayl/Features/Monetization/Views/PaywallSheet.swift` | **Modify** | Wire `restorePurchases()` → `entitlements.restore()` (+ alert); `openTerms/openPrivacy()` → `.sheet(item:)`. Remove 3 TODOs + the stale comment TODO strings. |
| `Vayl/Features/Auth/Views/SignInView.swift` | **Modify** | Make the flat legal line tappable → same `SafariView`. |

New Swift files live under `Vayl/` → the Xcode file-system-synchronized group auto-joins them (no pbxproj surgery; app-target only, not `VaylTests`).

---

## Task 1: Legal plumbing — `LegalLinks` + `SafariView`

**Files:**
- Create: `Vayl/Core/Services/LegalLinks.swift`
- Create: `Vayl/Design/Components/Navigation/SafariView.swift`

**Constraints — may NOT touch:** any feature view, design tokens, `OBSheetChrome`, `EntitlementStore`, `StoreKitService`.

- [ ] **Step 1: Create `LegalLinks.swift`**

```swift
//
//  LegalLinks.swift
//  Vayl
//
//  Single source of truth for the app's legal-document URLs (Terms of Service +
//  Privacy Policy), consumed by the paywall footer and the sign-in legal line.
//
//  ⚠️ PLACEHOLDER URLs (2026-06-20) — these point at Apple's public legal pages as
//  live, clean-rendering stand-ins so the in-app links route during development.
//  REPLACE BOTH with Vayl's own hosted pages during the App Store Ready pass, and
//  set the Privacy URL in App Store Connect. Checklist:
//  docs/superpowers/specs/2026-06-20-legal-pages-restore-wiring-design.md (§8).
//

import Foundation

enum LegalLinks {

    /// Terms of Service. PLACEHOLDER → Apple's standard Licensed Application EULA
    /// (a real, shippable Terms stand-in). Replace with Vayl's hosted Terms.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Privacy Policy. PLACEHOLDER → Apple's public privacy policy (renders cleanly).
    /// Replace with Vayl's hosted Privacy Policy + set it in App Store Connect.
    static let privacy = URL(string: "https://www.apple.com/legal/privacy/")!
}

/// Which legal document to present — drives `.sheet(item:)` in the consumers.
enum LegalDoc: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .terms:   LegalLinks.terms
        case .privacy: LegalLinks.privacy
        }
    }

    /// Human title (accessibility / fallbacks).
    var title: String {
        switch self {
        case .terms:   "Terms of Service"
        case .privacy: "Privacy Policy"
        }
    }
}
```

- [ ] **Step 2: Create `SafariView.swift`**

```swift
//
//  SafariView.swift
//  Vayl
//
//  Thin SwiftUI wrapper over SFSafariViewController for presenting web content
//  (legal pages) in-app via `.sheet(item:)`. Tinted to the Vayl palette.
//
//  Note: SFSafariViewController loads only live `https://` URLs — it CANNOT render
//  bundled/local HTML. That's why the legal docs are hosted (placeholder for now).
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .done
        // Bridge the SwiftUI color tokens to UIColor (iOS 14+). Keeps the slim
        // Safari chrome on-brand; the page body itself comes from the hosted URL.
        controller.preferredControlTintColor = UIColor(AppColors.accentPrimary)
        controller.preferredBarTintColor = UIColor(AppColors.modalBackground)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        // SFSafariViewController is configured at init; nothing to update.
    }
}
```

- [ ] **Step 3: Build-verify**

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -25
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Core/Services/LegalLinks.swift Vayl/Design/Components/Navigation/SafariView.swift
git commit -m "feat(legal): LegalLinks source-of-truth + SafariView wrapper

Single place for the Terms/Privacy URLs (live Apple placeholders for now)
+ a tinted SFSafariViewController wrapper for in-app presentation.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Restore Purchases wiring (PaywallSheet)

Wire the dead `restorePurchases()` stub to the already-built `EntitlementStore.restore()` (which does `AppStore.sync()` → couple re-grant → refresh). Success opens the gate; non-success shows one robust alert; the footer shows a spinner while in flight.

**Files:** Modify `Vayl/Features/Monetization/Views/PaywallSheet.swift`

**Constraints — may NOT touch:** `EntitlementStore`, `StoreKitService`, design tokens, `OBSheetChrome`, the Task 1 files.

> **Design note (deviation from spec §3 D5's two-message idea):** `EntitlementStore.restore()` returns only `Bool`, and its `loadError` is sticky across calls — so distinguishing "network error" from "nothing found" in the View is fragile. We use **one** non-success alert ("Nothing to restore"). Robust, Apple-conventional, no stale-state bug.

- [ ] **Step 1: Add restore state.** Find (lines 37-39):

```swift
    @State private var showDetails = false
    @State private var purchasing  = false
    @State private var hapticTick  = 0
```

Replace with:

```swift
    @State private var showDetails = false
    @State private var purchasing  = false
    @State private var hapticTick  = 0
    @State private var restoring   = false
    @State private var showRestoreFailedAlert = false
```

- [ ] **Step 2: Replace the `restorePurchases()` stub.** Find (lines 381-385):

```swift
    private func restorePurchases() {
        hapticTick += 1
        // TODO(monetization): wire StoreKit restore (AppStore.sync() + refresh EntitlementStore
        // entitlements), then reflect the unlocked state. App Store requires a working Restore.
    }
```

Replace with:

```swift
    private func restorePurchases() {
        guard !restoring else { return }
        hapticTick += 1
        restoring = true
        Task {
            let unlocked = await entitlements.restore()   // AppStore.sync() → couple re-grant → refresh
            restoring = false
            if unlocked {
                onUnlocked()                              // gate opens = the confirmation
            } else {
                showRestoreFailedAlert = true             // nothing owned / couldn't restore
            }
        }
    }
```

- [ ] **Step 3: Update the footer (spinner while restoring + drop the stale TODO comment).** Find (lines 328-337):

```swift
            // Legal trio: real tappable controls now (stubbed actions) so the wiring points exist.
            // App Store requires Restore Purchases + Terms + Privacy to be reachable. Actions are
            // the stub methods below (TODO(monetization) / TODO(legal)).
            HStack(spacing: AppSpacing.xs) {
                footerLink("Restore purchase", hint: "Restores a purchase you already made", action: restorePurchases)
                footerDot
                footerLink("Terms", hint: "Opens the Terms of Service", action: openTerms)
                footerDot
                footerLink("Privacy", hint: "Opens the Privacy Policy", action: openPrivacy)
            }
```

Replace with:

```swift
            // Legal trio — wired controls: Restore runs EntitlementStore.restore() (spinner while
            // in flight); Terms/Privacy open the in-app Safari sheet. App Store requires all three.
            HStack(spacing: AppSpacing.xs) {
                if restoring {
                    HStack(spacing: AppSpacing.xxs) {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AppColors.textTertiary)
                        Text("Restoring…")
                            .font(AppFonts.body(14, weight: .regular, relativeTo: .footnote))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                } else {
                    footerLink("Restore purchase", hint: "Restores a purchase you already made", action: restorePurchases)
                }
                footerDot
                footerLink("Terms", hint: "Opens the Terms of Service", action: openTerms)
                footerDot
                footerLink("Privacy", hint: "Opens the Privacy Policy", action: openPrivacy)
            }
```

- [ ] **Step 4: Add the restore alert to the body chain.** Find (lines 73-79):

```swift
    var body: some View {
        sizedSheet
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay { if showDetails { detailsPopOut } }
            .screenshotProtected()
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
    }
```

Replace with:

```swift
    var body: some View {
        sizedSheet
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay { if showDetails { detailsPopOut } }
            .screenshotProtected()
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
            .alert("Nothing to restore", isPresented: $showRestoreFailedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't find a purchase to restore on this Apple ID. If you've bought Vayl, make sure you're signed in with the same Apple ID you used to purchase.")
            }
    }
```

- [ ] **Step 5: Build-verify**

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -25
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Features/Monetization/Views/PaywallSheet.swift
git commit -m "feat(paywall): wire Restore Purchases to EntitlementStore.restore()

Tap → AppStore.sync() + couple re-grant + refresh (already built in the
Store layer). Success opens the gate; non-success shows one robust alert.
Footer shows a mini spinner while restoring. Removes TODO(monetization).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 7: Bryan device-verify (his gate).** In the StoreKit sandbox (`Vayl.storekit`): owned Apple ID → tap Restore → unlocks + sheet closes; un-owned → "Nothing to restore" alert; the footer shows the spinner mid-restore.

---

## Task 3: Wire Terms/Privacy links (PaywallSheet + SignInView)

**Files:**
- Modify: `Vayl/Features/Monetization/Views/PaywallSheet.swift`
- Modify: `Vayl/Features/Auth/Views/SignInView.swift`

**Constraints — may NOT touch:** `LegalLinks`/`SafariView` internals (consume only), design tokens, `OBSheetChrome`, `EntitlementStore`.

### PaywallSheet

- [ ] **Step 1: Add the `legalDoc` state.** Find the state lines added in Task 2:

```swift
    @State private var restoring   = false
    @State private var showRestoreFailedAlert = false
```

Replace with:

```swift
    @State private var restoring   = false
    @State private var showRestoreFailedAlert = false
    @State private var legalDoc: LegalDoc?
```

- [ ] **Step 2: Wire the two openers.** Find (lines 387-397):

```swift
    private func openTerms() {
        hapticTick += 1
        // TODO(legal): present the Terms of Service (in-app SFSafariViewController or external
        // Link). URL not defined yet; needs a real Terms page before submission.
    }

    private func openPrivacy() {
        hapticTick += 1
        // TODO(legal): present the Privacy Policy (in-app SFSafariViewController or external
        // Link). URL not defined yet; needs a real Privacy page before submission.
    }
```

Replace with:

```swift
    private func openTerms() {
        hapticTick += 1
        legalDoc = .terms
    }

    private func openPrivacy() {
        hapticTick += 1
        legalDoc = .privacy
    }
```

- [ ] **Step 3: Present the Safari sheet (after the alert added in Task 2).** Find the body chain:

```swift
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
            .alert("Nothing to restore", isPresented: $showRestoreFailedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't find a purchase to restore on this Apple ID. If you've bought Vayl, make sure you're signed in with the same Apple ID you used to purchase.")
            }
    }
```

Replace with:

```swift
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
            .alert("Nothing to restore", isPresented: $showRestoreFailedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't find a purchase to restore on this Apple ID. If you've bought Vayl, make sure you're signed in with the same Apple ID you used to purchase.")
            }
            .sheet(item: $legalDoc) { doc in
                SafariView(url: doc.url)
            }
    }
```

### SignInView

- [ ] **Step 4: Add the `legalDoc` state.** Find (lines 10-12):

```swift
    // MARK: - Dependencies

    var authService: AuthService
```

Replace with:

```swift
    // MARK: - Dependencies

    var authService: AuthService

    @State private var legalDoc: LegalDoc?
```

- [ ] **Step 5: Make the legal line tappable.** Find (lines 97-102):

```swift
                        // Legal footnote
                        Text("By continuing you agree to our Terms & Privacy Policy")
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)
```

Replace with:

```swift
                        // Legal footnote — Terms / Privacy are tappable (open in-app Safari).
                        // Custom-scheme markdown links are intercepted below so they open the
                        // SafariView sheet instead of leaving the app.
                        Text("By continuing you agree to our [Terms](vayl-legal://terms) & [Privacy Policy](vayl-legal://privacy)")
                            .font(AppFonts.meta)
                            .tint(AppColors.textSecondary)
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)
                            .environment(\.openURL, OpenURLAction { url in
                                guard url.scheme == "vayl-legal" else { return .systemAction }
                                legalDoc = (url.host == "privacy") ? .privacy : .terms
                                return .handled
                            })
```

- [ ] **Step 6: Present the Safari sheet.** Find (lines 112-114):

```swift
            }
        }
        .ignoresSafeArea()
    }
```

Replace with:

```swift
            }
        }
        .ignoresSafeArea()
        .sheet(item: $legalDoc) { doc in
            SafariView(url: doc.url)
        }
    }
```

- [ ] **Step 7: Build-verify**

```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -25
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Commit**

```bash
git add Vayl/Features/Monetization/Views/PaywallSheet.swift Vayl/Features/Auth/Views/SignInView.swift
git commit -m "feat(legal): wire Terms/Privacy links in paywall + sign-in

Paywall footer openers + sign-in legal line now open the in-app Safari
sheet (SafariView) over the LegalLinks placeholder URLs. Removes both
TODO(legal) stubs; the sign-in line is tappable for the first time.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 9: Bryan device-verify (his gate).** On device: paywall footer "Terms"/"Privacy" each open the Safari sheet over the right Apple stand-in and dismiss back (stacked sheet); the sign-in "Terms"/"Privacy Policy" words are tappable and open the same sheet.

---

## Done criteria (whole plan)

- All three `TODO(...)` + the footer comment's TODO strings removed: `grep -rn "TODO(legal)\|TODO(monetization)" Vayl/` returns nothing.
- `BUILD SUCCEEDED` after each task.
- Bryan confirms on device: Restore (sandbox), both paywall legal links, and the sign-in legal line all route correctly.

## Not in this plan (App Store Ready pass — spec §8)
Authoring the real Terms/Privacy copy, hosting them, swapping the two `LegalLinks` placeholder URLs, setting the ASC Privacy URL, and the separate **Delete Account** blocker. None are touched here.

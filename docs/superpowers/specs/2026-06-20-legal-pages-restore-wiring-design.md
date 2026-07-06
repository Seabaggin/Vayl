# Legal Links + Restore Wiring (Technical Pass) — Design Spec

- **Date:** 2026-06-20
- **Status:** Approved — implementing
- **Author:** Bryan (with Claude)
- **Scope this pass:** Wire the *mechanism* so every stubbed paywall-footer control (Restore · Terms · Privacy) and the flat sign-in legal line **actually route**, using **placeholder URLs**. Real legal copy, hosting, and App Store Connect setup are **deferred to a later "App Store Ready" pass** (Bryan's call).

> **Scope note (2026-06-20):** Originally scoped to also author + host the real legal docs. Bryan narrowed it: he'll do one dedicated App Store Ready pass for all Apple-approval needs later. **Now = technical placeholders that genuinely route.** Deferred items are tracked in §8 so the later pass has a checklist.

---

## 1. Problem

`PaywallSheet.swift` has three footer controls with dead stub actions:
- `restorePurchases()` — `TODO(monetization)`: no StoreKit restore wired.
- `openTerms()` / `openPrivacy()` — `TODO(legal)`: no Terms/Privacy URL or page exists anywhere.

The same Terms/Privacy must back the flat, non-tappable text at `SignInView.swift:98`.

Right now the goal is **functional routing**: taps fire the real navigation path (Safari sheet opens; restore runs the real backend) with placeholder content — not a dead stub.

---

## 2. Findings (verified in code)

- **Restore is already built** in the Store/Service layers — only the View stub is unwired:
  - `StoreKitService.restore()` → `AppStore.sync()` then returns the verified Core entitlement (`StoreKitService.swift:86`).
  - `EntitlementStore.restore()` → service call, re-grants the **couple** server-side (partner unlocks too), `refresh()`, returns `isCore` (`EntitlementStore.swift:145`).
  - ⇒ `restorePurchases()` only needs to **call `entitlements.restore()`** + reflect loading/result. **This is real, not placeholder.**
- **No legal URL/page exists**; no `SafariServices` import anywhere. Only URL plumbing is `Config.swift` (Supabase creds).
- **`Vayl.storekit` test config exists** ⇒ restore is testable in the StoreKit sandbox on-device.
- **`.vaylSheet` / `.vaylCover` do not exist** (aspirational in CLAUDE.md). The app presents modals with **raw `.sheet` / `.fullScreenCover`** everywhere. `OBSheetChrome` (`.obSheetChrome()`) is a *content-styling* modifier, not a presentation method.
- **Technical constraint:** `SFSafariViewController` loads only a live `https://` URL — it **cannot** display bundled/local HTML. ⇒ a visible placeholder must point at a reachable URL.

---

## 3. Decisions (locked)

| # | Decision | Rationale |
|---|---|---|
| D1 | **This pass = technical wiring only.** Real legal copy, hosting, ASC = deferred App Store pass. | Bryan's split: one dedicated Apple-approval pass later. |
| D2 | In-app render = **`SFSafariViewController`** via raw native **`.sheet(item:)`**. | Mainstream pattern; matches the app's real presentation convention. Building `.vaylSheet` is out of scope. |
| D3 | **Placeholder URLs = live Apple stand-ins** that render cleanly now, swapped later: **Terms → Apple standard EULA** (`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`), **Privacy → Apple privacy policy** (`https://www.apple.com/legal/privacy/`). | SFSafariVC needs a live URL; Apple legal pages are stable, real, and obviously placeholders. Nothing looks broken in dev. |
| D4 | URL source-of-truth = a single Swift `enum LegalLinks` (the two values + an `Identifiable` doc enum), loudly marked as placeholders. | One place to swap during the App Store pass; mirrors the `Config.swift` static-config pattern. |
| D5 | Restore feedback = **`.alert`** for "nothing to restore" + "error"; **success** = unlock + sheet closes. | StoreKit-conventional; a deliberate yes/no action needs a guaranteed-visible answer. |
| D6 | On-brand HTML styling of the legal body is **deferred** (it lives in the hosted page, authored in the App Store pass). Apple stand-ins are used as-is now. | No throwaway styling work; the real page gets the Vayl treatment later. |

---

## 4. Component design (this pass)

| Piece | File | Responsibility | Interface |
|---|---|---|---|
| URL source-of-truth | `Vayl/Core/Services/LegalLinks.swift` *(new)* | The two placeholder URLs + `Identifiable` doc enum for `.sheet(item:)`. Loud `// PLACEHOLDER — swap during App Store pass` marker. | `enum LegalLinks { static let terms: URL; static let privacy: URL }`; `enum LegalDoc: Identifiable { case terms, privacy; var url: URL; var id: Self }` |
| Safari wrapper | `Vayl/Design/Components/Navigation/SafariView.swift` *(new)* | `UIViewControllerRepresentable` over `SFSafariViewController`, tinted to Vayl colors via `UIColor(AppColors…)` (`preferredControlTintColor` = accent; `preferredBarTintColor` = modal/void). | `struct SafariView: UIViewControllerRepresentable { let url: URL }` |
| Paywall wiring | `Vayl/Features/Monetization/Views/PaywallSheet.swift` *(edit)* | `restorePurchases()` → `entitlements.restore()` + `restoring` flag + `.alert`; `openTerms/openPrivacy()` → set `@State legalDoc` → `.sheet(item:)`. Remove all 3 TODOs. | — |
| Sign-in wiring | `Vayl/Features/Auth/Views/SignInView.swift` *(edit)* | Flat line → tappable Terms / Privacy: markdown links in the `Text` + `.environment(\.openURL, OpenURLAction{…})` intercepting two custom-scheme links → set `@State legalDoc` → same `SafariView` via `.sheet(item:)`. | — |

**No shared wrapper view** — each consumer needs only one `@State legalDoc` + one `.sheet(item:)`; the shared units are `LegalLinks`, `LegalDoc`, `SafariView`.

### Data flow
- **Legal:** tap → set `legalDoc` → `.sheet(item: $legalDoc) { SafariView(url: $0.url) }` (URL from `LegalLinks`). Stacked over the paywall (iOS 16+), dismisses back. Same mechanism in SignInView (top-level, pre-auth).
- **Restore:** tap → `restoring = true` → `await entitlements.restore()` → `restoring = false`. `true` ⇒ `onUnlocked()`. `false` && no `loadError` ⇒ alert "No purchases found." `loadError != nil` ⇒ alert with the message.

---

## 5. Build segments (each independently verifiable — Build Protocol)

**Seg A — Restore wiring** *(smallest, independent)*
- Touches: `PaywallSheet.swift` only.
- Do: local `@State restoring`; `restorePurchases()` → `await entitlements.restore()`; success → `onUnlocked()`; non-success → `.alert`. Remove `TODO(monetization)`.
- **Done:** compiles; on device w/ StoreKit sandbox — owned account → unlocks; un-owned → "No purchases found" alert.
- May NOT touch: `EntitlementStore`, `StoreKitService`, tokens, OBSheetChrome.

**Seg B — Legal plumbing**
- Touches: `LegalLinks.swift` + `SafariView.swift` (new).
- Do: define the two placeholder URLs (loud marker) + `LegalDoc`; build the tinted `SafariView`.
- **Done:** compiles; a throwaway preview opens a placeholder URL in the Safari sheet.
- May NOT touch: feature views, tokens, OBSheetChrome.

**Seg C — Wire all consumers**
- Touches: `PaywallSheet.swift` + `SignInView.swift`.
- Do: `openTerms/openPrivacy()` → `legalDoc`; SignInView tappable line + `openURL` interception; both get `.sheet(item:)`. Remove both `TODO(legal)`.
- **Done:** compiles; on device both footer links + the sign-in line open the Safari sheet over the right Apple stand-in page and dismiss back.
- May NOT touch: `LegalLinks`/`SafariView` internals (consume only), tokens, OBSheetChrome.

Order: **A → B → C**.

---

## 6. Verification

- **Claude:** build-verify (compile) only — Bryan runs on device (standing preference). No sim runs by Claude.
- **Restore:** Bryan, on device, via the `Vayl.storekit` sandbox (owned vs un-owned Apple ID).
- **Legal links:** Bryan, on device — tap each control + the sign-in line, confirm the correct Apple stand-in opens in the Safari sheet and dismisses back.
- **iOS 26 compliance:** `SafariServices` is a system framework (no new SPM dep); `UIColor(_: Color)` for tints; no banned APIs; new files under `Vayl/` auto-join the synchronized group (no pbxproj surgery).

---

## 7. Out of scope (this pass)

- Building `.vaylSheet` / `.vaylCover`.
- Generator services (Termly/iubenda).
- On-brand HTML styling of the legal body (lives in the hosted page).

## 8. Deferred — "App Store Ready" pass checklist (NOT this pass)

When Bryan does the Apple-approval pass, this work remains:

1. **Author the real Terms + Privacy** content. The Privacy Policy must accurately describe the real stack (reference, verified this pass):
   - Sign in with Apple (Apple user id; name/email only if shared; possible relay email).
   - **Supabase** backend processor — stores profile, pairing/couple, Desire Map, Agreements, Pulse, reflections, entitlement tier; US processing.
   - **Sensitive intimacy data** + partner-sharing (revealed Desire Map, shared Agreements) + safeguards (RLS, HTTPS, on-device screenshot protection, user-paced reveal).
   - Apple-processed IAP — app stores only the couple **tier**, never card data.
   - Local **SwiftData** mirror.
   - **No third-party analytics / ads / ATT tracking** (verified: only `supabase-swift` dependency).
   - 18+; data-deletion right + contact.
2. **Host** the two pages (free static host or `vayl.app`) → replace the two placeholder values in `LegalLinks.swift`.
3. **App Store Connect:** set the required Privacy Policy URL.
4. **Fill-ins:** legal entity name, governing-law jurisdiction, contact email, effective date.
5. **In-app Account Deletion** — a *separate* App Store blocker (not legal links). The future real Privacy Policy references the deletion right + notes in-app deletion; it must not claim the in-app feature exists until built.
6. Optional: give the legal page body the on-brand (dark-void + spectrum) HTML treatment + tinted Safari toolbar.

## 9. Risks

- **Placeholder pages are Apple's, not Vayl's** — intentional + loudly marked; the App Store pass swaps them. Risk = forgetting to swap → mitigated by the loud `LegalLinks` marker + this checklist.
- **Stacked sheets** (Safari over PaywallSheet) — standard iOS 16+; verified on device in Seg C.

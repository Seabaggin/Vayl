# Legal Pages + Restore Wiring — Design Spec

- **Date:** 2026-06-20
- **Status:** Awaiting review
- **Author:** Bryan (with Claude)
- **Topic:** Wire the three stubbed paywall-footer controls (Restore · Terms · Privacy) to real behavior, create the legal pages that don't yet exist, and make the flat sign-in legal line tappable.
- **Blocker context:** App Store submission blocker list (app-routing-map): *Delete Account · Restore Purchases · Privacy Policy + Terms links*. This spec covers **Restore Purchases** and **Privacy Policy + Terms links**. **Delete Account is explicitly out of scope** (separate follow-up).

---

## 1. Problem

`PaywallSheet.swift` has three tappable footer controls with stubbed actions:

- `restorePurchases()` — `TODO(monetization)`: no StoreKit restore wired.
- `openTerms()` / `openPrivacy()` — `TODO(legal)`: no Terms/Privacy page or URL exists *anywhere* in the app.

The same Terms/Privacy must back the currently-flat text at `SignInView.swift:98` ("By continuing you agree to our Terms & Privacy Policy"), which is not tappable today.

Two of these are App Store hard blockers: Apple rejects a paywalled non-consumable app without a working **Restore Purchases**, and rejects any app without a reachable **Privacy Policy** (a public Privacy Policy **URL** is also a required App Store Connect metadata field).

---

## 2. Findings (verified in code)

- **Restore is already built in the Store/Service layers** — only the View stub is unwired:
  - `StoreKitService.restore()` → `AppStore.sync()` then returns the verified Core entitlement (`StoreKitService.swift:86`).
  - `EntitlementStore.restore()` → calls the service, re-grants the **couple** server-side (so the partner unlocks too), `refresh()`es, returns `isCore` (`EntitlementStore.swift:145`).
  - ⇒ `restorePurchases()` only needs to **call `entitlements.restore()`** and reflect loading + result.
- **No legal URL/page exists** anywhere; no `SafariServices` import anywhere. The only URL plumbing is `Config.swift` (Supabase creds).
- **No analytics/tracking SDK** — the only third-party SPM dependency is `supabase-swift` (+ its Apple/pointfree transitive deps). No Firebase/Amplitude/Sentry/AppTrackingTransparency. ⇒ the Privacy Policy can honestly state "no third-party analytics, no ad tracking, no ATT."
- **`Vayl.storekit` test config exists** ⇒ restore is testable in the StoreKit sandbox on-device.
- **`.vaylSheet` / `.vaylCover` do not exist.** They are aspirational in CLAUDE.md (same gotcha as `.glassCard()`). The app presents modals with **raw `.sheet` / `.fullScreenCover`** everywhere (HomeRouterView, PulseGraph, PairingSettingsView, …). `OBSheetChrome` (`.obSheetChrome()`) is a *styling* modifier for sheet **content**, not a presentation method.

---

## 3. Decisions (locked)

| # | Decision | Rationale |
|---|---|---|
| D1 | **I draft** both legal docs from the app's real data practices; Bryan (ideally a lawyer) reviews. | Bryan's call; accuracy requires knowledge of the actual stack. Not a substitute for legal counsel. |
| D2 | Canonical docs = **host-ready static HTML** (no Markdown mirror). | One source of truth → no drift between in-app render and the ASC-required public URL. |
| D3 | Bryan **hosts** the two pages (free static host now, or `vayl.app` later) and supplies the two live URLs. | App Store Connect hard-requires a public Privacy Policy URL regardless of in-app behavior. |
| D4 | In-app render = **`SFSafariViewController`** with **on-brand HTML** (dark-void + spectrum body that I author) and a tinted Safari toolbar. | The mainstream pattern; stays in-app; single source of truth with the hosted URL. The HTML I control supplies the Vayl look; only the slim Safari bar is system chrome. |
| D5 | Presentation = **raw native `.sheet(item:)`** (matching the app's real convention). Building the `.vaylSheet`/`.vaylCover` contract is **out of scope**. | Don't balloon scope; match reality, not the aspirational contract. |
| D6 | Restore result feedback = **`.alert`** for "nothing to restore" and "error"; **success** = unlock + sheet closes (the gate opening is the confirmation). | StoreKit-conventional; restore is a deliberate yes/no action that demands a guaranteed-visible answer. |
| D7 | URL source-of-truth = a single Swift `enum LegalLinks`. | One place to update post-hosting; mirrors the `Config.swift` static-config pattern. |

---

## 4. Data practices the Privacy Policy must encode (accurate to the build)

- **Account / auth:** Sign in with Apple. App receives an Apple user identifier; name/email only if the user shares (Apple may relay a private/proxy email). Used to create + identify the account.
- **Backend processor:** Supabase (Postgres). Stores profile, pairing/couple linkage, and the couple's content: Desire Map responses, Agreements, Pulse check-ins, post-session reflections, and the entitlement tier. Named as a third-party processor; data may be processed in the US.
- **Sensitive data, explicitly acknowledged:** this is intimate personal data about sexuality, boundaries, and relationships. Describe **partner sharing** (a paired partner can see content the user chooses to reveal/share — e.g. a revealed Desire Map, shared Agreements) and **safeguards** (row-level security scoping, in-transit encryption/HTTPS, on-device screenshot protection, user-paced reveal).
- **Purchases:** Apple In-App Purchase / StoreKit. **Apple processes payment**; the app stores only the resulting **entitlement tier** (couple-level). The app never sees card data.
- **Local storage:** SwiftData on-device mirror.
- **No tracking:** no third-party analytics SDKs, no ad networks, no ATT/IDFA tracking, no sale of data.
- **Age:** 18+ only; not directed to children.
- **Data rights / deletion:** users can request full deletion by contacting us; **in-app Account Deletion is being added** (tracked separately — see §8). Do not claim in-app deletion exists yet.
- **Standard clauses:** security, international processing, changes-to-policy + last-updated date, contact.

**Terms of Service** essentials: 18+ eligibility; license to use; acceptable-use (consent-centered — not for coercing/harassing a partner); IAP terms (one-time couple-level Core unlock; refunds handled by Apple; references Apple's standard EULA / Licensed Application EULA); **not professional advice** (educational, "grounded in research" ≠ therapy/medical/legal advice); limitation of liability; governing law; changes; contact.

### Fill-ins Bryan must supply (marked loudly in the docs + README)
1. Legal entity name (Bryan as sole proprietor, or an LLC)
2. Governing-law jurisdiction (state / country)
3. Contact email
4. Effective / last-updated date
5. The two hosted URLs (after hosting)

---

## 5. Component design

| Piece | File | Responsibility | Interface |
|---|---|---|---|
| URL source-of-truth | `Vayl/Core/Services/LegalLinks.swift` *(new)* | Holds the two public URLs + an `Identifiable` doc enum for `.sheet(item:)`. | `enum LegalLinks { static let terms: URL; static let privacy: URL }`; `enum LegalDoc: Identifiable { case terms, privacy; var url: URL; var id: ... }` |
| Safari wrapper | `Vayl/Design/Components/Navigation/SafariView.swift` *(new)* | `UIViewControllerRepresentable` over `SFSafariViewController`, tinted to Vayl colors (`preferredControlTintColor` = accent, `preferredBarTintColor` = modal/void via `UIColor(AppColors…)`). | `struct SafariView: UIViewControllerRepresentable { let url: URL }` |
| Legal HTML | `docs/legal/privacy.html`, `docs/legal/terms.html`, `docs/legal/README.md` *(new)* | Canonical host-ready docs (self-contained inline CSS, dark-void + spectrum, responsive, accessible: semantic headings, AA contrast). README = hosting steps + the §4 fill-in checklist. | n/a (static assets) |
| Paywall wiring | `Vayl/Features/Monetization/Views/PaywallSheet.swift` *(edit)* | `restorePurchases()` → `entitlements.restore()` + `restoring` flag + `.alert`; `openTerms/openPrivacy()` → set `@State legalDoc` → `.sheet(item:)`. Remove all 3 TODOs. | — |
| Sign-in wiring | `Vayl/Features/Auth/Views/SignInView.swift` *(edit)* | Flat line → tappable Terms / Privacy. Markdown links in the `Text` + `.environment(\.openURL, OpenURLAction{…})` intercepting two custom-scheme links → set `@State legalDoc` → same `SafariView` via `.sheet(item:)`. | — |

**No shared wrapper view** for the two consumers — each needs only one `@State legalDoc` + one `.sheet(item:)` modifier; abstracting that is over-engineering. The shared units are `LegalLinks`, `LegalDoc`, and `SafariView`.

### Data flow
- **Legal:** tap → set `legalDoc` → `.sheet(item: $legalDoc) { SafariView(url: $0.url) }` (URL from `LegalLinks`). Stacked sheet over the paywall (iOS 16+), dismisses back. Identical mechanism in SignInView (top-level sheet, pre-auth — fine).
- **Restore:** tap → `restoring = true` → `await entitlements.restore()` → `restoring = false`. `true` ⇒ `onUnlocked()`. `false` && no `loadError` ⇒ alert "No purchases found." `loadError != nil` ⇒ alert with the message.

---

## 6. Build segments (each independently verifiable — Build Protocol)

**Seg A — Restore wiring** *(smallest, independent of legal)*
- Touches: `PaywallSheet.swift` only.
- Do: local `@State restoring`; `restorePurchases()` calls `await entitlements.restore()`; success → `onUnlocked()`; non-success → `.alert`. Remove `TODO(monetization)`.
- **Done:** compiles; on device w/ StoreKit sandbox — owned account → unlocks; un-owned → "No purchases found" alert.
- May NOT touch: `EntitlementStore`, `StoreKitService`, tokens, OBSheetChrome.

**Seg B — Legal content**
- Touches: `docs/legal/*` only (no Swift, no device).
- Do: author `privacy.html` + `terms.html` (§4) + `README.md` (hosting + fill-ins). On-brand, self-contained, accessible.
- **Done:** Bryan reads + approves the copy (lawyer review encouraged).
- May NOT touch: any Swift.

**Seg C — Legal plumbing**
- Touches: `LegalLinks.swift` + `SafariView.swift` (new).
- Do: define URLs (placeholder, loudly marked) + `LegalDoc`; build the tinted `SafariView`.
- **Done:** compiles; a throwaway preview opens a doc URL.
- May NOT touch: feature views, tokens, OBSheetChrome.

**Seg D — Wire legal links**
- Touches: `PaywallSheet.swift` + `SignInView.swift`.
- Do: `openTerms/openPrivacy()` → `legalDoc`; SignInView tappable line + `openURL` interception; both get `.sheet(item:)`. Remove both `TODO(legal)`.
- **Done:** compiles; on device both footer links + the sign-in line open the in-app Safari sheet over the right page.
- May NOT touch: `LegalLinks`/`SafariView` internals (consume only), tokens, OBSheetChrome.

**Seg E — Bryan (outside code)**
- Host the two pages → paste real URLs into `LegalLinks.swift` → add the Privacy URL to App Store Connect → fill the §4 placeholders.
- **Done:** live URLs resolve; ASC Privacy field set.

Suggested order: **A → B → C → D → E** (A first: smallest, clears a standalone blocker; B can run anytime as it's Swift-free).

---

## 7. Verification

- **Claude:** build-verify (compile) only — Bryan runs on device (per standing preference). No sim runs by Claude.
- **Restore:** Bryan, on device, via the `Vayl.storekit` sandbox config (owned vs un-owned Apple ID).
- **Legal links:** Bryan, on device — tap each control, confirm the correct page opens in the Safari sheet and dismisses back.
- **iOS 26 compliance:** `SafariServices` is a system framework (no new SPM dep); `UIColor(_: Color)` for tints (no `UIScreen.main`); no banned APIs.

---

## 8. Out of scope / dependencies

- **In-app Account Deletion** — an App Store blocker, but a **separate** task. The Privacy Policy references a deletion *right* + contact path and notes in-app deletion is forthcoming; it must not claim the in-app feature exists. Flag as the next blocker to schedule.
- **Building `.vaylSheet` / `.vaylCover`** — the aspirational presentation contract is not built here.
- **Generator services** (Termly/iubenda) — not used; we self-author + self-host.
- **Subscription-style "Terms must be embedded in the binary"** strictness — N/A; Core is a one-time non-consumable. Both links are still provided (best practice + own blocker list).

## 9. Risks

- **Placeholder URLs ship dead until Seg E.** Mitigation: the spec/plan makes "host + set URLs" an explicit pre-submission gate; the `LegalLinks` placeholder is loudly commented as the one value to replace.
- **Legal accuracy.** The draft is grounded in the real stack but is **not legal advice**; Bryan should have it reviewed before submission.
- **Stacked sheets** (Safari sheet over PaywallSheet). Standard iOS 16+ behavior; verified on device in Seg D.

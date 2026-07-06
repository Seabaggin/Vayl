# Monetization — Implementation Spec (couple-core)

**Date:** 2026-06-15
**Phase:** 3 of 6 (Build Playbook: `docs/roadmap/vayl-build-roadmap.html`)
**Status:** **M1 (backend + Swift data layer) BUILT + verified on prod 2026-06-17** — see M1 below for the decision log. M2–M5 not started. The 4/27 model scaffolding is now wired to a live couple-scoped schema.
**Goal:** Free-tier gating + $24.99 lifetime (one buys → BOTH unlock) live, with the two conversion moments. The confirmed Act-1 model, couple-symmetric.

> **Fresh chat:** self-contained. The full rationale for every decision is in the source-of-truth doc (below) and `[[monetization_paywall_spec]]` (auto-loads via memory). This spec builds the reveal *gate* (M5) on top of the Desire Map reveal *mechanic* (Desire spec D4). Verify prod before acting.

---

## Source of truth + the V1 cut

**Authoritative doc (status "Confirmed", Apr 25 2026), outside the repo:**
`~/Documents/Vayl Work/Design System/Vayl — Paywall Structure & Decision Log.md`. Read it for full rationale. Memory `[[monetization_paywall_spec]]` is the summary.

**The V1 cut (Bryan, 2026-06-15): COUPLE-CORE.** Ship:
- Free-tier gating + **Vayl Lifetime $24.99** (one purchase covers BOTH partners) + StoreKit 2.
- The **two conversion moments**: Deck 2 unwrap + Desire Map reveal (1 free match → blur → upgrade).
- Couple-**symmetric** only: a new couple is never in a paid/free split — both free → one buys → both unlock.

**Deferred to the solo-poly / invite phase (M6):** the **asymmetric** Option-C waiting state + 7-day escape hatch + the personal nudge tool + Person-C free-tier invite flow; the **$7.99 additional connection** + Network/Metamour decks; Vayl **Pro** subscription + founding-member benefit (Act 2). These fire only when accounts are asymmetric — not for new couples.

---

## North-star principles (every choice checks against these)
1. **Charge for content + infrastructure, never for the act of connection.** Lock In and Learn are **never** paywalled.
2. **The mutual premise is sacred.** Data made together belongs to both — including when one paid and one didn't. (For couple-core, one purchase covers both, so this rarely bites until M6.)
Copy is always *"own your experience" / "yours forever"* — **never "pay to unlock."** Desire before friction: the ceremony/reveal plants the want *before* the ask.

---

## Current state (verified 2026-06-15)

**Models exist and mirror the spec exactly** (built 4/27, two days after the doc) — but nothing is wired:
- [`EntitlementRecord`](../../../Vayl/Core/Models/EntitlementRecord.swift) — `@Model`, couple-level Core purchase: `coupleId`, `productId` (`com.vayl.core.lifetime`), `transactionId`, `purchasedBy` (support-only, never shown), `purchasedAt`, `isActive`, `expiresAt` (nil = lifetime), `isFoundingMember`. Computed `isLifetime`/`isExpired`. Header: *"Receipt validation happens server-side via Edge Function. Never client-only."*
- `ConnectionEntitlement` (same file) — the $7.99 permanent connection purchase (M6 / deferred).
- [`AccessTier`](../../../Vayl/Core/Models/Enums/AppAccessEnums.swift) — `free` / `core` ($24.99 Act 1) / `pro` (Act 2, inactive). `ConnectionPlan` — `primary` / `additional`. `Couple.entitlementTier` holds the tier.

**Zero functional implementation (verified):**
- **No StoreKit** anywhere (no `import StoreKit`, no purchase flow).
- **No `entitlements` table** in prod; `couples` has **no tier column** (only `matches_revealed`).
- **No receipt-validation edge function** (only create-pair / lookup-code / rapid-task).
- **No paywall UI**, no free-tier gating logic, no reveal gate.

---

## The free / core boundary (from the paywall doc — exact)

**FREE ($0):** full onboarding; Desire Map — both complete + **1 mutual match revealed**; Deck 1 fully unlocked; Deck 2 unlocks after the first *sitting* (unwrap ceremony → gate); 1 game unlock; **Lock In always free**; Pulse — unlimited logging, insights locked; Journal — unlimited entries, Agreements + Roadmap locked; **Learn fully free**.

**CORE — Vayl Lifetime $24.99:** full Desire Map reveal; all Act-1 decks (now + future, forever); all games; pulse insights; Agreements vault; Roadmap; post-session reflection data. **One purchase, two full accounts, one couple.**

---

## Entitlement model (couple-level)

Tier is a property of the **couple**, not the user. When either partner buys, the couple is `core` and **both** unlock. Read path: a central `EntitlementStore` (or `AppState`) resolves the couple's tier from a server-validated entitlement and exposes a single `tier: AccessTier` that every gate reads. Never scatter per-feature purchase checks.

---

## Segments

| # | Does (one thing) | Done — on device | May not touch |
|---|---|---|---|
| **M1** | Couple-level entitlement schema + sync (one purchase → both unlock) | A couple's tier persists in prod; both partners read `core` | StoreKit, paywall UI |
| **M2** | StoreKit 2 purchase + restore for $24.99 lifetime | Sandbox purchase unlocks `core`; restore works on reinstall | gates, conversion UI |
| **M3** | Free-tier gates across surfaces | A free couple sees exactly the free tier; upgrade flips all | StoreKit |
| **M4** | Conversion moment 1 — Deck 2 unwrap ceremony → gate | First sitting completes → unwrap → converts or "Not yet" | reveal gate |
| **M5** | Conversion moment 2 — Desire Map reveal gate | Free couple sees 1 match + blurred rest; buy → both unlock all | Deck 2 path |
| **M6** | *(defer)* Asymmetric reveal + multi-connection | Out of V1 — solo-poly / invite phase | — |

### M1 — Couple-level entitlement schema + sync
Add the server store: an **`entitlements`** table (`couple_id`, `product_id`, `transaction_id`, `purchased_by`, `purchased_at`, `is_active`, `expires_at`, `is_founding_member`) **or** a `couples.access_tier` column. Couple-scoped; RLS so both partners read the couple's tier (reuse the `is_couple_member` SECURITY DEFINER fn). Sync `EntitlementRecord` to it. Build the `EntitlementStore` that resolves `tier` for the rest of the app.
**Done:** a couple's tier persists in prod; both partners read `core` after one buys.
**Risk:** must be couple-scoped (or the non-buyer stays locked); `couples` has no tier column today.
**Resolved (2026-06-17):** BOTH — a service-role-only `entitlements` ledger (the receipt/audit trail; `purchased_by`/`transaction_id` never client-readable) **and** denormalized `couples.access_tier` / `core_unlocked_at` / `is_founding_member` (the cheap value gates + RLS read, no join). Server-side **StoreKit 2 JWS** validation posture, implemented **fail-closed** in the `grant-entitlement` edge fn (the only writer) — real Apple verifier wired in M2. `core_unlocked_by` deliberately NOT on `couples`: "who paid" is support-only and lives solely in the service-role-only ledger.

**✅ BUILT + VERIFIED on prod (2026-06-17):**
- Migration `supabase/migrations/20260617120000_monetization_entitlements.sql` (applied via `execute_sql`; reconcile history later with `supabase migration repair --status applied 20260617120000`).
- RLS proven on prod (test couple): one service-role grant → BOTH partners read `couples.access_tier = core`; a stranger reads nothing; clients **cannot** write the tier (no UPDATE policy → 0 rows); `entitlements` is service-role-only (authenticated → `permission denied`). Test grant reverted; `get_advisors` clean (entitlements matches the sibling couple-tables' GraphQL-exposure posture, RLS-gated).
- Edge fn `grant-entitlement` deployed (`verify_jwt`; returns 401 without auth). Two server-authoritative paths converge on the same service-role write (ledger upsert idempotent on `transaction_id` + tier flip); a caller can only grant their OWN couple. **To activate later:** M2 sets `APPLE_VERIFICATION_ENABLED=true` + wires the verifier; set `ENTITLEMENT_GRANT_SECRET` (function env) to enable the admin/support grant path.
- Swift: `EntitlementService` (reads `couples.access_tier`; `grantCore` invokes the edge fn) + central `EntitlementStore` (`@Observable`; exposes `tier`/`isCore`; mirrors local `Couple`; `refresh()` on launch) wired at the app root (`VaylApp`). Target compiles clean.
**Open:** none for M1 — M2 owns the StoreKit purchase/restore + real Apple JWS verification + App Store Connect product.

### M2 — StoreKit 2 purchase + restore
New StoreKit service: configure product `com.vayl.core.lifetime` (App Store Connect), purchase flow, `Transaction.currentEntitlements`, restore-on-reinstall. On a verified transaction → write the couple `EntitlementRecord` (M1) and flip the couple to `core`. The paywall doc mandates **server-side receipt validation** ("never client-only") — pair this with M1's validation decision (a `validate-receipt` edge function, or accept StoreKit 2's signed `Transaction` for V1 and harden later).
**Done:** a real sandbox purchase unlocks `core` on device; restore works after reinstall.
**Open:** is `com.vayl.core.lifetime` + price tier set up in App Store Connect yet?

### M3 — Free-tier gates
One central `tier` read (M1's `EntitlementStore`) consumed by the Stores. Gate behind `core`: Deck 2+, pulse insights, Agreements, Roadmap, games beyond 1. Keep FREE: Deck 1, Lock In, Learn, journaling, pulse logging, full OB + Desire Map input + 1 match. Locked states read as "not yet," never "denied."
**Done:** a free couple sees exactly the spec's free tier; upgrading flips everything on.
**Risk:** gating sprawl — centralize. Never gate Lock In or Learn (north-star violation).
**Open:** which game is the free "1 game unlock"?

### M4 — Conversion moment 1: Deck 2 unwrap
When the first **sitting** completes (2–3 cards, real conversation), Deck 2's unwrap becomes visible on Home. Reaching for it → unwrap ceremony (cards partially visible — desire before friction) → paywall gate. Copy: *"You're ready for this one"* → *"Unlock everything — $24.99, yours forever."* Escape: *"Not yet"* — no guilt, no re-prompt, door stays open.
**Files:** Home + a paywall sheet + entitlement read. Builds on the card-session flow (Wire W3).
**Done:** completing a sitting surfaces the unwrap; tapping through converts or dismisses cleanly.
**Open:** what counts as a completed "sitting" — a card count, or an explicit end-session?

### M5 — Conversion moment 2: Desire Map reveal gate (the primary event)
Sits on the Desire Map reveal mechanic (Desire spec D4). Reveal exactly **1** mutual match free (`DesireMatch.isFreeReveal == true`, server-set); blur the rest with *"You have X more mutual matches — unlock everything, $24.99, yours forever."* On purchase: set `DesireMapStatus.fullRevealUnlocked` (+ `couples.matches_revealed`) and full-reveal **for both partners**.
**Couple-symmetric ONLY:** both free → both see 1 match → one buys → both unlock. **Do NOT build** the asymmetric Option-C waiting / 7-day / nudge here — that's M6. (The model scaffolds it via `DesireMapStatus.waitingStateSince` — leave it for later, don't delete.)
**Done:** a free couple sees 1 match + blurred rest; buying unlocks all matches for both partners.
**Open:** simultaneous cross-device full reveal in V1 (needs realtime), or single-device acceptable for launch?

### M6 — *(defer)* Asymmetric reveal + multi-connection
Option-C asymmetric waiting + **7-day escape hatch** (Day 1-2 organic, Day 3-4 one app reminder to Person C, Day 5-6 manual nudge, Day 7 resolution returns Person A's *individual* responses — never the mutual matches) + the personal nudge tool (a pre-written iMessage/WhatsApp Person A sends through their own channels — **never a Vayl push**) + Person-C free-tier invite flow; **$7.99 additional connection** (`ConnectionEntitlement` exists) + Network/Metamour decks. Fires only for asymmetric (one paid, one not) accounts = multi-connection, not new couples. Ships with the solo-poly / invite phase.

**Entitlement lifecycle — DECIDED 2026-06-17 (resolve logic built + verified with M1; unlink UX deferred):**
- **Payer-portable tier.** A couple is `core` if it holds an active non-expired entitlement **OR** a member is the `purchased_by` of one. `resolve_couple_access_tier(couple_id)` + `recompute_couple_entitlement(couple_id)` (SECURITY INVOKER, service-role-only EXECUTE) write the `couples` cache. The buyer's lifetime follows them: re-pairing inherits Core automatically (`recompute` runs in `rapid-task` at couple creation). Refund-aware by the same rule — flip `is_active=false` → re-resolve → both partners drop.
- **Couple data is per-couple; a new partner = clean slate.** Desire Map matches, reveal, sessions, deck progress are all couple-scoped, so A+C build their own from scratch. Only the entitlement (and each user's private `desire_ratings`) persists across partners.
- **Already-unlocked couple artifacts stay unlocked for BOTH members forever** (even archived) — the mutual premise. No entitlement gymnastics: "once a couple is unlocked, its artifacts stay readable to its two members."
- **Non-coercive unlink warning.** When the non-payer leaves, a quiet factual notice that Core going forward needs their own unlock — framed so it never becomes "stay with your partner to keep the perks," and never strips the data they made together.
- **Still blocked on an unlink feature (doesn't exist yet):** the unlink action, the warning UI, archived-couple read access. The resolve logic is built so these "just work" when unlink ships.

**Open:** when does the solo-poly / invite model come — fast-follow, or a later act?

---

## Architecture contracts (from CLAUDE.md + the paywall doc)
- Entitlement is **couple-scoped**; tier read through one central store; Views never check purchases directly.
- Receipt validation is **server-side** (never client-only).
- Lock In and Learn are **never** gated.
- Paywall copy: "own your experience" / "yours forever" — never "pay to unlock." Ceremony/reveal before the ask.
- Paywall surfaces use void + spectrum + glass tokens; press-state + haptic; `.ambientAnimation()` on loops; Reduce Motion fallbacks. Empty/locked states feel like "not yet."

## References
- Source of truth: `~/Documents/Vayl Work/Design System/Vayl — Paywall Structure & Decision Log.md`
- Memory: `[[monetization_paywall_spec]]`, `[[v1_strategic_positioning]]`
- Reveal mechanic: `docs/superpowers/specs/2026-06-15-desire-map-implementation-spec.md` (D4 — M5 gates it)
- Models: `Vayl/Core/Models/EntitlementRecord.swift` (EntitlementRecord + ConnectionEntitlement), `Enums/AppAccessEnums.swift` (AccessTier, ConnectionPlan), `Couple.swift` (entitlementTier)
- Playbook cards M1–M6: `docs/roadmap/vayl-build-roadmap.html`

## How to execute (fresh chat)
"Work Monetization Segment M1 from `docs/superpowers/specs/2026-06-15-monetization-implementation-spec.md`. Read the segment + the paywall doc + named models, verify prod, confirm scope per the Build Protocol, answer the open questions with me, build to the done-condition, update playbook status + log decisions. Couple-core only — M6 is deferred."

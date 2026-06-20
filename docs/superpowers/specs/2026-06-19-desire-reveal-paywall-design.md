# Desire Map Reveal + Paywall — Design Spec

**Date:** 2026-06-19
**Status:** Design settled, not yet built. This is **Segment 2** of the Desire Map work (the individual reveal).
**Source mockups:** session `24b4ddb2` (visualize widgets `vayl_paywall_mission_first`, `vayl_paywall_five_mission_lines`, `vayl_desire_map_paywall_AB`, `vayl_paywall_full_offer_grouped`, `vayl_paywall_B_with_access_disclosure`). Refined version produced 2026-06-19.

---

## 1. The reveal experience

### Architecture: ONE screen, phased by timing
The reveal is a single `.vaylCover` (immersive, protected) whose content moves through beats via animation/timing — **not** multiple navigated screens. Even the post-purchase unlock happens in place. Navigating between screens would break the one continuous emotional arc.

The matches only exist once **both** partners finish (the `compute-desire-matches` edge fn writes `desire_matches` only when `bothComplete`), so the reveal is inherently a both-completed payoff. Opened before both are done → the `.empty` "no shared matches yet" state.

### The 3-beat choreography (reveal door only)
1. **Beat 1 — the one (free) match, alone.** Just the single match, centered, with space. No locked cards, no price. Let it land (haptic, a beat). The positive emotional peak ("we want the same thing") must land *clean* before any commerce.
2. **Beat 2 — the gap opens.** The match settles up; the locked matches reveal beneath — blurred, staggered, with a count ("and N more you share"). Don't show what they are. This is the curiosity gap (Zeigarnik) — the real conversion engine, not the price.
3. **Beat 3 — the ask.** The paywall sheet (section 2).

### Consumer-psychology principles
- **Separate emotion from commerce** — the free match lands before any paywall/locked content appears.
- **Curiosity gap drives conversion**, not price pressure.
- **Give the strongest match free** (a mutual). The edge fn already picks a mutual as `is_free_reveal`. Don't withhold quality — a great free taste builds trust that the locked ones are gold.
- **Relational framing, not feature framing.**
- **No dark patterns** — no countdowns, no fake scarcity, no plan-anxiety picker. Vayl is anti-manipulation; pressure poisons a trust-based intimacy product.
- **Fast (~4–5s)** and **grace the edges** — 0–1 matches → no gap, no paywall (guard on `lockedCount > 0`).

### Screen/state inventory (all rendered by the one screen, + entry)
1. Loading ("finding where you align…")
2. Beat 1 — match alone *(new; today the stub shows everything at once)*
3. Beat 2 — gap (locked + count)
4. Beat 3 — paywall sheet
5. Unlock-in-place — blur lifts after purchase, everything revealed *(the payoff)*
- Branch: **already-core** → skip 3–4; match → all matches, no paywall (celebration)
- Branch: **1 / 0 matches** → no gap, graceful
- Entry: **"you both finished"** doorway → **Segment 3** owns this

---

## 2. The paywall sheet

### Three doors, one reusable sheet
| Door | Warm-up before the sheet | Top-line hook |
|---|---|---|
| **Reveal auto-prompt** | match lands → gap opens (Beats 1–2) | "Reveal your map" |
| **Settings → upgrade** | none (arrived with intent) | "Yours, together" / "Unlock Vayl" |
| **Play → locked deck** | deck preview (theme + 1 sample card, rest blurred) | "Unlock [Deck]" |

The **body is identical at every door.** Only the **hook line** and the **warm-up in front of it** swap. Build as ONE reusable sheet with an entry-context param (`reveal` / `settings` / `playDeck`). The 3-beat choreography belongs to the **reveal door only** — Settings goes straight to the sheet; Play goes deck-preview → sheet.

### Scope: $24.99 unlocks ALL of Core
The purchase is the full Act-1 Core unlock (every deck, all games, the full Desire Map, Pulse insights, Agreements vault, Roadmap) — **not** just the remaining matches. One payment, both partners unlock. The reveal is the *hook*; the value presented is *all of Core*. (Narrowly-scoped "$25 for 3 more matches" undersells.)

### Refined structure (the settled design — reveal door)
- **Hook header:** "Reveal your map"
- **Hero line** (lead with the no-subscription promise): *"One payment. Yours forever — never a subscription. It opens everything you two explore together."*
- **"What you'll do together" — FOUR outcome lines:**
  1. See everywhere your desires meet
  2. Talk openly about sex, boundaries & what-ifs
  3. Explore opening up — at a pace you both set
  4. Reach the agreements that let you move forward
- **Decision block (the focal point):**
  - **$24.99 · one time · yours forever**  + ⓘ (taps → receipt)
  - 👥 **covers both of you — your partner doesn't pay** (elevated as a badge)
  - "How access works for both of you" (expandable)
  - **CTA: "Unlock everything · $24.99"** (price-on-button — see Apple notes)
  - Footer: Restore purchase · Terms · Privacy · a small "grounded in real research"
- **Receipt (on-tap, behind ⓘ):** Full Desire Map (every match, now & future) · Every conversation deck · All games · Pulse insights · Agreements vault & shared Roadmap · Post-session reflections · "The Opener and your solo decks are always free — you never pay to start."
- **"How access works" (on-tap):** "Your maps are always yours" (each person's ratings stay with them, paired or not) · "Core follows whoever buys it" (covers both while paired; stays on the buyer's account if you unpair).

### Best-app refinements applied
- **Brevity** (Calm/Headspace): 4 outcome lines, not 5. The dropped "one trusted place / grounded in research" line was a *trust* signal, not an outcome → moved to a small credibility mark in the footer.
- **No-subscription as a proud headline** (Things, indie one-time apps), not fine print.
- **One unmistakable decision block** (Apple native IAP, Superhuman) — price + CTA as the clear focal point with air around it.
- **Elevate "covers both of you"** (Paired) — halves perceived cost + signals fairness.
- **Progressive disclosure** (Apple, Calm) — receipt + access detail on tap, emotional view stays clean.
- **No pressure tactics** (anti-Duolingo / anti-growth-SaaS).

### Apple compliance
- **CTA carries the price** ("Unlock everything · $24.99"). Apple does **not** require the literal word "Purchase"/"Buy"; it requires a clear, conspicuous price and a non-deceptive flow (Guideline 3.1.1 / 3.1.2 + the HIG for in-app purchase). The final explicit "Buy for $24.99" confirmation is Apple's own StoreKit sheet. Price-on-button removes any surprise at that sheet and is a conversion best-practice. (Verify the exact current 3.1.x wording before submission.)
- **One-time non-consumable** → no auto-renewal subscription disclosures apply.
- **Required surfaces present:** Restore · Terms · Privacy (footer). **Delete Account** is a separate Settings requirement (still on the App-Store-blocker list).

### Build notes
- Match counts must be **templated to the couple's real count** (not hardcoded "four / three").
- Reusable sheet with entry-context param; header/hook swaps, body constant.

---

## 3. Existing code (what Segment 2 changes)
- `DesireRevealView` / `DesireRevealStore` (Features/Desire Map) — stub; currently renders free + locked + CTA all at once. Segment 2 restructures the `.ready` state into the **3-beat timeline** + this **sheet**, and adds the **unlock-in-place** animation.
- `compute-desire-matches` edge fn — picks a mutual as the free reveal; stores partner values null (alignment-only).
- StoreKit purchase (`StoreKitService.purchase`) + `grant-entitlement` + the locked-teaser/blur UI already exist (M2 effectively done per the app-routing-map notes); the unlock path is `store.unlockAll()` → `entitlements.purchase()` → reload.

Relates to: `monetization_paywall_spec`, `project_app_routing_map`, `d4_reveal_stub_built`, `frontend_ux_nav_spec`.

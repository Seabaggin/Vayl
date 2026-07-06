# Paywall Surface — Design Spec

**Date:** 2026-06-18
**Type:** Surface design (the conversion UI that sits in front of the purchase)
**Status:** Design **resolved**; not built. Headline copy locked; bullets 4–5 wording open.
**Relationship to the monetization playbook:** this is the **surface** that **M5** (Desire Map reveal gate) presents and that **M2** (StoreKit) sits behind. It does **not** change M1/M2/M5 logic, the free/locked resolution, or `DesireRevealStore`. See `2026-06-15-monetization-implementation-spec.md`.

> **Why this doc exists:** the paywall is the app's primary conversion (the atlas: the reveal lands "on the personally-specific result, at peak intent"). Its *feel* was iterated in HTML mockups on 2026-06-18. This captures the resolved surface so the eventual `PaywallView(context:)` has a source of truth and the honest-copy promises don't evaporate.

---

## 1. What it is

One reusable, **context-parameterized** surface — `PaywallView(context:)` — presented as a `.vaylSheet` in the **founder-letter grammar** (the One Year card-sheet inset from the top, void/atmosphere showing above; the same grammar already built in `FounderLetterPhase` / `FounderLetterSheet`). It offers **Vayl Lifetime $24.99** (Core — one purchase, both partners, forever).

The hero leads with the **mission** (what an NM couple *accomplishes*), never a feature list. The itemized inventory lives one **ⓘ tap** away, by the price.

---

## 2. Where it fits — when a couple sees it

**It is only ever *opened*, never *pushed*.**

| Trigger | When | Headline context |
|---|---|---|
| **Primary — the reveal, at peak intent** | Free couple finishes both maps → Home "matches ready" → the **reveal celebrates** (1 free match + shimmering locked teasers) → they tap **"See all you share"** → this sheet. | `.reveal` |
| **Secondary — a calm door** | An always-available "Own your experience" row in the Vault (Map tab) / Settings, for the couple who closed the reveal and decided later. | `.settings` |

**Never:** push notifications, interstitials, countdowns, "open the app to unlock," or any unsolicited appearance. The sheet appears only on an explicit tap on something that needs Core. **Dismiss = "not yet"** — always clean; the free match stays theirs; no guilt, no re-prompt. (Matches CLAUDE.md humility + the monetization north-star "locked states read as 'not yet,' never 'denied.'")

**Presentation mechanics:**
- `.vaylSheet` — preview-and-return. **Not** a `.vaylCover` (it is not a protected, confirm-on-exit mode like Card Session).
- Card sheet inset from the top (~`0.15` screen height), void/atmosphere visible above (One Year grammar).
- Spectrum grab handle; **dismissable from the first frame** (pull-down + handle). Never hostage.
- Void + spectrum tokens; press-state + haptic on every tappable; `.ambientAnimation()` on any loop; Reduce Motion fallbacks. (Standard Vayl surface contract.)

---

## 3. Context parameterization

Only the **headline + subhead + CTA** change by entry point. Everything below is identical.

| Context | Headline | Subhead does | CTA |
|---|---|---|---|
| `.reveal` | **"Reveal all you share"** | carries the count — "unlock all four…" | **"Reveal everything"** |
| `.settings` | **"Yours, together."** | carries the precision — "Unlock all of Vayl — one payment, both of you, forever." | **"Own your experience"** |

**Rationale:**
- `.reveal` is the **literal answer to the tap that opened the sheet** — they press "See all you share," the sheet says "Reveal all you share." Precise: the gated object is *the full set of shared matches*, not "your map" (the map is the individual input they already completed; "your" is the wrong number for a shared unlock). On-surface language is always **"share / align,"** never "matches" (internal `DesireMatch` term; reads dating-app-y).
- `.settings` has no specific moment to point at, so the headline is **warm-evergreen by design** and the **subhead does the precise work.** (Alt if precision-forward is preferred there: "Unlock all of Vayl.")

---

## 4. Surface anatomy (top → bottom)

1. **Spectrum grab handle.**
2. **Headline** — `LivingText` spectrum treatment (animated on device; static gradient under Reduce Motion). Context-swapped (§3).
3. **Subhead** — founder-letter **mono** font, short, leads with the no-subscription framing. Context-swapped. Reveal example: *"one payment opens everything you two explore together. no subscription, yours to keep."*
4. **"What you'll do together"** — the **five mission outcomes** (§5), each with a spectrum check. Positive only.
5. **Divider.**
6. **Price row** — `$24.99 · one time · yours forever` + **ⓘ** (info-circle, spectrum) → opens the receipt (§6).
7. **Partner-coverage line** — `covers both of you — your partner doesn't pay` (users glyph). This is the real "lifetime includes the partner" idea — a quiet line, not a table row.
8. **"How access works for both of you ›"** — collapsed disclosure (§7).
9. **CTA** — spectrum-bordered capsule, context-swapped (§3).
10. **Footer** — Restore purchase · Terms · Privacy (Restore is required by Apple).

---

## 5. The five mission outcomes (the hero)

Positive, NM-specific, **what the couple accomplishes** — never a feature list, never a negative mirror (the rejected Paired "Without Paired: stuck / detached / avoiding" column is exactly the cringe we avoid). Exploratory, never presumptuous ("*explore* opening up," never "open your relationship") — keeps faith with "every outcome, including 'not for us,' is valid."

1. **Understand what you each want — as individuals, and as a couple**
2. **Talk openly about sex, boundaries, and what-ifs**
3. **Explore non-monogamy with more intention**
4. **Keep your boundaries and agreements clear — and honored** *(the Agreements vault; OPEN — alts: "Give your boundaries a home you both can see and trust" · "Your agreements, written down and actually kept")*
5. **One trusted place for all of it — grounded in real research** *(OPEN — see caveat)*

**Bullet 5 free/paid caveat:** the consolidated research hub is **Learn, which is free** (never paywalled — north-star). So bullet 5 is worded as the *whole app's* credibility + "it's all here" (the paid decks are research-grounded too) — **not** "pay to unlock research," which would be false. If it must read as a clearly *paid* line, point it at the deck **library** (paid): "Go deeper with the full library — built on real research."

> Mission copy is the founder's to own. These five are the resolved starting point; bullets 4–5 are explicitly open.

---

## 6. The ⓘ receipt (tap by the price → popover / small sheet)

**"Everything included, forever"** — the itemized proof for the detail-minded buyer. From the monetization spec's exact Core boundary:

- Full Desire Map — every match, now & future
- Every conversation deck — now and forever
- All games
- Pulse insights
- Agreements vault & your shared Roadmap
- Post-session reflections

**Free footer (the corrected free items):** *"The Opener and your solo decks are always free — you never pay to start."*
(Earlier drafts wrongly listed **Lock In** here. Lock In is a *friction/intentionality ritual* — a speed-bump before a session — not gateable value; it has no place in a free/paid statement. It stays an internal gating rule, off-surface.)

---

## 7. The access disclosure — data-vs-tier transparency

Collapsed by default; one tap expands. The "good way" to be transparent about couple-unlock portability without souring a celebratory moment: **separate the data (always theirs) from the tier (follows the buyer).**

> **Your maps are always yours.** Whatever each of you rates and saves stays with you — paired or not.
> **Core follows whoever buys it.** While you're paired it covers you both; if you ever unpair, it stays on the buyer's account.

**LOAD-BEARING REQUIREMENT (not just copy):** "your maps are always yours, paired or not" is a promise the data model must keep — **unpair must never delete Partner B's `desire_ratings`; it may only drop the couple's tier.** This is a hard prerequisite for the unlink feature (M6, not yet built). The monetization spec already commits to this ("Couple data is per-couple… only the entitlement and each user's private `desire_ratings` persists across partners"). Do not ship this copy until the unlink path provably honors it.

---

## 8. The 1.0 / 2.0 scope — why "yours forever" is honest

"Yours forever" is scoped, on purpose, and the scope stays **off-surface**:

- **Vayl 1.0 (this purchase):** everything in the app today **and** future 1.0 content — all of it, for life.
- **Vayl 2.0 (future):** the live-service relationship OS (multi-connection, Insight Engine, etc. — see `EXPANSION_ATLAS.md`, Acts 2–3) is a **separate tier with its own pricing**, announced with rationale. 1.0 owners keep 1.0; the 1.0 lifetime bundle stays purchasable.
- **The paywall says nothing about 2.0.** Pre-explaining a future product only muddies a clean offer. This is a commitment recorded here and honored when 2.0 ships — not buyer-facing copy today.

This keeps "no subscription / yours forever" truthful while leaving room for the Act-2 OS.

---

## 9. Copy guardrails

- **"own your experience" / "yours forever"** — never "pay to unlock," "denied," or a countdown.
- **Positive only.** No negative-mirror comparison. (The full Free-vs-Lifetime table was prototyped and rejected as too transactional for this moment; the value stands on its own + the demonstrated generosity of the free map + 1 match.)
- **No fake social proof at launch.** A single real testimonial above the price is the highest-trust element a paywall can carry — slot it in later, **real-only**, never invented.
- **No defensive "we won't charge for X" lines.** Trust is already carried two ways: *demonstrated* (they completed the whole map + saw a real match free, before this screen) and *stated* ("no subscription — one payment").

---

## 10. Open items

- **Bullets 4 & 5** final wording; whether 5 leans credibility (free-safe) or paid-library.
- **Testimonial slot** — design it (empty for now), populate with real couple quotes post-launch.
- **Unlink feature + warning UI (M6)** — the access-disclosure copy (§7) depends on it honoring the data-vs-tier promise.
- **`PaywallView(context:)`** — confirm `.vault` folds into `.settings` for V1 (assumed here) or needs its own headline.
- **Build dependency:** this surface is the front end of **M2** (StoreKit purchase) and is triggered by **M5** (reveal gate). It can be built as static UI before M2 wires the real transaction (mirrors how `DesireRevealView` was styled ahead of the live purchase).

---

## 11. References

- Monetization: `docs/superpowers/specs/2026-06-15-monetization-implementation-spec.md` (free/Core boundary, M2/M5, entitlement lifecycle)
- Strategy: `EXPANSION_ATLAS.md` (Acts 1–3; peak-intent conversion; 2.0 = different product)
- Grammar / components: `Vayl/Features/Onboarding/Phases/FounderLetterPhase.swift`, `Components/FounderLetterSheet.swift`, `Vayl/Design/Components/Text/LivingText.swift`
- The reveal it follows: `Vayl/Features/Desire Map/Views/DesireRevealView.swift`, `Store/DesireRevealStore.swift`
- Memory: `[[monetization_paywall_spec]]`, `[[monetization_m1_backend_built]]`, `[[d4_reveal_stub_built]]`, `[[v1_strategic_positioning]]`

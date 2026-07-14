---
target: PaywallSheet.swift
total_score: 35
p0_count: 0
p1_count: 2
timestamp: 2026-07-12T01-58-06Z
slug: ayl-features-monetization-views-paywallsheet-swift
---
Method: dual-agent (A: general-purpose design/humility review · B: Explore native evidence sweep). Native SwiftUI target; web detector + browser overlay N/A, native source sweep substituted. No simulator driven.

## Verdict: NOT AI slop — a genuinely humble paywall. 35/40.

For a monetization surface in an app whose first principle is humility, this is the hard case, and it mostly passes. It is hand-built, opinionated, and its ethics are enforced in architecture, not just copy.

## Humility & dark-pattern audit (the headline for this surface)

**The off-ramp is honest and architecturally guaranteed.** At the primary (reveal) door the paywall never auto-rises: it opens only when the user taps a locked star (`DesireRevealStore.swift:388-396`), and `closePaywall()` rewinds the ceremony so dismissing returns to the free reveal (413-416). The reveal is pinned-free; the user always keeps something.

**No dark patterns, none.** No countdown, no fake scarcity, no confirmshamed decline, single SKU so no pre-selected pricier tier, no disguised subscription. "one time · yours forever" (242) is the truthful anti-subscription signal.

**Honest free-vs-paid, erring humble.** "The Opener and The Check-In are always free." (300); "covers both of you, your partner pays nothing" (345); "If you ever unpair, it stays with whoever paid." (294). If anything the free tier is understated — the humble direction, not a dark pattern.

**Copy is restrained, hype-free, no em dashes** (verified; all `—` are code comments). Uses middots `·`, not em dashes.

The one humility weakness is the dismiss affordance (see P1 below).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Purchase/restore spinners, pending (Ask-to-Buy) + error status lines. |
| 2 | Match System / Real World | 4 | "yours forever", "covers both of you" — plain, concrete. |
| 3 | User Control and Freedom | 2 | No explicit Close/X in the sheet; reveal-door exit is scrim-tap-only; grab handle is decorative. |
| 4 | Consistency and Standards | 3 | Apple paywall triad (price/restore/terms/privacy) all present; but reveal door hand-rolls a scrim overlay while Play/Map use `.vaylSheet`. |
| 5 | Error Prevention | 4 | `guard !purchasing` + restore-ignored-during-purchase prevent double-charge/false-negative races. |
| 6 | Recognition Rather Than Recall | 4 | Full offer on screen; "What's included" pop-out holds detail. |
| 7 | Flexibility and Efficiency | 3 | One CTA, one path (right for a paywall); the exit is the friction. |
| 8 | Aesthetic and Minimalist | 3 | Focused, but bloom halo + per-row shimmer + blurred glow divider is a lot of motion on a decision surface. |
| 9 | Error Recovery | 4 | Pending-approval, verification-failure, "Nothing to restore" are human and actionable. |
| 10 | Help and Documentation | 4 | Info disclosure + in-app Terms/Privacy. |
| **Total** | | **35/40** | **Good, near-excellent — held back by the exit affordance and a price-fallback honesty risk.** |

## Anti-Patterns Verdict

**LLM assessment:** Not slop. File-local bloom constants with a documented "not tokens" rationale, a `ViewThatFits` scroll fallback proven with an AX5 Dynamic-Type preview, real StoreKit price path, Ask-to-Buy surfaced as first-class state. Human, specific copy.

**Native evidence sweep:** Remarkably clean. 0 raw colors, 0 raw fonts, no banned APIs, no colorScheme branches, presentation correctly via `.vaylSheet`/`.vaylCover` at all call sites, and the monetization plumbing (Restore / Terms / Privacy / real purchase CTA / StoreKit-sourced price) is all wired — no no-ops. Only 4 minor raw decorative literals.

**Where A and B agree:** the exit affordance and touch targets are the weak spots; everything structural is solid.

## Priority Issues

**[P1] Hardcoded `$24.99` price fallback** (`PaywallSheet.swift:65`, rendered `:239`). When StoreKit hasn't loaded, the sheet shows a literal that can diverge from the live App Store price — a misrepresentation/App-Review risk (Apple 2.3/3.1). **Fix:** gate the price/CTA on a loaded product, or show "Loading price…"; never assert a number StoreKit didn't give you. → `/impeccable harden`

**[P1] No explicit Close affordance; reveal-door exit is scrim-tap-only.** The sheet has no X/Close; the grab handle is decorative (`:163`) and the reveal host dismisses via a scrim tap (`DesireRevealView.swift:402`). For the "hesitant" persona that bolts under pressure, a visible, low-effort exit is exactly what makes the eventual yes durable — and a thin scrim strip above a tall sheet is a poor one-handed target. **Fix:** add an honest "Not now"/close control in-sheet (or a swipe-down on the reveal overlay), consistent across all three doors. → `/impeccable harden` or `/impeccable onboard`

**[P2] Dismiss inconsistency across the 3 doors.** Reveal uses a custom scrim overlay; Play/Map use `.vaylSheet` (grabber + interactive swipe). Same surface, three exit behaviors. **Fix:** unify on `.vaylSheet`, or give the reveal overlay an equivalent grabber/swipe. → `/impeccable polish`

**[P3] Ornament density on a decision surface.** headerBloom + per-row `SpectrumBulletRow` shimmer + blurred glow divider all compete right where the user decides. **Fix:** keep the hero halo as the single focal treatment; quiet the bullet shimmer or the divider bloom. → `/impeccable quieter`

**[P3] Raw decorative literals** (`:229` `.blur(radius: 6)`, `:231` `.opacity(0.9)`, `:311` `lineWidth: 1`). Minor token drift. → `/impeccable polish`

## Persona Red Flags

**The hesitant (peak pressure):** Well-served by the pinned-free reveal and rewind-on-close — the user is never trapped and never loses free value. The gap is the missing explicit off-ramp *inside* the sheet; this persona wants to see the door before walking through the room, and right now the door is an unlabeled scrim tap.

**Casey (distracted, one-handed):** Scrim-tap dismissal at the top of a tall sheet is the worst-case one-handed target; the CTA is thumb-reachable but the exit isn't. Footer links and the info-circle button also lack an explicit 44pt hit area.

**Fluent-iOS user:** Restore/Terms/Privacy and a StoreKit price meet expectations. Two norm violations they'd feel: a price that could be a hardcoded literal, and a paywall whose only dismiss is a scrim tap while a decorative handle reads as swipeable but isn't.

## Minor Observations

- Restore-failure alert says "We couldn't find a purchase…" (`:89`) — first-person "we". The no-"we/our" rule is OB-specific, so this is acceptable outside onboarding; noted only for consistency if you want a singular voice app-wide.
- `booksVertical` icon beside "Grounded In Research" (`:381`) isn't `.accessibilityHidden`; the decorative `GlowOrb`s aren't either (they are `allowsHitTesting(false)`).
- Footer text links and the info-circle button rely on intrinsic size for their tap area; may fall under 44pt.

## Questions to Consider

1. For a persona that bolts under pressure, should the exit be as visible as the CTA? What would the paywall feel like if "Not now" sat calmly beside "Unlock everything" instead of hiding as a scrim tap?
2. Is a hardcoded price ever worth the review risk, or should the CTA simply not render until StoreKit answers?
3. Three doors, three dismiss behaviors — is the reveal overlay's bespoke exit earning its difference, or just drift?

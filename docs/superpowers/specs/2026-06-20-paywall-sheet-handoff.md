# PaywallSheet — Handoff & Refinements

**Date:** 2026-06-20
**Status:** Reveal-door sheet built + feel-iterated on device. Compiles clean. "Close" per Bryan — remaining items below.

Files:
- `Vayl/Features/Monetization/Views/PaywallSheet.swift` — the sheet.
- `Vayl/Design/Components/Text/SpectrumBulletRow.swift` — the reusable spectrum bullet (flat disc + right-to-left specular sweep that cascades down a list; no checkmark by design — see its header).
- Design spec (partly stale on copy): `docs/superpowers/specs/2026-06-19-desire-reveal-paywall-design.md`.
- Source mockups: session `24b4ddb2`.

---

## What's built

One reusable `PaywallSheet` with an `entry` param (`.reveal` / `.settings` / `.playDeck(name:)`) that swaps **only the hook header**. Presented as the **OB custom bottom-sheet** (`obSheetChrome` — full-bleed, rounded top, spectrum top border), **NOT a system `.sheet`** (that fights the chrome — see "gotchas").

Top → bottom:
- Grab handle (spectrum pill) + "Restore" (top-right, stub).
- Centered `LivingText` hook, 34pt bold ("Reveal your map").
- Hero line, 18pt: "One payment, yours forever. Never a subscription. Opens everything you two explore."
- **Purple** section heading, 16pt uppercase: "EXPLORE WITH LESS GUESSWORK".
- Four cascading `SpectrumBulletRow` bullets, 20pt: Understand what you each want · Talk openly about sex, boundaries, and what-ifs · Open up at a pace you both set · Keep your agreements clear and honored.
- Glowing `SpectrumHairline` divider (crisp line over a soft bloom).
- Centered price ($24.99, 30pt) + "· one time · yours forever" + single **ⓘ** → **StatPhase-style pop-out** (dimmed scrim, tap-to-dismiss, centered spectrum card with the receipt + "How access works").
- `VaylButton` "Unlock everything" → `EntitlementStore.purchase()`. (Price is on the line, not the button — Apple-compliant since it's conspicuous directly above; the native StoreKit sheet is the final confirmation.)
- "covers both of you, your partner pays nothing" badge under the CTA.
- Footer **pinned to the bottom edge** (outside the scroll): "Restore purchase · Terms · Privacy" + "grounded in research".

Presentation: full-width, **proportional height** via `containerRelativeFrame(.vertical) { $0 * 0.88 }`, a `ScrollView` for overflow, footer pinned beneath it.

---

## Refinements needed

### A. Wiring (the real next build)
1. **Present from the reveal door** — replace the old inline unlock CTA in `DesireRevealView` with `PaywallSheet(entry: .reveal)`, shown via the **custom bottom-sheet** pattern over a scrim (like `CredentialEditorSheet`'s host — `GeometryReader` + `ZStack(alignment: .bottom)` + `.frame(maxWidth: .infinity)` + height). **Do not use a system `.sheet`.**
2. **The 3-beat reveal choreography** (separate from the sheet) — the one match lands → the gap opens (locked teasers + count) → this sheet (Beat 3). Per the design spec.
3. **Settings + Play doors** — present the same sheet with `.settings` / `.playDeck(name:)`. Quick wire-ups in those features.

### B. StoreKit / App Store (required before ship)
4. **Restore purchase** — top-right "Restore" and footer "Restore purchase" are stubs (`TODO(monetization)`); wire to StoreKit restore.
5. **Terms / Privacy links** — footer text is not tappable; wire the legal URLs. Plus **Delete Account** (separate, Settings) — all on the App-Store-blocker list.
6. **Real price** — reads `EntitlementStore.corePriceText` (StoreKit `displayPrice`), fallback `$24.99`; confirm products load so the localized price shows.

### C. Polish / feel (tunable knobs in the file)
7. **Height** `containerRelativeFrame … * 0.88` — proportional; revisit for small screens (the ScrollView is the backstop).
8. **Top push-down** `.padding(.top, AppSpacing.xxl)` above the header.
9. **Glow** — divider glow done (`blur 6 / opacity 0.9`). Optional, NOT done: a **paywall-only** soft spectrum bloom behind the header (do NOT modify shared `obSheetChrome`).
10. **Pop-out scope** — the details pop-out dims the **sheet**, not the whole screen. Decide if a full-screen dim is wanted (needs presenting the card above the sheet).
11. **Dynamic Type / device sizes** — most sizes are fixed pt; verify across Dynamic Type + small/large devices.
12. **Accessibility** — labels for the ⓘ, the "covers both" badge, the bullet list; confirm Reduce Motion (bullet shimmer is gated via `accessibilityReduceMotion`; `LivingText` self-gates).

### D. Copy / docs
13. **Update the design spec** (`2026-06-19-…`) to the final copy reflected above (it still has the older mission-line set + em-dashes).
14. **Reveal warm-up copy** (reveal door only) — the "you've seen 1 match, N more" framing lives in the reveal screen (Beat 2), not the sheet; template it to the couple's real match count.

---

## Gotchas (learned the hard way)
- `obSheetChrome` is built for a **custom bottom-sheet**, not a system `.sheet`. A system sheet + `.presentationBackground(.clear)` broke the full-width and mangled the spectrum border.
- A wrapping **`GeometryReader` insets the width** in this context (side gaps). Use `containerRelativeFrame(.vertical)` for proportional height without touching width.
- `LivingText` is `fixedSize` (no wrap) — the hook font ceiling is ~34pt for "Reveal your map" to stay one line at this width.
- Build with a separate `-derivedDataPath /tmp/vayl-buildcheck` so compile-checks don't collide with Xcode's live preview build (DB-lock errors otherwise).

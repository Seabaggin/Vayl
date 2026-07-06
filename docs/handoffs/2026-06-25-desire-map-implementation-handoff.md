# Desire Map — Implementation Handoff

**Date:** 2026-06-25
**Purpose:** Everything decided across the planning session, in one place, so a fresh chat can implement the full Desire Map vertical without re-deriving it. Read this, then the Segment 1 spec, then start building Segment 1.

---

## 0. Frame

- **Build approach:** vertical-to-done, one slice at a time, WIP limit of 1. The Desire Map is the first slice because the reveal is the app's **primary paywall conversion**.
- **Scope:** the *full* Desire Map vertical (rate → match → reveal → unlock → lives-in-Vault), built as three named segments. Build one segment to done (felt on device) before the next.
- **Design basis:** implement the settled specs, aligned to the current OB void / spectrum / glass aesthetic. Resolve open details as they come; most are already resolved below.

## 1. The big realization: it is ~80% built

The data and plumbing are real and solid. The gap is narrow and it is exactly the money moment.

| Piece | State | Path |
|---|---|---|
| Rater (3-card fan, answer rows, sync trigger) | **REAL, works** | `Vayl/Features/Desire Map/Views/DesireMapView.swift` + `Store/DesireMapStore.swift` |
| Corpus (17 desire items, cohort-adaptive copy) | **REAL** | `Vayl/Resources/Content/desire_items.json` |
| Data model + privacy | **REAL** | `Core/Models/DesireMapEntry.swift`, `DesireMatch.swift`, `Enums/AppDesireEnums.swift` |
| Sync + match compute | **REAL** | `Core/Services/DesireSyncService.swift` + `compute-desire-matches` edge fn |
| Entitlements (couple-level, StoreKit) | **REAL** | `Features/Monetization/Store/EntitlementStore.swift` |
| Reveal Store (matches, free/locked split, purchase→reload) | **REAL** | `Features/Desire Map/Store/DesireRevealStore.swift` |
| **Reveal View** | **STUB** — renders free + locked + inline CTA all at once; no choreography | `Features/Desire Map/Views/DesireRevealView.swift` |
| PaywallSheet (body, copy, purchase, **restore + legal wired**, ⓘ receipt) | **REAL** (2026-06-20 handoff is stale on "restore/legal stubs") | `Features/Monetization/Views/PaywallSheet.swift` |
| Map tab shell + Vault | **PARTIAL** (Seg 0 + Vault foundation; Agreements/Consent/Log stubbed) | `Features/Map/...`, `Features/Map/Vault/...` |
| Card-face flame | **CUT** (dead idea — removed 2026-06-26) | — |

## 2. Non-negotiable principles (also in CLAUDE.md → Product Principles)

- **The Desire Map is relational, never an assessment.** It measures the space between two people, led by overlap. It NEVER characterizes either individual. Unit of meaning is the pair, never the person.
- **Discovery, not assessment.** Name what the user said, never infer what they didn't. Only two operations on quiz/rating data: compare two points, or rank/distribute one person's own answers (a summary is fine only if traceable + descriptive, never an opaque verdict). Labels are wayfinding vocabulary, not assigned identity. End every quiz with a door to content, not a conclusion.
- **Privacy is architectural law.** `notForMe` NEVER syncs (`isSyncable = false`, enforced in Swift + Edge Fn + RLS). Matches are computed server-side only; partner raw values are never stored or shown; the read path is alignment-only.
- **Right-size against humility.** No engagement spam. One notification, the kind that unlocks a real shared moment (see §3).

## 3. The full Desire Map flow (canonical)

Synthesized from the two planning whiteboards + the conversation. This is the target.

**Ways to access** (Map Tab is the canonical home; the others are contextual entries into it, not co-equal surfaces):
1. Getting Started step on Home (activation path).
2. The Partner Pill / a Home DM card (shows partner's DM status).
3. The Map Tab Vault (its permanent home).

**Entry → Welcome screen.** First-time only (skip on re-entry). This screen must **carry the privacy promise**, not just describe the feature: "you rate privately, only mutual matches reveal, your *no* is never shown to them." That sentence is the de-risker for the partner-cautious user and is where trust is won.

**Rating.** The existing rater. Questions are plain-language desire statements ("do you want a loving connection outside your relationship?"). The act of answering IS the discovery. (Presentation feel — tile vs spring card — is a device decision; the rater already exists.)

**Finish → branch on whether there is a partner to compare against:**

- **Branch A — solo / waiting (no partner, or partner hasn't finished).** Show the user **their own answers reflected back**, ranked by what they're most excited about, each linked to content in Learn. A mirror with doors. **No verdict, no solo "type."** Frame it as the *waiting state of the same reveal*: "here's what you said, and the map of where you and [partner] meet appears when they finish theirs." Branch A literally becomes Branch B when the partner completes. It is one flow with a pending state, not two products.
- **Branch B — both done.** The **gated 3-beat reveal** (this is the paywall moment, not a free dump) + the **DM discussion tool** (the conversation bridge). See Segment 1 + Segment 3.

**Notification.** One quiet banner when the partner finishes their map (it unlocks the reveal — a real shared-moment trigger, not spam). Never nag if they haven't started, never a "come back" loop.

**Editability.** Re-rating is allowed (desires move) and quietly recomputes the overlap.

## 4. Segments

### Segment 1 — The Reveal (+ desire card-face) — START HERE
**Spec:** `docs/superpowers/specs/2026-06-24-desire-reveal-segment1-build.md` (read it fully).
Restructure `DesireRevealView.ready` into the **3-beat choreography**, host the existing `PaywallSheet(entry: .reveal)` as a custom bottom-sheet layer over a scrim **inside** the cover, **unlock in place** on purchase. Move the reveal to `.vaylCover`. Remove the `requestRow` (defer hidden-convo to Seg 3). Fold in the **desire card-face** (warm-biased burning border, §5).
- **Beats:** (1) free match lands via the 3-card fan + flip + medium haptic; (2) gap opens, locked teasers stagger in with the real count; (3) PaywallSheet rises. Then unlock-in-place.
- **Timing reference:** `docs/prototypes/desire-reveal.html` (per-transition values locked: fan 70/140ms, flip 540ms, locked stagger 80ms, sheet rise 500ms; inter-beat holds ~1.5s / ~1.2s still to be felt — add an auto-play toggle to the mockup first per the build protocol).
- **Branches:** already-Core → celebration, no paywall; 0/1 match → no gap.
- **Files:** `DesireRevealView.swift` (beats + host sheet + unlock-in-place), `DesireRevealStore.swift` (add a beat-state enum; keep `load()`/`unlockAll()`), `HomeRouterView.swift` (`.fullScreenCover(item:)` → `.vaylCover(isPresented:, confirmOnExit:false)`).

### Segment 2 — Home entry surfaces
The "map your desires" invitation card, the "waiting for [partner]" state, routing into the reveal when `bothReady`, and the surface vanishing once consumed. Wire the partner-completed notification (§3). Solo/waiting branch (Branch A) lives here too.

### Segment 3 — Vault hosting + consent + discussion tool
The unlocked map's long-term home in the Map Vault (summary, alignment preview, re-entry), the consent-unlock path for hidden/sensitive matches, and the **DM discussion tool** (the conversation bridge off each match). This is the most underdefined piece and needs its own design pass. `requestHiddenConversation()` behavior is decided here. (Agreements and Event Log are a separate feature, out of scope.)

## 5. The desire card-face (current state)

- **Prototype:** `Features/Desire Map/Prototype/DesireCardFacePrototype.swift` — a feel harness (NOT production), composing the real `OnboardingAtmosphere(.cardReveal)` + `VaylCardFace` (warm-tinted via a magenta-led colorway + animated `heat`) + `VaylButton` + `SelectablePill`. Three toggleable modes: **Burning border** (default), Bottom bloom, Glow-pop only.
- **Direction chosen:** warm-biased spectrum motion. A **burning border**: short fire wisps tight on the card's real edge, licking outward, that **ignite on the event and die** (NOT persistent). The flame is `BorderFlame` (a perimeter emitter built from the `FlameAura` wisp look).
- **Reuse, don't reinvent:** `FlameAura` (already magenta→purple), `SelectablePill` (the existing flame-aura-on-select), `OrbitSparkBorderView` (shader living border) all already exist.
- **Hard constraint:** the flame is an **overlay outside `VaylCardFace`'s `.drawingGroup()`** (never bake per-frame animation inside the rasterized face). The one-shot `heat` glow-pop is fine inside.
- **Pending:** device tuning of the `TUNE` knobs in `BorderFlame` (`spacing`, `minLen`/`maxLen` = tightness, `burnDuration`, outward-vs-hug). After it feels right, fold into (a) the reveal's flip card and (b) the rater's answer rows — the rater rows are currently a flat `.spectrumBorderGlow(0.6)`, inconsistent with the flame language used elsewhere.

## 6. Implementation gotchas (learned this session)

- **Use the real idioms, not the old contract's phantom ones:** `OnboardingAtmosphere(config:)` (NOT `AtmosphereView()`), `.themedCard()` / `.vaylGlassCard()` (NOT `.glassCard()`), and there is no chainable `.hairline()` modifier (the hairline is internal to `VaylCardFace` / `VaylBorderEffect`). CLAUDE.md was corrected 2026-06-25.
- **`.vaylCover` is `isPresented:`-based** (not `item:`) and defaults `confirmOnExit: true`. For the reveal, drive it off `activeReveal != nil` and pass `confirmOnExit: false` (a reveal is re-openable, not a destructive mid-task exit). The X button calls the `\.vaylDismiss` action.
- **PaywallSheet is a custom bottom sheet** (`vaylSheetChrome`, own grabber, bottom-bleed). Host it over a scrim in a `ZStack(alignment: .bottom)` (mirror `CredentialEditorSheet`). Do NOT present it via `.vaylSheet` or a system `.sheet` (double-chrome + width bug). The mockup's line-214 note saying ".vaylSheet" is stale.
- **Copy source of truth = `PaywallSheet`** (final copy). The 2026-06-19 spec copy is stale (older mission lines + em dashes).
- **No em dashes** in any Vayl copy.
- **Build protocol:** confirm what you're building before code; feel timing in the HTML/Swift reference before writing it into Swift; a segment is done when it runs on device and the feel is confirmed, not when it compiles. Bryan runs on device himself; Claude build-verifies (compile) only.

## 7. Reference index

**Specs**
- `docs/superpowers/specs/2026-06-24-desire-reveal-segment1-build.md` — Segment 1 build spec (primary)
- `docs/superpowers/specs/2026-06-19-desire-reveal-paywall-design.md` — settled reveal + paywall (copy stale, choreography current)
- `docs/superpowers/specs/2026-06-21-desire-map-ui-redesign-spec.md` — visual/motion language
- `docs/superpowers/specs/2026-06-20-paywall-sheet-handoff.md` — PaywallSheet (refinements section stale)
- `docs/superpowers/specs/2026-06-16-desire-map-cohort-adaptive-redesign.md` — cohort tracks
- `docs/superpowers/specs/2026-06-15-desire-map-implementation-spec.md` — D1/D2 data + sync

**Mockups**
- `docs/prototypes/desire-reveal.html` — 3-beat reveal timing reference
- `docs/prototypes/desire-rater-v2.html`, `desire-rater.html`, `desire-activation.html`

**Map tab context**
- `docs/handoffs/2026-06-24-map-tab-bridge.md` — where the unlocked map lives (Seg 3)

**Memory**: `desire_reveal_paywall_design`, `monetization_paywall_spec`, `frontend_ux_nav_spec`, `ob_voice_individual`, `ob_contract_gotchas` (phantom-symbol fixes).

## 8. Open / deferred

- **DM discussion tool** (Segment 3) — most underdefined; its own design pass.
- **`requestHiddenConversation()`** behavior — decided in Segment 3.
- **Flavor / orientation quiz** — separate feature, but bound by the same discovery-not-assessment rules (bar graph must be traceable to the user's own answers + end in a content door; names a theme, never assigns an identity).

---

## Kickoff prompt for the new chat

> We're implementing the **Desire Map** for Vayl (SwiftUI, 4-layer Store architecture, iOS 26). Start by reading, in order: `docs/handoffs/2026-06-25-desire-map-implementation-handoff.md`, then `docs/superpowers/specs/2026-06-24-desire-reveal-segment1-build.md`, then `CLAUDE.md` (especially Product Principles and the Design Token Contract). Also read the current code state of `DesireRevealView.swift`, `DesireRevealStore.swift`, `PaywallSheet.swift`, `HomeRouterView.swift`, and the prototype `Features/Desire Map/Prototype/DesireCardFacePrototype.swift`.
>
> The Desire Map is ~80% built; the gap is the reveal-to-paywall conversion moment plus the desire card-face. Build the **full Desire Map vertical in three named segments** (Reveal → Home entry → Vault hosting), one segment to done before the next, per the build protocol. **Start with Segment 1 (The Reveal).**
>
> Before writing any code: confirm with me what you're building for Segment 1 and the constraints (files it may not touch). Follow the handoff's gotchas (real token idioms, `.vaylCover` is `isPresented:`-based with `confirmOnExit:false`, PaywallSheet hosted as a custom bottom sheet not a system sheet, copy source is PaywallSheet, no em dashes). Feel timing in `docs/prototypes/desire-reveal.html` before writing it into Swift. I run on device and confirm the feel; a segment is done when the feel is right, not when it compiles.
>
> The desire card-face (warm-biased burning border) is a prototype pending my device tuning — treat its exact values as TBD and fold it into the reveal once I've dialed it. Do not turn the relational map into an individual assessment, and keep the solo/waiting branch a mirror-with-doors, never a verdict.

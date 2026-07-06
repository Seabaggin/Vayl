# Desire Map UI Redesign — Mockup Spec
**Date:** 2026-06-21
**Goal:** Three high-fidelity animated HTML mockups that give Opus a complete visual reference for one-shotting the Desire Map screens in SwiftUI, matching the couple-session aesthetic.

---

## Scope

Three separate HTML files, each owning one screen:

| File | Screen | Status target |
|---|---|---|
| `desire-rater-v2.html` | Rater | Aesthetic upgrade to match couple-session look |
| `desire-activation.html` | Home — Activation section | New: invite card + container-transform pill |
| `desire-reveal.html` | Reveal ceremony | New: 3-beat cinematic card-flip choreography |

Existing D2 (sync), D3 (edge fn), and DA Getting Started checklist (tracked separately in Get Started + partner pill) are out of scope for these mockups.

---

## Design Tokens (Shared Across All Three Files)

```
Void background:    #0a0810
Card surface:       #120f1a / #17131f (elevated)
Spectrum gradient:  120°, #00C2FF → #6C3AE0 → #FF006A
Text primary:       #E8E8F0
Text muted:         rgba(232,232,240,0.45)
Text ghost:         rgba(232,232,240,0.18)
Hairline border:    rgba(255,255,255,0.08)
Display font:       "Clash Display", "SF Pro Display"
Body font:          "Switzer", "SF Pro Text", -apple-system
Motion easing:      cubic-bezier(.32,0,.08,1) for morphs/enters
                    cubic-bezier(.4,0,.2,1) for exits
```

---

## File 1: `desire-rater-v2.html`

**Purpose:** Replaces `desire-rater.html` (June 16) with the couple-session visual language.

### Layout
- Top bar: back arrow · spectrum progress bar (gradient fill, glow) · item count ("6 of 18")
- **3-card fan** (identical pattern to couple-session deck): two ghost cards behind, rotated ±8°, scaled down and offset. Center card elevated with spectrum border glow.
- Center card face: overline (category, spectrum dot) → title → rule → 4 option rows → privacy note
- Option rows: colored left accent bar (cyan / purple / neutral / magenta for the 4 weights) + full answer text + selection glow state
- Completion screen: spinning spectrum emblem ring + ✦ center + messaging

### Motion
- Card transition on rating: leave-up/leave-down + enter-up/enter-down, ~400ms
- Progress bar fills smoothly on each rating
- Option selection: scale 0.98 + glow flash + haptic (light impact)
- Completion: emblem ring rotates in, halos expand

### States to show
1. Mid-progress (card visible, 3 options unrated, 1 selected)
2. Completion screen

---

## File 2: `desire-activation.html`

**Purpose:** Shows Home with the Desire Map section (below card carousel, above Pulse widget) across its lifecycle states. Also shows the Container Transform partner pill in the alignment-ready state.

### Home layout (top to bottom)
1. Nav bar: VAYL wordmark (left) · partner pill (right, see below)
2. Card carousel (existing)
3. **Desire Map section** (new, between carousel and Pulse)
4. Pulse widget placeholder

### Desire Map section — states

**Pre-completion (you haven't done it):**
- Simple invitation card with ✦ emblem, hook copy ("See where you and Alex align"), single CTA button "Map your desires →"
- Tapping CTA launches the rater as a `.vaylCover` (full-screen immersive, per presentation grammar)

**You're done, waiting for partner:**
- Card updates: emblem still present, copy shifts to "Waiting for Alex…", CTA becomes muted / disabled
- Partner pill shows partner's pending state

**Both done — card is gone:**
- Desire Map section disappears from Home entirely
- Notification lives in the partner pill (see below)

### Partner Pill — Container Transform

**Normal state:** Small pill in nav bar. Partner name + presence dot.

**Alignment-ready state (both done):**
- Pill glows with spectrum border + magenta badge (pulsing, `#FF006A`)
- Tap → **Container Transform**: pill stretches and morphs into a compact card (~half phone width, ~⅓ phone height), anchored top-right
- The card is NOT a modal — it physically grows from the pill
- Card content: tiny "Alex ✕" header row → glowing ✦ star (spectrum gradient) → "Your alignment is ready" headline → "Open your Desire Map →" CTA button
- Tapping CTA launches the reveal ceremony as a `.vaylCover` (immersive, dismiss-guarded)
- Tapping ✕ or scrim collapses the card back into the pill
- SwiftUI implementation: `.matchedGeometryEffect` shared between pill and card

**Proportions (phone-relative):**
- Expanded width: ~50% of screen width
- Expanded height: ~25–33% of screen height
- Border radius morphs from pill (99px) to card (~16px)

---

## File 3: `desire-reveal.html`

**Purpose:** The full reveal ceremony. Launched from the partner pill card CTA. Three distinct beats, cinematic (no user interaction required until paywall).

### Beat 1 — Fan arrives (0–1.5s)
- Screen arrives: void + overline "Your alignment" (faint, uppercase)
- 3 face-down cards fan in from bottom: two ghost cards (rotated ±9°, scaled down) flanking a center card
- Center card has a **spectrum pulse ring** — concentric border animating outward, opacity breathing
- All three cards show the VAYL ✦ mark on their backs (spectrum gradient, 40% opacity)
- No copy yet. Hold this moment.

### Beat 2 — Center card flips (1.5s)
- **Cinematic auto-flip** — user does not tap. The card turns over itself.
- Flip animation: card scaleX shrinks to 0 (first half, back face), then swaps content, then scaleX expands to 1 (second half, front face). Duration ~500ms, ease-in-out.
- Front face: spectrum-tinted card surface, item name (e.g. "Opening Up"), "You both marked this ✦" subtitle in muted text
- Subtle haptic on flip completion (medium impact)
- Card lifts slightly (translateY -4px, shadow deepens) after flip

### Beat 3 — Locked cards reveal (2.2s)
- Locked match rows slide up from below the fan, staggered 80ms apart
- Each locked row: blurred text (blur 5px), faint placeholder line, lock icon
- Count line appears: "4 more aligned desires" in muted text
- No CTA yet — let the gap breathe for ~1s

### Beat 4 — Paywall sheet (3.2s+)
- Sheet rises from bottom (standard sheet detent, not full-screen)
- Sheet content (from existing `2026-06-19-desire-reveal-paywall-design.md`):
  - Hook: "Reveal Your Map"
  - Hero copy: "Made to take your curiosity somewhere deeper…"
  - 4 outcome pills
  - Price button: "$24.99 · one time · covers both"
  - Restore / Terms / Privacy footer
- Sheet is dismissable; re-tap the locked count line to re-open

### States to show in the mockup
1. Fan arrived, center card pulsing (Beat 1)
2. Center card face-up (Beat 2 result)
3. Locked rows visible + count (Beat 3 result)
4. Paywall sheet open (Beat 4)

Interactive demo: clicking/tapping advances through the beats manually so the HTML mockup is explorable. In SwiftUI the timing is automatic — no user input between beats.

---

## What These Mockups Are For

These are **Opus reference files** — high-fidelity, animated, explorable. They encode:
- Visual language: spectrum glows, void surfaces, hairline borders, Clash Display + Switzer typography
- Motion language: spring entries, cinematic holds, staggered reveals
- Interaction patterns: container transform, auto-flip ceremony, sheet choreography
- Copy and labeling: exact strings for each state

They are **not** a complete state machine. Edge cases (offline, no match found, solo user) are handled in existing Swift stubs and not shown here.

---

## Relationship to Existing Specs

- Desire item content: `2026-06-16-desire-map-cohort-adaptive-redesign.md` (18 Curious / 12 Established items)
- Paywall sheet detail: `2026-06-19-desire-reveal-paywall-design.md`
- D1 / D2 / D3 Swift implementation: existing `DesireMapStore`, `DesireSyncService`, edge fn — unchanged
- D4 reveal stub (`DesireRevealView.swift`): replaced by what's in `desire-reveal.html`

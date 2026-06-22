# Opus One-Shot Prompt — Desire Map HTML Mockups

> Copy everything below the horizontal rule into Opus.

---

You are building three high-fidelity, fully animated HTML prototype files for a feature called the **Desire Map** in **Vayl** — a SwiftUI couples app with a premium, dark, spectrum-lit aesthetic.

These files are design references that will be handed to another AI agent to one-shot the SwiftUI implementation. They must be complete, explorable, and visually indistinguishable from the target iOS app. No placeholders. No wireframes. Full animation, full copy, full interaction.

---

## Artistic Direction — Read These First

Before writing any code, read these existing prototype files in `docs/prototypes/` to internalize the visual language:

- `couple-session-northstar.html` — the north star for atmosphere and card design
- `couple-session-carousel.html` — card fan physics and selection patterns
- `couple-session-card-morph.html` — card transformation animation approach
- `couple-session-hero-v2.html` — hero screen composition and spectrum glow treatment
- `docs/prototypes/desire-rater.html` — existing desire map rater (needs aesthetic upgrade)

The visual DNA you must carry across all three files:

**Colors:**
```
--void:        #0a0810   /* page background, always */
--card:        #120f1a   /* card surface */
--card-raised: #17131f   /* elevated card, slightly lighter */
--spectrum-c:  #00C2FF   /* cyan */
--spectrum-p:  #6C3AE0   /* purple */
--spectrum-m:  #FF006A   /* magenta */
--text:        #E8E8F0
--text-muted:  rgba(232,232,240,0.45)
--text-ghost:  rgba(232,232,240,0.18)
--hairline:    rgba(255,255,255,0.08)
```

**Spectrum gradient (use everywhere — progress bars, glows, borders, emblems):**
```css
background: linear-gradient(120deg, #00C2FF, #6C3AE0, #FF006A);
```

**Typography:**
- Display / titles: `"Clash Display", "SF Pro Display", system-ui` — weight 600–700, letter-spacing -0.01em
- Body / labels: `"Switzer", "SF Pro Text", -apple-system, system-ui`
- Overlines: 10–11px, weight 700, letter-spacing 0.14em, text-transform uppercase

**Motion:**
- Enter easing: `cubic-bezier(.32,0,.08,1)` (~400ms)
- Exit easing: `cubic-bezier(.4,0,.2,1)` (~280ms)
- Micro interactions: 140–200ms ease
- Breathing/ambient: 1.8–2.4s ease-in-out infinite
- All looping animations respect `prefers-reduced-motion`

**Card anatomy:**
- Border: `1px solid rgba(255,255,255,0.08)`
- Radius: 20–24px (large cards), 12–16px (small cards), 99px (pills)
- Shadow: `0 20px 48px rgba(0,0,0,0.55)`
- Glow: `0 0 24px rgba(108,58,224,0.25)` (purple), `0 0 20px rgba(0,194,255,0.2)` (cyan)

**Atmosphere (every screen):**
- Background: `#0a0810` always
- 2–3 large radial gradient blobs, very low opacity (0.08–0.14), slowly drifting (16–20s loops)
- These should feel like light in fog — not obvious, just alive

---

## File 1: `docs/prototypes/desire-rater-v2.html`

The Desire Map rater. Users answer 18 questions (Curious track) or 12 (Established track) privately. This replaces `desire-rater.html`.

### Layout (full screen, portrait iPhone proportions)

**Top bar:**
- Back arrow (←) left
- Spectrum progress bar center — gradient fill (`linear-gradient(90deg,#00C2FF,#6C3AE0,#FF006A)`), glowing, animates smoothly on each rating
- Item count right ("6 of 18"), ghost text

**3-card fan (the hero):**
- Three cards stacked: two ghost cards behind (rotated ±8°, translateY +4px, scale 0.88, opacity 0.4), center card elevated (z-index, full opacity, spectrum border glow, `box-shadow: 0 12px 36px rgba(0,0,0,0.6)`)
- Center card face:
  - Overline row: small spectrum-colored dot (`background: linear-gradient(...)`, round, 5px) + category name
  - Item title: 22–26px Clash Display, weight 600
  - Description: 13–14px Switzer, muted, 1.5 line-height
  - Rule: 1px horizontal line, hairline color, 40px wide, centered
  - Prompt label: "How do you feel about this?" overline style
  - 4 option buttons (see below)
  - Privacy note: "Your answer is private — Alex will never see it" — ghost text, 11px, centered, bottom of card

**4 option buttons** (rated Excited → Open → Probably not → Not for me):
- Each: full-width pill-adjacent row, left accent bar (3px, colored), label text, right side optional "🔒 private" badge on option 4
- Accent colors: option 1 = cyan (`#00C2FF`), option 2 = purple (`#6C3AE0`), option 3 = `rgba(232,232,240,0.2)` (neutral), option 4 = magenta (`#FF006A`)
- Selected state: background becomes `rgba([accent],0.1)`, border becomes `1px solid rgba([accent],0.4)`, glow, scale 0.98
- Unselected hover: slight border brightening
- Tapping any option auto-advances to next card after 320ms

**Card transition on advance:**
- Selected rating triggers: current card exits upward (`translateY(-120%) rotate(-6deg)`, opacity 0, 360ms ease-in)
- Next card enters from below (`translateY(120%)` → `translateY(0)`, opacity 0→1, 380ms cubic-bezier(.32,0,.08,1))
- Ghost cards shift subtly inward as new card enters

**Completion screen:**
- Spinning spectrum emblem ring: 60px circle, `border: 2px solid transparent`, background clip trick for spectrum gradient border, rotating 360° at 6s linear infinite
- Inner void circle, ✦ center (spectrum gradient text)
- Headline: "Your Desire Map is complete" — Clash Display, 24px
- Subtext: "We'll let you know when Alex finishes" — muted
- No CTA (the screen is informational)

### Sample content to render (use real items, not lorem ipsum):

```
Item 1 (Curious):
  id: opening
  category: structures
  name: Exploring an Open Relationship
  description: How actively you want to start exploring openness — the appetite and the pace, not whether.
  answers: ["Yes — I want to start exploring", "Curious, but slowly", "Just the idea for now", "I'm only ready to think about it"]

Item 2 (Curious):
  id: swinging
  category: structures
  name: Swinging or Playing Together
  description: Sexual experiences with others that you share as a couple — same room, same event, together.
  answers: ["Yes — that excites me", "I'm curious to try it", "I'm nervous about it", "Not for me"]

Item 3 (Curious):
  id: polyamory
  category: structures
  name: Multiple Loving Relationships
  description: Romantic love with more than one person at once — openly and with everyone's knowledge.
  answers: ["Yes — I want this", "I'd explore it", "Probably not for me", "Not for me"]
```

### Show two interactive states in the file:
1. **Mid-progress state** — card 6 of 18 visible, option 2 selected (purple glow), progress bar 33% filled
2. **Advance demo** — clicking any option triggers the card transition animation; file loops through 3 sample cards

---

## File 2: `docs/prototypes/desire-activation.html`

Home screen showing the Desire Map activation section and the partner pill Container Transform. Show all lifecycle states as tabs or a state switcher at the top.

### Phone frame

Render inside a centered iPhone-proportioned frame (375×812px equivalent, scaled to fit screen). Show the full home screen context.

**Nav bar:**
- Left: VAYL wordmark (Clash Display, spectrum gradient text clip)
- Right: partner pill (see states below)

**Below nav bar (top to bottom):**
1. Card carousel strip (simplified — 3 mini cards in a fan, existing deck visual, not interactive)
2. **Desire Map section** (between carousel and Pulse)
3. Pulse widget (placeholder — spectrum-tinted EKG line, breathing end node)

### States (show as tabs: "Pre-completion" | "Waiting" | "Alignment Ready")

**State A — Pre-completion (you haven't started):**

Desire Map section:
- Card with spectrum border glow (`border: 1px solid rgba(108,58,224,0.25)`, `box-shadow: 0 0 20px rgba(108,58,224,0.12)`)
- Background: very subtle spectrum gradient tint
- Left: ✦ emblem (small, 32px circle, spectrum gradient border, void inner)
- Headline: "Desire Map" — Clash Display 15px
- Subtext: "See where you and Alex align — privately"
- Bottom: CTA button "Map your desires →" — spectrum gradient border, glow

Partner pill (normal):
- `rgba(255,255,255,0.05)` background, hairline border
- Presence dot (gray) + "Alex"

**State B — Waiting (you're done, Alex hasn't):**

Desire Map section:
- Same card, copy changes:
- Headline: "Desire Map — you're done ✓"
- Subtext: "Waiting for Alex to finish…"
- CTA replaced with muted waiting indicator (pulsing dot + "Alex hasn't started yet")

Partner pill:
- Still normal, no badge
- Pill shows "Alex · not started" on tap (normal overlay, not hijacked)

**State C — Alignment Ready (both done):**

Desire Map section:
- Card is **gone** from this area — blank space or section collapses

Partner pill:
- **Glowing state**: `background: linear-gradient(90deg, rgba(0,194,255,0.14), rgba(108,58,224,0.2))`, `border: 1px solid rgba(0,194,255,0.48)`, `box-shadow: 0 0 12px rgba(0,194,255,0.22)`
- Presence dot: cyan, pulsing glow
- Magenta badge (7px dot): top-right of pill, `background: #FF006A`, pulsing `box-shadow`

**Container Transform on pill tap (State C only):**

The pill physically morphs into a compact card. This is NOT a modal — the pill stretches and grows in place. Implement with CSS transition on `width`, `height`, `border-radius`, and `top`/`right` offset on an absolutely-positioned element.

Pill state: `width: 72px, height: 26px, border-radius: 99px`
Expanded state: `width: 124px (≈50% of phone width), height: 116px (≈30% of phone height), border-radius: 16px`

Transition: `cubic-bezier(.32,0,.08,1)` 400ms on all dimensional properties. Content crossfade: pill content opacity → 0 at 120ms, card content opacity → 1 at 230ms.

Card content (expanded):
- Top row (8px padding): `● Alex` (tiny, ghost text, left) + `✕` (right, ghost)
- Body: centered column — glowing ✦ star (spectrum gradient, `filter: drop-shadow(0 0 8px rgba(108,58,224,0.6))`, breathing animation) → "Your alignment" overline → "is ready" headline (Clash Display 16px) → "You and Alex both mapped your desires" muted subtext → "Open your Desire Map →" CTA button (spectrum border, glow)
- Footer: "Alex · active today" (ghost text, 8px)

Scrim: when expanded, home content behind dims to `rgba(10,8,16,0.45)`. Tapping scrim collapses card back into pill.

---

## File 3: `docs/prototypes/desire-reveal.html`

The reveal ceremony. Launched after tapping the partner pill CTA. Cinematic — no user input needed between beats. The HTML version advances manually on tap/click for exploration.

### Overall layout

Full screen. Void background + atmosphere. Content centered vertically.

Include a subtle tap/click listener that advances through the 4 beats manually for the prototype. Show current beat as small dot indicators at top (4 dots, active dot is spectrum-colored).

### Beat 1 — Fan arrives (0.0s → 1.5s)

Elements that animate in on entry (staggered):
1. Overline fades in: "Your alignment" — ghost text, uppercase, letter-spacing 0.14em
2. 3 face-down cards fan in from below (staggered 60ms apart):
   - Ghost cards: rotated ±9°, translateY +6px, scale 0.85, opacity 0.35
   - Center card: full size, `border: 1px solid rgba(108,58,224,0.4)`, `box-shadow: 0 0 24px rgba(108,58,224,0.3)`
   - All cards show VAYL ✦ mark on back (Clash Display, spectrum gradient text, 40% opacity, 28px)
3. Center card pulse ring: `::before` pseudo with concentric border (`border: 1px solid rgba(108,58,224,0.4)`), animating `scale(1)→scale(1.12)` + opacity 0.6→0, 1.4s ease-in-out infinite

Hold here (in prototype: waiting for tap to advance).

### Beat 2 — Center card flips (1.5s → 2.0s)

3D card flip using `rotateY`:
- Phase 1 (200ms): card `rotateY(0)` → `rotateY(90deg)` (card narrows to nothing, ease-in)
- At `rotateY(90deg)`: swap card face content (backface hidden, front face revealed)
- Phase 2 (220ms): card `rotateY(90deg)` → `rotateY(0)` (card widens back, ease-out)

Front face content:
- Top: small category overline with spectrum dot
- Center: item name — "Opening Up" — Clash Display 22px, weight 700
- Sub: "You both marked this" + spectrum ✦ — muted text
- Brief description excerpt: 12px, muted, 2 lines max
- Bottom: soft rule + "Talk about this →" link (ghost text, no button chrome)

Card after flip: lifts slightly (`translateY(-4px)`), shadow deepens, spectrum border brightens.
Pulse ring stops.

Haptic would fire here (annotate with a comment: `/* haptic: medium impact */`).

### Beat 3 — Locked cards appear (2.2s → 3.0s)

Below the fan, 4 locked match rows slide up, staggered 80ms:
- Each row: `height: 44px`, full-width, `border-radius: 10px`, faint background + hairline border
- Content: blurred (`filter: blur(5px)`), opacity 0.3 — renders real item names underneath but they can't be read
- Lock icon (🔒 or SVG lock) on the right, ghost color
- Stagger: rows 1→2→3→4 each delay 80ms

After rows settle (3.0s):
- Count line fades in below: "4 more aligned desires" — muted text, 13px
- Thin spectrum line underneath count (decorative)

Breathe here for ~1s before Beat 4.

### Beat 4 — Paywall sheet rises (3.2s+)

A sheet slides up from the bottom. It should look like an iOS sheet:
- Rounded top corners (20px)
- `background: #120f1a`
- Hairline top border
- Grabber handle (36px × 4px, `rgba(255,255,255,0.15)`, centered, 8px from top)

Sheet content (scrollable if needed):
```
Hook:     "Reveal Your Map"               — Clash Display 24px, weight 700, centered
Sub:      "Made to take your curiosity    — 15px Switzer, muted, centered, 2 lines
           somewhere deeper."

Divider: hairline rule

4 outcome rows (icon + text):
  ✦  See where your desires meet
  ◎  Talk openly about what you want
  ⟳  Explore opening up together
  ⬡  Reach agreements that feel good

Divider: hairline rule

Price button (full-width, 52px tall, border-radius 14px):
  Background: linear-gradient(90deg, rgba(0,194,255,0.15), rgba(108,58,224,0.25))
  Border: 1px solid rgba(108,58,224,0.5)
  Box-shadow: 0 0 20px rgba(108,58,224,0.25)
  Label: "$24.99  ·  one time  ·  covers both"
  Sub-label (below): "Lifetime access for you and Alex"
  Font: Clash Display 16px weight 700 (label), Switzer 11px muted (sub)

Footer (below button):
  "Restore Purchases  ·  Terms  ·  Privacy"
  Ghost text, 11px, centered, hairline separator above
```

Sheet is interactive — tapping outside the sheet collapses it back (locked rows and count remain visible).

### Prototype navigation

Small dot row at top (4 dots). Tapping anywhere on screen advances to next beat. After Beat 4 sheet opens, tapping the sheet backdrop closes the sheet (returns to Beat 3 state for re-exploration).

---

## Output Format

Write all three files as complete, self-contained HTML documents. Each file:
- Works when opened directly in Safari/Chrome with no server
- Uses only CSS + vanilla JS (no libraries, no CDN dependencies)
- Is fully interactive and animated
- Contains a `/* SwiftUI note: ... */` comment above any pattern that has a specific SwiftUI implementation (e.g., `.matchedGeometryEffect`, `withAnimation(.spring())`, `scaleEffect`, etc.)
- Has the `prefers-reduced-motion` media query respected for all looping animations

Do not use Lorem Ipsum anywhere. Use real copy from this spec.

Filenames:
- `docs/prototypes/desire-rater-v2.html`
- `docs/prototypes/desire-activation.html`
- `docs/prototypes/desire-reveal.html`

# Handoff — Pulse / Map tab / Me card

**Date:** 2026-06-23
**Where the work lives:** HTML prototypes in `docs/prototypes/` (front-end feel) + one written spec. None of this is in Swift yet (except the Pulse, which has real code that needs a rework — see below). The Map tab in code is still a stub (`MapView` renders `PairingSettingsView`).

This session redesigned three things as HTML protos: the **Map tab**, the **Me card**, and the **Pulse feature**. The Pulse just got finalized via a design Q&A and is the live next step.

> A fresh chat already has the auto-memory loaded (`MEMORY.md` → `map_tab_direction.md` has the long version of all of this). This doc is the focused "what's still open" picture.

---

## ★ START HERE — The Pulse (finalized, needs rebuild)

**The reframe that unblocked it:** the Pulse is **not** a solo capacity mirror. It's a **two-line couple compare** — your capacity line + (on a toggle) your partner's, where the read is **the gap between the two lines, shown but NEVER interpreted** (no "in sync"/"drifting" labels, no advice — a neutral mirror). This is why every solo-line mock felt thin.

- **Full decisions:** `docs/superpowers/specs/2026-06-23-pulse-feature-finalization.md` (read this first).
- **Real Swift code it touches:** `Vayl/Features/Pulse/PulseGraph.swift` (the EKG graph), `PulseWidget.swift` (compact home widget, last-7), `PulseFullView.swift` (the Me|Us-tab Pulse — an explicit STUB), `PulseEntry.swift`, `AppPulseEnums.swift` (`PulseTier`, `PulseWindow`, `PulseCapacityColor`).
- **Original author handoff (April 2026):** `~/Documents/Vayl Work/Projects/Open Lightly/Open Lightly — Pulse Feature Handoff.md` — has the gradient/dot-summary/check-in architecture history. Note it says the **check-in still needs rework** (should expand from the widget with the graph as the stage, not a fullScreenCover report card).
- **Latest proto (OLD solo direction, superseded):** `docs/prototypes/pulse-feature.html`. It has the smooth-curve fix + a Lines/Gradient/Minimal "express the spaces" toggle that's still useful, but it is a SOLO line — needs rebuilding to the two-line spec.

**Next step:** rebuild the proto to the two-line spec (you solid / partner dashed + their initial, neutral tier zones, the gap as the read with zero interpretation, a Me↔compare toggle, the "+" check-in, last-~7 density, shared DATE x-axis), tune on device, then do the Swift rework of `PulseFullView` + the check-in container.

**Known code bug to fix:** `PulseGraph` tier badge letters read `E/S/P/C`; the `PulseTier` enum is expansive/sovereign/friction/**protective** → should be `E/S/F/P`.

---

## The Map tab (proto built, Swift not started)

- **Proto:** `docs/prototypes/map-dashboard.html`. Re-skinned to the real **Midnight** tokens + Clash Display/Switzer + Tabler icons + the floating RacetrackTabBar capsule (canonical `:root` token set lives in `docs/mockups/learn-tab.html`).
- **Structure:** a **Me / Us segmented toggle**. *Me* = Pulse hero + your card + The Record. *Us* = together stats + couple card + "where you align" + the **Vault** (Desire Map + Agreements + the two-sided **consent-unlock** "Open a conversation"). The Record merged the sessions list + the category-spread into one block.
- **NOTE:** the Map's Pulse in this proto is the OLD solo version — it will be replaced by the finalized two-line Pulse above.

**Open Map items:**
- Orphaned/dead **pulse history sheet** markup (unreachable since the Pulse became a self-contained feature) — strip it.
- The **Us-layer couple card on the surface** is still the older plain crest row; only its sheet got the new flavor-card styling. Match them if wanted.
- The **"Drawn to" picker** (Feeld-style tag selection + tap-and-hold glossary) is described but not built.
- `MapView` in Swift is a stub (`PairingSettingsView`) — the whole tab is unbuilt in code.

---

## The Me card (proto built + wired into the Map)

- **Proto:** `docs/prototypes/me-card.html`. A **simple, title-led identity card** (NOT the earlier Pokémon-TCG version, which Bryan rejected as "too extra"; that version is in git history if ever wanted).
- **Anatomy:** portrait (opt-in photo or diamond-lattice sigil) · name · a **Title chosen from a shortlist** (the superlative hero, poetic-with-a-wink) · a Flavor chip + two-word essence · a few **"Drawn to"** tags (shared ones glow). The whole card wears the person's **Flavor color** (Explorer/Architect/Catalyst/Anchor from the Learn quiz). Also wired into the Map's card-inspect with Share / Invite-a-partner (the solo→partner growth loop).

**Open Me-card items:**
- Tune the **title pool** (Bryan's call on which land; worth real-user input — "fun" is subjective).
- Build the **"Drawn to" picker** + glossary.
- The **couple card** as a "Tag Team"/2-up variant.

---

## Decisions locked this session (do NOT re-litigate)

- **Map = an individual-leaning couple dashboard with a Me/Us toggle.** Do NOT call it "The Mirror" (an AI coined that; Bryan dislikes it).
- **No streaks anywhere.** Milestones/gentle trends only; cadence is "whenever."
- **Pulse = two-line couple compare**, gap shown not interpreted, color encodes nothing (person = solid/dashed + initial). Tier names kept (Expansive/Sovereign/Friction/Protective). "Pulse" + "capacity" kept. Full compare ships in V1.
- **Me card = title-led, chosen-from-shortlist**, photos opt-in on the card, abstract sigil fallback.
- **Consent-unlock** (Vault) = soft decline never discloses a "no"; opening generates one neutral discussion card.

---

## Gotchas / how to work with Bryan

- **Canonical design tokens live in `docs/mockups/learn-tab.html`** (`:root`) — the real Midnight palette, Clash/Switzer, Tabler, RacetrackTabBar. Match those, not the older home/play protos.
- **No em dashes** in Vayl copy or in replies (commas/periods/colons; hyphens in compounds OK).
- **Humility rule (CLAUDE.md):** Vayl is a small, optional corner of a couple's life. Don't build features that assume the app is the center of their world.
- **Ask, don't assume confidence** (`feedback_ask_dont_assume_confidence`): Bryan often agrees in the moment then rethinks. Surface choices, name the conventional option + why + a rec, let him confirm. He also likes **multiple-choice/tappable** options over typing long answers.
- **Verify protos in the live preview** (the `prototypes` server, port 7333) — screenshot + console-check; don't claim it works without looking.
- Bryan runs Swift on device himself; Claude build-verifies (compiles) only.

---

## Immediate next step

Rebuild the Pulse prototype to `docs/superpowers/specs/2026-06-23-pulse-feature-finalization.md` (the two-line compare), get Bryan's feel-check on device, then plan the Swift rework of `PulseFullView` + the check-in container.

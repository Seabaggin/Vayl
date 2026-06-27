# The Pulse — Finalization Spec

**Date:** 2026-06-23
**Status:** Intent locked via design Q&A. Supersedes the solo-line mockups (`docs/prototypes/pulse-feature.html`, the Map's band/altitude versions).
**Source of truth for the code it touches:** `PulseGraph.swift`, `PulseWidget.swift`, `PulseFullView.swift` (the Me|Us-tab stub), `PulseEntry`/`AppPulseEnums`, and the April-2026 handoff (`~/Documents/Vayl Work/Projects/Open Lightly/Open Lightly — Pulse Feature Handoff.md`).

These are decisions, not options. Open implementation details are flagged `↳ to confirm` with a recommendation.

---

## 1. What the Pulse is (the reframe)

The Pulse is a **relationship signal**: each partner's emotional **capacity** over time, drawn as a line. The couple-native payoff is the **comparison of the two lines** — *are our capacities close or far apart right now?* (Capacity mismatch is exactly what creates friction in NM, so this is the whole point.)

- **Primary view = your own line.** A **toggle overlays your partner's line** anytime. Openly viewable both ways, no consent gate — primarily your own view, theirs on demand.
- **In compare mode the read is the GAP between the two lines** — *shown, never interpreted.* No "in sync" / "drifting" labels, no "be gentle" prompts, no advice. The couple decides what the gap means. The app is a neutral mirror.

This kills the old framing of the Pulse as a private solo mirror. It is a couple comparison.

---

## 2. Form

- **A timeline line graph** (kept). Smooth, flowing line — the earlier jagged-EKG → smooth-curve fix stands; do **not** revert to hard straight segments.
- **Two lines in compare mode**, distinguished by **line style + label, not color**:
  - **You = solid.** **Partner = dashed**, tagged with their **first initial** near its leading end.
  - Both lines use the **same spectrum styling** (color is decorative, identical for both). Color does **not** encode person or capacity.
- **Capacity = vertical height** through the **4 tier zones** (Expansive / Sovereign / Friction / Protective). Tier zones render as a **neutral, ambient backdrop** (the "gradient/altitude" or "minimal" treatment — *not* colored grid lines; colored lines would clash with two spectrum lines).
- **Density: the last ~7 check-ins** per person as the hero view (matches `PulseWidget`'s `suffix(7)`). The long-window selector (1W…2Y/All) is **demoted out of the hero** into a deeper "full history" screen.
  - `↳ to confirm:` plot both lines on a **shared recent-date x-axis** (each connecting its own check-ins by date), not an entry-index axis — otherwise the gap isn't a true same-moment comparison. Recommended: shared date axis, ~last 2 weeks of room, showing each person's recent points.

---

## 3. Interaction & hierarchy

- **Check-in and the graph are co-equal.** Each partner logs via the **5-question check-in**; the comparison is the payoff.
- **The "+" check-in** lives top-right of the graph. Per the handoff's "correct" architecture: the check-in **expands from the widget with the graph as the stage** (questions slide up, the live dot moves as you answer) — *not* a separate full-screen report card. (Handoff flags this as still-needs-rework in code.)
- **Tap a dot → that day's summary** (the film-burn `PulseDotSummary`, kept).
- **A Me ↔ Us / "compare" toggle** switches solo line ↔ partner overlay.

---

## 4. Data honesty & cadence

- **Check in whenever.** No daily target, **no streaks**, no obligation framing (humility rule).
- Show the **last ~7 check-ins** regardless of when they happened; old data is honest because the axis is recent-time and a stale partner line simply isn't recent.
- The app never editorializes the data (see §1: gap shown, not interpreted).

---

## 5. Language, naming, color — settled

- **Tier names KEPT:** Expansive / Sovereign / Friction / Protective (and their sublabels). Bryan is fine with the clinical edge.
- **Names KEPT:** "The Pulse" + "capacity."
- **Color is freed up** (person is encoded by solid/dashed + initial). Keep both lines the calm spectrum styling. The earlier "color = capacity altitude" proposal is **retired** — with two lines it would paint both the same hue, and height + tier zones already carry capacity.

---

## 6. Tone & privacy

- **Neutral mirror.** The app does not interpret the gap, name a couple-state, or react to lows with commentary or resources on this surface.
- **Partner line openly viewable** via the toggle (no per-check-in consent). Your view is primary; theirs is on demand.

---

## 7. Scope

- **V1 ships the full two-line compare** — your line, the partner overlay, the gap read — from day one. The compare *is* the feature; do not split it into a fast-follow.

---

## 8. Open implementation items (recommendations)

- **Shared date axis** for the two lines (see §2) — recommend yes.
- **Graph tech:** keep the bespoke `PulseGraph` Canvas (built, and Bryan likes it). Flag `Swift Charts` only if Dynamic Type / VoiceOver upkeep on the custom graph becomes painful. `↳ to confirm.`
- **Accessibility:** the tier badges are fixed 8pt (won't scale with Dynamic Type); VoiceOver should read *your current state + the gap to your partner*, not every point. `↳ to confirm.`
- **Code bug to fix:** `PulseGraph` tier badge letters read `E/S/P/C`; the `PulseTier` enum is `E/S/F/P`. Reconcile.
- **Motion:** keep the subtle breathing line + heartbeat empty-state; honor Reduce Motion.

---

## Next step

Rebuild the prototype to this spec: a smooth two-line capacity graph (solid you / dashed partner + initial), neutral tier zones, the gap as the read with **zero interpretation**, a Me↔compare toggle, the "+" check-in, last-~7 density. Then tune the feel on device.

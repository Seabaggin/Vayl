---
target: journal mockup v8.2 (map tab + overall feel)
total_score: 30
p0_count: 2
p1_count: 2
timestamp: 2026-07-19T05-05-26Z
slug: docs-mockups-journal-screens-v8-2-html
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Saved / Not-saved / door count+recency are exemplary |
| 2 | Match System / Real World | 4 | "What's here right now?", "This space is yours" — human, on-voice |
| 3 | User Control and Freedom | 2 | Delete is immediate + permanent + no undo on vulnerable writing |
| 4 | Consistency and Standards | 3 | Map has two section grammars: Pulse/Record wear overlines, Journal is a bare card |
| 5 | Error Prevention | 3 | Delete is an equal-width peer beside magenta Share in the reread row |
| 6 | Recognition Rather Than Recall | 3 | Prompts + tags aid recall well |
| 7 | Flexibility and Efficiency | 3 | Another-prompt, dictation, optional tags — good range |
| 8 | Aesthetic and Minimalist Design | 2 | Map: two competing cyan heroes + triple privacy framing |
| 9 | Error Recovery | 4 | "Your words are safe on this screen" is genuinely reassuring |
| 10 | Help and Documentation | 2 | Info affordance only on Pulse, inconsistent across Map |
| **Total** | | **30/40** | **Good (lower edge) — sheets are shipped-quality, Map drags the family down** |

## Anti-Patterns Verdict

Not AI slop. Judged against Vayl's own system, the mockup is disciplined: glass at 3%, spectrum reserved for strokes/emblems, magenta load-bearing for the Me→Us crossing, gold absent, two-tempo breathing respected. Detector flagged 51 items; ~48 are false positives given the native/DESIGN.md context (px-downscaled ramp inside a 330px frame, graded-white text system, the Pulse-orb cyan ramp, caption prose em-dashes, gallery index numbers, the signature orb glow). Genuine detector residue: `#fff` vs documented `#E8E8F0`, a `#232030` chip bg off the card fills, a couple of unmapped font sizes.

The real problem is not slop — it is compositional indecision on the Map tab. That is what reads as "not final."

## Priority Issues

- **[P0] Two competing cyan heroes on the Map (screen 0).** The 152px Pulse orb and the Journal door's 74px full-spectrum book emblem (own cyan aura + two-pass glow + cyan accent border) both glow and both anchor cyan, ~32px apart. No focal point. Void Rule: one hero per surface; a door is secondary content. Fix: demote the door emblem to ~40-44px, single crisp stroke (no blur/aura layer), drop the accent-cyan border. Let the orb be the only glowing thing.
- **[P0] The Map does not fit its own viewport (screen 0).** Measured: The Record block renders 28-85px BELOW the frame bottom and is clipped entirely; the Journal door's "3 entries · last tonight" line collides with the tab bar. Even granting the real tab scrolls, three heavy stacked blocks with no ranked primary means the first surface has no answer to "what is this tab for." Fix: decide the Map's one hero, make the door a quiet peer, resolve The Record's status (peer vs footnote).
- **[P1] Triple/quadruple privacy framing (screens 0-1).** "your side of the map" + "Only you" + door "A place to name things for yourself" + sheet "Private to you..." all say private/solo/yours before and after opening. Belt-and-suspenders copy is a draft tell and protests too much for the partner-cautious persona. Fix: one framing per surface — keep the lens sub on the masthead, cut "Only you," make the door summary describe the action not the privacy.
- **[P1] "& casey" contrast + "bryan." wordmark ghosting (screen 0).** Partner name renders at ~1.87:1 (far below AA) and reads like a disabled/deprecated partner rather than lens identity. The gradient wordmark shows a visible doubled/misregistered ghost in static render. Fix: lift the partner-name opacity to a legible secondary; verify the LivingText glow-pass registers cleanly on device.
- **[P2] Delete is a visual peer of Edit and Share (screen 5).** Three equal-width buttons; permanent Delete sits one thumb-width from magenta Share. Casey (one-thumb) can fat-finger it; the confirm is the only net. Fix: Edit + Share as the primary pair, Delete demoted/separated so it reads as a deliberate reach.

## Persona Red Flags

- **Casey (distracted, one-thumb):** Map has no ranked primary — orb, door, Record, gear all invite a tap; cognitive stall on the first surface. Reread: permanent Delete adjacent to Share at equal weight = mis-tap risk.
- **Jordan (first-timer):** Two glowing cyan things + three ungrouped sections = can't tell what the tab is for at a glance. Triple privacy framing reads as the app being nervous, priming anxiety instead of calm.
- **Partner-cautious NM-curious (PRODUCT.md core):** Journal is sold as the private solo bridge, yet the first Earlier entry already wears a "shared" badge and reread foregrounds "Share a copy" as a first-class equal action. Risks reading as the gentle funnel PRODUCT.md warns against. Off-ramp ("Not now") is good; Share's prominence inside the private space is the thing to watch.

## Minor Observations

- "Open ›" styled as a bright cyan button competes with the whole-card-tap affordance — redundant.
- Empty state stacks VaylEmptyState + prompt-hero + New-entry button = three invitations to one action.
- Reread meta mixes share-status ("shared with casey · tonight") with user-chosen tags in one visual row.
- Screen 7 delete's shared-snapshot-survives copy is flagged in the mockup itself as unlocked — provisional, not final.
- Borderline sub-44pt targets: tab items 42px, top info icon 26×30, composer "Done" 39px wide.

## Questions to Consider

- What if the Map had exactly one hero? Resolve the Map's hero question and the door's weight answers itself.
- Should a private journal show sharing at all until the user reaches for it?
- Is permanent-no-undo delete the humble choice or the harsh one for raw exploration writing?
- Does The Record belong on the Map at all, or is it a third thing competing for a one-hero surface?

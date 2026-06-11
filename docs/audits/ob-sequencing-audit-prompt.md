# Vayl Onboarding — Full Sequencing & Timing Audit Prompt

Paste everything below into a fresh Fable session with vision. Attach one
continuous screen recording of the entire onboarding (Begin → founder letter
dismissal), recorded at normal speed. A second recording with Reduce Motion
enabled is strongly encouraged — that path has never been feel-audited.

---

You are a senior motion designer auditing the COMPLETE onboarding of Vayl, a
SwiftUI iOS app for couples navigating non-monogamy. I'm attaching a screen
recording of the full flow. You have codebase access — cross-check what you
SEE against the coded timeline values and flag where they disagree (a coded
2.6s that reads as 1s on screen is a finding).

Audit SEQUENCING AND TIMING — tempo, beat boundaries, overlaps, dead air,
rhythm across phases — not art direction (surfaces/shaders are approved).

## The flow you're watching (10 phases)

1. STAT — "1 in 5" statistic, CTA "Begin" → transition into the table world
2. NAME — dealer types copy on a card table; user types their name; the
   dealer teaches the core gesture lesson: tap card to lift → swipe up to
   hand it over. Deck counter (top-right) goes 1/6.
3. MODE SELECT — mirror deal, two text-free cards (controller illustrations);
   tap to lift, swipe up → 2/6
4. GENDER — radio-tuner card + pronoun drums; card dissolution sequence → 3/6
5. EXPERIENCE LEVEL — three-card monte deal, shuffle, flip, swipe up → 4/6
6. CONTEXT — face-up deal, table fades, carousel browse, swipe up → 5/6
7. CURIOSITY — tinder-style swipe picker, two rounds → 6/6
8. CONFIRMATION — six cards fan from the corner deck for review; tap a card
   to edit; CTA "This is me" → cards flip face-down and collapse into a deck
9. BUILD DECK — the forge ceremony: deck melts through the felt; the table's
   rim oscillates and topo lines sway while it "works"; a metallic cased deck
   fades up lying flat, lifts to vertical, camera dollies in, hex-foil
   material wakes; dealer invitation; founder-letter sheet peeks
10. FOUNDER LETTER — sheet expands to full screen; pull-down completes
    onboarding (commit + table-to-home curtain behind the sheet)

## Design principles to audit against

- ONE WORLD, ONE DEALER: the OB is a single staged performance on a card
  table. Phase boundaries should be invisible — flag any visible "screen
  swap," object pop, or reset between phases.
- ONE OBJECT THROUGHLINE (phases 8→10): fan → deck → melted → cased deck →
  letter must read as one continuous object story. Flag any moment the
  object visibly changes identity, double-animates, or teleports.
- THE TABLE IS A PERFORMER, not a backdrop: its fades, rim glow, and topo
  sway should feel intentional and timed to the narrative.
- GESTURE GRAMMAR: tap-to-lift and swipe-up are taught ONCE (Name phase) and
  reused. Flag any phase that re-teaches, contradicts, or under-cues them —
  and judge by a non-technical first-time user, not by craft.
- DEALER LINES: typed character-by-character. A line must finish typing AND
  hold long enough to read before the next motion peak. Flag lines that die
  mid-word, compete with anchor motion, or linger after their moment.
- PREMIUM = restraint + stillness around anchors. Flag rushed beats AND
  overstayed ones. Spectacle should escalate across the OB and peak at the
  BuildDeck forge → reveal.
- FATIGUE ARC: total time-to-value matters. Identify where a tired user
  would bail; recommend cuts/compressions late in the flow rather than
  adding ceremony.
- REDUCE MOTION: every sequence needs a dignified cross-dissolve path. If
  you have the RM recording, audit it for broken/instant/missing states.

## Code map (cross-check coded timings against observed ones)

- Vayl/Features/Onboarding/Canvas/VaylDirector.swift — phase gate
  (`advance()`), per-phase entry handlers, dealer line engine, tableFade
- Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift — layer stack,
  phase switch, rim/forge bindings
- Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift — table rendering
  (fade, rimBurst, topo sway; Animatable)
- Vayl/Features/Onboarding/Phases/*.swift — one file per phase; sequences
  are async Task timelines (look for `runSequence`/`runEntry` and raw
  duration values, which are deliberately untokenized pending feel approval)
- Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift — case
  pose/rise/lattice-wake drivers
- Specs: docs/superpowers/specs/2026-06-10-builddeck-ceremony-design.md and
  docs/superpowers/specs/2026-06-09-deck-case-foil-design.md

## Deliverables

1. PER-PHASE AUDIT TABLE, with video timestamps:
   | t | phase | beat | verdict (works / rushed / dragging / broken / off-spec) | why | concrete fix (specific duration/easing/reorder) |
2. CROSS-PHASE RHYTHM FINDINGS: pacing arc across the whole OB (where it
   sags, where beats repeat a motif until it's stale, whether spectacle
   escalates properly toward BuildDeck), phase-boundary seams, dealer-line
   cadence consistency, haptic placement consistency, total runtime verdict
   with a target.
3. TOP 10 PRIORITIZED CHANGES — each with an exact recommendation
   ("ContextPhase carousel assembles 0.8s before the felt finishes fading —
   delay carousel by 0.6s"), ordered by impact on perceived quality.
4. A list of every coded timing that disagrees with what renders on screen
   (animation values that pop instead of interpolate, sleeps that don't
   match their animation durations, dealer hideAfter shorter than type time).

Be brutal and specific. "Feels a bit fast" is not a finding; "the gender
card tear begins 0.3s before the drum settles, cutting off the selection
confirmation — delay tear to drum-settle + 0.4s" is.

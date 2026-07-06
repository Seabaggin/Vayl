# Feature Teaching Strategy: when to tutorial, when to guide

**Status:** DECIDED 2026-07-03. Bryan's picks: **Sessions 1A (build now, not staged) · Desire Map 2A ·
Pulse 3B (door + once-ever annotated landing beat) · Path 4B.**

**Post-decision correction (source re-verification):** 2A is ALREADY BUILT. The rater's start screen
(`DesireMapView.startScreen`, S2.1) states the global contract twice: "you each answer in private, and
only the desires you **both** want are ever revealed," plus the diamond footnote "If only one of you
wants it, it stays private. Your no is never shown to your partner." Section 3's claim that the global
rule is unstated at entry was wrong (this spec's recon read the pill hints but not the start screen).
No Desire Map work item exists; 2A's pick is satisfied as-is. Two picks went heavier than the
consultant recommendation (1A-now over staged; 3B over 3A), both deliberate. Implementation notes:
3B must land BEFORE Bryan's Pulse on-device pass (category F of the Pulse finalization goal doc) so
the check-in surface is verified once, not twice; 4B is an amendment to plan 20, not a code item.
**Scope:** the four novel-mechanic features: Card Sessions, Desire Map, Pulse, The Path. Plus the
shared infrastructure they'd draw on.
**Out of scope:** onboarding itself (already a complete teaching system), Learn (it IS the deep-dive
destination other features point to), Settings/pairing (conventional patterns, nothing novel to teach).

---

## 1. The doctrine Vayl already has (name it, don't reinvent it)

Recon of the current codebase shows a consistent house style for teaching, built feature by feature
without ever being written down:

| Existing pattern | Where it lives | What it teaches |
|---|---|---|
| Dealer's guided lesson, taught once | OB NamePhase + `LiftHalo.swift` reused everywhere after | Card gestures (tap-lift, swipe-up) |
| First-run ritual that collapses on repeat | `AirlockView` six house-rule bullets → one-line "settle in" (`UserDefaultsKey.hasCompletedCoupleSession`) | Session safety contract |
| Point-of-choice micro-copy | Rater pill hints (`DesireMapView.pillHint`), incl. "stays private" on notForMe | The privacy contract, at the exact moment of anxiety |
| Choreographed pacing as teacher | `DesireRevealView` beats (intro star → teasers → assembly) | What the reveal is, by sequencing not words |
| Coach after, never during | `SessionCloseView` ("the only place communication gets coached: after, by your own noticing") | Reflection without in-flow interruption |
| Journey sequencing | `GettingStarted` bridge on Home (one active step at a time) | The path to the couple loop, not mechanics |

**The implicit doctrine: teach inside the ritual, at the moment of need, once, then get out of the
way.** No overlay coach-marks, no darkened-screen tooltips, no skippable slide decks. This spec keeps
that doctrine and only decides how much teaching each feature earns.

One caution from real-user testing (2026 gesture-validation lesson, recorded in project memory):
implicit teaching is NOT a strength on its own. Choreography without worded cues failed with
non-technical users. Every option below that relies on pacing also includes words.

---

## 2. The decision rule (answers "full tutorial vs light guidance" generally)

Score each feature on three axes:

1. **Stakes of a mistake.** What happens if the user does it wrong the first time? Emotional/relational
   exposure is expensive; a wrong mood dot is free.
2. **Novelty of the MECHANIC vs novelty of the CONCEPT.** Mechanics (gestures, two-device sync moments)
   need demonstration or practice. Concepts (invented vocabulary, unusual framings) need a sentence and
   a door to more. Confusing the two produces the classic bad tutorial: a slideshow explaining a gesture,
   or a forced walkthrough for something a label would fix.
3. **Frequency.** A daily ritual must cost near-zero after day one. A rare ceremony can afford full
   choreography.

That gives four teaching tiers, from heaviest to lightest:

- **Tier 1, guided first run:** an actual practiced first experience. Earned only by HIGH stakes AND a
  novel mechanic. (In this app: Card Sessions, and nothing else.)
- **Tier 2, framing moment:** a one-time, worded, 2-3 beat framing before first use, when the danger is
  a conceptual MISREAD rather than a mechanical mistake. (Candidate: The Path.)
- **Tier 3, point-of-need cues:** micro-copy and affordance echoes at the moment of choice, collapsing
  or disappearing with familiarity. (Already the Desire Map's approach; the default tier.)
- **Tier 4, the door:** a persistent, optional "what is this" reference sheet. Never a gate. Every
  feature gets one of these regardless of its tier, because vocabulary questions recur long after
  first use. (The dead `PulseInfoSheet` stub is the intended template.)

---

## 3. Per-feature options

### Card Sessions (the card game)

Current state: the airlock already teaches the safety contract (Tier 2-ish, built, collapses on
repeat). OB already taught the card gestures. The untaught remainder: two-device MECHANICS. What
happens when I flip, when do we both see a card, how turn/reveal sync works, where the safe word
lives mid-session. Stakes are the highest in the app: two people, emotionally exposed, in the most
protected surface (`.vaylCover`, confirm-on-exit).

**1A: The dealer returns (Tier 1, guided first hand).**
The first card of a couple's first-ever session is a scripted zero-stakes practice card, dealt by the
same dealer voice from onboarding. It walks both partners, on their real paired devices, through
flip → sync moment ("you'll both see this once you've both flipped") → respond/pass → where the safe
word is. One card, maybe 60-90 seconds, never seen again (`hasCompletedCoupleSession` already exists
as the flag).

- *For:* This is the one feature that meets the Tier 1 bar: highest stakes, genuinely novel two-device
  mechanic that words cannot demonstrate, and a mistake mid-session (a partner confused about why
  nothing is happening, or fumbling for the safe word) damages exactly the trust the feature exists to
  build. The dealer is already the app's established teacher, so this is continuity, not new grammar.
  Duolingo-lesson protection logic already treats the session as sacred; a protected practice beat
  matches that posture.
- *Against:* Real build cost (a scripted card, two-device choreography, tone risk if the dealer reads
  as cutesy in an intimate context). Lengthens the first session, which is also the couple's most
  fragile moment of buy-in. And the airlock already delays play once; two pre-game gates back to back
  could read as bureaucracy.

**1B: The airlock teaches, plus first-need hints (Tier 2 + Tier 3, extend what exists).**
No practice hand. Add one or two mechanic lines to the first-run airlock rules screen (which already
collapses on repeat), then teach in-flow at first need: LiftHalo echo on the first real card, a
one-time inline line at the first sync moment ("this appears for both of you once you've both
flipped"), safe-word location shown once in the session chrome.

- *For:* Cheapest path, ships with what exists, respects the couple's momentum toward their first real
  card, and trusts the session's own pacing the way the reveal trusts its beats. The airlock is
  already the sanctioned first-run teaching surface; adding two lines is free.
- *Against:* Reading rules is not practicing mechanics; the two-device sync confusion this feature
  risks is precisely the kind of thing that hits mid-moment, where a hint arriving DURING an intimate
  beat is more intrusive than a practice card before it would have been. Worded cues at first need
  are also split across two devices: no guarantee both partners see the same hint at the same time.

### Desire Map

Current state: the best-taught feature in the app, and the reason is visible: Tier 3 done properly
(pill hints at the moment of choice, "stays private" exactly where the fear is), plus Getting Started
sequencing the journey, plus reveal choreography with worded beats. The one genuinely untaught thing:
the OVERALL privacy contract at rater entry. The notForMe hint teaches that one answer stays private,
but nothing states the global rule (only mutual wants ever surface; a solo want is never shown) before
the user starts answering. That's the single highest-anxiety unknown in the whole flow.

**2A: One contract line at rater entry, nothing else (stay Tier 3).**
A single sentence on the rater's opening state, in the existing visual language: "Only what you BOTH
want is ever revealed. Everything else stays yours." Keep every current hint. No interstitial, no
sheet, no gate.

- *For:* The feature already works; the fix targets the one real gap with one sentence at the moment
  the user is deciding how honest to be. Honesty in the rater is the entire value of the map, and the
  privacy contract is what buys honesty. Anything heavier dilutes the app's best example of the
  doctrine and adds friction to the primary activation step (Getting Started's "Map your desires" is
  the funnel's most fragile point).
- *Against:* A single line can be scrolled past; a user who misses it may still self-censor, and
  self-censored data quietly degrades the reveal for both partners forever. There is no second chance
  at a first honest rating pass.

**2B: A one-time "how the map works" beat before first rating (Tier 2).**
A short, worded, 3-beat framing before the first rating session only: you rate privately → your
partner rates privately → only overlaps ignite as shared stars. Could be an inline expandable that
starts open, or one interstitial screen. Never seen again after first entry.

- *For:* The dyadic gating concept is genuinely novel; most users' prior for "intimate quiz" is
  "results get shown," and correcting that prior BEFORE answer one maximizes honesty where it matters
  most. Three beats is still humble; it frames rather than tutors.
- *Against:* It gates the app's most important activation moment behind reading, for a concept the
  pill hints already whisper answer by answer. The curious-but-cautious persona bolts under pressure;
  a screen of framing before they've touched anything is pressure. And the reveal choreography
  already retro-teaches the same concept beautifully the first time overlaps ignite.

### Pulse

Current state: zero teaching. Four invented space names, two invented axes, and a sharing contract,
with no explanation anywhere. `PulseInfoSheet` exists as a placeholder wired to a `.vaylSheet` in
`HomeDashboardView` but `showPulseInfo` is never set true: it is unreachable dead UI. The check-in
itself needs no tutorial (five plain-language questions; the position is derived, so there is no
wrong way to do it). The teachables are pure CONCEPT: vocabulary and the privacy contract. Daily
frequency means any gate is a tax paid 365 times a year.

**3A: Learn by doing, plus wire the door (Tier 4 only).**
First check-in is the tutorial; build nothing before it. Make `PulseInfoSheet` real: the two axes in
one line each, the four spaces in one line each, and the sharing contract ("your partner sees where
you are, never your answers"). Reachable via a small, quiet "what is this?" affordance on the dormant
Home card and the Map hero, forever. Delete nothing; the sheet and presentation wiring already exist.

- *For:* Matches the decision rule exactly: zero-stakes, zero mechanical novelty, high frequency →
  lightest tier. The invented vocabulary is REFERENCE material, not a lesson; people look up "what
  does Sovereign mean" on day 9, not day 1, and a door serves day 9 while a tutorial only serves
  day 1. Cheapest option in this spec, and it converts existing dead UI into the app-wide Tier 4
  template every other feature reuses.
- *Against:* The first landing moment ("you're in the Friction space") arrives with no context, and
  Friction/Protective read as mildly alarming words without their one-liners. A user who never taps
  the door may carry a wrong mental model of the map indefinitely.

**3B: First-landing micro-ceremony (Tier 3 choreography, once) plus the door.**
Everything in 3A, plus: after the FIRST-ever completed check-in, the landing beat expands once into
the full field with a short worded annotation pass: the two axis pairs name themselves, then the
user's space names itself with its one-line character. Never repeats. (The check-in cover already
owns the screen; this extends its final beat.)

- *For:* Teaches the map at the exact moment the user first has a stake in it: their own light just
  landed somewhere. This is the reveal-choreography house move applied to Pulse, with words, and it
  directly fixes 3A's weakness (the uncontextualized first landing).
- *Against:* Real animation/copy build cost on a secondary feature, spent on a moment each user sees
  exactly once. A ceremony on a daily mood dot risks self-importance ("it's a check-in, not a
  prophecy"), and Pulse just reached "final" (A-E, 2026-07-03); reopening its most delicate surface
  (the check-in cover and landing beat) invites regression in the one flow that took longest to
  stabilize.

### The Path (roadmap, plan 20, unbuilt)

Current state: spec'd, not built, so teaching should be designed INTO plan 20, not retrofitted. The
novel load here is entirely CONCEPTUAL, and it is the heaviest in the app: territory-not-progress-bar,
branching O/OO/O-O topology, capacity framing, self-picked structure. The dangerous failure is not a
mis-tap; it is a MISREAD. Every mainstream prior (roadmaps, habit trackers, quest logs) says
"progress bar," and a couple who reads their Path as a progress bar has imported exactly the
comparison/guilt mechanic the design exists to reject.

**4A: The preset ladder is the tutorial (Tier 3, structural).**
No separate teaching moment. First entry goes straight into choosing a preset path; the spec's own
preset → customize → theorycraft ladder IS the difficulty curve, and each preset's description does
the framing. Territory is learned by seeing your own first node placed on it.

- *For:* The most doctrine-pure option: the feature teaches itself through use, the ladder was
  already designed as a gradual-mastery structure, and there is nothing mechanical to practice. No
  added surface, no added copy beyond what presets need anyway.
- *Against:* It bets the feature's central philosophical point on users reading preset descriptions,
  and users do not read descriptions. The progress-bar misread is silent: nothing about placing a
  node CORRECTS the "we're behind" interpretation, it can even reinforce it. This is the one feature
  where the wrong mental model actively harms a relationship rather than just confusing a user.

**4B: One "this is not a checklist" framing moment, then the ladder (Tier 2 + 4A).**
First open only: a short worded framing in the cover grammar, 2-3 beats: this is territory, not a
checklist (nothing here is owed); it flexes with your capacity (Pulse vocabulary, already taught by
then); you choose what exists on your map. Then drops directly into 4A's preset pick. Plus the
standard Tier 4 door for the topology vocabulary (O/OO/O-O).

- *For:* Meets the Tier 2 bar precisely: the risk is a conceptual misread with relational cost, and
  counter-teaching a strong wrong prior needs explicit words once (the same reasoning that earned the
  airlock its six read-aloud bullets). Three beats of framing is cheap insurance on the app's most
  philosophically fragile feature, and it composes with 4A rather than replacing it.
- *Against:* Front-loads reading before the user has seen any value, on a feature whose whole pitch
  is exploratory play. Framing can read as preachy ("the app is telling me how to feel about it"),
  and a determined progress-bar reader will misread it anyway; structure (4A's self-pick) may correct
  priors better than words can.

---

## 4. Shared infrastructure (applies whichever letters get picked)

- **The door becomes a component.** One reusable info-sheet pattern (content per feature, presented
  `.vaylSheet` at 0.75, quiet "what is this?" entry affordance). `PulseInfoSheet` is the first real
  instance and the template. Every big feature gets one; it is never a gate.
- **First-run flags stay in `UserDefaultsKey`.** `hasCompletedCoupleSession` is the established
  pattern; any option above that says "once" adds a sibling key there, not a scattered literal.
  (Server-side persistence of these flags is deliberately NOT included: losing a "seen it" flag on
  reinstall just means one harmless re-teach.)
- **Banned regardless of picks:** overlay coach-marks, darkened-screen tooltips, skippable slide
  decks, progress-through-tutorial meters. All fight the void aesthetic, the humility principle, or
  both.
- **Choreography always gets words.** Any pacing-based teach includes worded cues (the
  gesture-validation lesson). Implicit-only teaching is not an option on this list.

## 5. Recommendations (one consultant's picks, not decisions)

- **Card Sessions: 1A**, staged if the timeline is hot (ship 1B's airlock lines for V1, build the
  dealer's practice hand as the fast-follow). It is the only feature that clears the Tier 1 bar, and
  it clears it decisively.
- **Desire Map: 2A.** Protect the funnel; one sentence closes the one real gap.
- **Pulse: 3A.** The decision rule says Tier 4 and nothing more; 3B is a lovely post-launch delight
  that should not reopen a just-finalized surface now.
- **The Path: 4B**, written into plan 20 before building starts, so the framing moment is part of the
  feature's first build rather than a retrofit.

## 6. What happens after picks (updated with decisions)

- **2A + 3B** (rater contract line, Pulse door + landing beat): one implementation plan, since both
  are small and 3B should precede the Pulse on-device pass.
- **1A** (dealer's practice hand): its own plan segment in the Sessions track; folds into the same
  two-device proof session Bryan already owes plan 16.
- **4B**: written into plan 20's build steps directly; no separate work item.

No shared "tutorial system" project exists or should: the doctrine in section 1 plus the door
component in section 4 is the whole system.

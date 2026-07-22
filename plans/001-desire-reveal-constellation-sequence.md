# 001 — Desire Map reveal: re-sequence the constellation ceremony

**Status:** IMPLEMENTED — build clean, 309 tests pass. **Values are NOT locked**: every timing
number is the prototype's starting value, live-tunable on device via `DesireRevealDebugView`.
Feel has not been confirmed and no agent may assert that it has.
**Base commit:** `8f35cc2`
**Owner decisions:** settled with Bryan 2026-07-21 (grill session)
**Scope:** `Vayl/Features/DesireMap/` reveal only. Does not touch the rater, the Vault, or the paywall's own content.

---

## The problem

Constellation lines are full-length static paths whose **opacity** crossfades 0 → 0.68. There is no
`.trim(to:)` anywhere in `DesireConstellationView`. A line therefore never has a beginning or an end
— it is a fully-formed object fading up on top of stars that are already sitting there. It reads as a
wiring diagram laid over the sky rather than a constellation being drawn.

Three compounding causes:

1. **No draw.** Alpha animation, not length animation. [`DesireConstellationView.swift:130`](../Vayl/Features/DesireMap/Views/Components/DesireConstellationView.swift#L130)
2. **No causality.** In `.teasers`, `lineDrawn` returns `true` for every edge unconditionally
   ([`:169`](../Vayl/Features/DesireMap/Views/Components/DesireConstellationView.swift#L169)) — the whole network materialises at once, including edges to dim locked stars.
   A line is currently a property of *the beat*, not of *its two stars*.
3. **Variant-blind.** `gather` / `sweep` / `constellate` differ only in star ignition order; all three
   share one identical line behaviour, so the variant system pays off nowhere in the lines.

---

## The agreed sequence

Replaces the current beat1 = "hero ignites alone" opening.

| Step | What happens |
|---|---|
| 1 | Empty sky. Stars **cascade in**, hero-outward, plain bloom (scale + fade). No lines. |
| 2 | Brief hold. |
| 3 | Lines **draw** — trim, hero-outward, full confident weight. |
| 4 | Match rows **cascade in below, all locked** — including the free one. |
| 5 | Brief hold, then the **first row opens by itself**: teaser text → real name, orb + stroke warm to magenta — **on the same frame** its star plays the two-seed convergence in the sky. Light haptic. |
| 6 | Rests here (beat2). Paywall stays user-initiated. |

A tap at any point during steps 1–5 **skips to the finished state**.

### Beat mapping (store barely changes)

- **beat1** → steps 1–3 (constellation ceremony)
- **beat2** → steps 4–5 (rows cascade + first reveal)
- **beat3** → paywall, unchanged, still only from an explicit locked-star/locked-row tap or the Full Map CTA

---

## Locked decisions

Each of these was decided explicitly. Do not re-open them during implementation.

1. **Lines draw, they do not fade.** `.trim(from: 0, to: progress)`, not opacity.
2. **Direction is structural, not temporal: every line grows *away from the hero*** — from the endpoint
   nearer the hero in the MST toward the farther one. Computed once at layout time from the hero-rooted
   MST; the view never consults ignition timing. This is the only rule that is defined in all four
   modes (`.intro` / `.teasers` / `.assemble` / `.resolved`) with zero special cases.
   - Rejected: "whichever endpoint lit first" — undefined in `.teasers` (nothing ignites) and
     `.constellate` (all stars at `delay: 0`), and in `sweep` with a right-side hero it would draw
     lines *inward*, contracting the sky while the band expands.
3. **Plain trim. No leading head, no travelling spark.** The broken thing is topology of motion, not
   luminosity. A bright tip is a defensible later upgrade (same `.trim`, second overlaid stroke at a
   shorter range) — do **not** build it speculatively.
4. **Lines follow the stars; they do not lead them.** A line draws once its endpoints exist. Rejected
   the chain-reaction alternative (line arrival igniting the far star) because it collapses the three
   ceremony variants into one — `constellate`'s "every star merges simultaneously" becomes impossible
   to express, and `sweep`'s spatial order stops mattering.
5. **New animation token `desireLineDraw`, ease-out family.** Do **not** reuse `desireLineCondense`
   (1.3s ease-in-out). Its ease-in-out was chosen specifically because ease-out "read as an abrupt
   pop" *for an opacity fade* ([`:143`](../Vayl/Features/DesireMap/Views/Components/DesireConstellationView.swift#L143)) — that reasoning does not survive the switch to trim, where a slow
   start reads as hesitation. `desireLineCondense` stays for the opacity work it still does elsewhere.
6. **No dim lines.** Lines always draw at full confident weight (`0.68`), including pre-unlock. The
   `0.30` teaser weight is deleted. A line either connects two things or it doesn't; half-connecting is
   a UI hedge, not a real state.
7. **The unlock gate is stars and names, not structure.** Locked stars stay dim and carry no name;
   unlocking is the sky *brightening* (every dim star igniting with its two-seed convergence, names
   arriving), not the shape appearing. The shape of the sky isn't the secret — the content is.
8. **Hero keeps the two-seed ignite; cascading locked stars just bloom** (scale + fade, no seeds). The
   purple+magenta convergence *means* "you two met on this desire" — spending it on 8 stars at 0.1s
   intervals turns a meaning into a texture, and on a dim locked star it flashes a brightness the star
   immediately takes back. Free user sees the convergence exactly once, on the one match they get.
   Post-unlock, every star does it — that's the payoff.
9. **Row and star light on the same frame.** They are the same match. Landing them together teaches
   that the sky and the list are one object, which is what makes tapping a star to open its detail
   feel discoverable.
10. **Auto-reveal, no reveal mechanic.** Explicitly rejected scratch-off: it is a lottery idiom
    (*chance*, *prize*) sitting directly upstream of a paywall — scratch, win one, now pay for seven
    more is structurally a gacha pull, and it violates the product principle against
    engagement-maximising / "open to find out" mechanics. The content is a desire you both
    independently named; it is not a prize and should not be won. Also rejected press-and-hold: the
    screen already trains tap-to-advance, so a second gesture would be shadowed by the first.
11. **Tap skips to the finished state.** Never trap someone in an animation. This is a real constraint
    on the implementation — the ceremony must be jumpable to its end at any frame.
12. **Rows become tappable, same rule as stars.** Free row → detail sheet; locked row → paywall. Same
    `store.selectStar(match)` call, no new logic.

---

## Confirmed bugs to fix as part of this

### B1 — The row stagger is dead code

[`DesireRevealView.swift:511-527`](../Vayl/Features/DesireMap/Views/Components/DesireRevealView.swift#L511) staggers each row by `0.08 × index` off `isVisible`, plus a 22pt offset.
It never plays. `_LockedSection` is only *constructed* at beat2, and `isVisible` is
`beatPhase.rawValue >= 2` — already `true` on first render. `.animation(_, value:)` fires on a
*change*; there is none. Every row renders at final position via the parent's `.transition(.opacity)`.
All n rows appear simultaneously.

**Fix:** drive the cascade off an `@State` flipped in `.onAppear` (or an explicit store-owned step),
not off a value that is already true at construction.

### B2 — Stale comment: the paywall does not auto-rise

[`DesireRevealView.swift:147`](../Vayl/Features/DesireMap/Views/Components/DesireRevealView.swift#L147) says "beat3: PaywallSheet auto-rises". It doesn't. The store rests at beat2 with
no further timer ([`DesireRevealStore.swift:258`](../Vayl/Features/DesireMap/Store/DesireRevealStore.swift#L258)); beat3 only fires from `selectStar` on a locked match or
the Full Map CTA. Correct the comment.

### B3 — `desireBeatHold1` is sized for the old opening

`1.5s` ([`AppAnimation.swift:910`](../Vayl/App/Theme/AppAnimation.swift#L910)) was sized for "hero ignites." The new beat1 is a full cascade + line
draw and is longer. beat1 would advance while lines are still drawing. Retune against the prototype.

### B4 — The full-map sheet has no entrance at all

[`DesireMapListSheet.swift:124`](../Vayl/Features/DesireMap/Views/Components/DesireMapListSheet.swift#L124) is a bare `ForEach` — no opacity, no offset, no stagger. Out of scope
for this plan's core, but note it: once the reveal cascades and the sheet doesn't, the sheet will look
broken by comparison. Either add a matching cascade or file it separately.

### B5 — Missing references

Both docs cited in the file headers are gone: `docs/prototypes/desire-map-ceremony-variants.html`
and `docs/superpowers/specs/2026-06-27-desire-map-reveal-ceremony-design.md`. There is no locked
visual reference for this screen. The prototype produced by Step 1 below becomes the new reference,
and the header comments must be updated to point at it.

---

## Build order

### Step 1 — HTML prototype (do this first, before any Swift)

Per the project's animation contract: never guess timing, feel it in an interactive reference first.

Write `docs/mockups/desire-reveal-sequence.html` rendering the **real** topology — a hero-rooted MST
over 5 and over 9 stars — playing the full agreed sequence. It must expose, as live controls:

- star cascade stagger step, and cascade duration
- hold between cascade-complete and line-draw-start
- **`desireLineDraw` duration and curve** — put 3–4 candidates side by side (start the search near
  0.9s ease-out; the current 1.3s ease-in-out is the thing being replaced)
- hold between line-draw-complete and row cascade
- row cascade stagger step
- hold before the first row auto-opens
- the row-open crossfade, tuned **against** the star's two-seed ignite so they land together —
  `desireStarSeedDrift` 0.56s + `desireStarMergeBloomDelay` 0.18s ([`AppAnimation.swift:821`](../Vayl/App/Theme/AppAnimation.swift#L821))

Bryan picks the values. **Those picked values become the tokens.** Do not author numbers into Swift
ahead of this step.

Also validate on the prototype: does the star cascade + line draw read as *one continuous outward
motion* (both hero-rooted) or as two unrelated events? If two, the cascade order or the hold is wrong
— fix it here, not in Swift.

### Step 2 — Layout: hero-rooted edge direction

`ConstellationLayout` already grows its MST outward from the hero, nearest-neighbour-first
([`DesireConstellationView.swift:135`](../Vayl/Features/DesireMap/Views/Components/DesireConstellationView.swift#L135) documents this). Make direction explicit rather than inferred: give
`Edge` an orientation such that `a` is always the hero-nearer endpoint, or add a `depth` field, so the
view can draw `a → b` unconditionally. This is a pure data change, no visuals.

### Step 3 — Tokens

Add `desireLineDraw` (value from Step 1) and any new cascade-step tokens. Retune `desireBeatHold1`
(B3). Delete the `0.30` teaser line opacity (decision 6).

**Contract note:** if constant-*speed* line drawing is ever wanted (long edges taking proportionally
longer, so the sky reads as one propagating front rather than lines that mysteriously all finish
together), that requires `length / speed` and will trip the project's own grep guard
`AppAnimation\.\w+ *[*/]`. **Deferred, not adopted** — uniform-duration trim ships first.

### Step 4 — `DesireConstellationView`

- Replace the opacity stroke with `.trim(from: 0, to: progress)` per edge, drawn `a → b`.
- Per-star cascade entrance: hero uses the existing two-seed ignite (`ignites: true`); the rest bloom
  only. `DesireStarView` already separates these — `playsEntrance` gates the seeds, `bloomed` gates
  scale+opacity ([`DesireStarView.swift:88-110`](../Vayl/Features/DesireMap/Views/Components/DesireStarView.swift#L88)) — so this is a new gate, not a new entrance.
- Ceremony must be jumpable to its terminal state at any frame (decision 11).
- Keep one view structure across all modes. The existing comment at [`:115-122`](../Vayl/Features/DesireMap/Views/Components/DesireConstellationView.swift#L115) explains why branching
  on `mode` broke interpolation before — do not reintroduce it.

### Step 5 — `DesireRevealView` rows

- Fix B1: real cascade driven by a value that actually changes.
- All rows land locked, including the hero's — remove the pre-revealed hero row
  ([`:507-511`](../Vayl/Features/DesireMap/Views/Components/DesireRevealView.swift#L507)).
- First row auto-opens, synced frame-exact to its star (decision 9). Light haptic on landing.
- Rows tappable → `store.selectStar(match)` (decision 12). Ensure the tap-anywhere-to-advance layer
  ([`:158-163`](../Vayl/Features/DesireMap/Views/Components/DesireRevealView.swift#L158)) does not swallow row taps — the row's gesture must take priority, the same way the
  stars' own gestures already do.
- Fix B2 comment.

### Step 6 — Reduce Motion / Low Power

Every new loop or entrance goes through `.reduceMotionSafe` / `.ambientAnimation`. Under Reduce
Motion the sequence collapses to the finished state with a fast opacity confirm — same terminal state
the tap-skip produces, so build them as one code path.

---

## Out of scope

- The chain-reaction alternative (decision 4). Available later if plain trim lands flat on device,
  but it costs the variant system and that is a product decision, not an animation one.
- Bright-tip / travelling-spark line heads (decision 3).
- Constant-speed line drawing (Step 3 note).
- `DesireMapListSheet` entrance (B4) — flagged, not fixed here.
- Any change to `selectStar`'s free/locked routing. It is already correct
  ([`DesireRevealStore.swift:388`](../Vayl/Features/DesireMap/Store/DesireRevealStore.swift#L388)).

---

## What shipped vs. what this plan said

The sequence changed during the grill after the plan was first written. Recorded so the file isn't
read as the current design where it disagrees:

- **The hero no longer gets a solo opening beat.** Beat 1 is now the constellation ceremony with the
  sky arriving *entirely locked*, hero included. The free match's moment moved to beat 2, after the
  rows land: the first row opens itself and its star ignites on the same frame. This supersedes the
  "hero first, alone" decision recorded above.
- **A scratch-off / interactive reveal was considered and rejected** — lottery idiom immediately
  upstream of a paywall, against the product principles. Auto-reveal shipped.
- **`extraLengthSpan` 1.35 → 1.70** in `ConstellationLayout` (see the layout finding below).
- **`desireBeatHold1` 1.5s → 0.4s**, demoted to a tail settle; the store now computes the ceremony
  duration from star count and MST depth.

## Layout finding — why 5 matches read worse than 9

`buildEdges` only considers non-MST candidate links shorter than `mean × 1.35`. At low star counts
that pool is frequently **empty**, so the 1–2 extras the generator asks for were silently dropped
and the figure fell back to a bare spanning tree — which at 4–6 stars is almost always a *path*, a
chain that reads as a scribble. Nine stars have a dense enough pool that it never happened.

Measured over 12 seeds at 5 stars (via the gallery in the HTML reference):

| `mean ×` | skies with zero extras | mean extras |
|---|---|---|
| 1.35 (was) | **5 of 12** | 1.00 |
| **1.70 (now)** | 0 of 12 | 1.83 |
| 2.10 | 0 of 12 | 2.00 |

The lever was the *length cap*, not the extras count.

## Verification

- Build clean; existing DesireMap tests pass with counts reported.
- **Feel-check is Bryan's and happens on device**, not in the simulator and not asserted by an agent.
  Build-clean is not "done" for this plan — the entire plan is a feel change.
- Check all three ceremony variants (`CeremonyVariant` is seeded per couple; use
  `store.debugVariantOverride` in DEBUG to force each). They should now read as *visibly different*,
  which they currently do not — that is the test that decision 2 paid off.
- Check at 1, 4, and 9 matches. The 1-match case skips straight to `.revealed`
  ([`DesireRevealStore.swift:244`](../Vayl/Features/DesireMap/Store/DesireRevealStore.swift#L244)) and must not regress.
- Check tap-skip at every point in the sequence lands on the identical terminal state.
- Check Reduce Motion lands on that same terminal state.

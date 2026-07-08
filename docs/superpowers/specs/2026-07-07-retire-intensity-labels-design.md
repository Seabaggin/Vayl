# Retire user-facing intensity/difficulty labels

2026-07-07

## Problem

`CardIntensity` (void → supernova, 8 levels) backs a `difficultyLabel`
("Easy" / "Medium" / "Deep" / "Sensitive" / "Ultimate") shown on decks in
Play, and a positional depth label ("warming up" / "deepening" / "opening
up" / "deep") shown on cards in the carousel. Both assert a fixed,
universal read on how intense a piece of content is. Intensity is
relative — what's "Easy" for one couple may not be for another — and
declaring it is a value judgment Vayl shouldn't be making, in the same
spirit as the existing discovery-not-assessment principle (CLAUDE.md):
name what's there, don't hand down a verdict.

Confirmed via grep that `intensity` is presentation-only — no gating,
matching, or paywall logic reads it — so this is a display/copy change,
not a behavior change. Card ordering within a deck already comes from
`sortOrder`, independent of `intensity`.

## Decisions

1. **Deck-level difficulty label — removed.** Drop the difficulty text
   everywhere it's shown (deck cell caption, deck detail pill row, Play
   hero meta row). Expectation-setting for a deck relies solely on its
   existing `description` / `whenToUse` copy, which is already
   contextual prose rather than a graded scale.
2. **Per-card depth label — removed, no replacement.** The carousel's
   "warming up → deep" label is deleted outright. Deck-level progress
   headers already shown above the carousel (Home's "X / Y explored",
   Play's continuity bar) already cover wayfinding; a per-card label is
   redundant with those either way.
3. **Per-card heat glow — unchanged.** The wordless glow ramp
   (`CardHeatGlow`, driven by `Card.intensity.rawValue`) stays. It reads
   as ambient visual pacing, not a textual claim, and is consistent with
   the app's existing use of glow/heat as a design language elsewhere.
4. **Dead code from this change — deleted**, not deprecated or
   backward-compat shimmed:
   - `CardIntensity.difficultyLabel` (no longer called anywhere)
   - `CardCarousel.depthLabel(forIndex:)` and the top-leading overlay
     that rendered it
5. **Adjacent unused scaffolding — deleted in the same pass.**
   `UserProfile.defaultIntensity` and `NMStage.defaultDifficulty` derive
   a "recommended" intensity from the user's stated NM stage, but
   nothing in the app reads either value — grep turns up only their own
   definitions. This is leftover scaffolding from the same
   AI-assisted pass that built the original intensity system, and the
   same "don't assert an intensity read" reasoning applies to it. Their
   doc comments claim they "drive deck recommendations and content
   sequencing" — that claim is stale and gets removed along with the
   code.

   Out of scope: `ProfileService.SupabaseProfile.defaultDifficulty`
   (a Supabase-backed string column, default `"warm"`) is a live,
   wired field (`SyncManager`, `DesireSyncService`) — a separate,
   backend-facing concept from the two client-only computed properties
   above. Touching a synced schema field is a different kind of change
   and isn't part of this cleanup.

## Files touched

- `Vayl/Design/Components/Cards/CardCarousel.swift` — remove depth-label
  overlay + `depthLabel(forIndex:)`
- `Vayl/Features/Play/Components/DeckCellView.swift` — meta caption
  becomes just `"\(cardCount) cards"`
- `Vayl/Features/Play/Components/DeckDetailView.swift` — pill row drops
  the accented difficulty pill
- `Vayl/Features/Play/Components/PlayHeroView.swift` — meta row drops
  the difficulty text (and its separator dot)
- `Vayl/Core/Models/Enums/AppCardEnums.swift` — delete
  `CardIntensity.difficultyLabel`
- `Vayl/Core/Models/UserProfile.swift` — delete `defaultIntensity`
- `Vayl/Core/Models/Enums/AppEnums.swift` — delete
  `NMStage.defaultDifficulty`; trim the stale doc comment on `NMStage`
  that references it

`CardIntensity` itself, `displayName`, `from(difficulty:)`, and
`from(score:)` are all still used (heat glow, JSON decoding, DEBUG
preview) and are untouched.

## Out of scope

- `ProfileService.SupabaseProfile.defaultDifficulty` (backend schema
  field) — noted above, not touched.
- Any reconsideration of `sortOrder` / deck pacing — unaffected by this
  change and not being revisited here.

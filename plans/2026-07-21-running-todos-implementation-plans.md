# Running To-dos — Implementation Plans (2026-07-21)

Source: Bryan's running to-do screenshot, 2026-07-21 2:23 PM. Each plan is grounded in
code research (six parallel Explore agents). Ordered by recommended attack order:
functional bugs first, then design passes, then tuning/copy.

Right-sizing note (per CLAUDE.md): none of these is a feature suite. Each plan is a
"relevant tail" run — locked reference → build → verify. No Phase 1–2 ceremony needed
except where a Bryan decision is flagged.

---

## Plan A — Partner Pill: invite doesn't work + invite Pending  «functional, do first»

The Swift path View → Store → Service is fully wired and real (Supabase, not stubbed).
The component is `PartnerChip` (`Vayl/Tabs/HomeTab/Components/PartnerChip.swift`). The
failure is not a dead button; it's one or more of the following, in likely order:

### A1. Verify Edge Function deployment (blocker candidate #1)
- `PairingService.swift:22` maps create-couple to the deployed slug **`"rapid-task"`**;
  `get-partner` at `PairingService.swift:23`. If either isn't deployed under that exact
  slug, `claimCode`/`fetchPartner` throw and linking silently fails.
- **Blocked on Supabase MCP auth** — the connector is unauthorized in this session.
  Bryan: re-auth via claude.ai connector settings (or `/mcp` in an interactive session),
  then Claude can list deployed functions and confirm. Alternative: check the Supabase
  dashboard manually.
- If misnamed: either redeploy under a sane slug (`create-couple`) and update the
  constant, or align the constant to what's actually deployed.

### A2. Fix `isPaired` derivation (chip shows the wrong state)
- `HomeStore.swift:159` — `isPaired` is derived purely from `appState.appMode == .together`,
  not from real link status. Consequence: the invite "+" only appears when
  `linkState == .unlinked && !isPaired`; a user in `.together` mode but unlinked gets
  `.invitePending`/`.nudge` (clock icon) and can never reach the invite-generate button.
- Fix: derive paired-ness from actual link state (couple record / `PairingLinkState.linked`),
  with appMode as presentation context only. Touches `HomeStore.partnerChipState`
  (`HomeStore.swift:172-186`).

### A3. Fix invite-pending tap routing (acknowledged placeholder)
- `HomeRouterView.swift:259-265`: `.invitePending`/`.nudge` tap → **Join** sheet ("Enter
  your partner's code") — wrong screen for someone who already *sent* an invite. In-code
  comments at `HomeDashboardView.swift:634-636` admit this is placeholder wiring.
- Fix: `.invitePending`/`.nudge` should reopen the user's own invite (code + waiting
  state, `PairingInviteView`), or a small pending status surface (see A4). Settings
  already routes invite vs join correctly (`SettingsView.swift:142-153`) — mirror that.

### A4. Pending expanded UI (the "invite Pending" to-do)
- `PartnerChipExpand.swift:21` renders content **only for `.active`**; every other state
  returns `EmptyView()`. Pending today = a clock badge with no detail.
- Build: a pending branch in the expand popover — "Invite sent · waiting" + code recall /
  re-share + expiry, driven by `PairingStore` state (`.waitingForPartner(code)`,
  `codeExpiresAt`). Data already exists; this is a View-layer addition.

### A5. Pre-build check
- `PairingInviteView.swift:6-8` / `PairingJoinView.swift:6-8` flag a dependency on
  `AppIcons.exclamationTriangle` — confirm it exists before building.

**Verify:** build + `PairingStore` unit paths; real two-device link is Bryan's on-device
pass. Note each sheet news up its own `PairingStore` (`HomeRouterView.swift:121,127`) —
by design, but keep in mind when adding pending recall (code must be re-fetchable, not
held only in a dismissed sheet's store).

---

## Plan B — Pairing design pass + "all the places pairing can be reached?"

Answer to the reachability question (verified exhaustive):

| Entry | Route | Ref |
|---|---|---|
| Settings → Partner | invite or join, explicit | `SettingsView.swift:113-114,142-153` |
| Home PartnerChip | invite (`.none`) / join (pending — bug, see A3) | `HomeRouterView.swift:258-265` |
| Getting Started "Bring in your partner" step | invite | `HomeRouterView.swift:308-309`, `GettingStarted.swift:34,67` |
| Home dashboard CTA `onInvitePartner` | invite | `HomeRouterView.swift:258` |

Non-entries (deliberate or gap — **Bryan decision**):
- **Desire Map / Reveal unpaired**: passive empty state, copy "Pair with your partner…"
  but **no CTA** (`DesireRevealView.swift:89-93`). Adding a quiet "Invite" door here fits
  the guide-by-clarifying principle (the invite as the user's own conclusion) — but it's
  a product call, not a default.
- **Play tab unpaired**: silent no-op (`SessionOpener.swift:20-37`, `PlayStore.swift:473`).
  Same decision class.

Design-pass state: both pairing views are already fully tokenized, high polish, every
state covered (generating/waiting/linked/error/expired), all presentations grammar-clean
`.vaylSheet(0.92)`. No raw sheets anywhere. So the "design pass" is a feel/visual
refinement pass, not a cleanup:
1. Bryan reviews `PairingInviteView` / `PairingJoinView` / `CompositionConfirmCard` on
   device and marks what feels off (no mockup exists — if wanted, write one to
   `docs/mockups/` first).
2. Fold in the A3/A4 routing + pending surfaces so the pass covers the full state family.
3. Optional: write the missing pairing design doc while at it (only structural refs exist
   today: `DESIGN_DOC.md:145`, CLAUDE.md presentation grammar).

---

## Plan C — Learn tab: Browse pass, Resources pass, hub cards matching

### C1. Fix "Knowledge Hub and Content Hubs cards not matching"
Research finding: the outer card chrome **already matches** — both panels wrap in
`.padding(AppSpacing.md)` + `.learnCard()` (radius 24, glass, one spectrum hairline)
(`ResearchSection.swift:85-86`, `ContentHubSection.swift:86-87`). The real divergences:
- **Header grammar**: Knowledge Hub's heading sits in an HStack with a trailing "Browse"
  pill (extra `pillSurfaceBottom` capsule chrome, `ResearchSection.swift:31-63`); Content
  Hub has a bare heading with its control (`SegmentedPillGroup`) inside the card body
  (`ContentHubSection.swift:64-74`).
- **Body idiom**: carousel (chrome-less slides, height 212) vs segmented panels.
Fix = align the header grammar (either both get a trailing control slot or neither;
one heading row pattern shared by both sections). If the mismatch Bryan saw is something
else visual, capture it before coding — the chrome itself is already unified.

### C2. Resources screen design pass — the real outlier
`ResourcesOverlayView.swift` is the one Learn surface off the design language: rows are
hand-rolled `RoundedRectangle`s with conditional opaque/tinted fills and raw strokes
(`:44-60`), no shared card modifier, no glass, no hairline.
- Migrate rows to the Learn language: `.learnCard(cornerRadius: AppRadius.lg)` (matching
  Browse rows) or `.vaylGlassCard(accent:)` if the cyan/gold tier accents should tint.
- Keep the crisis-tier gold distinction — accent via stroke/icon tint, not a bespoke
  surface.
- Consider whether the sheet wants an atmosphere or stays plain (it's a 0.75 sheet).

### C3. Browse screen design pass
`ResearchDatabaseView.swift` is already token-clean (rows use `.learnCard(.lg)`, chips
are tokenized capsules, `spectrumTextSafe` stats). The pass here is visual judgment, not
repair. Candidate refinements to put in front of Bryan:
- Chip selected-state (purple 0.2 fill / 0.45 stroke) vs the rest of the app's selection
  language.
- Header density (custom "‹ Learn" back + `screenTitle` + count, `:73-97`).
- Row rhythm in the LazyVStack (spacing `md`, every row a full glass card — possibly
  heavy; a lighter row treatment is a legit direction).
Run as: screenshot/HTML side-by-side options → Bryan picks → implement.

---

## Plan D — Onboarding polish batch (5 small items, all located)

Independent one-file fixes; can be one session or one subagent each.

1. **Weird bar over the corner card** — `CornerDeckView.swift:75-82`: each 48×72 mini-card
   overlays a full-width 1.8pt spectrum hairline flush at its top; stacked offset cards
   let multiple hairlines peek, compounding into a "bar". Fix: drop the hairline on
   corner-deck minis (or keep it only on the front card, scaled to the mini's width and
   inset). Verify against the stack offsets at `:37-45`.
2. **Underline under faded dealer text** — `ProjectedTextView.swift:87-93`: a static
   ~2pt spectrum line at 0.09 opacity under the dealer line; it doesn't track the text's
   fade so it lingers. Fix: remove it, or multiply its opacity by the text's current
   opacity so it fades in lockstep. Bryan's note says "needs removed" → default to
   removal.
3. **Context card text size** — `ContextCardFace.swift:70-74`: title is a raw one-off
   `AppFonts.display(24, …)` (no semantic token; `cardTitle` is 22). Options to review:
   `cardTitle` (22), `sectionHeading` (20), `prompt` (17), `cardTitleCompact` (16).
   Recommendation: `cardTitle` first — smallest change, kills the raw call, becomes
   token-compliant. Render the options in an HTML mock if the choice isn't obvious on
   read.
4. **Confirmation phase swipe-right affordance** — `ConfirmationPhase.swift`: today's
   affordance = fan nudge (`startNudge`, `:233-246`) + dealer line "If that's you —
   swipe right." (`:228`) + haptics. No persistent visual directional cue. Add a quiet
   rightward chevron/glyph consistent with the OB idiom (1D stroke, spectrum, breathing
   at `ambientPulse`, Reduce-Motion-gated via `.ambientAnimation`), appearing after the
   fan settles and dissolving on first drag. Feel-check in an HTML mock before Swift if
   timing is in question.
5. **BuildDeckPhase copy** — all strings inline in `BuildDeckPhase.swift`; current
   verbatim set: "Take your deck" (`:176`), "Your Deck" (`:352`), "It fights back. Tap
   again." (`:420`), "It's losing. One more." (`:423`), "From everything you've shown
   me…" (`:670`), "…I'm building a deck that's yours alone." (`:693`), "It's ready. Tap
   to let it out." (`:733`). **Blocked on Bryan**: which lines change and to what
   ("Changhe" in the note reads as "Change"). Prep: none needed — it's a find-replace
   once the new copy exists.

**Verify:** build + Bryan's on-device OB run (feel gate).

---

## Plan E — Desire Map Constellation Animation  «tuning, not building»

The full sequence is implemented per `plans/001-desire-reveal-constellation-sequence.md`
(status: IMPLEMENTED): hero-outward star cascade, trim-based line draw with per-line
stagger, two-seed hero ignite, telegraphs, sparkle loops — all tokenized in
`AppAnimation.swift:805-1077`, driven by `DesireRevealStore.BeatPhase`.

Remaining work, in order:
1. **Device tuning (Bryan-owned)** — every timing value is explicitly a prototype
   *starting* value (`AppAnimation.swift:839-846`), to be live-tuned via
   `DesireRevealDebugView` / `DesireSequenceTuning` dials, then locked into the tokens.
   This is the actual to-do: a tuning session on device, then Claude commits the locked
   values.
2. **Doc drift cleanup (Claude, mechanical)** — plan doc still says modes
   `.intro/.teasers` (code: `.ceremony/.settled`) and line weight 0.68 (code lowered
   `lineOpacity` to 0.42 on 2026-07-21, `DesireConstellationView.swift:243-249`). Update
   the plan doc to match code.
3. **Deferred upgrades — only if flat on device**: travelling spark head on the line
   draw; chain-reaction line→star ignition (`DesireConstellationView.swift:231-236`);
   per-edge variable draw duration. Plan doc explicitly says don't build speculatively.

---

## Plan F — Getting Started screen  «needs a Bryan clarification»

Research finding: this is **already fully built and unit-tested** — `GettingStarted`
state machine (`Tabs/HomeTab/Models/GettingStarted.swift:63`), entry card with
matchedGeometry morph (`GettingStartedEntryCard.swift:41`), path overlay
(`GettingStartedPathView.swift`), routing (`HomeRouterView.swift:151-169,297-315`),
4 test cases. Only open thread in code: the "Moments" hook TODO at
`HomeRouterView.swift:299`.

So the to-do likely means one of:
- a **design/feel pass** on the entry card + path overlay (copy lives inline:
  "Begin together" / "Three steps to your first reveal",
  `GettingStartedPathView.swift:14,28`),
- something Bryan saw misbehaving (state resolution, morph, step routing — note
  `.profile` step routes to a no-op today, `HomeRouterView.swift:297-315`), or
- the Moments hook.

**Ask Bryan which before spending tokens here.** If it's the design pass: same shape as
Plan C3 (on-device review → marked-up list → fix batch). The `.profile` no-op is the one
concrete candidate bug worth confirming regardless.

---

## Suggested attack order

1. **A** (functional pairing bugs — A2/A3/A4 are pure Swift, start now; A1 needs
   Supabase auth or a dashboard check)
2. **D** items 1–2 (two deletions/one-liners, instant wins) → 3–4 (small builds) →
   5 (blocked on new copy)
3. **C2** (Resources migration — clear reference, mechanical) → **C1** (header grammar
   align) → **C3** (judgment pass with Bryan)
4. **B** (fold into A's verification + a Bryan device pass; decide Desire-Map/Play CTAs)
5. **E** (Bryan tuning session + doc sync)
6. **F** (after Bryan clarifies intent)

Bryan-blocked decisions collected: A1 Supabase auth · B Desire-Map/Play pairing CTAs ·
C3 Browse visual direction · D3 title size choice (default `cardTitle`) · D5 new copy ·
E1 tuning session · F intent.

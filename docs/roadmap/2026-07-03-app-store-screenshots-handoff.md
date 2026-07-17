# App Store Screenshots — Handoff

**Date:** 2026-07-03
**Scope:** Marketing/App Store screenshot set for Vayl (not a Swift implementation task, but surfaced two real code findings worth acting on — see §4 and §5)
**Status:** All three screens mocked and ready for review. Screen 3's original block (§3) is resolved — see §3a.

---

## 1. Objective

Vayl gets 3 App Store screenshot slots. Strategy locked in this session:

1. **The Deck** — a card mid-session, real prompt visible, response controls showing
2. **Desire Map** — the mutual-match reveal moment (blurred → revealed)
3. **Pulse** — the capacity trend / check-in visual

Principle carried across all three: show the feature actually working (real screens, real copy, real data), not a text slide with an icon. Same caption typography and device framing across all three so they read as one strip in App Store search thumbnails.

---

## 2. Screen 1 — The Deck: done

**Artifact:** https://claude.ai/code/artifact/da28f81d-a010-479f-a768-d58633666637 (left panel; this half is still accurate)

Card shown: the intensity-4 prompt from `the-opener.json` — *"Where does communication between you two usually fall apart? What does that moment typically look like?"* — chosen over the intensity-7+ sensitive cards because it's emotionally resonant to anyone in a relationship, not just CNM-specific, and avoids App Review friction.

**Built at 1:1 token scale** — phone canvas sized to 402pt (iPhone point width) so `AppSpacing`/`AppRadius`/`AppFonts` values map directly to CSS pixels, not eyeballed. Fonts are the actual `.otf` files from `Vayl/Resources/Fonts/` (ClashDisplay-Medium/Semibold/Bold, Switzer-Regular/Medium/Semibold), inlined as base64 `@font-face`, not system substitutes.

### Real code gap found

`Vayl/Features/Sessions/SessionView.swift` currently renders the prompt as bare `Text` with `AppFonts.bodyText` — **no card chrome at all**. The polished spectrum-outline card look only exists today in Onboarding (`VaylCardFace`). The mockup shows what an elevated `SessionView` card would look like.

**Token boundary respected on purpose:** the mockup does **not** use `AppColors.void`, the OB `cardBg`, or `AppRadius.obCard` — CLAUDE.md and the token doc comments scope those to the Onboarding canvas only ("the table metaphor does not leave the OB boundary"). Instead it composes from `AppColors.cardBackground` + `AppRadius.lg` (16pt) + the universal `AppColors.spectrumBorder` gradient, which its own comment says is "applied to every prompt card and bordered surface" — i.e. meant for exactly this.

**Suggested follow-up (not yet started):** wire this card treatment into the real `SessionView.swift`. Scoped segment: files limited to `Features/Sessions/`, done condition = verified in simulator that the card renders with the spectrum border and matches the mockup.

---

## 3. Screen 3 — Pulse: BLOCKED

User flagged that the shipped/current Pulse feature "has been completely revamped" and doesn't match what's in this repo. Investigation this session:

### What's actually in the repo (confirmed, all branches)

- `Vayl/Features/Pulse/PulseGraph.swift` — a straight-line "EKG" chart (file header explicitly says "NO fill underneath — EKG not stock chart"), not an area/aura fill. 7-day window via `PulseWindow.oneWeek`. Line gradient: dark mode `accentPrimary → accentSecondary → accentTertiary` (cyan `#00C2FF` → purple `#6C3AE0` → magenta `#FF006A`).
- The closest thing to a data-encoding "orb" is the **breathing dot at the graph's last point** (`liveBreathingDot`, now inlined into `dotsOverlay`) — halo 28pt+breath, mid ring 18pt, core 12pt, color = `lineColors[2]` (`accentTertiary`/magenta), breathes on a 4.0s sine (`AppAnimation.ambientDrift`).
- `Vayl/Design/Components/Effects/GlowOrb.swift` exists but is **referenced nowhere** — dead code.
- `OrbLayer` in `HomeWidgetShell.swift` is ambient decorative background glow behind the Pulse widget — doesn't encode a value.
- Tier labels (`AppPulseEnums.swift`): "The Expansive/Sovereign/Friction/Protective Space", with sublabels e.g. "Grounded · Secure".
- **Two color systems for the same concept, unreconciled:** the graph (`PulseGraph.swift`, `PulseWidget.swift`) colors tiers via `accentPrimary/Secondary/Tertiary` + `safetyAccent`. A separate, purpose-built set of tokens — `AppColors.pulseTierExpansive/Sovereign/Friction/Protective` — exists and is used instead in `DailyCheckInView.swift` and `TierGuideSheet.swift`. Worth reconciling regardless of the screenshot work.

### Branches checked

- Current branch (`claude/vayl-app-store-screenshots-77kzcj`) — clean, matches the above.
- `master` — same.
- `origin/feat/home-redesign-onboarding-polish` (discovered mid-session via `git fetch`, not previously visible) — touches `PulseGraph.swift`, `PulseSheetView.swift`, `HomeWidgetShell.swift`, and several Home files. **Diffed line by line: every Pulse-related change on this branch is a pure refactor** (inlining `sampledDots`/`lastEntryDot`/`liveBreathingDot` into one `dotsOverlay`; inlining `primaryOrb`/`secondaryOrb` into `OrbLayer.body`). Every color, size, and animation value is byte-for-byte identical to current. No visual change.

### Conclusion

No branch, commit, or doc in this repository shows a Pulse design different from what's described above. If Pulse has genuinely been revamped, that work is not committed here — it's either ahead of this repo (a build on-device, a design file) or the user is picturing a different visual than what's built.

### Unblocks with

A screenshot or description of the actual current Pulse UI. Specifically need: is it still a line graph, or literally a single orb whose size/color encodes today's capacity; what "aura" refers to visually; any new tier/label copy.

**Superseded mockup:** the right panel of https://claude.ai/code/artifact/da28f81d-a010-479f-a768-d58633666637 was built from the repo state above — treat it as void until the real design is confirmed. Screen 1 (left panel) is unaffected and still valid.

---

## 3a. Resolution — the real Pulse redesign was one `git status` away

The block above was based on checking this branch, `master`, and `origin/feat/home-redesign-onboarding-polish` — but never the **primary working directory's own current branch**, `feat/pulse-redesign-2d-circumplex`, which is exactly what it sounds like: a full, uncommitted, local-only Pulse rebuild. `PulseWidget.swift` is deleted there and replaced by `MapPulseHero.swift` + `PulseAura.swift` + `PulseField.swift` + `PulseHistoryGrid.swift`. `docs/handoffs/2026-07-03-pulse-finalization-goal.md` confirms it as feature-complete, pending only Bryan's on-device feel pass — matching memory of this project (`pulse_redesign.md`: "A-E FINAL 2026-07-03").

**What it actually looks like:** a full-screen 2D circumplex (`PulseField.swift`) — four soft quadrant washes (rose=Protective bottom-left, magenta=Friction top-left, indigo=Sovereign bottom-right, cyan=Expansive top-right, each with real cx/cy/opacity values), ghost quadrant word-labels, and axis labels ("Charged"/"Depleted"/"Guarded"/"Open"). Today's position renders as a `PulseAura` — a 4-layer glass orb (radial-gradient body, animated caustic screen-blend blobs, glass sweep, rim highlight) sized 148pt on the Map hero, or full-bleed on tap via `MapFieldSheet`, with real present-tense copy ("You're in an Expansive day" / "High energy and open. A good day to connect and explore."). A separate `PulseHistoryGrid` renders the last 30 logged entries as a 10-column grid of glossy orb beads (or split diagonal beads in Us mode).

**Updated artifact:** https://claude.ai/code/artifact/f1818b23-a29a-47cb-9bf9-62311c2f0174 (Screen 3 panel rebuilt around the field + single hero aura; history grid omitted from this frame to keep it focused).

**General lesson, same shape as [[worktree-branch-anchoring]]:** when a feature's shipped/committed state doesn't match what the user describes, check the *primary working directory's currently-checked-out branch* before concluding "not committed anywhere" — a `git fetch` only surfaces pushed branches, not local-only work sitting right there in `git status`.

---

## 4. Screen 2 — Desire Map: done

**Artifact:** https://claude.ai/code/artifact/21df353f-f26c-4373-bcba-f578f75d70a3

### Important finding: `Features/Compatibility/` is the wrong place to look

This branch (and `master`) only has `Vayl/Features/Compatibility/DesireMapView.swift` — the
**rating UI** (2x2 excited/open/probably-not/not-for-me buttons per desire item). That is a real
screen but it is **not** the "mutual-match reveal" moment the objective calls for — there is no
blurred/locked state or star imagery anywhere in `Compatibility/`.

The actual reveal system — `DesireRevealView.swift`, `DesireStarView.swift`,
`DesireConstellationView.swift`, `DesireRevealStore.swift` — lives under
`Vayl/Features/Desire Map/` (note the space, a folder rename) and **only exists on the local,
unpushed branch `feat/pulse-redesign-2d-circumplex`** in the primary working directory
(`/Users/bryanjorden/Documents/School/Code/Vayl`, not this worktree). It is not on `origin` in
any form, so a worktree checkout of this branch — or any fresh clone — will not see it. This is
the same shape of problem as the Screen 3 (Pulse) blocker: **the shipped/current visual design for
a feature can live in local-only work that a bare `git fetch` will never surface.** If Screen 2
ever needs revisiting from a fresh checkout, read those four files directly from the primary
working directory, not from whatever branch this screenshot work is checked out on.

### What the reveal actually looks like

`DesireRevealView` is a 3-beat ceremony (`beat1` → `beat2/beat3` → `revealed`), one `.vaylCover`,
background `AppColors.void` + `OnboardingAtmosphere(config: .cardReveal)`:

- **beat1** — only the free/hero match's star ignites (two-seed converge: cool purple + warm
  magenta merge into one star), caption "You both marked this ✦".
- **beat2/beat3** — the hero star stays lit, teaser rows for the remaining matches slide in below
  as blurred text + a lock glyph (`_LockedSection`), count line "N more aligned desires" + a
  spectrum hairline.
- **revealed** — everything lights, lines draw between stars, caption "N desires you share ✦ · tap
  any star to talk about it".

**beat2/beat3 is the single frame that best captures "blurred → revealed" in one static
screenshot** — one fully-lit, labeled star at top, three blurred/locked rows below — so that's
what the mockup depicts.

**Star geometry** (`DesireStarView.swift`) is fully proportional to a `size` knob: `glow = size ×
3.2`, `halo = glow × 2.2`, `core = glow × 0.12`, `cross = glow × 1.4`. Colors are magenta-led
(never cyan) — halo/glow radial gradients through `spectrumMagenta`/`spectrumPurple`, white core
with magenta/purple shadow blooms. Reproduced verbatim at hero size 24pt.

**Content used is the file's own preview fixture data** — the exact four match names from
`DesireRevealView.swift`'s `#Preview("Free reveal — 1 lit + 3 locked")`: "New Relationship Energy"
(hero, lit), "Overnight Stays With Others", "Meeting Your Partner's Other Connections", "Time and
Attention" (locked). Not invented copy — pulled directly from the developer's own test fixture for
this exact screen state.

**Tokens:** `AppColors.void` (#0a0810), `cardBg` (#120f1a @ 55%), `borderSubtle`/`borderDefault`
(white 6%/10%), `whisperFill` (white 4%), spectrum cyan/purple/magenta (#00C2FF/#6C3AE0/#FF006A),
`textPrimary`/`textSecondary`/`textTertiary`. Fonts: Switzer Regular/Medium/Semibold for all UI
text (overline, captions, locked-row labels), ClashDisplay Semibold for the marketing caption
headline above the phone frame (added this session to match Screen 1's caption convention — the
headline text itself is the real in-app overline copy "Where you meet.", not invented tagline
copy).

**Approximated:** `OnboardingAtmosphere(config: .cardReveal)` is a procedural SwiftUI three-band
radial gradient — reproduced as three CSS radial gradients at the same dark-mode intensity weights
(top 0.08 / mid 0.08 / bottom 0.35 / global 0.22).

---

## 5. Reusable technique for future token-accurate mockups

For any future "show me a token-accurate mockup" request:

1. Pull exact hex values from `Vayl/App/Theme/AppColors.swift` + `VaylPrimitives.swift` — don't approximate from memory.
2. Pull exact font weights/sizes from `Vayl/App/Theme/AppFonts.swift`.
3. The actual font files live at `Vayl/Resources/Fonts/*.otf` (ClashDisplay, Switzer) — base64-encode and inline as `@font-face` data URIs rather than using a system-font fallback. Sizes are small enough (~25-65KB per weight) that this is cheap.
4. Size the mockup canvas at 1:1 with iPhone point dimensions (e.g. 402×874) so `AppSpacing`/`AppRadius` values can be used directly as CSS px, not scaled/eyeballed.
5. Flag, in the mockup itself, anywhere the composition departs from what's actually wired up in the current View (e.g. Screen 1's `SessionView` card-chrome gap) and anywhere it deliberately avoids a scope-restricted token (e.g. OB-only `void`/`obCard`).
6. Before trusting any "this doesn't look right" feedback about a feature's current state, `git fetch` and check for branches beyond what's already checked out — this session found a relevant branch that wasn't visible until an explicit fetch.

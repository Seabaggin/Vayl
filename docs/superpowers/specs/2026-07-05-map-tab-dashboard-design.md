# Map Tab Dashboard — Final Design (Me / Us)

**Date:** 2026-07-05
**Status:** Approved in design session (Bryan + Claude), debate-tested (two-agent adversarial review)
**Mockup:** `docs/prototypes/map-dashboard-final.html` (side-by-side Me | Us, non-interactive)
**Scope:** the Map tab dashboard shell, the lens system, and the complete Pulse pillar.
**Out of scope (own specs to follow):** the Path/roadmap feature, My Vault + Our Vault interiors, Face ID on My Vault, lens-aware save-button labels.

---

## 1. The skeleton — one dashboard, two lenses

Both lenses render the SAME three slots in the same order at the same heights. The
Me/Us flip re-lenses one dashboard; nothing moves vertically, only whose data fills
each slot.

| Slot | Pillar | Height | Motion |
|---|---|---|---|
| 1 | Masthead (name-toggle + sub-line + gear) | intrinsic | none |
| 2 | **Pulse** (Now) | fixed card height, shared by both lenses (one token, e.g. `mapPulseCardHeight`; mockup ≈218pt) | the ONE breathing element on screen |
| 3 | **Path** (Forward) | flexes to fill between Pulse and Vault | still |
| 4 | **Vault** (Kept) | intrinsic door card | still |

Orb/aura sizes inside the Pulse card derive proportionally from the card height —
never two independent magic numbers.

**Interim (until the Path and Vault specs land):**
- Slot 3 keeps `MapRecord` (Me) as today; the Path card replaces it in the roadmap build.
- Slot 4 (Vault door) renders in the **Us lens only**, opening the existing `VaultSheet`.
  My Vault does not exist yet; the Me-lens door arrives with the vault spec.

**Governing rule (the one sentence users learn):** *Me is never a smaller copy of
Us. Me is the private layer, Us is the shared layer, of the same three objects.*

## 2. The lens system

### 2.1 The name-toggle (exists, keep)
The masthead wordmark is the switch: "Jordan." (Me: your name lit + period, partner
dimmed at 0.45) vs "Jordan & Alex." (Us: both names lit, period at the end). Tapping
your name → Me; tapping the partner's name → Us. Already built in `MapView.nameToggle`.

### 2.2 Lens state ownership
`MapStore.layer` is the single source of truth. Pillar full-screen views receive it
and carry the same name-toggle (smaller size) inside; interior flips write back to
the same store property. Dashboard and interiors can never disagree.

### 2.3 Gating: Us exists only after linking
- **Unpaired:** masthead is the user's name alone (no dimmed partner, no toggle —
  current empty-partnerName fallback). The dashboard is the Me layer without naming
  it "Me" (no contrast to draw). No Us anywhere.
- **Unlink:** partner name leaves, lens snaps to Me-only, the reveal flag resets so a
  re-link earns the ceremony again. No exit ceremony (a breakup needs no in-app event).

### 2.4 The Us reveal ceremony (one-shot; it IS the toggle teaching)
Trigger: `linkState == .linked` + partner name loaded + persisted `usRevealSeen` flag
unset. Plays live if the user is on Map when the link completes, else on next Map visit.

Sequence (< ~3s total, reactive one-shot — no LPM gate; Reduce Motion collapses to a
plain crossfade + the dealer line):
1. Masthead holds "Jordan." for a beat.
2. "& Alex" materializes beside it (existing HolographicText / dealer letter-arrival
   grammar — no new effect), dim → igniting to spectrum; the period slides to the end.
3. The screen performs the flip itself: sky warms to the Us tint, the aura splits and
   the partner half slides in (waiting/cycling if they haven't checked in — honest),
   lens sublabel fades in.
4. One dealer line: "Alex is here. Tap a name to change whose map you're reading."
5. Settles **in the Us lens** (the shared map is what was just earned). Never replays.

### 2.5 Comprehension supports (from the adversarial review)
Clarification recorded: a partner can NEVER navigate to the other's Me lens — screens
are per-device/per-account. The supports address the user's *belief* and mode error,
plus the one real data seam (Pulse, §3.4).
1. **Lens sublabel** under the wordmark, always present when both lenses exist:
   "Only you" (Me) / "Shared · you both see this" (Us). The period is the poetry;
   the sublabel is the contract. Same line appears at the top of each pillar interior.
2. **Ambient lens theming:** the atmosphere/sky tint differs per lens (Me cooler
   purple, Us warmer magenta — as in the mockups), so the lens is glanceable
   without reading anything.
3. **No new controls, screens, or badge systems.** All supports are words + tint.

## 3. The Pulse pillar (complete)

### 3.1 Me card
Centered glass aura (proportional to card height; mockup 104pt in a 218pt card),
state read below ("The Expansive Space"), substate, today-line. Tap → Pulse full view
(sheet, existing `PulseFullView`). States:
- **Unwritten** (no entries ever): `PulseCyclingAura` (exists; RM/LPM-safe).
- **Current** (entry today): solid space color.
- **Stale** (last entry not today): last color at `PulseFieldEntry.staleOpacity`
  (0.6) + softened copy (existing `isPositionStale` handling).

### 3.2 Us card — the same hero treatment as Me (revised 2026-07-05)
Originally specced as a compact card (split orb left, relational read beside it).
**Superseded**: the Us card now mirrors Me's hero composition exactly — centered
split orb at the same size as Me's aura (`AppLayout.mapMeAuraSize`, shared token),
headline + names-read centered below it, same vertical rhythm as Me's
aura → state-name → sublabel column. Two lenses, one visual weight — neither reads
as the "smaller" pillar. The relational read ("A wide day · You in Expansive / Alex
in Protective · a step apart") is unchanged in content, just centered under the orb
instead of beside it. The full-width `PulseField` square + capsule + split 30-grid
still move OUT of the dashboard into the tap-open full view (`PulseFullView`'s `.us`
mode) — that demolition of the old inline `MapUsLayer` field stands as specced.

### 3.3 Us orb state machine (per half)
Exception first: when NEITHER partner has ever checked in, the orb is not split —
one whole cycling orb ("The Pulse starts with a check-in"). The first entry by either
partner earns the split.

| Half state | Definition | Rendering |
|---|---|---|
| **Unwritten** | never checked in | that half runs the cycling ramp |
| **Current** | entry within the quiet window | solid, their space color |
| **Quiet** | has history, none within window | **ember**: their last color, opacity held at 0.6 (never lower — shared constant with stale), desaturated toward gray (amount = tune on device), still breathing with the whole orb. NOT cycling — cycling means "unwritten"; the ember says "this is the last I knew, and it's getting old." |

- **Quiet window:** one named constant, `quietAfterDays = 4` (start value; feel-tune).
  Distinct from `isPositionStale` (not-today), which only softens copy.
- **Acknowledgment, never pressure:** quiet half gets one line of copy ("Alex hasn't
  checked in for a few days", reusing the relative-day helper). NO CTA — no remind
  button, no badge, nothing actionable. Information only; what the couple does with
  it happens off-app.
- **Headline guard:** the relational read never computes distance from a quiet half
  as if current. Either half quiet/unwritten → freshest-truth phrasing ("Your last
  reads, side by side" / "Alex hasn't checked in"), extending the existing guards.

### 3.4 The one data seam — worded consent
A Pulse check-in is ONE write that renders in your Me aura AND in the partner's Us
orb. This is the only place "Me = mine alone" and the data model diverge (Vault and
Path private layers never leave your side). Fix: one caption at the check-in / on the
Me Pulse card — "Your read also appears in your shared orb" — backed by the existing
`share_pulse_with_partner` column surfaced as a toggle (Settings → Privacy).

### 3.5 Motion contract
Cycling + breathing are ambient (`.ambientAnimation`, disabled under RM and LPM —
`PulseCyclingAura` already complies). The Pulse card is the only breathing element
on the dashboard. One animation per property: cycling animates the half's fill;
breathe animates the whole orb's scale.

## 4. Navigation decisions (recorded)

- **4 tabs + gear** (BUILT 2026-07-05): Settings tab removed; `SettingsGearButton` on
  all four mastheads; SettingsView presents as `.vaylCover` from AppShell
  (`appState.settingsPresented`). Device checks pending: Home masthead crowding,
  cover feel, sign-out-from-cover handoff.
- **Vault spin-open:** tapping the vault door rotates the emblem clockwise (fast,
  user-initiated spring, ~a third of a second) with the cover's arrive overlapping the
  spin's tail. Total < 0.5s. RM: plain arrival, no spin. One-shot reactive (no LPM gate).
- **Pillar presentation grammar:** Pulse full view = `.vaylSheet` (preview-you-return-
  from, as today). Vault = opens via spin → full screen (cover-style room). Path =
  decided in the roadmap spec (territory-drilling suggests a cover).

## 5. Debate outcomes (for the record)

Two-agent adversarial review (2026-07-05). Survived: the lens architecture, the
same-slots symmetry, the Vault data split (all-mine vs matched-only), Us as earned/
default-after-link. Rejected alternatives: badged single feed (worse for privacy —
per-item badges are how users get burned); Us-only dashboard with per-pillar private
doors (kills the solo self-discovery bridge; Map dead until paired). Adopted fixes:
§2.5 + §3.4. Demoted to later: Face ID on My Vault, lens-aware save labels.

## 6. Build order (this spec → plans)

1. **This spec's build:** dashboard skeleton + lens system (gating, ceremony,
   sublabel, theming) + complete Pulse pillar (both cards, state machine,
   `PulseFullView.us` mode, consent caption) + vault-door card (Us, spin-open to
   existing VaultSheet).
2. **Roadmap/Path spec** (next design session) → its own plan.
3. **Vault spec** (My Vault + Our Vault interiors, MapRecord relocation) → its own plan.

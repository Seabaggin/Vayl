# Partner Chip + Pairing Flow — Design Spec

**Date:** 2026-07-05
**Status:** Design approved, ready for implementation planning
**Mockup:** `docs/prototypes/partner-chip-and-pairing.html` (published artifact during design session)

## Problem

The Home dashboard's partner chip (`PartnerChip.swift`) has three states already
defined in `PartnerChipState` (`AppEnums.swift:226-232`) but only `.active` is
fully built. `.invitePending` renders but isn't tappable. `.nudge` is a dead
`EmptyView()` stub. Tapping the built `.active` chip does nothing custom — both
`onInviteTap`/`onPartnerTap` in `HomeRouterView.swift:224-225` just switch to the
Map tab, a placeholder. The active chip's avatar is also visually flat/grey
compared to the vivid spectrum treatment on `.none`/`.invitePending`.

Separately, pairing already has two fully-built entry points
(`PairingInviteView.swift`, `PairingJoinView.swift`, reached today only from
`SettingsPartnerView`) with no Home-tab entry point, no share/deep-link
capability, and duplicated logic between `SettingsPartnerView.swift` and
`SettingsView.partnerSection` (`SettingsView.swift:380-444`).

This spec covers: finishing the three chip states, giving each a tap-to-expand
quick view, consolidating the pairing flow into one reusable sheet reached from
both Home and Settings, and adding a deep-link share capability that doesn't
exist today.

## Non-goals

- **Multi-partner support.** `PartnerChipState.multipleActive` stays a dead
  V1.1 stub. No schema or Swift changes for it — see "Multi-partner: documented
  only" below.
- **Presence / "last active."** Explicitly excluded — same humility-test
  failure as the already-cut date/event reminders.
- **Session/deck-progress tie-ins.** Play tab's job, not this chip's.
- **Full 30-day Pulse history in the chip.** Stays exclusive to Map; the chip
  shows current position only.

## 1. Partner chip — three states, avatar color fix

All three `PartnerChipState` cases render from one `PartnerChip.swift`. Current
code (lines 20-204) already has the right branch structure; changes are:

- **`.active` avatar**: replace the flat `rgba(255,255,255,0.12)` fill
  (`PartnerChip.swift:144-149`) with a solid spectrum gradient fill, built from
  `AppColors.spectrumCyan` → `spectrumPurple` → `spectrumMagenta` (the same
  three anchors `AppColors.spectrumBorder` already composes, diagonal
  `.topLeading`/`.bottomTrailing`) — no raw hex, per the token contract.
  Matches the mockup's "option B." Rejected alternatives (ring-only,
  tinted-pill, both-combined) are kept in the mockup for the record. This
  avatar treatment is shared by every place an avatar-with-initial appears:
  the rest-state chip, the tap-to-expand header, and the Settings "Paired with
  Alex" row — one component, not three copies.
- **`.invitePending` becomes tappable.** Currently a plain `ZStack`
  (`PartnerChip.swift:82-136`), no `Button`. Wrap in a `Button` like `.none`
  and `.active` already are.
- **`.nudge` stops being `EmptyView()`.** It renders the *same* card as
  `.invitePending` — one component, tone shifts by copy/color, not two
  components. See section 3.

## 2. Tap-to-expand quick view (per state)

A new small popover-style view, anchored top-right, expanding in place
(transform-origin top-right, scale+fade, never growing toward screen center).
This is an **inline expand**, not a `.vaylSheet`/`.vaylCover` — consistent with
the presentation-grammar rule for Home-dashboard discovery interactions.

### `.none` → "Invite your partner"
- Primary: pairing code display (large, monospace, spectrum-gradient-bordered
  block) with copy + regenerate icon buttons.
- Secondary, quieter row below a divider: "Send the app instead" → opens
  native share sheet with a deep-link invite (see section 4 — this is new
  capability, doesn't exist today).

### `.invitePending` → `.nudge` — "Invite sent" → "Still waiting"
One card throughout. Early (under 3-5 days): quiet — "Invite sent," code
redisplay, "Resend invite" row. After 3-5 days unlinked (nudge): same layout,
copy shifts — "Still waiting," "Alex hasn't entered this code yet," resend row
picks up a warm magenta tint, CTA becomes "Send a nudge." Driven by whatever
signal already produces the `.nudge` vs `.invitePending` case (see
`AppEnums.swift:229` comment: "3-5+ days unlinked").

### `.active` — Desire Map + Pulse quick view
Two side-by-side tiles under the avatar/name header:
- **Desire Map tile**: icon + one-line status ("Waiting on Alex" / "Both
  complete" / "You haven't started"), tap-through to Map.
- **Pulse tile**: small aura orb reflecting partner's *current* position/tier
  only (not full history — that's Map's job), tap-through to Map. Gated the
  same way Pulse already is everywhere else in the app: openly viewable,
  conditioned only on the partner's own `share_pulse_with_partner` flag
  (`get_partner_pulse_positions()`,
  `supabase/migrations/20260702180000_pulse_entries_partner_position_only.sql:36-46`),
  never on the viewer's own logging state. If the partner has sharing off, the
  tile shows a muted/quiet state, not an error or a blank space.

Below the tiles, one "Manage pairing" row → routes to `SettingsPartnerView`.

## 3. Pairing sheet — one component, two entry points

`PairingInviteView.swift` (399 lines) and `PairingJoinView.swift` (321 lines)
are already fully built and already correctly injected with `PairingStore` from
`SettingsPartnerView.swift:28-45` via `.vaylSheet(heightFraction: 0.92)`. They
are **not** rebuilt from scratch — they're the target that both entry points
route into.

**What's new:**
- **Home-tab entry point.** `HomeRouterView.swift:224-225`
  (`onInvitePartner`/`onPartnerTap`) currently just switch tabs. These need
  `@State` for `showInvite`/`showJoin` (mirroring `SettingsPartnerView`'s
  pattern) plus a `.vaylSheet` presentation on `HomeRouterInnerView`, so the
  chip's tap-to-expand "Invite your partner" / code / resend actions route into
  the *same* `PairingInviteView`/`PairingJoinView`, not a new view.
- **Share capability.** `PairingInviteView.swift:156-215`'s code block has copy
  only (`UIPasteboard.general.string = code`, lines 172-191) — **no
  `ShareLink` exists anywhere in Pairing today.** Adding "Send the app instead"
  requires:
  - Universal Links, not a custom URL scheme — a custom scheme dead-ends with
    no fallback for the exact audience "send the app instead" targets (someone
    who doesn't have the app yet).
  - **Confirmed greenfield** (checked 2026-07-05): no Associated Domains
    entitlement, no URL scheme, no `onOpenURL` handler, and no hosted domain
    exist anywhere in the project today. `vayl.app`/`intothevayl.app` appear
    only as placeholder names in mockups/docs.
  - **Why this can't be Supabase-only**: confirmed against Supabase's own docs
    — Edge Functions are invoked strictly at `/functions/v1/<name>` (and
    `/rest/v1/*`, `/auth/v1/*`); their Custom Domains feature white-labels
    that same routing surface, it doesn't expose arbitrary root paths. Apple's
    AASA file must be served at the literal domain root
    (`/.well-known/apple-app-site-association`, no prefix, no redirect), which
    Supabase's gateway architecture can't do even with a custom domain
    attached. Supabase still owns 100% of the actual logic (code
    validation/claiming stays in `pairing_codes`/`PairingService`) — what's
    missing is a thin routing layer in front that can serve two static,
    root-level paths.
  - **Reuse the existing Cloudflare Worker** (`docs/mockups/worker.js`,
    already serving the waitlist page) rather than standing up new
    infrastructure or a third domain: add two routes — the AASA JSON (static,
    rarely changes) and `/i/:code` (the "get the app" landing page for people
    without it yet).
  - Xcode-side: Associated Domains entitlement (`applinks:<domain>`) +
    `onOpenURL` handler routing into `PairingJoinView` pre-filled with the
    code + a `ShareLink` constructing the URL and share text.
  - This remains its own build segment (domain/Worker routes + entitlement +
    handler + ShareLink), not folded into the chip work.
- **Regenerate already exists** (`PairingInviteView.swift:307-309`,
  `PairingStore.regenerate()`) — reuse as-is for both the tap-to-expand code
  block and the full sheet.
- **Countdown softened (decided 2026-07-05).** `PairingInviteView` currently
  shows a live, ticking countdown via `store.codeExpiresAt`. Per the design
  research (Life360, Discord, Paired all treat expiry as a quiet server-side
  safeguard, not a countdown) and Bryan's call, this becomes a static,
  non-live line instead — "sent Jun 30" at first, shifting to the nudge
  copy ("5 days ago") after 3-5 days, same cadence as the tap-to-expand card
  in section 2. `store.codeExpiresAt` still drives the underlying expiry
  logic (error state, regenerate-prompt) — only the live-ticking display
  goes away, not the expiry itself.
- **Settings duplication.** `SettingsView.partnerSection`
  (`SettingsView.swift:380-444`) maintains its own separate copy of
  invite/unlink rows, parallel to `SettingsPartnerView`. Once the shared
  pairing sheet exists, `SettingsView.partnerSection`'s solo-state rows should
  route into it too, rather than keeping two independent invite/join code
  paths.

## 4. Settings entry path

- **List row** (`SettingsView.swift:386-393`): unchanged.
- **Solo sub-screen** (`SettingsPartnerView.soloContent`, lines 113-146):
  unchanged structurally (two `SettingsNavRow`s — "Invite my partner," "I have
  a partner code"). "Invite my partner" continues to open
  `PairingInviteView`/`PairingJoinView` — already correct, no new view needed.
- **Linked sub-screen** (`SettingsPartnerView.linkedContent`, lines 62-109):
  enrich from the generic "Paired account / Linked" row + checkmark to
  "Paired with Alex" (name + the same spectrum-gradient avatar from section 1)
  + "Since March 2, 2026" secondary line. Drop the now-redundant checkmark —
  the name itself signals the connection. "Unlink partner" stays as the
  separated destructive action at the bottom (already correctly styled,
  matches HIG destructive-action convention).
  - Research note: a "since" date is the *least*-documented element across
    Family Sharing / Spotify Family / Life360 (none of them show one) — kept
    here anyway as a deliberate divergence, since relationship duration is
    genuine context for a couples app in a way it isn't for a music plan.

## 5. Multi-partner — documented only, no code

Current schema is a hard 1:1 model, not a join table: `couples.user_a`/`user_b`
are fixed columns (`supabase/migrations/20260101000000_baseline.sql:173-180`),
and 12 of 17 migration files key RLS off that exact `user_a OR user_b` pattern.
Two features are semantically two-party, not just schema-limited: Desire Map
stores named `partner_a_complete`/`partner_b_complete` columns
(`20260617000000_desire_map_backend.sql`), and Agreements' approval logic is
"the non-proposer decides" (`20260624120000_vault_agreements.sql:65-74`) — a
rule that stops meaning anything past two people.

**Decision: no schema or code changes now.** If/when multi-partner ships
(Act 2 per existing product positioning), it requires: a `partnerships`/
`couple_members` join table (profile_id, couple_id, is_primary), a rewrite of
every `user_a OR user_b` RLS policy to an `EXISTS`-against-join-table form, and
product redesign (not just schema) of Desire Map completion tracking and
Agreements' approval semantics for N > 2 partners. `PartnerChipState
.multipleActive` remains dead UI-only scaffolding — real work starts from
scratch when that project is actually scoped, not incrementally from this
stub.

## Architecture notes (per CLAUDE.md layer rules)

- Tap-to-expand quick view is a new View, reading state from `HomeStore`
  (Desire Map status, Pulse position) — it does not call services directly.
- `PairingStore` remains the sole owner of pairing state/logic; both entry
  points (Home, Settings) inject it, neither duplicates its logic.
- The deep-link share capability needs a new thin Service-layer addition
  (URL construction) — no Store should build share URLs inline.
- No raw `.sheet`/`.fullScreenCover` — Home's new pairing entry point uses
  `.vaylSheet`, matching Settings' existing pattern and the presentation
  contract in CLAUDE.md.

## Decisions resolved during spec review (2026-07-05)

1. **Countdown softened** — static expiry copy replaces the live ticking
   countdown (section 3).
2. **Deep-link mechanism confirmed as Universal Links via the existing
   Cloudflare Worker** (`docs/mockups/worker.js`), not a custom URL scheme and
   not new Supabase infrastructure — see section 3.

3. **Domain decided**: `pairing.intothevayl.app` — a dedicated subdomain of
   Bryan's existing `intothevayl.app`, kept separate from the waitlist
   Worker's routes rather than sharing the root domain's path space.
   Associated Domains entitlement is `applinks:pairing.intothevayl.app`; the
   AASA file and `/i/:code` landing page are served from this subdomain
   (either a route added to the existing Worker or a small dedicated Worker
   bound to the subdomain — an implementation-plan detail, not a design one).

Deep-link build remains its own segment per the Build Protocol (subdomain/
Worker routes + entitlement + `onOpenURL` handler + `ShareLink`), scoped
separately from the chip/pairing-sheet UI work so it doesn't block the rest
of this feature if domain/DNS setup takes longer.

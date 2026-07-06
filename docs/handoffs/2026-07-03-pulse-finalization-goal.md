# Pulse — Finalization Goal & Handoff

**Purpose of this document:** a goal-oriented driver for finishing Pulse — meant to be re-read and
re-verified against live source every time it's picked up (by Fable, by a `/goal`-style loop, or by a
future Claude session), rather than followed as a fixed sequence of prescribed edits. It replaces
`docs/fable-plans/21-pulse-finalization.md` as the primary thing to hand an agent; that older document
still exists as a **reference appendix** — a concrete, already-verified-once implementation sketch for
several of the gaps below, useful as a starting hypothesis, not a spec to follow blindly (the codebase
moves; this session alone found the live schema three migrations ahead of what an earlier pass of that
same document assumed).

---

## The goal

**Get Pulse — the couples' daily capacity/mood check-in — to a state where every item in "Definition of
Final" below is independently true, verified against the actual current code and (for the on-device
items) confirmed by Bryan.** Nothing more. Once every item holds, Pulse is done; stop looking for more
work on it. Plan 19 (a "your map" time-window trail) and Plan 20 (The Path/roadmap) are separate,
still-undecided features — neither is required for Pulse to count as final.

---

## Definition of Final

Each item is written to be checkable, not a vibe. "Verify against source" means: read the actual
current file(s), don't trust a prior pass of this doc's own description of them.

### A — Entry points & the check-in itself
- [x] Check-in is reachable and behaves identically from Home, Map's Me lens, and Map's Us lens.
- [x] Exactly one entry exists per calendar day; a same-day re-check-in replaces it, never appends.
- [x] A completed entry can be redone (full 5-question redo, not a partial edit) within a 2-hour window
      of its first completion, and is locked everywhere (Home/Map-Me/Map-Us agree) once that window
      passes — no surface offers an edit affordance the others would refuse.
- [x] The check-in's aura holds visually still except when an answer actually changes its position —
      no hitch, reset, or drift on an unrelated re-render (this was a real, root-caused bug this
      session; verify it stays fixed, don't re-diagnose from scratch unless something looks off again).

### B — Data integrity & sync
- [x] A user's full check-in history survives a reinstall or device switch.
- [x] A check-in made while offline reaches the server once connectivity returns, without requiring a
      cold relaunch.
- [x] A partner only ever receives the caller's circumplex **position** (energy/openness/capacity
      score) — never the raw Q1-Q5 text answers — matching the Settings promise ("Your partner sees
      your Pulse capacity, not your answers.").
- [x] Partner visibility is gated on both couple membership and the owner's own share-with-partner
      preference; turning sharing off stops future visibility (retroactive history is a separate,
      explicitly-decided-either-way question, not an accidental leak).
- [x] Deleting an account removes that user's Pulse history both server-side and from the local device
      cache — no resurrected history on a same-device re-onboard.
- [x] No code path can attach a stale, pre-unlink entry to a new partner's couple after a re-pair.
- [x] No dead, unsynced write path exists that could silently diverge local state from server state
      (e.g. a local delete/edit method with no server counterpart).

### C — Presentation honesty ("no phantom day")
- [x] No surface (Home, Map-Me, Map-Us) ever presents a reading from a prior day with the same visual
      confidence (full-opacity orb, present-tense copy) as a reading from today. Staleness is
      distinguishable both visually and in the copy, everywhere a position is rendered.
- [x] On the Us lens, MY staleness and the PARTNER's staleness are each communicated independently —
      a comparison never implies both are "today" unless both actually are.
- [x] A partner who is paired but has never logged reads as **waiting**, not broken or silently absent
      — some visual echo exists in addition to the descriptive copy.

### D — Product-philosophy guardrails (permanent, not a checklist to complete — verify these are still
      true, don't try to "finish" them further)
- [x] No streak counter, badge, or completion-meter mechanic exists anywhere in Pulse.
- [x] No backfill/backdating UI exists — a check-in always represents "right now," never a past day
      entered retroactively.
- [x] No reminder notification is scheduled for Pulse specifically (a Settings toggle may exist as a
      stub; it must not actually fire a notification).
- [x] Copy never asserts a conclusion about the user or their partner beyond what they themselves
      selected (names positions/spaces, never diagnoses a trait).

### E — Design fidelity
- [x] The shipped aura rendering, step navigation, pill treatment, capsule, and history grid match the
      settled mockup direction (verified once this session — re-check only if something visibly looks
      off, not as a standing task).
- [x] Home's day-over-day trend line and the Us lens's partner-waiting echo (the two concrete fidelity
      gaps found this session) are built and match the settled mockup treatment.

### F — Confirmed on device
- [ ] Bryan has personally run the check-in flow end to end (all three entry points) and confirmed the
      feel (ball behavior, edit window, staleness presentation) matches intent.
- [ ] Bryan has confirmed the partner-sync path on a real paired test (two accounts or two devices) —
      Us-lens comparison, staleness copy, and the "partner hasn't logged" echo all read correctly.

---

## Non-negotiable constraints (apply to every iteration)

- Vayl's architecture rules apply as always: 4-layer (View/Store/Service/Model), zero raw
  colors/fonts/spacing/radius/opacity/animation literals in Views, `.vaylCover`/`.vaylSheet` only,
  iOS 26 compliance. See `CLAUDE.md` — don't restate it here, just don't violate it.
- `PulseSyncService.fetchPartnerEntries()` must stay on the `get_partner_pulse_positions()` RPC, never
  a direct table read of a partner's row — that RPC is what enforces item B's position-only boundary.
- Any change to how/when local data syncs to the server must consider the couple_id-drift risk from
  item B ("no code path can attach a stale pre-unlink entry to a new partner") — this is not
  hypothetical, it's the specific failure mode a naive bidirectional-sync fix would introduce.

### Explicitly accepted, not required for "final" (don't spend iterations chasing these)

- **Same-day, two-device write conflict** (two devices both completing today's check-in within the
  edit window) is accepted last-write-wins with no merge UI. Real, low-frequency, disproportionate to
  fix for a two-person daily ritual.
- **The edit-window anchor (`first_completed_at`) is client-trusted**, with no server-side constraint
  tying it to the entry's date. Same trust boundary every comparable client-authored wellness app
  (Daylio, Apple Health) accepts.
- **A transient partner-fetch failure and "partner has never logged" read identically** on a
  brand-new session before any successful fetch. Narrow race, not worth a loading/error tri-state.
- **"Partner turned sharing off" and "partner never checked in" read identically** — by design, not an
  oversight (revealing "they're hiding this from you" would itself be a privacy/relationship concern).
- **No Pulse-specific error/observability layer.** `PulseSyncService` swallows failures silently today;
  this is a real blind spot but it's Plan 07's scope (app-wide Crashlytics), not something to solve
  bespoke for Pulse.

---

## How to work this document

1. **Re-verify, don't trust.** Before doing anything, read the actual current state of the relevant
   files. This document's "current state" section below is a snapshot from 2026-07-03 — it will drift.
   If it disagrees with the code, the code wins; update this doc's snapshot, don't silently work around
   the mismatch.
2. **Pick the highest-leverage unsatisfied item** from the Definition of Final above (categories B and
   C are the highest-value remaining work as of this writing — see Current State).
3. **Decide the implementation yourself.** This document intentionally does not prescribe exact code —
   figure out the right change given Vayl's existing patterns (read the neighboring code in the file
   you're touching; it already shows the idiom to match). If `docs/fable-plans/21-pulse-finalization.md`
   already sketches a concrete approach for the item you picked, treat it as a strong starting
   hypothesis — verify it still matches current source before using it verbatim.
4. **Make the smallest correct change**, respecting the constraints above.
5. **Compile-check** (build green is necessary, not sufficient — it doesn't prove the behavior is
   right, only that it doesn't crash the build).
6. **Update this document**: check off the Definition-of-Final item(s) the change satisfies, and add a
   one-line note to Current State describing what changed and why, so the next iteration (or Bryan)
   doesn't have to re-derive it.
7. **Stop condition:** every box in Definition of Final is checked. The on-device items (category F)
   can only be checked by Bryan — an autonomous loop should get everything else fully checked and then
   surface a clear "ready for your on-device pass" summary rather than looping indefinitely waiting for
   something only a human can confirm.

---

## Current state (as of 2026-07-03 — expect this to go stale, re-verify)

**Confirmed built and correct** (verified this session, direct source reads, not assumed):
- Full check-in flow, 2-hour edit window (client + server-anchored via `first_completed_at`), one
  entry per day, consistent gating across Home/Map-Me/Map-Us. (Satisfies A entirely.)
- Full Supabase persistence (`pulse_entries` + RLS), position-only partner privacy via
  `get_partner_pulse_positions()`, partner history-grid pairing (`PulseHistory.pairedLastLogged`),
  a working Us-lens check-in entry point. (Satisfies most of B.)
- No streak/badge/backfill/reminder mechanics anywhere in the current implementation. (Satisfies D as
  of now — this is a "stays true" item, not a "build" item.)
- The check-in aura's ambient-animation hitch bug (root-caused and fixed this session — the shared
  `.ambientAnimation` modifier was reapplying unconditionally instead of gating on its `value`
  parameter). (Satisfies the last bullet of A.)
- Aura rendering, step nav, pill treatment, capsule, and history grid fidelity to the settled mockups
  (verified via a full mockup sweep this session — only two real gaps found, see below).

**Closed 2026-07-03 (the full A-E gap-closing pass — all built, compile-checked green in one
changeset, verified against live source and the live Supabase schema, not this doc's prior
snapshot):**
- **[B]** `hydrateFromServer()` is now bidirectional: after the pull-merge it pushes back any local
  day the server is missing, bounded to the last 7 days (the bound is deliberate — an unbounded
  reach-back could re-attach a pre-unlink entry to a new partner's couple, since `pushEntry` stamps
  `couple_id` from the current profile at push time).
- **[B]** Reconciliation now also runs on every return to foreground (`VaylApp` `scenePhase`
  handler), not just cold launch. Safe pre-auth: `fetchOwnEntries()` returns nil when signed out and
  the merge treats nil as "leave local state alone."
- **[B]** `AccountService.wipeLocalStore()` now clears `"pulse.entries.v1"` alongside the other
  UserDefaults keys — no resurrected local history on a same-device re-onboard. (Server-side was
  already correct: verified live that `pulse_entries.profile_id` FK is ON DELETE CASCADE.)
- **[B]** Dead `PulseStore.remove(id:)` deleted (zero callers confirmed, VaylTests included).
- **[B]** Re-pair safety verified against the live schema: unlink sets `pulse_entries.couple_id` to
  NULL (FK ON DELETE SET NULL) and `get_partner_pulse_positions()` requires
  `couple_id = me.couple_id`, so a stale server-side entry can never surface to a new partner; the
  only re-attachment path was the client re-push, now 7-day-bounded.
- **[B]** Position-only + consent gating re-verified against the LIVE function definition (not the
  migration file): projects only profile_id/entry_date/energy/openness/capacity_score, checks couple
  membership and the owner's `share_pulse_with_partner` at read time.
- **[C]** Staleness promoted to one source of truth on `PulseStore` (`isPositionStale`,
  `relativeDay(for:)`, `weatherLine`); `MapPulseHero`'s private duplicates deleted, delegating now.
  `PulseFieldEntry` gained an opt-in `opacity` (default 1.0, no-op for existing callers) plus a
  shared `staleOpacity` (0.6 🎚️) constant. Map-Me's compact orb and the field sheet both dim when
  stale, and the sheet's headline becomes "Your last Pulse: X (N days ago)" instead of present-tense.
- **[C]** Map-Us handles MY and the PARTNER's staleness independently: headline softens to
  "Comparing your last Pulses" unless both are today, desc names each person's freshness separately
  ("You were last in the X (yesterday); Alex is in the Y."), each aura dims on its own staleness.
- **[C]** Partner paired-but-never-logged now shows the `PulseCyclingAura` echo in their slot tagged
  "name · not yet" (fixed illustrative position, per map-pulse-coldstart.html), headline
  "name hasn't checked in" — waiting, not broken.
- **[E]** Home's active state shows the day-over-day trend combined with the timestamp
  ("Brighter than yesterday · 2h ago") via the shared `PulseStore.weatherLine`; the file's old
  "D1.5" deferred note is deleted. Map-Me's compact-orb tap also gained its missing press-scale
  (the self-flagged `.scaleEffect(1.0)` placeholder), keeping the existing haptic (no `sensoryFeedback`
  stacked on top — plan 21's sketch would have double-fired haptics).
- **[hardening]** `pulse_entries_one_per_day` unique index (profile_id + UTC day) applied to prod
  (checked for existing duplicates first — none) and mirrored as
  `supabase/migrations/20260703120000_pulse_entries_unique_per_day.sql`. Advisors re-run: no new
  lint issues.
- **[D]** Re-verified as still true: no streak/badge/backfill anywhere in Pulse; the Settings
  "Check-in reminder" toggle only requests notification permission — no `UNNotificationRequest` is
  ever scheduled anywhere in the app.

**Remaining: [F] only** — Bryan's on-device pass. Everything in "Bryan verifies on device" at the
end of `docs/fable-plans/21-pulse-finalization.md` applies verbatim; feel-tunables are the 0.6 stale
dim (`PulseFieldEntry.staleOpacity`), the staleness/trend copy phrasing, and the 7-day
reconciliation window.

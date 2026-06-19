# Desire-Map (Phase 2) — Kickoff Context / Handoff

**Date:** 2026-06-16
**For:** the fresh chat starting the Desire-Map work (roadmap Phase 2 — "the magic moment").
**Read this first.** It carries forward what the Pairing week (P1–P5, now complete) established, plus the verified prod facts and gotchas so you don't re-derive them. `CLAUDE.md` + `MEMORY.md` auto-load — this supplements them. Verify any prod claim against the live DB before acting; true on 2026-06-16.

---

## Where things stand
- **Pairing P1–P5 complete + device-verified.** A real couple exists in prod: couple **`e1f6d035`** = Bryan (profile `ff9cec3b`, auth `4f69…`) + Mylena (profile `34874fdd`, auth `6a7f…`). Both onboarded (local profiles exist), both have remote names. **Use this couple to test the reveal end-to-end** (two phones).
- **Backend is secure + reproducible:** repo==prod (single baseline migration `20260101000000`), RLS solid on all tables, anon locked out of existing + future tables. Migration history is clean — don't re-tangle it.

## Critical conventions — don't re-trip these
1. **Profile id vs auth id (the FK-class bug that broke pairing for months).** `desire_ratings.user_id`, `desire_matches.couple_id`, `couples.user_a/user_b` are FKs to **`user_profiles.id` (PROFILE ids)**, never auth uids. ✅ `DesireSyncService.syncRatings` already does this right (`ProfileService.ensureProfileExists(authId:)` → profile id before insert; see `DesireSyncService.swift:129`). Any new desire write or edge function MUST resolve the profile id first.
2. **Migrations via the CLI, not MCP.** Apply schema with **`supabase db push`** (CLI is linked). Do **NOT** use the MCP `apply_migration` tool — it records server-side timestamps that mismatch local filenames and re-tangles history (we just spent the end of the pairing session untangling exactly that). New tables auto-lock anon (P5d revoked anon from postgres default privileges), but verify with `get_advisors`.
3. **Couple-scoped writes are server-side only.** `couples` and `desire_matches` have **no working client INSERT/UPDATE policy** → only the service role (edge functions) writes them, exactly like `rapid-task` / `get-partner`. **D3 (match computation) MUST be a service-role edge function.**
4. **OB data is local-only.** The rich onboarding profile lives in **local SwiftData**; remote `user_profiles` only has `auth_id` + defaults + link fields + (P3) `name`/`pronouns`. If the reveal needs other profile signals server-side, they are NOT synced — plan for it.

## Verified prod schema (the shapes D2/D3/D4 must hit)
- **`desire_ratings`**: `id uuid, user_id uuid (=PROFILE id), desire_item_id text, rating text, created_at`. **0 rows** today. RLS (post-P5a): owner SELECT/INSERT/UPDATE by profile id, scoped to `authenticated`.
- **`desire_matches`**: `id uuid, couple_id uuid, desire_item_id text, alignment_level text, partner_a_value text, partner_b_value text, gap_size int, bridge_card_id text, created_at`. RLS: 1 SELECT policy ("Partners can view kink matches", couple-scoped). **No client write → service-role only.**
- So **D3** = a service-role edge fn: resolve caller's couple → both members' profile ids → read both sides' `desire_ratings` → per `desire_item_id` compute `alignment_level` + `gap_size` (+ optional `bridge_card_id`) → write `desire_matches`. (The column shape tells you exactly what to produce.)

## The reveal is the magic moment (Build Protocol)
- **D4 (reveal/compare UI) is THE premium beat.** Per Build Protocol + memory: build a **felt prototype** (timing/motion) BEFORE writing Swift — "a held breath releasing," a spectrum prism unveiling alignment, never a table of rows. Reuse PrismView's visual language.
- **Reuse the P3 partner-read path:** `get-partner` edge fn + `PairingStore.refreshPartner` / `partnerDisplayName` already deliver the partner's name with a fallback. The reveal can reuse this for partner identity.

## D1–D5 (roadmap) + open questions to settle with Bryan
- **D1** — route + rebind the rater to the real model.
- **D2** — wire `DesireSyncService` (ratings → Supabase). The Pairing-P2 dependency (a profile row exists) is now **satisfied**. ⚠️ Verify whether `syncRatings` actually has a **live caller** (the rater UI) or is orphaned the way `syncProfileToSupabase` was — that's the real work of D2.
- **D3** — match-computation **service-role edge function** (shape above). Open: does compare require BOTH partners complete, or show partial/waiting?
- **D4** — reveal/compare UI (magic moment). **Feel-proto first.** Open: solo "view my completed map" surface in V1, or only rate-then-reveal?
- **D5** — Map tab houses the compare. ⚠️ `MapView` today is a **"temporary P2 test harness"** (just renders `PairingSettingsView`). Also note tension to reconcile with Bryan: memory `[[map_tab_direction]]` frames the Map as an **individual "Your Mirror" dashboard** (Pulse hero + the Vault), whereas roadmap D5 says "Map houses the couple compare." Clarify before building.

## Process / Bryan's working style
- Bryan **runs the app on device**; Claude compile-verifies (`xcodebuild`) only — no sim runs (`[[feedback_no_sim_runs]]`).
- **Build Protocol:** named segments, one thing each, device-verified done-condition (not "build succeeds"), **feel-before-Swift** for any motion.
- **Feedback:** don't ask whether he's wrapping up / assume time of day (`[[feedback_dont_ask_wrapping_up]]`); surface real choices and let him confirm (`[[feedback_ask_dont_assume_confidence]]`); he tests couple features on two phones (his + Mylena's).
- Monetization gate for later: the **Desire Map reveal is the primary paywall** (`[[monetization_paywall_spec]]`) — D-work is scaffolding-only on entitlements; the reveal *gate* ships in M-week. Entitlements must be service-role-only (`2026-06-16-m1-entitlement-security-rule.md`).

## Pointers
- Roadmap: `docs/roadmap/vayl-build-roadmap.html` (Phase 2 = `desire`, now `active`; current pointer = `D1`).
- Pairing spec (done): `2026-06-15-pairing-implementation-spec.md`. Follow-ups: `2026-06-16-pairing-relink-spec.md`, `2026-06-16-m1-entitlement-security-rule.md`.
- Memories: `[[supabase_security_posture]]`, `[[backend_app_reconciliation]]` (auth-id vs profile-id), `[[map_tab_direction]]`, `[[project_curated_session_system]]`, `[[v1_strategic_positioning]]`.
- Edge fns live: `rapid-task` (create-couple), `get-partner`. Dead/orphaned: `create-pair`, `lookup-code`.

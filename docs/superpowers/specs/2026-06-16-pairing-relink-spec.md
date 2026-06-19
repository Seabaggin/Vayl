# Pairing — Re-link on Reinstall / New Device (P-relink)

**Date:** 2026-06-16
**Status:** Not started. Surfaced during P3 device testing (2026-06-16).
**Parent:** [`2026-06-15-pairing-implementation-spec.md`](2026-06-15-pairing-implementation-spec.md) — the pairing hinge (P1–P5 complete).

---

## Problem

Local link state is restored **only** from on-device storage; there is **no remote→local restore**. So a delete+reinstall (or a new phone) returns a user who is still linked **in the database** as **unlinked in the app**, with no clean recovery path.

Specifics:
- `AppState.linkState` / `AppState.coupleId` are read from **UserDefaults** at init (`AppState.swift` ~104–133). UserDefaults is wiped on app delete.
- `UserProfile.isLinked` / `coupleId` / `linkedAt` live in **SwiftData** (`Application Support/Vayl.store`), also wiped on delete.
- `PairingStore.persistLink(coupleId:)` is the **only** writer of local link state, and it runs only during an active pairing flow.
- Nothing reads the remote `user_profiles.couple_id` back into local state on sign-in.
- Re-pairing doesn't recover it: `rapid-task` rejects with **409 "already paired"** because the profile still has `couple_id` set remotely.

**Net:** a real user who reinstalls or upgrades phones loses their couple link in-app despite being linked in prod, and can't re-establish it. For a couples app where the link is the whole product, this is a launch blocker for the reinstall/upgrade path.

> Observed 2026-06-16: Mylena's phone showed "Linked with Bryan" after a reinstall — *unexplained by the code* (likely her reinstall didn't fully clear UserDefaults). That ambiguity is exactly why this needs a deliberate restore path **and** a deliberate reinstall test.

---

## Verified context (2026-06-16)

- Remote `user_profiles` has `couple_id` (uuid, set on linked profiles), `is_linked` (bool), `linked_at`. Confirmed populated for the live couple `e1f6d035`.
- `ProfileService.SupabaseProfile` does **not** currently decode `couple_id` (its CodingKeys omit it) — a read path must be added.
- `AuthService.ensureRemoteProfile()` (added in P2) already runs post-sign-in and is the natural restore hook.
- In the onboarding-first routing, onboarding (→ local `UserProfile`) happens **before** sign-in, so a local profile exists to stamp.

---

## Approach

On confirmed sign-in (after the remote row exists), read the remote `couple_id` for the caller's `auth_id`. If it's set **and** the local `UserProfile` isn't linked, restore local link state (`coupleId`, `isLinked`, `linkedAt`) + mirror into `AppState` — reusing/extending `PairingStore.persistLink`'s logic. Validate the couple still exists (a stale `couple_id` pointing at a deleted couple must not mark the user linked).

---

## Segments

| # | Does (one thing) | Done — on device | May not touch |
|---|---|---|---|
| **R1** | Read remote `couple_id`/`is_linked` for the current auth_id | Returns the live couple_id for a linked user | pairing UI, schema, edge fns |
| **R2** | Restore local link state on sign-in if remote-linked + local-unlinked | Reinstall a linked phone → after sign-in the app shows linked (+ partner name via P3) with no re-pairing | edge fns, schema |

**Files:** `ProfileService.swift` (read couple_id — add to `SupabaseProfile` or a scoped query), `AuthService.swift` (restore hook) or a new `PairingStore.restoreLinkFromRemote()` the hook calls, `AppState.swift` (mirror).

**Done (device):** reinstall a phone that's linked in prod → sign in → the app shows the couple as linked (and the partner's name) with no re-pairing and no 409.

---

## Constraints

- Identity/pairing layer only. **No edge-fn or schema change** (`couple_id` already exists remotely).
- Idempotent: if local is already linked, no-op.
- Architecture: a Service reads remote; a Store writes local SwiftData. `AuthService` should route through `PairingStore`/`SyncManager` rather than writing SwiftData directly, to keep the layer clean.

---

## Open questions (Bryan)

- Restore inside `AuthService.ensureRemoteProfile`, or a dedicated `PairingStore.restoreLinkFromRemote()` called from the launch/sign-in hook?
- If the remote `couple_id` points at a couple that no longer exists → self-heal (clear the remote link too) or just skip?
- Should re-pairing **also** be unblocked (let an already-paired-but-locally-unlinked user re-attach) as a fallback to the auto-restore?

---

## References
- Parent pairing spec — P5 status + the "reinstall/new-device relink gap" note.
- Memory: `[[pairing_p4_and_local_profile]]`, `[[pairing_p2_profile_creation]]`.

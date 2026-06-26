# Desire Map Backend Reconciliation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the live Supabase backend and the Swift read sites into line with the final Desire Map flow, collapsing reveal-state onto two couple truths + one per-user truth, and fixing the latent bug where a paid couple's unlock is invisible in Home / Map / Vault.

**Architecture:** Server-authoritative / online-first. Reveal is three states: **Available** = `desire_map_status.bothComplete`; **Unlocked** = `couples.access_tier == 'core'` (surfaced as `EntitlementStore.isCore`, mirrored locally as `Couple.canRevealDesireMap`); **Seen** = per-user `desire_reveal_progress` row (own-user RLS). Display rule everywhere: `shown = isCore || isFreeReveal`. Privacy boundary is partner-vs-partner via RLS, not app-vs-server.

**Tech Stack:** Supabase (Postgres 17, project `ynhjlabjzauamntbyxdp`), Deno/TypeScript edge functions, Swift 6 / SwiftUI / SwiftData, `supabase-swift`.

**Source spec:** `docs/superpowers/specs/2026-06-26-desire-map-backend-reconciliation-design.md` (read it first).

**Deliberate deviation from spec §5.4:** the spec says "edit the server→local match sync." Investigation found **no such sync exists** (the local `DesireMatch` @Model is only ever instantiated in a preview). Per the online-first stance and the `DesireRevealStore` precedent, Map/Vault will **read server matches directly** via `DesireSyncService.fetchMatches` rather than a newly-built local mirror. The local `DesireMatch` @Model is left in place (it backs a `Couple` relationship) but is no longer read for display; its removal belongs to the spec §7 mirror-cleanup pass.

**Verification reality (per CLAUDE.md build protocol + memory):** Swift "tests" here = `xcodebuild` compiles clean; behavior is confirmed by Bryan on device, not by Claude. Backend "tests" = SQL assertions + advisors + a smoke invocation. There is no XCTest harness wired for these paths, so do not invent one; verify by compile + on-device gate (Task 9).

**Commit discipline:** one commit per task. The branch already has unrelated in-progress files; `git add` only the paths each task names. Never `git add -A`.

---

## File / surface map

| Surface | Change |
|---|---|
| `supabase/migrations/20260626000000_desire_map_reveal_state_collapse.sql` | **Create** — drop 6 dead/vestigial columns, create `desire_reveal_progress` + RLS |
| `supabase/functions/compute-desire-matches/index.ts` | Stop writing dropped columns |
| `supabase/functions/create-pair/index.ts`, `rapid-task/index.ts` | Drop `matches_revealed` write |
| `Vayl/Core/Services/DesireSyncService.swift` | Trim DTOs + selects; add `fetchRevealProgress` + `markRevealSeen` |
| `Vayl/Features/Map/MapStore.swift` | Read server matches; gate on `canRevealDesireMap` |
| `Vayl/Features/Map/Vault/VaultStore.swift` | Same |
| `Vayl/Features/Home/Store/HomeStore.swift` | `revealDone` → Seen; repoint `desireMapState` inputs |
| `Vayl/Features/Desire Map/Store/DesireRevealStore.swift` | Write Seen on open |
| `Vayl/Core/Models/DesireMatch.swift` | Drop `revealedAt` / `isRevealed` |
| `Vayl/Core/Models/Couple.swift` | Drop `matchesRevealed` + `desireMapRevealedAt` |
| `Vayl/Core/Models/Enums/AppDesireEnums.swift` | Fix `notForMe` doc comment |

---

## Task 1: Database migration

**Files:**
- Create: `supabase/migrations/20260626000000_desire_map_reveal_state_collapse.sql`

- [ ] **Step 1: Write the migration file** with exactly this content:

```sql
begin;

-- desire_matches: drop vestigial partner-raw + gap (privacy now structural) and dead revealed_at
alter table public.desire_matches
  drop column if exists partner_a_value,
  drop column if exists partner_b_value,
  drop column if exists gap_size,
  drop column if exists revealed_at;

-- desire_map_status: drop dead unlock mirror (derive from couples.access_tier / core_unlocked_at)
alter table public.desire_map_status
  drop column if exists full_reveal_unlocked,
  drop column if exists full_reveal_at;

-- couples: drop dead matches_revealed (redundant with access_tier)
alter table public.couples
  drop column if exists matches_revealed;

-- per-user reveal viewing state ("Seen"), server-authoritative + benign.
-- keyed (user_id, couple_id) so a re-pair replays the reveal for the new map.
-- own-user RLS: a person reads/writes ONLY their own row.
create table if not exists public.desire_reveal_progress (
  user_id             uuid not null references public.user_profiles(id) on delete cascade,
  couple_id           uuid not null references public.couples(id) on delete cascade,
  free_reveal_seen_at timestamptz,
  full_reveal_seen_at timestamptz,
  updated_at          timestamptz not null default now(),
  primary key (user_id, couple_id)
);
alter table public.desire_reveal_progress enable row level security;
create policy "own reveal progress - select" on public.desire_reveal_progress
  for select to authenticated
  using (user_id in (select id from public.user_profiles where auth_id = auth.uid()));
create policy "own reveal progress - insert" on public.desire_reveal_progress
  for insert to authenticated
  with check (user_id in (select id from public.user_profiles where auth_id = auth.uid()));
create policy "own reveal progress - update" on public.desire_reveal_progress
  for update to authenticated
  using (user_id in (select id from public.user_profiles where auth_id = auth.uid()));

commit;
```

- [ ] **Step 2: Apply it** via the Supabase MCP `apply_migration` tool:
  - `project_id`: `ynhjlabjzauamntbyxdp`
  - `name`: `desire_map_reveal_state_collapse`
  - `query`: the SQL above
  - (CLI alternative: `supabase db push` after placing the file, against project ref `ynhjlabjzauamntbyxdp`.)

- [ ] **Step 3: Verify the schema** with `execute_sql` (project `ynhjlabjzauamntbyxdp`):

```sql
select
  (select count(*) from information_schema.columns
     where table_name='desire_matches'
       and column_name in ('partner_a_value','partner_b_value','gap_size','revealed_at')) as matches_dead,
  (select count(*) from information_schema.columns
     where table_name='desire_map_status'
       and column_name in ('full_reveal_unlocked','full_reveal_at')) as status_dead,
  (select count(*) from information_schema.columns
     where table_name='couples' and column_name='matches_revealed') as couples_dead,
  (select count(*) from information_schema.tables where table_name='desire_reveal_progress') as progress_table,
  (select count(*) from pg_policies where tablename='desire_reveal_progress') as progress_policies;
```

Expected: `matches_dead=0, status_dead=0, couples_dead=0, progress_table=1, progress_policies=3`.

- [ ] **Step 4: Run advisors** — `get_advisors(project_id, type:"security")` then `type:"performance"`. Expected: no new errors referencing the dropped columns or the new table (a "policy uses auth.uid() per-row" perf note on the new policies is acceptable and matches the existing tables' pattern).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260626000000_desire_map_reveal_state_collapse.sql
git commit -m "feat(db): collapse desire-map reveal state; add desire_reveal_progress"
```

---

## Task 2: Edge function `compute-desire-matches`

**Files:**
- Modify: `supabase/functions/compute-desire-matches/index.ts`

- [ ] **Step 1: Remove the dead status keys.** In the `status` object (currently ~lines 96-106), delete these two lines:

```ts
      full_reveal_unlocked: existingStatus?.full_reveal_unlocked ?? false,
      full_reveal_at: existingStatus?.full_reveal_at ?? null,
```

Keep `couple_id`, `track`, `partner_a_complete`, `partner_b_complete`, `partner_a_completed_at`, `partner_b_completed_at`, `waiting_state_since`.

- [ ] **Step 2: Remove the dead match-row keys.** In the `rows.push({ ... })` object (currently ~lines 137-151), delete these four lines:

```ts
        partner_a_value: null,
        partner_b_value: null,
        gap_size: null,
        revealed_at: null,
```

Keep `couple_id`, `desire_item_id`, `alignment_level`, `bridge_card_id`, `is_free_reveal`, `created_at`. Leave the two-tier `matchType()` logic and the one-mutual-preferred `is_free_reveal` pick unchanged.

- [ ] **Step 3: Redeploy** via the Supabase MCP `deploy_edge_function` tool (`project_id` `ynhjlabjzauamntbyxdp`, `slug` `compute-desire-matches`, the edited file). CLI alternative: `supabase functions deploy compute-desire-matches --project-ref ynhjlabjzauamntbyxdp`.

- [ ] **Step 4: Smoke-check** — confirm the deploy reports ACTIVE and the new version number incremented (`list_edge_functions`). A full functional check happens on device in Task 9 (it requires two completed maps).

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/compute-desire-matches/index.ts
git commit -m "feat(edge): stop writing dropped reveal-state columns in compute-desire-matches"
```

---

## Task 3: Edge functions `create-pair` + `rapid-task`

**Files:**
- Modify: `supabase/functions/create-pair/index.ts` (~line 100)
- Modify: `supabase/functions/rapid-task/index.ts` (~line 95)

- [ ] **Step 1: Remove the `matches_revealed` write** from the `couples` insert object in BOTH files. Delete the line:

```ts
        matches_revealed: false,
```

Leave every other column in those inserts unchanged.

- [ ] **Step 2: Redeploy both** (`deploy_edge_function` for `create-pair`, then `rapid-task`; or `supabase functions deploy create-pair --project-ref ynhjlabjzauamntbyxdp` and likewise `rapid-task`).

- [ ] **Step 3: Verify** both report ACTIVE with incremented versions (`list_edge_functions`).

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/create-pair/index.ts supabase/functions/rapid-task/index.ts
git commit -m "feat(edge): drop dead matches_revealed write from pairing functions"
```

---

## Task 4: `DesireSyncService` — trim DTOs, add reveal-progress I/O

**Files:**
- Modify: `Vayl/Core/Services/DesireSyncService.swift`

- [ ] **Step 1: Trim `SupabaseDesireMatch`.** First check usage:

```bash
grep -rn "SupabaseDesireMatch" Vayl
```

If it appears ONLY in its own definition (lines ~75-97), delete the whole struct. If it has other callers, instead delete the `partnerAValue`, `partnerBValue`, `gapSize` properties and their three `CodingKeys` cases.

- [ ] **Step 2: Trim the matches read.** Change the `fetchMatches` select string (line ~185) to drop `revealed_at`:

```swift
            .select("id, desire_item_id, alignment_level, is_free_reveal, bridge_card_id")
```

- [ ] **Step 3: Trim `DesireMatchRow`** (lines ~204-223) to remove `revealedAt` + `isRevealed`. Result:

```swift
struct DesireMatchRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let desireItemId: String
    let alignmentLevel: String     // "mutual" | "adjacent"
    let isFreeReveal: Bool
    let bridgeCardId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case desireItemId = "desire_item_id"
        case alignmentLevel = "alignment_level"
        case isFreeReveal = "is_free_reveal"
        case bridgeCardId = "bridge_card_id"
    }

    var matchType: DesireMatchType? { DesireMatchType(rawValue: alignmentLevel) }
}
```

- [ ] **Step 4: Trim the status read.** Change the `fetchStatus` select (line ~195) to drop `full_reveal_unlocked`:

```swift
            .select("track, partner_a_complete, partner_b_complete")
```

- [ ] **Step 5: Trim `DesireMapStatusRow`** (lines ~226-240) to remove `fullRevealUnlocked` (the property and its CodingKey). Keep `track`, `partnerAComplete`, `partnerBComplete`, and the `bothComplete` computed var.

- [ ] **Step 6: Add reveal-progress I/O.** Append to the service (own-user RLS makes these safe direct client calls — no edge fn):

```swift
    // MARK: - Reveal progress (per-user "Seen"; own-user RLS)

    /// This user's reveal viewing state for the couple, or nil if they have not opened it yet.
    func fetchRevealProgress(coupleId: UUID) async throws -> RevealProgressRow? {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let rows: [RevealProgressRow] = try await supabase
            .from("desire_reveal_progress")
            .select("free_reveal_seen_at, full_reveal_seen_at")
            .eq("user_id", value: profileId.uuidString)
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    /// Stamp that this user watched the reveal. `full == false` stamps the free reveal;
    /// `full == true` stamps the post-unlock full reveal. Upsert on (user_id, couple_id);
    /// only the named column is written, so stamping one never clears the other.
    func markRevealSeen(coupleId: UUID, full: Bool) async throws {
        let authId = try await supabase.auth.session.user.id
        let profileId = try await profileService.ensureProfileExists(authId: authId)
        let now = isoFormatter.string(from: Date())
        var row: [String: String] = [
            "user_id": profileId.uuidString,
            "couple_id": coupleId.uuidString,
            "updated_at": now,
        ]
        row[full ? "full_reveal_seen_at" : "free_reveal_seen_at"] = now
        try await supabase
            .from("desire_reveal_progress")
            .upsert(row, onConflict: "user_id,couple_id")
            .execute()
    }
}

/// This user's reveal viewing state, client-safe (own row only).
struct RevealProgressRow: Decodable, Sendable {
    let freeRevealSeenAt: String?
    let fullRevealSeenAt: String?

    enum CodingKeys: String, CodingKey {
        case freeRevealSeenAt = "free_reveal_seen_at"
        case fullRevealSeenAt = "full_reveal_seen_at"
    }

    var hasSeenFree: Bool { freeRevealSeenAt != nil }
    var hasSeenFull: Bool { fullRevealSeenAt != nil }
}
```

> Note: the trailing `}` above closes the `DesireSyncService` class — place the new methods inside the class and `RevealProgressRow` after it. Match the existing file's brace structure.

- [ ] **Step 7: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: `BUILD SUCCEEDED`. (Adjust the simulator name to one installed locally: `xcrun simctl list devices available`.)

- [ ] **Step 8: Commit**

```bash
git add "Vayl/Core/Services/DesireSyncService.swift"
git commit -m "feat(desire): trim match/status DTOs; add reveal-progress read/write"
```

---

## Task 5: Map + Vault read server matches, gate on `canRevealDesireMap`

The display rule is `shown = canRevealDesireMap || isFreeReveal`. Both stores currently read the empty local `DesireMatch` mirror; switch them to the server rows. `Couple.canRevealDesireMap` (`entitlementTier != .free`) is the local isCore mirror maintained by `EntitlementStore`.

**Files:**
- Modify: `Vayl/Features/Map/MapStore.swift` (`drawnTags` ~line 181-201, `loadUs` ~line 225-259)
- Modify: `Vayl/Features/Map/Vault/VaultStore.swift` (`loadDesire` ~line 40-86)

- [ ] **Step 1: MapStore — fetch server matches in the async load path.** Wherever `loadUs`/`loadMeCard` are driven (the store's async `load`), fetch once:

```swift
let matchRows: [DesireMatchRow]
if let coupleId = appState.coupleId {
    matchRows = (try? await DesireSyncService.shared.fetchMatches(coupleId: coupleId)) ?? []
} else {
    matchRows = []
}
```

Thread `matchRows` (and the resolved `canReveal` below) into `loadUs` and `drawnTags` instead of fetching local `DesireMatch`.

- [ ] **Step 2: MapStore — resolve the gate from the local Couple mirror.**

```swift
let canReveal: Bool = {
    guard let coupleId = appState.coupleId,
          let couple = try? context.fetch(
              FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
          ).first else { return false }
    return couple.canRevealDesireMap
}()
```

- [ ] **Step 3: MapStore — rewrite the `loadUs` match loop** (replaces the `FetchDescriptor<DesireMatch>` block at ~243-256):

```swift
var revealed: [AlignItem] = []
var locked = 0
let items = (try? ContentLoader.loadDesireItems()) ?? []
let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
for row in matchRows {
    let shown = canReveal || row.isFreeReveal
    if shown {
        revealed.append(AlignItem(
            id: row.desireItemId,
            name: nameById[row.desireItemId] ?? row.desireItemId,
            isMutual: row.matchType == .mutual
        ))
    } else {
        locked += 1
    }
}
alignItems = revealed.sorted { $0.isMutual && !$1.isMutual }
lockedAlignCount = locked
```

- [ ] **Step 4: MapStore — rewrite `drawnTags` shared-set** (replaces the `FetchDescriptor<DesireMatch>` block at ~190-194). Change the function to take `matchRows: [DesireMatchRow]` and `canReveal: Bool` instead of resolving them from `context`:

```swift
var sharedIds = Set<String>()
for row in matchRows where (canReveal || row.isFreeReveal) && row.matchType == .mutual {
    sharedIds.insert(row.desireItemId)
}
```

- [ ] **Step 5: VaultStore — make `loadDesire` use server matches.** If `loadDesire` is synchronous, convert it (or its caller) so it can `await DesireSyncService.shared.fetchMatches(coupleId:)`; fetch the local Couple for `canRevealDesireMap`. Replace the `FetchDescriptor<DesireMatch>` loop (~69-83) with:

```swift
var revealed: [MapStore.AlignItem] = []
var locked = 0
if let coupleId = appState.coupleId {
    let canReveal = (try? context.fetch(
        FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
    ).first)?.canRevealDesireMap ?? false
    let rows = (try? await DesireSyncService.shared.fetchMatches(coupleId: coupleId)) ?? []
    let items = (try? ContentLoader.loadDesireItems()) ?? []
    let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    for row in rows {
        if canReveal || row.isFreeReveal {
            revealed.append(MapStore.AlignItem(
                id: row.desireItemId,
                name: nameById[row.desireItemId] ?? row.desireItemId,
                isMutual: row.matchType == .mutual
            ))
        } else {
            locked += 1
        }
    }
}
align = revealed.sorted { $0.isMutual && !$1.isMutual }
lockedAlignCount = locked
```

- [ ] **Step 6: Build-verify** (same `xcodebuild` command as Task 4 Step 7). Expected `BUILD SUCCEEDED`. Resolve any call-site fallout from `drawnTags`/`loadDesire` signature changes.

- [ ] **Step 7: Commit**

```bash
git add "Vayl/Features/Map/MapStore.swift" "Vayl/Features/Map/Vault/VaultStore.swift"
git commit -m "feat(map): read server desire matches; gate display on canRevealDesireMap"
```

---

## Task 6: HomeStore — `revealDone` becomes Seen

`revealDone` feeds `GettingStarted.resolve` (the `.seeReveal` step). It must mean "this user has watched their reveal," sourced from `desire_reveal_progress`, NOT payment. Available (`bothComplete`) already drives reachability via `partnerMapComplete`.

**Files:**
- Modify: `Vayl/Features/Home/Store/HomeStore.swift` (`loadDesireStatus` ~line 76-83, plus the `desireMapState` computation ~line 100-145)

- [ ] **Step 1: Source `revealDone` from reveal progress.** In `loadDesireStatus`, replace line ~83 (`revealDone = status.fullRevealUnlocked`) with a progress fetch:

```swift
partnerMapComplete = status.bothComplete
let progress = try? await DesireSyncService.shared.fetchRevealProgress(coupleId: coupleId)
revealDone = progress?.hasSeenFree ?? false
```

- [ ] **Step 2: Repoint the `desireMapState` computation.** Read HomeStore's `desireMapState` computed property and repoint its inputs to the three real states (do NOT invent new enum cases — map onto the existing `DesireMapState`):
  - `.bothReady` / "reveal available" ← `partnerMapComplete && !revealDone` (both done, not yet seen).
  - `.freeRevealSeen` ← `revealDone` (has seen the free reveal).
  - `.fullyUnlocked` / `.revealed` ← the couple's `canRevealDesireMap` (isCore). Resolve `canReveal` the same way as Task 5 Step 2 (fetch the local Couple).
  - Remove any remaining reference to the deleted `status.fullRevealUnlocked`.

- [ ] **Step 3: Build-verify** (`xcodebuild`, expect `BUILD SUCCEEDED`).

- [ ] **Step 4: Commit**

```bash
git add "Vayl/Features/Home/Store/HomeStore.swift"
git commit -m "feat(home): revealDone reads per-user Seen, not the dropped unlock flag"
```

---

## Task 7: Write Seen when the reveal is opened

**Files:**
- Modify: `Vayl/Features/Desire Map/Store/DesireRevealStore.swift` (`load()` ~line 74-94)

- [ ] **Step 1: Stamp Seen at the end of a successful `load()`.** After `phase = matches.isEmpty ? .empty : .ready` (and only when there are matches and a couple), stamp the appropriate column:

```swift
phase = matches.isEmpty ? .empty : .ready
if !matches.isEmpty {
    let full = entitlements.isCore
    Task { try? await service.markRevealSeen(coupleId: coupleId, full: full) }
}
```

Rationale: opening the reveal while free → stamps `free_reveal_seen_at`; opening it while Core → stamps `full_reveal_seen_at`. Both are idempotent upserts; stamping one never clears the other.

- [ ] **Step 2: Build-verify** (`xcodebuild`, expect `BUILD SUCCEEDED`).

- [ ] **Step 3: Commit**

```bash
git add "Vayl/Features/Desire Map/Store/DesireRevealStore.swift"
git commit -m "feat(reveal): stamp per-user Seen on reveal open"
```

---

## Task 8: Drop dead local fields + fix the privacy comment

**Files:**
- Modify: `Vayl/Core/Models/DesireMatch.swift`
- Modify: `Vayl/Core/Models/Couple.swift`
- Modify: `Vayl/Core/Models/Enums/AppDesireEnums.swift`

- [ ] **Step 1: `DesireMatch.swift`** — remove `var revealedAt: Date?` (line ~38), its init assignment `self.revealedAt = nil` (line ~54), and the `isRevealed` computed var (lines ~60-62). Keep `isFreeReveal`, `matchType`, `bridgeCardId`. (The `freeRevealExample` preview at ~72 still compiles; leave it.)

- [ ] **Step 2: `Couple.swift`** — remove `var matchesRevealed: Bool` (line ~39) and `var desireMapRevealedAt: Date?` (line ~40), plus their init lines `self.matchesRevealed = false` and `self.desireMapRevealedAt = nil` (~81-82). Keep `canRevealDesireMap`, `entitlementTier`, `coreUnlockedAt`.

- [ ] **Step 3: Confirm no stragglers** reference the removed fields:

```bash
grep -rn "matchesRevealed\|desireMapRevealedAt\|\.isRevealed\|revealedAt" Vayl
```

Expected: no hits in app code (only this plan / the spec). Fix any that remain.

- [ ] **Step 4: `AppDesireEnums.swift`** — replace the `DesireRatingValue` doc comment (the block at lines ~58-64 claiming "notForMe ... NEVER leaves the device" with "Three enforcement layers") with the accurate posture:

```swift
/// How a partner rates a Desire Map item — a fixed 4-point weight (the displayed
/// answer copy is cohort-adaptive; only this stored weight crosses to matching).
/// All four weights sync to `desire_ratings`. `notForMe` is the boundary: it is
/// protected by own-only RLS (a partner cannot read your ratings) and excluded from
/// `desire_matches` by the edge function. It is obscured at the match layer, not
/// withheld at upload — the privacy boundary is partner-vs-partner, enforced by RLS.
```

- [ ] **Step 5: Build-verify** (`xcodebuild`, expect `BUILD SUCCEEDED`). SwiftData removing two stored properties is a lightweight schema change; if the local store fails to open in the simulator, delete the app from the sim and relaunch (acceptable in dev).

- [ ] **Step 6: Commit**

```bash
git add "Vayl/Core/Models/DesireMatch.swift" "Vayl/Core/Models/Couple.swift" "Vayl/Core/Models/Enums/AppDesireEnums.swift"
git commit -m "refactor(desire): drop dead reveal fields; correct notForMe privacy comment"
```

---

## Task 9: Full build + on-device verification gate

**This is the real "done" gate (CLAUDE.md build protocol). Bryan runs it on device.**

- [ ] **Step 1: Clean build** — `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' clean build`. Expected `BUILD SUCCEEDED`.

- [ ] **Step 2: Hand off the device script to Bryan.** On two paired devices (or the admin-grant path until M2 StoreKit lands):
  1. Both partners complete their Desire Map → `compute-desire-matches` writes `desire_matches` (verify with `execute_sql: select count(*), bool_or(is_free_reveal) from desire_matches where couple_id = '<id>'`).
  2. Open the reveal → the one free match shows; `desire_reveal_progress.free_reveal_seen_at` is stamped for the opener (verify per-user).
  3. Home "Getting Started" flips the `See what you share` step to done once the reveal is seen.
  4. Grant Core (admin path) → re-open: locked stars open; the **Map "Us" layer** and the **Vault** now list the shared desires (this is the bug that was invisible before).
  5. Re-rate one item → overlap quietly recomputes; unlock is NOT lost (couple stays Core).

- [ ] **Step 3: Bryan confirms the feel on device.** A segment is done when the feel is right, not when it compiles.

---

## Self-review notes (for the executor)

- **Line numbers drift** as you edit; they are anchors, not contracts. Confirm by symbol/string, not by line.
- **Do not** add XCTest files for these paths (no harness is wired; see VaylTests-not-synchronized constraint). Verification is compile + on-device.
- **Scope guard:** do not touch `waiting_state_since` / the 7-day timer (deferred), the mockup, `bridge_card_id`, or the Segment 3 discussion tool. Do not remove the local `DesireMatch` @Model type (it backs a `Couple` relationship; its removal is the spec §7 follow-on).
- **If `SupabaseDesireMatch` had other callers** (Task 4 Step 1), you trimmed fields instead of deleting; make sure those callers still compile.

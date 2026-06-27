# The Vault — Implementation Plan (Agreements · Event Log · Consent)

> **For agentic workers:** Use superpowers:executing-plans (inline) or superpowers:subagent-driven-development to implement this task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the three remaining Vault features on the foundation already in the tree: free synced **Agreements** (dual-lock, mutual approval to change), the free private/shared **Event Log**, and the **Consent exchange** ("open a conversation," a decline never discloses).

**Architecture:** Each feature follows the app's split: couple-scoped synced data behind couple RLS, private data behind user-scoped RLS, sensitive server-authoritative logic behind Edge Functions. UI replaces the forming-state placeholders inside `VaultSheet`. Spec: `docs/superpowers/specs/2026-06-24-vault-design.md`.

**Tech Stack:** SwiftUI + SwiftData (`@Model` + `SchemaV1`), Supabase Postgres (RLS, triggers, Edge Functions / Deno), the existing `DesireSyncService`/`SyncManager` patterns.

---

## Conventions for this plan (read once)

- **Verification = compile, not XCTest.** Each Swift task ends with:
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ```
  Feel + multi-device behaviour are verified by the human on device (checklists at each phase end).
- **Migrations touch the production `vayl` DB (`ynhjlabjzauamntbyxdp`).** Apply via the Supabase MCP `apply_migration`, but **show Bryan the SQL and get his go-ahead before each apply**, then run `get_advisors(type: security)` and confirm the new table reports no "RLS disabled / no policy" finding.
- **Git:** Bryan owns git. Commit points are marked as checkpoints; do not auto-commit unless he asks. Never `git add -A`; never commit `project.pbxproj`.
- **New `@Model`s** get added to `SchemaV1.models` in `Vayl/App/ModelContainer.swift` on the same change. `AppMigrationPlan.stages` stays empty (no real users yet).
- **RLS templates** (from the live schema): couple-scoped = `couple_id IN (SELECT couples.id FROM couples WHERE couples.user_a IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()) OR couples.user_b IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid()))`; user-scoped = `<owner> IN (SELECT id FROM user_profiles WHERE auth_id = auth.uid())`.
- **Tier:** Agreements, Event Log, and the consent mechanic are FREE; only the full Desire Map reveal stays paid (already wired via `PaywallSheet(entry: .reveal)`).
- **No em dashes** in any user-facing copy.

## Current state (do not rebuild)

Vault Segment 1 is live: `Features/Map/Vault/VaultStore.swift` (segment enum `.desire/.agreements/.log`, Desire summary), `Vault/VaultSheet.swift` (header + `LearnSegmented` + section switch; Agreements and Log are `MapEmptyState` placeholders), `Vault/Components/VaultDesireSection.swift` (your map + where you align + "Open a conversation" placeholder). `MapView` presents `VaultSheet` + `PaywallSheet(.reveal)`. This plan fills the three placeholders.

---

## Phase A — Agreements (free, synced, dual-lock)

**Model of the dual lock:** an `agreements` table holds settled agreements; an `agreement_proposals` table holds pending create/edit/retire proposals. You *propose* (INSERT, proposer = you); your partner *decides* (UPDATE, enforced by RLS to be the non-proposer). An approved proposal is applied to `agreements` by a `SECURITY DEFINER` trigger, so neither client needs direct write to `agreements` and the change is atomic. Mutual approval is the "stop changing it every two seconds" friction.

**File structure:**
- DB: migration `vault_agreements` (two tables + RLS + trigger).
- Create `Vayl/Core/Services/AgreementsService.swift` (async fetch + propose/decide, mirrors `DesireSyncService`).
- Modify `Vayl/Features/Map/Vault/VaultStore.swift` (agreements state + load + actions).
- Create `Vayl/Features/Map/Vault/Components/VaultAgreementsSection.swift`.
- Modify `Vayl/Features/Map/Vault/VaultSheet.swift` (`.agreements` case → the new section).

### Task A1: Agreements migration (show Bryan, then apply)

- [ ] **Step 1: Review this SQL with Bryan, then `apply_migration(name: "vault_agreements")`:**

```sql
create table public.agreements (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  text text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.agreements enable row level security;

create table public.agreement_proposals (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  target_agreement_id uuid references public.agreements(id),  -- null = propose-create
  action text not null check (action in ('create','edit','retire')),
  proposed_text text,                                         -- for create/edit
  proposed_by uuid not null references public.user_profiles(id),
  status text not null default 'pending' check (status in ('pending','approved','declined')),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
alter table public.agreement_proposals enable row level security;

-- helper: my profile ids for the current auth user
-- (inline in policies below to match the existing convention)

-- agreements: couple can read; writes happen only via the trigger (no direct client write)
create policy "Partners read agreements" on public.agreements
  for select to authenticated
  using (couple_id in (select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- proposals: couple can read
create policy "Partners read proposals" on public.agreement_proposals
  for select to authenticated
  using (couple_id in (select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- propose: insert allowed if proposer is me and I am in the couple
create policy "Partners propose" on public.agreement_proposals
  for insert to authenticated
  with check (
    proposed_by in (select id from user_profiles where auth_id = auth.uid())
    and couple_id in (select couples.id from couples
      where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
         or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));

-- decide: the NON-proposer updates pending -> approved/declined (the dual lock)
create policy "Partner decides" on public.agreement_proposals
  for update to authenticated
  using (
    status = 'pending'
    and proposed_by not in (select id from user_profiles where auth_id = auth.uid())
    and couple_id in (select couples.id from couples
      where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
         or couples.user_b in (select id from user_profiles where auth_id = auth.uid())))
  with check (status in ('approved','declined'));

-- apply an approved proposal to agreements, atomically, as definer
create or replace function public.apply_agreement_proposal()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status = 'pending' then
    if new.action = 'create' then
      insert into public.agreements (couple_id, text) values (new.couple_id, new.proposed_text);
    elsif new.action = 'edit' then
      update public.agreements set text = new.proposed_text, updated_at = now()
        where id = new.target_agreement_id;
    elsif new.action = 'retire' then
      update public.agreements set is_active = false, updated_at = now()
        where id = new.target_agreement_id;
    end if;
    new.decided_at = now();
  elsif new.status = 'declined' and old.status = 'pending' then
    new.decided_at = now();
  end if;
  return new;
end $$;

create trigger trg_apply_agreement_proposal
  before update on public.agreement_proposals
  for each row execute function public.apply_agreement_proposal();
```

- [ ] **Step 2: Run `get_advisors(type: security)`** and confirm no new "RLS disabled" / "no policy" finding for `agreements` or `agreement_proposals`.

### Task A2: AgreementsService

- [ ] **Step 1: Create `Vayl/Core/Services/AgreementsService.swift`** (mirror `DesireSyncService`'s supabase usage):

```swift
import Foundation

struct AgreementRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let isActive: Bool
    enum CodingKeys: String, CodingKey { case id, text, isActive = "is_active" }
}

struct AgreementProposalRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let targetAgreementId: UUID?
    let action: String          // create | edit | retire
    let proposedText: String?
    let proposedBy: UUID
    let status: String
    enum CodingKeys: String, CodingKey {
        case id, action, status
        case targetAgreementId = "target_agreement_id"
        case proposedText = "proposed_text"
        case proposedBy = "proposed_by"
    }
}

@MainActor
final class AgreementsService {
    // Reuse the app's shared supabase client (same accessor DesireSyncService uses).
    func fetchActive(coupleId: UUID) async throws -> [AgreementRow] {
        try await supabase.from("agreements")
            .select("id, text, is_active")
            .eq("couple_id", value: coupleId.uuidString)
            .eq("is_active", value: true)
            .execute().value
    }
    func fetchPendingProposals(coupleId: UUID) async throws -> [AgreementProposalRow] {
        try await supabase.from("agreement_proposals")
            .select("id, target_agreement_id, action, proposed_text, proposed_by, status")
            .eq("couple_id", value: coupleId.uuidString)
            .eq("status", value: "pending")
            .execute().value
    }
    func propose(coupleId: UUID, proposerId: UUID, action: String,
                 targetAgreementId: UUID?, text: String?) async throws {
        try await supabase.from("agreement_proposals").insert([
            "couple_id": coupleId.uuidString,
            "proposed_by": proposerId.uuidString,
            "action": action,
            "target_agreement_id": targetAgreementId?.uuidString as Any,
            "proposed_text": text as Any
        ]).execute()
    }
    func decide(proposalId: UUID, approve: Bool) async throws {
        try await supabase.from("agreement_proposals")
            .update(["status": approve ? "approved" : "declined"])
            .eq("id", value: proposalId.uuidString)
            .execute()
    }
}
```

> Before writing, grep `DesireSyncService.swift` for the exact `supabase` client accessor (global vs injected) and the real `insert`/`update` call shape, and match it. If the client uses a different builder signature, adapt these four calls to it.

- [ ] **Step 2: Compile.** Expected: BUILD SUCCEEDED.

### Task A3: VaultStore agreements state + actions

- [ ] **Step 1: Add to `VaultStore`** (new section + state + load + actions):

```swift
// MARK: - Agreements (Phase A)
struct AgreementVM: Identifiable { let id: UUID; let text: String }
struct ProposalVM: Identifiable {
    let id: UUID; let action: String; let proposedText: String?
    let targetId: UUID?; let mineToDecide: Bool   // true if partner proposed (I decide)
}
private(set) var safeWord: String = "red"
private(set) var agreements: [AgreementVM] = []
private(set) var proposals: [ProposalVM] = []
private let agreementsService = AgreementsService()

func loadAgreements(appState: AppState, context: ModelContext) async {
    guard let coupleId = appState.coupleId,
          let couple = try? context.fetch(
            FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })).first,
          let me = try? context.fetch(FetchDescriptor<UserProfile>()).first
    else { return }
    safeWord = couple.sharedSafeWord
    let active = (try? await agreementsService.fetchActive(coupleId: coupleId)) ?? []
    let pend = (try? await agreementsService.fetchPendingProposals(coupleId: coupleId)) ?? []
    agreements = active.map { AgreementVM(id: $0.id, text: $0.text) }
    proposals = pend.map {
        ProposalVM(id: $0.id, action: $0.action, proposedText: $0.proposedText,
                   targetId: $0.targetAgreementId, mineToDecide: $0.proposedBy != me.id)
    }
}

func proposeAgreement(_ text: String, appState: AppState, context: ModelContext) async {
    guard let coupleId = appState.coupleId,
          let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    try? await agreementsService.propose(coupleId: coupleId, proposerId: me.id,
        action: "create", targetAgreementId: nil, text: text)
    await loadAgreements(appState: appState, context: context)
}
func proposeEdit(_ id: UUID, newText: String, appState: AppState, context: ModelContext) async {
    guard let coupleId = appState.coupleId,
          let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    try? await agreementsService.propose(coupleId: coupleId, proposerId: me.id,
        action: "edit", targetAgreementId: id, text: newText)
    await loadAgreements(appState: appState, context: context)
}
func proposeRetire(_ id: UUID, appState: AppState, context: ModelContext) async {
    guard let coupleId = appState.coupleId,
          let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    try? await agreementsService.propose(coupleId: coupleId, proposerId: me.id,
        action: "retire", targetAgreementId: id, text: nil)
    await loadAgreements(appState: appState, context: context)
}
func decide(_ proposalId: UUID, approve: Bool, appState: AppState, context: ModelContext) async {
    try? await agreementsService.decide(proposalId: proposalId, approve: approve)
    await loadAgreements(appState: appState, context: context)
}
```

- [ ] **Step 2: Compile.** Expected: BUILD SUCCEEDED.

### Task A4: VaultAgreementsSection view

- [ ] **Step 1: Create `Vayl/Features/Map/Vault/Components/VaultAgreementsSection.swift`.** Structure (mirror `VaultDesireSection`'s card/`MapSectionHeader`/`MapEmptyState` idioms and tokens exactly):
  - **Safe word** card at top: `MapSectionHeader("Shared safe word")` + a `.vaylGlassCard(accent: AppColors.safetyAccent)` showing `store.safeWord` in `AppFonts.display(20, .bold)`.
  - **Pending proposals** (if any): for each `ProposalVM`, a row reading "X proposed: <text/retire>" with, when `mineToDecide`, two buttons "Not now" / "Approve" calling `store.decide(_:approve:...)`; when not mine to decide, "awaiting your partner."
  - **Active agreements** list in a `.vaylGlassCard`, each row = text + a small "Propose change" / "Retire" affordance opening an edit sheet (text field) that calls `proposeEdit`/`proposeRetire`.
  - **Add** affordance ("Propose an agreement") opening a `.vaylSheet` text editor calling `proposeAgreement`.
  - Empty state via `MapEmptyState(icon: "doc.text", headline: "No agreements yet", message: "Propose one. It becomes active once you both agree.")`.
  - Copy: no em dashes.

- [ ] **Step 2: Replace the `.agreements` placeholder in `VaultSheet.swift`** with `VaultAgreementsSection(store: store)` and add `.task`/`onChange` so `store.loadAgreements(...)` runs when the segment becomes `.agreements`. `VaultSheet` will need `appState` + `modelContext` from the environment (add `@Environment(AppState.self)` + `@Environment(\.modelContext)`).

- [ ] **Step 3: Compile.** Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Checkpoint (Bryan's call to commit).** Device check (two accounts): propose an agreement on A; it shows "awaiting partner" on A and as a decision on B; approve on B; it becomes active for both; edit + retire each require the partner's approval.

---

## Phase B — Event Log (free, private or shared)

**Storage:** one `event_log_entries` table holds both private and shared entries; a compound RLS policy makes private rows readable only by the author and shared rows readable by the couple. Per Bryan's call, **private entries are remote (backed up) but partner-unreadable** — remote does not mean not-private. Local `EventLogEntry` `@Model` is the source of truth and syncs up; the device pulls down your own + shared rows. (This supersedes the spec's `isSyncable == shared` line: all entries sync; RLS scopes who can read.)

**File structure:**
- DB: migration `vault_event_log` (table + compound RLS).
- Create `Vayl/Core/Models/Enums/EventLogEnums.swift` (`EventMood`, `EventTag`).
- Create `Vayl/Core/Models/EventLogEntry.swift` (`@Model`), register in `SchemaV1.models`.
- Create `Vayl/Core/Services/EventLogService.swift` (sync up/down).
- Modify `VaultStore.swift` (event log state + load + add/edit/delete).
- Create `Vayl/Features/Map/Vault/Components/VaultLogSection.swift` (timeline) and `Vayl/Features/Map/Vault/EventEntryEditor.swift` (the add/edit `.vaylSheet`).
- Modify `VaultSheet.swift` (`.log` case).

### Task B1: Event log migration (show Bryan, then apply)

- [ ] **Step 1: Review, then `apply_migration(name: "vault_event_log")`:**

```sql
create table public.event_log_entries (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.user_profiles(id),
  couple_id uuid references public.couples(id),     -- nullable; set on shared entries
  occurred_on date not null,
  title text not null,
  note text,
  mood text,
  tags jsonb not null default '[]'::jsonb,
  who text,
  visibility text not null default 'private' check (visibility in ('private','shared')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.event_log_entries enable row level security;

-- read: your own (any visibility) OR shared rows in your couple
create policy "Read own or shared log" on public.event_log_entries
  for select to authenticated
  using (
    author_id in (select id from user_profiles where auth_id = auth.uid())
    or (visibility = 'shared' and couple_id in (select couples.id from couples
        where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
           or couples.user_b in (select id from user_profiles where auth_id = auth.uid()))));

-- insert/update/delete: author only
create policy "Insert own log" on public.event_log_entries
  for insert to authenticated
  with check (author_id in (select id from user_profiles where auth_id = auth.uid()));
create policy "Update own log" on public.event_log_entries
  for update to authenticated
  using (author_id in (select id from user_profiles where auth_id = auth.uid()));
create policy "Delete own log" on public.event_log_entries
  for delete to authenticated
  using (author_id in (select id from user_profiles where auth_id = auth.uid()));
```

- [ ] **Step 2: `get_advisors(type: security)`** — confirm clean for `event_log_entries`.

### Task B2: Enums + `@Model`

- [ ] **Step 1: Create `Vayl/Core/Models/Enums/EventLogEnums.swift`:**

```swift
import SwiftUI

enum EventMood: String, CaseIterable, Codable, Identifiable {
    case light, good, mixed, tender, hard
    var id: String { rawValue }
    var label: String {
        switch self {
        case .light:  return "Light"
        case .good:   return "Good"
        case .mixed:  return "Mixed"
        case .tender: return "Tender"
        case .hard:   return "Hard"
        }
    }
}

enum EventTag: String, CaseIterable, Codable, Identifiable {
    case date, play, metamour, milestone, hardConvo, reconnection
    var id: String { rawValue }
    var label: String {
        switch self {
        case .date:         return "Date"
        case .play:         return "Play"
        case .metamour:     return "Metamour"
        case .milestone:    return "Milestone"
        case .hardConvo:    return "Hard convo"
        case .reconnection: return "Reconnection"
        }
    }
}

enum EventVisibility: String, Codable { case `private`, shared }
```

- [ ] **Step 2: Create `Vayl/Core/Models/EventLogEntry.swift`:**

```swift
import Foundation
import SwiftData

@Model
final class EventLogEntry {
    var id: UUID
    var authorId: UUID
    var coupleId: UUID?
    var occurredOn: Date
    var title: String
    var note: String?
    var mood: String?        // EventMood.rawValue
    var tags: [String]       // EventTag.rawValue
    var who: String?
    var visibility: String   // EventVisibility.rawValue
    var createdAt: Date
    var updatedAt: Date

    init(authorId: UUID, coupleId: UUID?, occurredOn: Date, title: String,
         note: String? = nil, mood: String? = nil, tags: [String] = [],
         who: String? = nil, visibility: String = "private") {
        self.id = UUID(); self.authorId = authorId; self.coupleId = coupleId
        self.occurredOn = occurredOn; self.title = title; self.note = note
        self.mood = mood; self.tags = tags; self.who = who
        self.visibility = visibility; self.createdAt = Date(); self.updatedAt = Date()
    }
}
```

- [ ] **Step 3: Register** `EventLogEntry.self` in `SchemaV1.models` (`Vayl/App/ModelContainer.swift`).

- [ ] **Step 4: Compile.** Expected: BUILD SUCCEEDED.

### Task B3: EventLogService (sync) + VaultStore wiring

- [ ] **Step 1: Create `Vayl/Core/Services/EventLogService.swift`** — `push(_ entry:)` upserts a row to `event_log_entries` (`onConflict: "id"`); `pull(authorId:coupleId:)` selects rows (RLS returns your own + shared) and returns decodable rows. Match `DesireSyncService`'s client + upsert signature (grep it first). Map jsonb `tags` to `[String]`.

- [ ] **Step 2: Add to `VaultStore`:** `private(set) var logEntries: [EventLogEntry] = []`; `func loadLog(context:)` fetches local `EventLogEntry` sorted by `occurredOn` desc; `func saveEntry(...)` inserts/updates the local `@Model`, `context.save()`, then `Task { await EventLogService().push(entry) }` and reloads; `func deleteEntry(_:)`. A `func syncLogDown(appState:)` pulls remote rows and upserts missing ones into SwiftData (call from `MapView.task`).

- [ ] **Step 3: Compile.** Expected: BUILD SUCCEEDED.

### Task B4: Log UI

- [ ] **Step 1: Create `EventEntryEditor.swift`** — a `.vaylSheet` form: date picker, title field, note (multi-line), a `FlowLayout` of `EventMood` chips (single select), a `FlowLayout` of `EventTag` chips (multi), a `who` text field, and a prominent **Private / Shared** toggle (segmented, using `LearnSegmented`). Save calls `store.saveEntry(...)`. Reuse `choiceChip`-style chips from `MeCardSheet` (factor a shared chip in the Seg 6 sweep; for now mirror the style).

- [ ] **Step 2: Create `VaultLogSection.swift`** — date-grouped timeline of `store.logEntries`; each row shows title, mood + tags chips, `who`, and a small shared/private marker; tap opens the editor for that entry. `MapEmptyState(icon: "book", headline: "No entries yet", message: "Log a date, a night, a feeling. Keep it private, or share it.")` + an "Add entry" affordance.

- [ ] **Step 3: Wire `.log` case in `VaultSheet.swift`** to `VaultLogSection(store: store)`; load on appear.

- [ ] **Step 4: Compile.** Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Checkpoint (commit on Bryan's call).** Device check: create a private entry (not visible on partner's device), create a shared entry (visible on both), edit + delete your own; a second device pulls your private entries down (backup works).

---

## Phase C — Consent exchange (free mechanic, in-app, a decline never discloses)

**Invariant:** the asker can never distinguish "declined" from "still pending." Enforced by Edge Functions (service role) + RLS that never exposes a decline to the asker. **No push notifications in V1** — the partner sees the request in-app next time they open the Vault.

**File structure:**
- DB: migration `vault_consent` (`consent_requests` couple-readable, `consent_declines` service-role-only).
- Edge Functions: `consent-ask`, `consent-respond` (Deno, deploy via MCP `deploy_edge_function`).
- Modify `VaultStore.swift` (consent state + ask/respond).
- Modify `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift` (replace the "Open a conversation" placeholder with the real flow).

### Task C1: Consent migration (show Bryan, then apply)

- [ ] **Step 1: Review, then `apply_migration(name: "vault_consent")`:**

```sql
create table public.consent_requests (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  item_id text not null,
  asker_id uuid not null references public.user_profiles(id),
  status text not null default 'pending' check (status in ('pending','opened')),  -- NEVER 'declined'
  discussion_card_id text,
  created_at timestamptz not null default now(),
  opened_at timestamptz
);
alter table public.consent_requests enable row level security;

-- declines are recorded here; NO select policy for anyone -> only the service role reads it.
create table public.consent_declines (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id),
  item_id text not null,
  decided_by uuid not null references public.user_profiles(id),
  created_at timestamptz not null default now()
);
alter table public.consent_declines enable row level security;
-- (no policies added => RLS denies all authenticated access; Edge Functions use the service role)

-- requests: couple can read (pending/opened only). All writes go through Edge Functions.
create policy "Partners read consent requests" on public.consent_requests
  for select to authenticated
  using (couple_id in (select couples.id from couples
    where couples.user_a in (select id from user_profiles where auth_id = auth.uid())
       or couples.user_b in (select id from user_profiles where auth_id = auth.uid())));
```

- [ ] **Step 2: `get_advisors(type: security)`** — `consent_declines` should report RLS enabled with no policies (intended: authenticated clients cannot read it; only the service role can). Confirm `consent_requests` is couple-scoped.

### Task C2: Edge Functions (deploy via MCP)

- [ ] **Step 1: `deploy_edge_function` "consent-ask"** — body authenticates the caller, resolves their profile + couple, and upserts a `pending` `consent_requests` row for `(couple_id, item_id)`. If a `consent_declines` row already exists for that pair, it still returns success and leaves status `pending` (no disclosure, optionally rate-limited). Returns `{ ok: true }`.

```ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req) => {
  const { item_id } = await req.json();
  const authHeader = req.headers.get("Authorization")!;
  const url = Deno.env.get("SUPABASE_URL")!;
  const svc = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: me } = await asUser.from("user_profiles").select("id, couple_id").single();
  if (!me?.couple_id) return new Response(JSON.stringify({ ok: false }), { status: 400 });
  // upsert a pending request (service role; bypasses the no-write RLS by design)
  await svc.from("consent_requests").upsert(
    { couple_id: me.couple_id, item_id, asker_id: me.id, status: "pending" },
    { onConflict: "couple_id,item_id" });
  return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
});
```
> Add a unique index for the upsert: `create unique index on public.consent_requests (couple_id, item_id);` (include in the C1 migration).

- [ ] **Step 2: `deploy_edge_function` "consent-respond"** — input `{ item_id, decision: "open" | "decline" }`. Verifies the caller is the partner (not the asker). On **open**: set the request `status='opened'`, `opened_at=now()`, set `discussion_card_id` to a neutral card id (same regardless of either side's rating). On **decline**: insert a `consent_declines` row and do **nothing visible** to the asker (leave/clear the request so the asker still reads "pending"). Returns `{ ok: true }` either way (identical response, so even traffic analysis does not leak).

- [ ] **Step 3:** Re-run `get_advisors` after deploy.

### Task C3: VaultStore consent state + actions

- [ ] **Step 1: Add to `VaultStore`:**

```swift
// MARK: - Consent (Phase C)
struct ConsentVM: Identifiable {
    let id: UUID; let itemId: String; let itemName: String
    let status: String          // pending | opened
    let iAmAsker: Bool
    let discussionCardId: String?
}
private(set) var consent: [ConsentVM] = []

func loadConsent(appState: AppState, context: ModelContext) async {
    guard let coupleId = appState.coupleId,
          let me = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    let items = (try? ContentLoader.loadDesireItems()) ?? []
    let nameById = Dictionary(items.map { ($0.id, $0.name) }, uniquingKeysWith: { f, _ in f })
    let rows = (try? await consentService.fetchRequests(coupleId: coupleId)) ?? []
    consent = rows.map {
        ConsentVM(id: $0.id, itemId: $0.itemId, itemName: nameById[$0.itemId] ?? $0.itemId,
                  status: $0.status, iAmAsker: $0.askerId == me.id, discussionCardId: $0.discussionCardId)
    }
}
func ask(itemId: String, appState: AppState, context: ModelContext) async {
    try? await consentService.ask(itemId: itemId)
    await loadConsent(appState: appState, context: context)
}
func respond(itemId: String, open: Bool, appState: AppState, context: ModelContext) async {
    try? await consentService.respond(itemId: itemId, open: open)
    await loadConsent(appState: appState, context: context)
}
```
Create `Vayl/Core/Services/ConsentService.swift` with `fetchRequests(coupleId:)` (select on `consent_requests`) and `ask`/`respond` (invoke the Edge Functions via the supabase functions client; match how the app already calls edge functions, grep for `.functions.invoke` or the `SupabaseFunction` enum).

- [ ] **Step 2: Compile.** Expected: BUILD SUCCEEDED.

### Task C4: Consent UI (replace the placeholder)

- [ ] **Step 1: In `VaultDesireSection.swift`**, replace `openAConversation`'s `MapEmptyState` with the real flow driven by `store.consent`, mirroring the mockup's two sides:
  - **Asker side** (`iAmAsker`): per topic, "You're curious, ask to open this together" → button calls `store.ask`; `pending` → "Asked, waiting" (this row is identical whether the partner is genuinely pending OR has declined, that is the guarantee); `opened` → "Opened together" + the neutral discussion card.
  - **Responder side** (not asker, status pending): an incoming card "Your partner asked to open <name>" with "Not now" / "Open it" calling `store.respond(open:)`. "Not now" shows a confirming toast and the row disappears; the asker is never told.
  - Topics to surface: the user's private positive items that are not yet matched/opened (derive from `DesireMapEntry` + existing requests). Keep V1 to a short list.
  - `VaultDesireSection` will need `store` (pass `VaultStore` in, or pass the `consent` array + callbacks). Update the call site in `VaultSheet.swift`.

- [ ] **Step 2: Load consent** in `VaultSheet`/`MapView` `.task` and on segment change.

- [ ] **Step 3: Compile.** Expected: BUILD SUCCEEDED.

- [ ] **Step 4: THE PRIVACY TEST (two devices, Bryan).** As A, ask to open a topic. As B, decline ("Not now"). Back as A: the topic still reads "Asked, waiting," **identical to a genuinely-pending request**, with no decline signal anywhere (UI, and confirm in `consent_requests` there is no asker-readable decline). Then as B on another topic, open it: both see "Opened together" + the same neutral card. This test passing is the done condition for Phase C.

---

## Phase D — Cohesion sweep (Segment 6, after the above)

Fold the duplicated align-row/badge (`MapUsLayer` vs `VaultDesireSection`) and the chip styles (`MeCardSheet` vs `EventEntryEditor`) into shared components; promote `LearnSegmented` to a neutral `Design/Components` location and update Learn + Map call sites; wire the gear in the Map masthead to settings/pairing; confirm every Vault block has its empty/error/loading state. Compile.

---

## Self-review

- **Spec coverage:** Agreements (spec §3) → Phase A; Event Log (§5) → Phase B; Consent (§4) → Phase C; Desire Map (§2) + foundation (§1) already live; cohesion (§1.5) → Phase D. Tiers (§0) honored (all three free; only `.reveal` gated). Sequencing (§6) honored: Agreements → Event Log → Consent.
- **Decisions folded:** private entries = remote backed-up, partner-unreadable (B1 compound RLS); consent decline = service-role-only `consent_declines` table (C1); mood/tags = accepted lists (B2); Agreements = dual-lock propose/approve (A1 trigger + RLS); consent notify = in-app only (C, no push).
- **Open items the executor must resolve at the file:** the exact `supabase` client accessor + builder signatures (grep `DesireSyncService`), and the Edge Function invoke path (grep `SupabaseFunction`/`.functions`). These are real and named, not placeholders.
- **Production safety:** every migration/function task gates on Bryan's review + `get_advisors`.

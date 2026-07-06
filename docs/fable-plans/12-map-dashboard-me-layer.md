# 12 — Map Dashboard Shell + the Me Layer (T3, Seg 0–3)

**Goal:** In one pass, land the Map tab as a calm, returnable individual-leaning couple dashboard behind a single Me / Us toggle, with the **Me layer fully wired to real data**: the Home-grammar name-toggle masthead, ONE canonical `.vaylGlassCard` language across every surface, the reused Pulse hero (check-in via `.vaylCover`, history via `.vaylSheet`), the Record (session history + category spread from `CardSession`), and the title-led Me Card (Flavor color + chosen Title + "Drawn to" tags derived from `DesireMatch` mutual matches + opt-in sigil). The Us layer and the Vault are **left as clean seams for plans 13/14** and not built here. Definition of Done = build-green + the Me dashboard renders with real data and correct empty states; the "calm, cohesive, returnable" feel is Bryan's device pass.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

> ## ⚠️ ONE-SHOT CAVEAT — this plan is feel-heavy; read before you start
>
> This is **not** a pure mechanical pass. The Map's entire reason to exist is a _feel_: "an
> individual-leaning couple dashboard, calm and returnable, behind one Me / Us toggle." Fable can and
> should build the whole dashboard + Me layer in one pass and get it **build-green with real data and real
> empty states** — that is the Definition of Done here. But two things are explicitly **Bryan's device /
> canvas pass, not Fable's**:
>
> 1. **The "one cohesive, calm glass language."** The cohesion rule is a hard contract (§Cohesion), but
>    whether the assembled screen actually _reads_ calm and returnable — spacing rhythm, how much breathes
>    between the Pulse hero, the card, and the Record, whether the name-toggle masthead feels like a switch
>    or a title — is a taste judgment Bryan makes on device.
> 2. **The Me Card identity feel.** Flavor color, the Title shortlist wording, how the "Drawn to" tags glow
>    when shared, the sigil — the _data_ is Fable's job; whether the card feels like an identity you'd want
>    to return to is Bryan's.
>
> Everything marked 🎚️ below is a feel-value: use the given default, do not re-derive it, and list it on
> the device checklist for Bryan. **Build it correct and complete; Bryan tunes the feel.**

---

## Context Fable needs

- **The Map tab is NOT greenfield — it is ~80% built.** The bridge doc's "MapView is a stub" line
  (`docs/handoffs/2026-06-24-map-tab-bridge.md` §2) is **stale**. As of 2026-07-01 the whole Map Me layer
  already exists and compiles: `MapView.swift` (237 lines, real dashboard), `MapStore.swift` (314 lines,
  full 4-layer store), `MeCardSheet.swift`, `MeCardCompact.swift`, `MapPulseHero.swift`, `MapRecord.swift`,
  `MapPrimitives.swift`, `FlavorVisuals.swift`, plus `Flavor.swift` and the profile fields
  (`UserProfile.flavor`, `UserProfile.chosenTitle`). **So this plan is a verify-finish-harden pass, not a
  from-scratch build.** Trust the repo, read each file, and complete the gaps below rather than
  re-authoring what is there.
- **What is already done (do not rebuild, just verify it compiles and reads correctly):**
  - Seg 0 shell: `MapView` renders `AppColors.void` + `OnboardingAtmosphere(config: .stat)`, a
    `GeometryReader` pinned to `layout.screenWidth` (the Home ZStack-width fix), the name-toggle masthead
    (`"Jordan"` lit / `"& Alex"` dim → tap to switch layer), and `switch store.layer { .me / .us }`.
    `MapStore.Layer` is a `String, CaseIterable` enum (`me`, `us`).
  - Seg 1 Pulse: `MapPulseHero` reuses `PulseAura` / `PulseHistoryGrid` / `PulseField`, opens the field map
    via `.vaylCover`, and the check-in is presented from `MapView` via `.vaylSheet` calling
    `PulseCheckInView(store: pulse, onClose:)`.
  - Seg 2 Record: `MapRecord` renders the category-distribution bar + recent-session rows, with a real
    `MapEmptyState` ("No sessions yet"). `MapStore.loadRecord` fetches `CardSession` (couple-owned) and
    resolves deck titles/categories via `DeckCatalogService().loadSummaries()`.
  - Seg 3 Me Card: `MeCardCompact` (on the Me layer) + `MeCardSheet` (full card + Title/Flavor choosers).
    `MapStore.loadMeCard` reads `UserProfile.flavor` / `.chosenTitle`; `setFlavor` / `setTitle` persist and
    re-render; `drawnTags` + `loadServerAlignData` derive the "Drawn to" tags from Desire data.
- **The canonical glass card already exists and is already used everywhere on Map** — do **not** define a
  new one. It is `.vaylGlassCard(accent: Color? = nil, radius: CGFloat = AppRadius.lg)` at
  `Vayl/App/Theme/ThemeModifiers.swift:92`. `MeCardCompact`, `MeCardSheet`, and `MapRecord` all already
  call it. Cohesion rule #3 is **satisfied**; the remaining risk is any NEW surface you add must also use
  it (never hand-roll card chrome).
- **`LearnSegmented` exists and IS promotable to the shared Me/Us control** — but note the current Map
  masthead does NOT use it. `LearnSegmented<Value: Hashable>` at
  `Vayl/Features/Learn/Views/LearnSegmented.swift:11` is a clean, token-only generic segmented control
  (glass track, accent pill, optional SF Symbol). The bridge contract (#8) says promote it rather than
  authoring a fourth bespoke control. **The Map deliberately chose a different affordance:** the masthead
  name-toggle ("Jordan" ↔ "& Alex.") *is* the Me/Us switch (see `MapView.nameToggle`), per the
  [tab header system] memory. That is a valid, intentional design — do **not** rip it out for a pill. What
  this plan asks (Seg 0 task) is a small, non-behavioral **relocation**: physically move `LearnSegmented`
  out of `Features/Learn/` into a shared location so plans 13/14 (and any future consumer) can use it
  without importing across features. See Seg 0.
- **`DesireMatch` mutual data comes from the server via `DesireSyncService.shared.fetchMatches(coupleId:)`**
  (`Vayl/Core/Services/DesireSyncService.swift:157`), which returns `[DesireMatchRow]`. Each row's
  `matchType` is `DesireMatchType?` (`.mutual` / `.adjacent`) derived from `alignmentLevel`. The Me Card's
  glowing "shared" tags = the user's positive `DesireMapEntry` ratings whose `itemId` appears in a
  server row with `matchType == .mutual` (and is revealable given the entitlement gate). This is already
  implemented in `MapStore.loadServerAlignData` — but it **duplicates** logic that
  `DesireRevealStore.load()` already owns (Seg 3 reconciliation note below).
- **Canonical patterns to imitate:** the store is already modeled the right way — keep it as the shape to
  follow (`@Observable @MainActor final class`, `private(set)` state, an idempotent `load(...)`, async
  server work in a child `Task`). For the Me/Us **layer switch animation**, the existing
  `withAnimation(AppAnimation.spring) { store.layer = ... }` in `MapView.nameToggle` is the pattern. For
  Reduce-Motion on any looping aura, copy `Vayl/Features/Pulse/Components/PulseAura.swift` verbatim
  (already reused by `MapPulseHero`).
- **PrismView is DEAD.** `Vayl/Features/Map/PrismView.swift` (833 lines) is kept in-repo as a visual mine
  only. Do not import it, wire it, or delete it. Nothing in this plan touches it.
- **Pulse stays local.** Pulse reads/writes `pulse.entries.v1` in `UserDefaults` via
  `PulseStore` (`Vayl/Features/Pulse/Store/PulseStore.swift:19`). The Pulse→Supabase migration is
  **explicitly OUT of Map V1** — do not touch persistence, do not add a fetch, reuse the injected
  `PulseStore` exactly as `MapView`/`MapPulseHero` already do (`@Environment(PulseStore.self)`).

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Design/Components/Navigation/VaylSegmented.swift` | The promoted shared segmented control. A verbatim move of `LearnSegmented` into a shared location (renamed `VaylSegmented`) so Map, Learn, and plans 13/14 (Us layer, Vault Desire/Agreements toggle) share ONE control, not four. Keep a thin `LearnSegmented` typealias so existing Learn call-sites keep compiling. |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Features/Learn/Views/LearnSegmented.swift` | whole file (11–60) | Gut the struct body; replace with `typealias LearnSegmented<Value: Hashable> = VaylSegmented<Value>` so Learn keeps compiling and there is one source of truth. (Do NOT delete the file — it is wired into the app target; a typealias file is the safe move.) |
| `Vayl/Features/Map/MapStore.swift` | 170–295 | Reconcile the Me Card tag derivation onto `DesireRevealStore` instead of re-implementing `fetchMatches` gate logic; harden the two `try? context.save()` sites in `setFlavor`/`setTitle` to `saveWithLogging()`; add an idempotency guard so `loadServerAlignData` does not clobber tags on repeated appears. |
| `Vayl/Features/Map/MeCardCompact.swift` | 20–29 | Fix the eyebrow copy: it reads `"\(card.flavor.label) Type"` (e.g. "Explorer Type") — reword to the calmer `"Your card"` eyebrow used elsewhere, OR keep flavor but drop the assessment-flavored word "Type" (product principle: labels are wayfinding, not assigned identity). See Seg 3. |
| `Vayl/Features/Map/Components/MeCardCompact.swift` | 59–71 | Add an empty-state branch for the "Drawn to" block: when `card.tags.isEmpty`, show a one-line forming hint instead of silently omitting the section (empty-state contract). |
| `Vayl/Features/Map/MapView.swift` | 193–206 | Wrap the Me layer's Me Card block so the compact card always has a sensible render even before the profile loads (name empty → still shows the flavor + a "set your title" affordance). Small, see Seg 3. |

### Delete

_None._ (PrismView stays; `LearnSegmented.swift` stays as a typealias shim; no dead files are introduced.)

---

## Build steps (segments)

> All four segments ship in ONE pass. They are ordered for readability. Because most of the Me layer is
> already built, each segment below is framed as **verify → finish the gap**. Read the named file first;
> only change what the segment calls out.

### Seg 0 — Shell, `MapStore`, the ONE glass language, and the shared segmented control

**One thing:** confirm the shell + canonical card + masthead are correct, and promote `LearnSegmented`
to a shared control so plans 13/14 can reuse it.

**0a — Verify the shell (no code change expected).** Open `MapView.swift` and confirm all of the
following already hold; if any drifted, fix to match:
- Background is `AppColors.void.ignoresSafeArea()` + `OnboardingAtmosphere(config: .stat).ignoresSafeArea()`.
- The screen `ZStack` is pinned with `.frame(width: layout.screenWidth, alignment: .center)` (the
  [Home ZStack width inflation] fix — an `ignoresSafeArea` atmosphere child must not inflate the column).
- `layerContent` is a `switch store.layer { case .me: meLayer; case .us: usLayer }`.
- Every card surface on the Me layer routes through `.vaylGlassCard(...)` (it does: `MeCardCompact`,
  `MapRecord`). **Cohesion rule #3 is satisfied — do not add a second card style.**

**0b — Confirm the masthead + name-toggle.** `MapView.masthead` shows the personal name (Home grammar),
and `MapView.nameToggle` IS the Me/Us switch: your name always lit (`AppColors.spectrumText`), the
partner name dim in Me and lit in Us, tapping either drives
`withAnimation(AppAnimation.spring) { store.layer = ... }`. This is the intended design (per the
[tab header system] and [map tab direction] memories: "Jordan & Alex." shows the personal name on Map).
**Keep it.** Do not replace it with a pill. The shared segmented control (0c) is for the Us layer and the
Vault (plans 13/14), not the top-level Me/Us switch.

**0c — Promote `LearnSegmented` → `VaylSegmented` (shared).** Create the shared control by moving the
body verbatim into `Vayl/Design/Components/Navigation/VaylSegmented.swift` and renaming the type. The body
is already token-clean, so this is a rename + relocate only:

```swift
// Vayl/Design/Components/Navigation/VaylSegmented.swift
//
// The shared void/spectrum segmented control (promoted from LearnSegmented so Map,
// Learn, the Us layer, and the Vault's Desire/Agreements toggle share ONE control,
// not four). A glass track holds equal segments; the active segment lifts on an
// accent-tinted pill. Optional SF Symbol above the label, or label-only.

import SwiftUI

struct VaylSegmented<Value: Hashable>: View {
    struct Item: Identifiable {
        var id: Value { value }   // identity is the value — stable across rebuilds
        let value: Value
        let label: String
        let icon: String?
        init(_ value: Value, _ label: String, icon: String? = nil) {
            self.value = value; self.label = label; self.icon = icon
        }
    }

    let items: [Item]
    @Binding var selection: Value
    var accent: Color = AppColors.spectrumMagenta

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            ForEach(items) { item in
                let on = selection == item.value
                Button { withAnimation(AppAnimation.standard) { selection = item.value } } label: {
                    VStack(spacing: AppSpacing.xs) {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(on ? accent : AppColors.textSecondary)
                        }
                        Text(item.label)
                            .font(AppFonts.buttonLabelSmall)
                            .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(on ? accent.opacity(0.16) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableCardStyle())
            }
        }
        .padding(AppSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.whisperFill)
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.borderSubtle, lineWidth: 1))
        )
    }
}
```

Then replace the entire body of `Vayl/Features/Learn/Views/LearnSegmented.swift` with a compatibility
shim so every existing Learn call-site (`LearnSegmented(items:selection:accent:)`,
`LearnSegmented.Item(...)`) keeps compiling unchanged:

```swift
// Features/Learn/Views/LearnSegmented.swift
//
// Compatibility shim. The segmented control moved to the shared
// Vayl/Design/Components/Navigation/VaylSegmented.swift so Map / Vault / Us can
// reuse it. Learn call-sites keep the LearnSegmented spelling via this typealias.

import SwiftUI

typealias LearnSegmented<Value: Hashable> = VaylSegmented<Value>
```

> Note the `.Item` nested type: `LearnSegmented.Item` resolves through the typealias to
> `VaylSegmented.Item`, so `LearnSegmented.Item(...)` call-sites still compile. If any Learn file spells it
> `LearnSegmented<SomeType>.Item`, that also resolves. Grep `LearnSegmented` after the change to confirm no
> call-site broke; there are Learn consumers (`ContentHubSection`, the Voices filter) that must still build.

**Done (Seg 0):** shell + masthead + name-toggle render as before; `VaylSegmented` exists in the shared
Navigation folder; `LearnSegmented` is a typealias; every Learn call-site still compiles.

---

### Seg 1 — The Pulse hero (Me)

**One thing:** confirm the Pulse hero reuses `Features/Pulse/*` and presents check-in / history through
the correct grammar — the components are already wired, so this is verify + one presentation confirm.

**1a — Verify reuse (no new drawing).** `MapPulseHero` already reuses:
- `PulseAura(quadrant:size:148)` for the hero aura,
- `PulseHistoryGrid(mode: .me(...))` for the last-30-**logged** grid (never "last 30 days"),
- `PulseField(entries:size:showAxisLabels:)` inside the field-map cover.
Do not re-draw any of these. The current quadrant/position derive from `pulse.entries.last?.resolvedPosition`.

**1b — Confirm the presentation grammar.** Two presentations, both must match the contract:
- **Check-in** = a discrete task the user returns from. `MapView` currently presents it as a `.vaylSheet`
  (`heightFraction: 0.82`) calling `PulseCheckInView(store: pulse, onClose:)`. Per the presentation
  grammar, a Pulse check-in is "entering a protected, immersive mode" → `.vaylCover`. **However**, the
  preamble notes the Pulse check-in presentation fix is **its own Pulse plan**, not this one. So here:
  **leave the existing `.vaylSheet` presentation as-is** (reuse the component + present it the way the
  codebase currently does), and add a single-line code comment flagging it for the Pulse plan. Do not
  change the presentation type in this plan — that is out of scope and owned elsewhere.

  ```swift
  // MapView.swift — inside the check-in .vaylSheet(...) block, above PulseCheckInView(...)
  // NOTE: presentation grammar says a Pulse check-in is a protected mode (.vaylCover).
  // The check-in presentation fix is owned by the Pulse plan, not this Map plan — reuse
  // the component here and leave the presentation for that plan to correct.
  ```
- **History / field map** = previewing something you return from. `MapPulseHero` opens the field via
  `.vaylCover(isPresented: $showMap, confirmOnExit: false)` for the immersive full-field read, and
  `MapView` opens `PulseFullView` via `.vaylSheet`. Both are acceptable. Leave as-is.

**1c — Forming / empty state.** The hero already degrades: with no entries, `currentPosition` falls back
to the neutral centre `PulsePosition(energy: 0.5, openness: 0.5)`, the history grid hides when
`meGridQuadrants.isEmpty`, and the weather one-liner is `nil` until there are two days of data. This is an
acceptable "forming" state (the aura still renders at centre). 🎚️ Whether the neutral-centre aura reads as
"forming" vs "a real reading" is a feel call — leave the default and list it for Bryan. Do not add a
separate cold-start card.

**Done (Seg 1):** Pulse hero renders from real `PulseEntry` data or the neutral forming state; check-in
opens (as a sheet, flagged for the Pulse plan); the field map opens via cover; history grid shows only
logged days.

---

### Seg 2 — The Record (Me)

**One thing:** confirm session history + category spread come from `CardSession` and the empty state is
present — already built, verify only.

**2a — Verify the data path.** `MapStore.loadRecord(coupleId:context:)` (MapStore.swift:135) fetches
`CardSession` filtered by `coupleId`, sorted `startedAt` reverse, `fetchLimit = 50`, resolves each to a
`RecordSession` (deck title + `DeckCategory` via `DeckCatalogService().loadSummaries()`), then groups into
`CategoryShare` sorted by count. This is correct 4-layer (store fetches, view reads). `CardSession` is
couple-owned (`coupleId`, not `userId`) — confirmed against `Core/Models/CardSession.swift:31`. Deck JSON
is bundle content, so loading it in the store is allowed (comment already says so). No change.

**2b — Verify the render + empty state.** `MapRecord` shows the distribution bar (per-category
`mapColor` from `MapPrimitives.DeckCategory.mapColor`, tokens only) + up to 5 recent rows, and a real
`MapEmptyState(icon: "rectangle.stack", headline: "No sessions yet", ...)` when `sessions.isEmpty`. This
satisfies the empty-state contract. The distribution caption ("Where your conversations have gone · most
in X, then Y") is descriptive, not interpretive — it **ranks/distributes one person's own answers**, which
is the permitted operation under the discovery-tool product principle. No change.

**2c — One correctness check.** `MapRecord.distribution`'s `GeometryReader` HStack widths use
`geo.size.width * fraction(share.count)` with a `max(2, ...)` floor per segment. With many categories the
floors can sum past the track width; the `.clipShape(Capsule())` hides overflow, so it is cosmetically
safe. 🎚️ Leave as-is; flag for Bryan only if the bar looks wrong on device.

**Done (Seg 2):** Record renders real sessions + distribution, or "No sessions yet"; all colors are
tokens; no interpretation copy.

---

### Seg 3 — The Me Card (title-led identity) — the biggest piece

**One thing:** the title-led Me Card renders from the profile (Flavor color + chosen Title + "Drawn to"
tags derived from `DesireMatch` mutual matches + the lattice sigil), editing persists, and the tag
derivation is **reconciled onto `DesireRevealStore`** instead of duplicating its match-gate logic.

**3a — Verify the card render (already built).** `MeCardCompact` (compact, on the Me layer) and
`MeCardSheet` (full card + choosers) both render: `FlavorPortrait` (the spectrum-ring lattice sigil,
`FlavorVisuals.swift`), name + `card.title` in a white→flavor gradient, `FlavorChip` + `flavor.essence`,
and the "Drawn to" `DrawnTagChip` cloud (shared tags glow in the flavor color via a `sparkle` icon). All
route through `.vaylGlassCard(accent: card.flavor.color)`. `Flavor` (`Core/Models/Enums/Flavor.swift`) has
4 cases (explorer/anchor/catalyst/architect) with `.color` (spectrum tokens), `.icon`, `.essence`, and a
6-item `.titles` shortlist each. This is the intended design — do not restyle.

**3b — Product-principle copy fix (small, required).** `MeCardCompact` line 21 renders the eyebrow as
`"\(card.flavor.label) Type".uppercased()` → "EXPLORER TYPE". The word "Type" reads like an assigned
identity / assessment verdict, which the product principles forbid (labels are **wayfinding vocabulary,
not assigned identity**; the Flavor was self-picked on the card, not concluded about the user). Reword the
eyebrow to the neutral, self-authored framing:

```swift
// MeCardCompact.swift — replace the eyebrow Text (currently "\(card.flavor.label) Type")
Text("Your card")
    .font(AppFonts.overline)
    .tracking(1.0)
    .foregroundStyle(AppColors.textTertiary)
```

The flavor is still fully visible via the `FlavorChip` + `essence` below — this only removes the
"Type" verdict framing from the eyebrow.

**3c — Add the "Drawn to" empty state (required by the empty-state contract).** `MeCardCompact` currently
omits the whole "Drawn to" block when `card.tags.isEmpty` (line 59 `if !card.tags.isEmpty`). Silent
omission is not an empty state. Replace with an explicit forming hint so the card never has a blank gap:

```swift
// MeCardCompact.swift — replace the `if !card.tags.isEmpty { ... }` block
VStack(alignment: .leading, spacing: AppSpacing.xs) {
    Text("Drawn to".uppercased())
        .font(AppFonts.overline)
        .tracking(1.0)
        .foregroundStyle(AppColors.textTertiary)
    if card.tags.isEmpty {
        Text("Your Desire Map fills this in as you and your partner rate what you're drawn to.")
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    } else {
        FlowLayout(spacing: AppSpacing.xs) {
            ForEach(card.tags) { tag in
                DrawnTagChip(tag: tag, flavor: card.flavor)
            }
        }
    }
}
```

**3d — Reconcile the tag derivation onto `DesireRevealStore` (the real Seg 3 work).**
`MapStore` currently owns **two** copies of "fetch matches, apply the entitlement gate, resolve to display
names": `loadServerAlignData` (MapStore.swift:250) re-implements exactly what `DesireRevealStore.load()`
(`Vayl/Features/Desire Map/Store/DesireRevealStore.swift:191`) already does — same
`DesireSyncService.shared.fetchMatches`, same `isCore || row.isFreeReveal` gate, same
`matchType == .mutual` filter. This is the duplication the bridge doc's reuse rule warns against ("derive
[tags] from existing DesireMatch data rather than inventing a parallel"). It also risks drift: if the gate
rule changes in the reveal store, Map silently keeps the old rule.

**The fix (keep it minimal — do not over-refactor):** extract the shared piece to ONE place and have both
call it. Add a small static helper on `MapStore` that returns the mutual, revealable item IDs given the
already-fetched rows and the gate, so the *gate rule* lives once. The simplest safe move that respects the
one-shot budget:

```swift
// MapStore.swift — add near the other statics; the ONE place the gate rule lives.
/// The set of desire-item IDs that are BOTH a mutual match AND revealable under the
/// entitlement gate. Shared by the Me-Card tag glow and (later) the Us align list so the
/// reveal rule is defined once, not copied. `canReveal` is the OR'd entitlement (server
/// tier OR local StoreKit ownership) threaded from the View.
static func revealableMutualItemIDs(
    from rows: [DesireMatchRow],
    canReveal: Bool
) -> Set<String> {
    Set(
        rows
            .filter { (canReveal || $0.isFreeReveal) && $0.matchType == .mutual }
            .map(\.desireItemId)
    )
}
```

Then rewrite `loadServerAlignData` to use it for the tag glow (leaving the Us align list build in place as
the seam plan 14 will own), and add an idempotency guard so a second appear does not rebuild tags from a
possibly-empty fetch:

```swift
// MapStore.swift — inside loadServerAlignData, replace the ad-hoc sharedIds computation
// used for the meCard tags with the shared helper. (The alignItems build above stays as
// the Us seam for plan 14.)
let sharedIds = Self.revealableMutualItemIDs(from: matchRows, canReveal: canReveal)

if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
    let profileId = profile.id
    let entryFetch = FetchDescriptor<DesireMapEntry>(predicate: #Predicate { $0.userId == profileId })
    let entries = (try? context.fetch(entryFetch)) ?? []
    let positive = entries.filter { $0.rating == .excitedAboutIt || $0.rating == .openToIt }
    let tags = positive.map { entry in
        DrawnTag(name: nameById[entry.itemId] ?? entry.itemId, isShared: sharedIds.contains(entry.itemId))
    }
    // Only overwrite if we actually resolved something, so a transient empty fetch on a
    // later appear does not wipe glowing tags the user already saw.
    let resolved = Array(tags.sorted { $0.isShared && !$1.isShared }.prefix(5))
    if !resolved.isEmpty || meCard.tags.isEmpty {
        meCard.tags = resolved
    }
}
```

> Why not fully route through `DesireRevealStore`? That store is an `@Observable @MainActor` view-model
> with its own lifecycle and purchase flow; instantiating it inside `MapStore.load` would tangle two
> stores and blow the one-shot budget. Extracting the **gate rule** to one static (above) removes the real
> drift risk — the duplication that mattered — without a cross-store dependency. That is the right-sized
> reconciliation; note it in the handoff as "gate rule now shared; a fuller merge onto DesireRevealStore
> is a future cleanup if the Us layer (plan 14) also needs it."

**3e — Harden the persistence writes.** `setFlavor` (MapStore.swift:210) and `setTitle` (MapStore.swift:221)
persist the user's chosen identity via a bare `try? context.save()`. Losing a chosen Title/Flavor silently
is real (not cosmetic) data loss, and the codebase mandates `saveWithLogging()` for that
(`ModelContext+Extensions`). Convert both:

```swift
// MapStore.swift — setFlavor(_:context:)
func setFlavor(_ flavor: Flavor, context: ModelContext) {
    guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    profile.flavor = flavor.rawValue
    if let current = profile.chosenTitle, !flavor.titles.contains(current) {
        profile.chosenTitle = nil
    }
    do { try context.saveWithLogging() } catch { /* logged by saveWithLogging; profile stays in memory */ }
    loadMeCard(context: context)
}

// MapStore.swift — setTitle(_:context:)
func setTitle(_ title: String, context: ModelContext) {
    guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
    profile.chosenTitle = title
    do { try context.saveWithLogging() } catch { /* logged by saveWithLogging */ }
    loadMeCard(context: context)
}
```

> Verify the helper's exact name/signature at `Vayl/Core/Persistence/ModelContext+Extensions.swift` before
> using it (plan 02 documents it as `func saveWithLogging() throws`). If it lives elsewhere or is spelled
> differently, trust the repo and match it; if it genuinely does not exist, fall back to the codebase's
> most common non-silent save form and note the drift.

**3f — Guard the empty-name compact card.** In `MapView.meLayer`, when the profile has not loaded, `card.name`
is empty. `MeCardCompact` still renders (flavor defaults to `.explorer`, title to the flavor's first). This
is acceptable — the sigil + flavor + a default title show, and the eyebrow now reads "Your card". No code
change needed beyond 3b; just confirm the compact card is never a blank rectangle on cold start. (The
`loadMeCard` fallback at MapStore.swift:171 already seeds a default `MeCard`, so this holds.)

**Done (Seg 3):** Me Card renders title-led identity from the profile with a real "Drawn to" empty state;
choosing a Title/Flavor persists via `saveWithLogging`; the mutual-match gate rule lives in ONE static and
the tag glow uses it; no "Type" verdict copy.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

- [ ] `VaylSegmented` exists at `Vayl/Design/Components/Navigation/VaylSegmented.swift`; `LearnSegmented`
      is a typealias to it; every existing Learn call-site still compiles (grep `LearnSegmented`).
- [ ] Map tab renders: void + `OnboardingAtmosphere(.stat)`, name-toggle masthead, and the Me/Us switch
      flips `store.layer` on tap with the spring animation.
- [ ] The Me layer renders three sections, all on the ONE `.vaylGlassCard`: Pulse hero, the Me Card
      (compact), the Record.
- [ ] Pulse hero reuses `Features/Pulse/*` (no re-drawn graph); check-in opens (as the existing sheet,
      with the `.vaylCover` comment flag); the field map opens via `.vaylCover`; history grid shows only
      logged days; neutral-centre forming state when there are no entries.
- [ ] The Record shows real `CardSession` history + category distribution, or the "No sessions yet" empty
      state; all colors are tokens; caption is descriptive, not interpretive.
- [ ] The Me Card shows Flavor color + chosen Title + "Drawn to" tags (shared ones glow), or the "Drawn to"
      forming hint when there are no tags; the eyebrow reads "Your card", not "… Type".
- [ ] Choosing a Title or Flavor in `MeCardSheet` persists via `saveWithLogging()` and re-renders the card.
- [ ] The mutual-match reveal gate lives in ONE static (`revealableMutualItemIDs`); the Me-Card tag glow
      uses it; `loadServerAlignData` no longer duplicates the gate expression; a transient empty fetch does
      not wipe already-shown tags.
- [ ] The Us layer is untouched and still compiles as the seam for plan 14; the Vault sheet still opens as
      the seam for plan 13. (This plan does not build either — see Constraints.)
- [ ] Zero raw literals in any changed View; no banned iOS-26 APIs introduced; PrismView untouched.
- [ ] `#Preview("Map tab")` in `MapView.swift` still builds with the existing preview environment
      (`AppState` with `displayName = "Jordan"`, `PulseStore()`, `EntitlementStore(...)`,
      `.previewContainer`).

---

## Bryan verifies on device

- [ ] **Calm & returnable (🎚️).** The whole Me screen reads calm — enough breathing room between the Pulse
      hero, the Me Card, and the Record. Adjust the inter-section `AppSpacing.xl` in `meLayer` if it feels
      cramped or too airy.
- [ ] **Name-toggle feel (🎚️).** Tapping "Jordan" ↔ "& Alex." reads as a *switch*, not a title. Confirm the
      dim/lit contrast on the partner name (`opacity 0.45` in Me) is obviously "off," and the spring flip
      feels like a lens change, not a page load.
- [ ] **Me Card identity feel (🎚️).** The card feels like an identity you'd return to: Flavor color, the
      Title wording (browse the shortlists in `MeCardSheet`), and the shared-tag glow. Confirm a shared tag
      obviously reads "shared" vs a plain one.
- [ ] **Pulse forming state (🎚️).** With no check-ins, the neutral-centre aura reads as "forming," not as a
      false reading. If it looks like a real reading, that is the cue for the separate Pulse plan.
- [ ] **Check-in presentation (flag only).** The check-in opens as a sheet today; per the grammar it should
      be a `.vaylCover`. Confirm whether it bothers you — that fix is owned by the Pulse plan, not this one.
- [ ] **Record distribution bar.** With several categories logged, the bar segments look proportional and
      the caption names the right top-two categories.
- [ ] **Editing persists.** Choose a Title and a different Flavor, background the app, reopen — the choice
      survives (proves `saveWithLogging` wrote it).
- [ ] **Solo / cold start.** Fresh profile, no partner, no sessions: masthead shows just your name (no
      "& Alex" in release), Record shows the empty state, Me Card shows the default flavor + "Drawn to"
      forming hint — no blank rectangles, no dead ends.

---

## Constraints / do-not-touch

- **PrismView is DEAD** — do not import, wire, or delete `Vayl/Features/Map/PrismView.swift`. Mine visually
  only. Nothing in this plan references it.
- **Pulse persistence is off-limits.** `PulseStore` stays on `pulse.entries.v1` in `UserDefaults`. Do not
  add a Supabase fetch/write for Pulse; the Pulse→Supabase migration is explicitly OUT of Map V1. Reuse the
  injected `@Environment(PulseStore.self)` exactly as today.
- **Do not build the Us layer or the Vault here.** `MapUsLayer` (Us) and `VaultSheet` (Vault) are the seams
  for **plans 14 and 13** respectively. Leave `MapView.usLayer`, `MapStore.loadUs`, `MapStore.usStats`,
  `alignItems`, `lockedAlignCount`, `partnerPosition`, `VaultStore`, and the Vault `.vaylSheet` wiring
  intact and untouched so those plans attach cleanly. The `revealableMutualItemIDs` static you add in Seg 3
  is deliberately shaped so the Us align list (plan 14) can also call it.
- **The check-in presentation type is out of scope.** Reuse `PulseCheckInView`; leave the `.vaylSheet`
  presentation as-is with the flag comment. The Pulse plan owns changing it to `.vaylCover`.
- **Do not add a second card language.** Every surface uses `.vaylGlassCard(...)`. Cohesion rule #3 is
  already satisfied; keep it that way.
- **Tokens only, 4-layer, no em dashes** in any copy you write ("Your card", the "Drawn to" forming hint).
  Views read from `MapStore`; the store calls services; no fetch logic moves into a View.
- **Do not touch** Home, Play, Learn feature views beyond the `LearnSegmented` typealias shim (which must
  keep every Learn call-site compiling).

---

## Open decisions (each with a recommended default — Fable proceeds on the default)

1. **Me/Us switch affordance — name-toggle vs promoted `VaylSegmented`?**
   **Default: keep the name-toggle masthead** as the Me/Us switch (it is the intended, memory-backed
   design) and promote `VaylSegmented` only as the *shared* control for plans 13/14. Proceed on this;
   flag for Bryan if he wants the pill on top instead.
2. **How far to reconcile Map's tag derivation onto `DesireRevealStore`?**
   **Default: extract the gate rule to ONE static (`revealableMutualItemIDs`) and have Map call it**, not a
   full cross-store merge (that tangles two `@Observable` view-models and blows the one-shot budget). Note
   the fuller merge as a future cleanup. Proceed on the static.
3. **"Drawn to" empty state — hide the block or show a forming hint?**
   **Default: show the forming hint** ("Your Desire Map fills this in …") so the card is never a blank gap,
   per the empty-state contract. Proceed on the hint.
4. **Eyebrow copy — keep "Explorer Type" or neutralize to "Your card"?**
   **Default: "Your card"** — "Type" reads as an assigned-identity verdict the product principles forbid;
   the flavor is still shown via the chip + essence. Proceed on "Your card"; flag for Bryan if he prefers
   a flavor-named-but-not-"Type" eyebrow (e.g. just "Explorer").
5. **Check-in presentation (sheet vs cover) — fix here or defer?**
   **Default: defer** — reuse the component, leave the `.vaylSheet`, add the flag comment. The Pulse plan
   owns the `.vaylCover` correction. Proceed on defer.

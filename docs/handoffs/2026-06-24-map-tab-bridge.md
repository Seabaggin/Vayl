# Map Tab — Mockup-to-Implementation Bridge (2026-06-24)

> Bridges the Map mockups (`docs/prototypes/map-dashboard.html`, `docs/prototypes/me-card.html`) to a Swift implementation that is **cohesive with Home, Play, and Learn and with the existing codebase**. Written after a four-tab cohesiveness audit (Home as baseline). This doc is the brief + the build plan; section 9 is the prompt to run it in a fresh chat. Decisions in section 4 are LOCKED unless marked pending.

---

## 1. Working agreement (same as the rest of this redesign)

- **Branch** `spec/contextphase-2x3-redesign` directly. ~138 unrelated in-flight files. Never `git add -A`, never commit `project.pbxproj`, no worktrees/branches. New files under `Vayl/Features/Map/` auto-join the app target. The human owns git.
- **Verify = compile + `#Preview`, not XCTest.** Build:
  ```
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ```
  `database is locked` = Xcode is busy, wait and retry.
- **You compile; the human runs on device and judges feel.** Spec-faithful changes, then a device checklist.
- **Architecture is law** (`CLAUDE.md`): zero raw literals (tokens only), `.vaylSheet`/`.vaylCover` for modals, 4-layer (View, Store, Service, Model). iOS 26 / Swift 6, no `UIScreen.main`.
- **Build protocol:** confirm each segment's scope before code; feel is verified on device.
- **Reuse before you build.** This tab is mostly an assembly job (see section 5). Grep first.
- **No em dashes** in copy or replies.

---

## 2. Current state (the starting point is not greenfield)

- **`MapView.swift` is a stub:** it renders `PairingSettingsView()` (a P2 pairing test harness, comment says "Replace with real Map/Desire Map implementation after P3 passes"). So the Map screen itself is greenfield, but the data and feature pieces it needs already exist.
- **`PrismView.swift` (833 lines, in `Features/Map/`) is a DEAD component.** It implements Journal / Reflect / Agreements with privacy labels and is currently rendered on **Home** via `HomeWidgetShell`. The new Map does **not** use it. Keep it in the repo as a visual reference to mine (its shell chrome, pill switcher, privacy-label treatment), do not delete it, do not build on it. (Removing it from Home is a separate Home cleanup, out of scope for this build.)
- **Already built and meant to be reused:** the whole `Features/Pulse/` feature, the `PulseEntry` model + `AppPulseEnums` + `AppColors.pulseTier*` tokens, `Home`'s `HomePulseRail`, the Desire layer (`DesireMatch`, `DesireRating`, `DesireSyncService`, `AppDesireEnums`), the `Couple` and `CardSession` models, and `PairingSettingsView`.

---

## 3. Cohesion contract (the yardstick from the audit)

The four-tab audit found the app has a strong shared spine but three divergent dialects in the details (three card languages, three masthead sizes, scattered token violations, Learn missing state coverage). **Map must not add a fourth dialect.** Hard rules for this build:

1. **Floor + sky:** `AppColors.void.ignoresSafeArea()` + `OnboardingAtmosphere(config: .stat)`, identical to Home/Play/Learn. (Map mockup currently differs only in dev chrome.)
2. **Masthead matches HOME, not Play/Learn.** The Map mockup uses `"Jordan."` (personal name) + sub + a top-right gear, which is Home's grammar. The app splits into **personal/mirror tabs (Home + Map)** and **editorial/content tabs (Play + Learn)**. Reuse Home's greeting/masthead construction (`HomeDashboardView` greeting block + name from `AppState`); do not invent a new header.
3. **ONE canonical glass card for every Map surface.** The mockup carries three card treatments (`idMini` playing-cards, `mecard`, plain translucent `.card`). Do not port them literally. Define or adopt a single shared glass-card modifier (the audit's #1 recommendation: a `.vaylGlassCard(accent:)` or an extended `.themedCard`) with one opacity, one radius, one border model, and use it everywhere. The playing-card foil look is a *variant* of that card (accent + foil overlay), not a separate system.
4. **Pulse uses the existing tokens + feature.** Bands Expansive/Sovereign/Friction/Protective map to `AppColors.pulseTierExpansive/Sovereign/Friction/Protective` (they exist). Reuse `Features/Pulse/*`, do not re-draw the graph.
5. **Navigation grammar:** all overlays via `.vaylSheet` (Pulse detail, Me Card, Vault, settings); the Pulse check-in via `.vaylCover`. No raw `.sheet`/`.fullScreenCover`.
6. **Tokens only:** `AppColors / AppFonts / AppSpacing / AppRadius / AppAnimation`. Zero hex, zero `.font(.system(...))`, zero magic numbers. (`AppColors.gold` does not exist; gold lives in `accentTertiary` + `safetyAccent`.)
7. **Empty / error / loading on every data surface.** Learn shipped without these; do not repeat that. Every Map data block (Pulse, Record, Align, Vault) needs a real empty/forming state (the mockup already specifies most: "No sessions yet", "No matches yet", "Your Pulse is forming").
8. **Reuse a shared segmented control** for Me/Us (and the Vault's Desire/Agreements toggle). Learn has `LearnSegmented`; promote it to a shared component rather than authoring a fourth bespoke segmented control.
9. **4-layer:** View reads from a new `MapStore` (`@Observable @MainActor`); the store calls existing services/repositories; no service or fetch logic in views.

---

## 4. Locked decisions

- **Me Card = full title-led identity, in V1** (Flavor color + chosen Title + Drawn-to tags + opt-in portrait/sigil). This is a real new-data workstream (Segment 3). Visual spec = `me-card.html`. **Prefer deriving content from existing Desire data where possible:** the "Drawn to" tags and "shared ones glow" are conceptually the Desire Map's mutual matches (`DesireMatch`), so derive them rather than inventing a parallel tag store. Only genuinely new identity data (the Flavor typology Explorer/Anchor/Catalyst/Architect, and the chosen Title) is net-new.
- **PrismView is dead:** not wired into Map, kept in repo, mine visually only.
- **Masthead matches Home** (personal name + sub + gear). Map and Home are the personal/mirror pair.
- **Pulse:** Home shows the glance (`HomePulseRail`), Map is the full Pulse hero + history + check-in entry. Same data + components, different depth. (Confirm the division with the human if it feels redundant on device.)

---

## 5. The reuse map (mockup section to existing code)

| Map mockup section | Build from | New work |
|---|---|---|
| Masthead (`"Jordan."` + sub + gear) | Home greeting block + `AppState` name; gear → `PairingSettingsView`/settings | thin |
| Me / Us toggle | promote `LearnSegmented` to shared | small |
| **The Pulse** hero (arc, bands, forming<7d, check-in) | `Features/Pulse/*` (`PulseGraph`, `PulseFullView`, `CheckInShell`), `PulseEntry`, `AppPulseEnums`, `AppColors.pulseTier*`; `HomePulseRail` for the cold-start placeholder | wiring only |
| The Record (session list + category spread) | `CardSession` history; `DeckCategory` for the distribution | list + empty state |
| **The Me Card** (title-led) | `me-card.html` visual; derive tags from `DesireMatch`; persist Title/Flavor on profile | Flavor enum, Title shortlist, card render + editor (biggest new piece) |
| Us: together stats | `Couple` + `CardSession` counts | thin |
| Us: where you align (mutual/adjacent) | `DesireMatch` / `DesireSyncService` | preview + empty state |
| The Vault: Desire Map + consent unlock | `DesireRating` / `DesireMatch`; reconcile with the existing Desire reveal work (`DesireRevealStore`, D4 stub) | consent flow |
| The Vault: Agreements + safe word | no `Agreement` model exists yet (PrismView held the concept, but it is dead) | new SwiftData model OR stub (pending, see section 7) |
| Settings (gear) | `PairingSettingsView` (currently the stub) | route |

---

## 6. Segmented build plan

Each segment: one thing, a device-verified done condition, a do-not-touch list. Confirm scope with the human before coding each.

- **Seg 0 — Shell + MapStore + the canonical card.** Replace the stub: `void` + `OnboardingAtmosphere(.stat)`, Home-style personal masthead, Me/Us segmented toggle, scroll, empty Me/Us layers. Create `MapStore`. **Define/adopt the shared glass-card modifier here** (cohesion rule #3) since every later segment depends on it. *Done:* masthead + working Me/Us toggle over the shared atmosphere; compiles + preview. *Do not touch:* Home, PrismView, Play, Learn.
- **Seg 1 — Pulse hero (Me).** Reuse `Features/Pulse/*` + `pulseTier*` tokens. Real arc from `PulseEntry`; forming<7d animated placeholder (reuse Home's); check-in pill → `CheckInShell` as `.vaylCover`; Pulse tap → `PulseFullView` as `.vaylSheet`. *Done:* real Pulse or forming state, check-in launches.
- **Seg 2 — The Record (Me).** Session history + category distribution from `CardSession`; empty state. *Done:* real sessions or "No sessions yet".
- **Seg 3 — The Me Card (full title-led).** Sub-segment: 3a data (Flavor enum + Title + tag derivation from `DesireMatch` + profile persistence), 3b compact `mecard` on the Me layer routed through the canonical card, 3c full card + Title chooser + tag/portrait editor in a `.vaylSheet`. *Done:* Me Card renders from profile; choosing a Title/tags persists.
- **Seg 4 — Us layer.** Together stats, couple card (crest), "where you align" preview from `DesireMatch` (mutual/adjacent), empty states. *Done:* couple summary + alignment preview or empties.
- **Seg 5 — The Vault (`.vaylSheet`).** Desire Map segment (counts, where-you-align, locked-more, consent "open a conversation") reusing the Desire layer + reconciling with the existing reveal work; Agreements segment (safe word + list + add) built fresh on the canonical card (PrismView may be mined visually, never imported). *Done:* Vault opens, both segments render, consent flow works or is the agreed stub.
- **Seg 6 — Settings + cohesion sweep.** Gear → settings/pairing; reduce-motion; final pass that every surface uses the canonical card, `pulseTier*` tokens, and has its empty/error state. *Done:* full tab cohesion-clean.

---

## 7. Open decisions for kickoff (resolve with the human, do not assume)

1. **Agreements persistence:** there is no `Agreement` SwiftData model. V1 = build a real `Agreement` model (with safe word) now, or ship the Agreements segment as a "coming" stub and add the model later?
2. **Consent-unlock depth:** the full ask → partner-flips → "a decline never discloses" flow, or a simpler reveal for V1 tied to the existing `DesireRevealStore` / D4 work?
3. **Me/Us as one screen vs two:** the mockup toggles layers in one scroll. Confirm that over a push or separate routes.
4. **Pulse redundancy:** Home glance + Map full. Confirm on device it does not feel like the same thing twice.
5. **PrismView on Home:** dead but still rendered there. Leave it (this build) and schedule a separate Home cleanup, or pull it in a follow-up.

---

## 8. References

- **Visual truth:** `docs/prototypes/map-dashboard.html` (the couple dashboard, Me/Us, Pulse, Record, Vault) and `docs/prototypes/me-card.html` (the title-led identity card, Flavor + Title chooser + Drawn-to tags).
- **Cohesion baseline:** Home (`Features/Home/Views/HomeDashboardView.swift`), Play (`Features/Play/`), Learn (`Features/Learn/`). Match Home's masthead and the shared atmosphere; reuse Play/Learn patterns where they are already token-clean.
- **Reuse targets:** `Features/Pulse/*`, `Core/Models/PulseEntry.swift`, `Core/Models/Enums/AppPulseEnums.swift`, `Core/Models/{DesireMatch,DesireRating,Couple,CardSession}.swift`, `Core/Services/DesireSyncService.swift`, `Features/Home/Components/HomePulseRail.swift`, `PairingSettingsView`.
- **Mine visually, do not import:** `Features/Map/PrismView.swift` (dead).
- **Architecture + tokens:** `CLAUDE.md`.

---

## 9. Continuation prompt for the new chat

```
You are a senior iOS engineer implementing the Map tab in Vayl (SwiftUI, Swift 6,
Xcode 26, iOS 16+). The top of the tab is greenfield (MapView is a stub), but most
of what the Map needs already exists in the codebase, so this is mostly a
reuse-and-assemble job. Your north star: ship a Map that is COHESIVE with Home,
Play, and Learn and with the existing data layer, not a fourth visual dialect.

READ FULLY, in this order, before touching code:
1. docs/handoffs/2026-06-24-map-tab-bridge.md  (this brief: current state, the
   cohesion contract in section 3, locked decisions, the reuse map, the segmented
   plan, and the open kickoff decisions in section 7).
2. docs/prototypes/map-dashboard.html and docs/prototypes/me-card.html  (the visual
   truth for the dashboard and the title-led identity card).
3. CLAUDE.md  (architecture law: zero raw literals, tokens only, .vaylSheet/.vaylCover,
   4-layer; and the build protocol: confirm each segment's scope before code, verify
   feel on device).
4. Skim Home's HomeDashboardView.swift (masthead + atmosphere to match), the
   Features/Pulse/ folder, and the Desire models (DesireMatch/DesireRating) so you
   reuse them instead of rebuilding.

LOCKED (do not redesign without the human):
- MapView is a stub (PairingSettingsView); replace it. PrismView.swift is a DEAD
  component: do not wire it in, do not delete it, mine it visually only.
- Masthead matches HOME (personal name + sub + gear), not Play/Learn's editorial
  wordmark. Home + Map are the personal/mirror tabs.
- Me Card = full title-led identity in V1 (Flavor + chosen Title + Drawn-to tags +
  opt-in portrait). Derive the tags from existing DesireMatch data where possible;
  only the Flavor typology and chosen Title are net-new.
- Reuse the Pulse feature (Features/Pulse/*, PulseEntry, AppColors.pulseTier*) for
  the Pulse hero; reuse Couple/CardSession/Desire layer for the rest.

COHESION CONTRACT (non-negotiable, full version in section 3 of the brief):
- void + OnboardingAtmosphere(.stat), same as the other tabs.
- ONE canonical glass-card modifier for every Map surface. The mockup carries three
  card languages; do not port them literally. Define/adopt a single shared glass card
  (e.g. .vaylGlassCard) in Segment 0 and use it everywhere; the foil playing-card look
  is a variant of it, not a separate system.
- Pulse bands use the pulseTier* tokens. All overlays via .vaylSheet, check-in via
  .vaylCover. Tokens only (no hex, no .system fonts, no magic numbers). Empty/error
  states on every data block. Promote LearnSegmented to a shared control for Me/Us.
- View -> MapStore (@Observable @MainActor) -> services -> models.

HARD CONSTRAINTS:
- Branch spec/contextphase-2x3-redesign directly. ~138 unrelated in-flight files.
  Never git add -A, never commit project.pbxproj, no worktrees/branches. New files
  under Vayl/Features/Map/ auto-join the target.
- Verify = compile + #Preview, not XCTest. Build:
  xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
  ("database is locked" = Xcode is busy, retry.)
- You compile; the human runs on device and judges feel. Hand over an exact device
  checklist. Do not claim it "works", say "compiles, here is what to verify."
- Reuse before you build. AppColors.gold does not exist.
- No em dashes in copy or replies.

FIRST MOVES:
1. Resolve the open kickoff decisions in section 7 of the brief with the human
   (Agreements model now vs stub; consent-unlock depth; one-screen Me/Us; Pulse
   redundancy; PrismView-on-Home cleanup).
2. Confirm and build Segment 0 (shell + MapStore + the canonical glass card), compile,
   and hand over a device checklist. Then proceed segment by segment per section 6,
   confirming scope before each.

Use the brainstorming + mobile-ios-design skills for any open design work.
```

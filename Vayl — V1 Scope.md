# Vayl — V1 Product Scope

> Source of truth: the codebase. This document reflects what is built and what is scoped for V1 ship.

---

## App Identity

**Name:** Vayl  
**Audience:** People navigating consensual non-monogamy (CNM) — solo, partnered, or coupled  
**Core loop:** Daily emotional check-in → prompt card session → reflection → relationship insight  
**Experience modes** (set at onboarding, persists in UserDefaults):
- `.browsing` — Guest, read-only access to Learn
- `.soloSingle` — Individual CNM journey, no partner
- `.soloPartnered` — Has a partner but using solo
- `.coupleNew` — Paired account, new to CNM
- `.coupleExperienced` — Paired account, experienced

---

## Navigation — 4 Tabs

```
Home  |  Play  |  Map  |  Learn
```

Custom `RacetrackTabBar` — animated pill draws/reverses between selections, 0.35s per direction with 0.1s handoff overlap. Haptic on selection.

---

## Tab 1 — Home ("The Cockpit")

Daily dashboard. Scroll-driven, opacity-animated greeting fades at 160pt scroll threshold.

**Entry routing** (`HomeRouterView`):

| State | Condition | Screen |
|---|---|---|
| `.gated` | Desire Map not started | Gate prompt |
| `.postReflection` | Post-map reflection pending | Reflection flow |
| `.waiting` | Partner hasn't completed map | Waiting screen |
| `.matchReady` | Both complete, reveal pending | Match reveal |
| `.dashboard` | Fully unlocked | HomeDashboardView |

**HomeDashboardView widgets (top → bottom):**

**The Deck** — `CardChestContainer`  
Fanned prompt card deck. Tap → gathered → lifted → carousel session (`CardCarousel`). Cards use `PremiumCardShell` with specular glass, ambient orbs, fuse animation. Difficulty maps to `CardIntensity` (8 levels: Void → Supernova).

**The Pulse** — `PulseWidget` / `CheckInShell` / `DailyCheckInView`  
7-day neon graph (`PulseGraph`). Inline `[+]` expands check-in directly — never a fullScreenCover. Cyan line = solo baseline. Persisted in `PulseStore` via UserDefaults.

**Pick Up** — `PickUpCard`  
Content recommendation cards. Context-aware, driven by `HomeEventEngine`.

**The Beacon** — `ResearchTicker`  
Auto-cycling research facts at the scroll floor. Tap → expands to full content in Learn tab.

**Supporting home components:** `HomeWidgetShell` (container shell), `PartnerChip` (partner presence indicator), `DesireMapIndicator` (status badge), `ReflectionCard`, `ReflectionBannerView`, `PostMapReflectionView`, `GravLiftView`.

---

## Tab 2 — Play ("The Simulator")

Proactive preparation and gamified exploration.

**Components built:**
- `PlayView` — tab root (structure exists, content in progress)
- `ConversationCard` + `ConversationCardTypes` — scenario cards
- `CategoryTileView` — category selector grid
- `AtmosphericGhostDeck` — deck atmosphere effect
- `CardCarousel` — horizontal scroll session container

**V1 scope:**

**Simulations** — RPG text scenarios. Solo or Couch Co-op (coupled mode).

**Pre-Flight** — 3-question diagnostic (Event type · Nervous System state · Biggest Fear) → generates custom emotional Flight Plan.

**The Path** — Vertical winding progression through glowing neon nodes (`ConstellationNode`). Completing nodes unlocks new Deck cards and Simulation levels.

**The Archive** — Searchable grid of all unlocked card categories.

---

## Tab 3 — Map ("The Nav System")

Long-term relational infrastructure. Two-panel toggle.

**Views built:** `MapView`, `PrismView`, `DesireMapView` (Compatibility)

**[ THE ORIGIN ] — Individual view**
- The User Manual: bandwidth, processing speed, communication preference sliders
- The Macro-Pulse: 30-day / 6-month solo emotional graph (extended `PulseGraph`)
- The Private Log: full archive of journals and solo reflections

**[ THE ORBIT ] — Network view**
- Constellation Carousel: horizontal scroll of partner cards. Proximity states: Docked · In Orbit · Deep Space
- Agreements Log: Mad Libs natural-language form builder
- Agreements Evolution: timeline from Restrictive → Relaxed

**Data models backing this:** `UserProfile` (SwiftData), `Couple`, `CoupleSessionRecord`, `DesireRating`, `DesireMatch`, `AssessmentResponse`, `AssessmentResult`

---

## Tab 4 — Learn ("Intelligence")

External wisdom and professional support. Available in `.browsing` guest mode.

**Views built:** `LearnView`, `ConstellationNode`

**V1 sections:**

**Dossiers** — Editorial summaries from Polysecure, The Ethical Slut, and curated CNM literature. Referential only — no clinical advice.

**The Lexicon** — Alphabetical glossary of CNM terms.

**The Library** — Curated reading lists and resource links.

**The Ground Crew**
- Peer Support: r/polyamory, r/nonmonogamy
- Professional Support: CNM-safe therapist directories
- Vetting Guide: "How to Interview a Therapist"

**The Beacon deep-link** — ResearchTicker items on Home expand into full Dossier entries here.

---

## Onboarding Flow (9 screens)

`OnboardingFlowView` orchestrates; `OnboardingBrandView` opens with the Vayl animation sequence.

| Screen | View |
|---|---|
| Brand animation | `OnboardingBrandView` |
| Name entry | `OnboardingNameView` |
| Mode select | `OnboardingModeSelectView` |
| Context | `OnboardingContextView` |
| Curiosity picker | `OnboardingCuriosityPickerView` |
| Building path | `OnboardingBuildingPathView` |
| Card reveal | `OnboardingCardRevealView` |
| Ground rules | `OnboardingGroundRulesView` |
| Stat reveal | `OnboardingStatView` |

Gate: `hasCompletedOnboarding` (@AppStorage) → shows onboarding or main app.

---

## Auth & Backend

- Sign in with Apple (`AuthService`, `SignInView`)
- Supabase backend (`SupabaseManager`, `SyncManager`)
- Sync services: `DesireSyncService`, `SessionSyncService`, `AssessmentSyncService`
- Local persistence: SwiftData (`UserProfile`, sessions, assessments, ratings)
- Pending sync retry on app launch

---

## What is NOT in V1

- Paywall / premium gating (folder exists, not wired)
- Push notifications
- In-app messaging between partners
- Therapist booking / external app launch (directory links only)
- Full session history analytics UI

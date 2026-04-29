# Open Lightly — LLM Audit Prompts

> One concern per session. Fresh conversation every time. Never combine more than two bundles.

---

## Bundle Quick Reference

| Bundle | Script | Load When |
|---|---|---|
| `foundation` | `gather_foundation.sh` | App-wide routing, theme changes |
| `design_system` | `gather_design_system.sh` | Any UI component or visual work |
| `onboarding` | `gather_onboarding.sh` | Any onboarding screen or flow |
| `sessions` | `gather_sessions.sh` | SessionView, cards, session persistence |
| `home` | `gather_home.sh` | Any home variant, ExperienceType routing |
| `data_sync` | `gather_data_sync.sh` | Services, models, Supabase, sync |

---

---

## Phase 1 — Targeted Audits

---

### 1 · Dead Code & Cleanup
**Feed:** `foundation` + `design_system`
**Purpose:** Confirm all flagged dead code, find anything else that's unused and safe to delete.

I'm auditing this Swift codebase for dead code and cleanup candidates.Known issues already flagged in the tracker:
FilamentMode.swift — entire file, no references
10 unused color tokens in AppColors.swift
CTABorderModifier in HoloCTAButton.swift:165-176 — defined but never used
GradBadge in GradientButton.swift:45-59 — only 2 usages
Your job:
Confirm each flagged item is genuinely unused by tracing all references
Find any additional dead code I haven't flagged yet
Find any imports that are unused
Find any private functions or computed vars that are never called
Find any ViewModifiers defined but never applied
For each item found, give me: file, line range, what it is,
confidence it's dead (high/medium/low), and safe removal steps.
---

### 2 · Design Token Extraction
**Feed:** `design_system`
**Purpose:** Find every magic number and propose the DesignTokens enum to replace them.

I'm extracting magic numbers into a DesignTokens system in Swift.The tracker already identified these candidates:
Corner radius 20 → DesignTokens.cardCornerRadius
Padding 28 → DesignTokens.cardPadding
Button height 56 → DesignTokens.buttonHeight
Border widths 1.5/2.5/3.0 → DesignTokens.borderStandard/strong/cta
Card transition 0.25-0.4s → Animation.cardTransition
spring(response:0.4, dampingFraction:0.75) used 7+ times → Animation.cardSpring
Triple light mode shadow block copied in 2 files → .lightGlowShadows() modifier
Dark/light border conditional repeated in 3+ files → ThemedBorderModifier
Your job:
Find every instance of each flagged value across all files
Find any additional magic numbers I haven't flagged
Propose the exact DesignTokens enum structure in Swift
For each constant, show me a before/after diff of one usage site
Flag any values that look identical but serve different semantic
purposes and should NOT be merged

---

### 3 · Naming Consistency
**Feed:** `foundation` + `design_system`
**Purpose:** Catch every naming violation against Swift conventions and internal consistency.

Audit this Swift codebase for naming inconsistencies.Already flagged:
mythBusterComplete → hasMythBusterCompleted (UserProfile.swift:39)
mythBusterSkipped → isMythBusterSkipped (UserProfile.swift:40)
index/total params → cardIndex/totalCards (ContextCard.swift:7-8)
@Environment var t → palette (ProgressRingView, ContextCard)
NM abbreviation usage inconsistency across AppEnums
Your job:
Confirm each flagged item and show me the exact rename
Find additional boolean properties not following is/has/can/should convention
Find single-letter or overly abbreviated variable names
Find any type names that don't match their file names
Find inconsistencies in how environment variables are named
across views (some use t, some use theme, some use palette)
Check for any Swift API Design Guidelines violations
(parameter labels, method names, etc.)
For each issue: file, line, current name, proposed name, reason.
---

### 4 · Services Layer Architecture
**Feed:** `data_sync`
**Purpose:** Fix production risks — crashes, silent failures, hardcoded keys, legacy patterns.

Audit the services and persistence layer of this Swift app.Critical issues already flagged:
Config.swift: API keys hardcoded in source
SyncManager: hardcoded UserDefaults strings vs PersistenceKey enum in AppState
ProfileService: nested SupabaseProfile struct should be extracted
ContentLoader: fatalError on JSON parse failure
AuthService/ProfileService/PairingService: legacy ObservableObject
(not yet migrated to @Observable)
Your job:
For each flagged issue, give me the exact refactor with code
Find any other places where UserDefaults keys are hardcoded strings
Find any other fatalError or force-unwrap (!) that could crash in production
Identify any missing error handling (silent failures, empty catch blocks)
Identify any race conditions or actor isolation issues
Check if the local-first sync pattern (SwiftData → Supabase → retry)
is applied consistently across ALL sync services
Find any duplicated logic between sync services that should be extracted
Prioritize by production risk: crashes first, data loss second, inconsistency third.
---

### 5 · SessionView God Object Refactor
**Feed:** `sessions`
**Purpose:** Break SessionView into clean, testable pieces with a proper ViewModel.

SessionView in this app is a god object — it manages session state,
UI presentation, timing, card advancement, progress tracking, and
persistence all in one view with 50+ lines of logic.Your job:
Read SessionView fully and map every responsibility it currently holds
Propose a decomposition: which responsibilities should move where
(ViewModel, dedicated service, child view, etc.)
Write the SessionViewModel with proper @Observable, actor isolation,
and clean separation from the view layer
Show me how SessionView looks after the refactor (thin view only)
Identify any state that's currently local to the view that should
actually live in DataStore or SyncManager
Check that SafeWordButton's callback chain still works correctly
after the refactor
Show full code for each proposed file, not pseudocode.
---

### 6 · Onboarding Flow Integrity
**Feed:** `onboarding`
**Purpose:** Verify no data is dropped, no screen can be skipped incorrectly, and all animations are clean.

Audit the onboarding flow of this SwiftUI app for logic and correctness issues.Your job:
Trace the complete data flow from OnboardingFlowView through each screen
to the final AppState write — confirm no data is dropped or overwritten
Verify ExperienceType derivation logic covers all combinations
of mode + NMStage + relationship context
Check that OnboardingData is correctly passed as @Binding where needed
vs copied by value
Find any screen that could call advance() without required fields filled
Check the ANIM-STD protocol — are all screens implementing the
three-slot cascade correctly? Any that deviate without reason?
Find any animation state that isn't cleaned up on view disappear
Check PairingForkView — does "Pair Later" leave the user in a
broken state for the full app lifecycle?
Find any missing reduce-motion fallbacks
For each issue: severity (blocks user / data loss / cosmetic), file, line, and fix.
---

### 7 · Theme System Completeness
**Feed:** `foundation`
**Purpose:** Confirm every palette token is used, every mode resolves correctly, and no raw colors bypass the system.

Audit the theme system of this Swift app for completeness and consistency.Your job:
Map every semantic color in AppPalette — confirm each token
is actually used at least once in the design system
Find the 10 flagged unused raw tokens in AppColors and confirm
none are referenced by any theme calculation
Check that all three ThemeModes (system/light/amoled) produce
valid palettes — no token returns nil or falls back silently
Find any place in ThemeManager where the palette could be stale
(colorScheme changes not triggering a re-resolve)
Check that ThemedRootModifier is only applied once — confirm there's
no double-application risk
Find any hardcoded Color() or UIColor() calls in theme files
that bypass AppColors
Are there any tokens used in design components that don't exist
in AppPalette (compile error or runtime crash risk)?
Output: a table of all palette tokens with used/unused status,
plus a list of issues ordered by severity.
---
---

## Phase 2 — Cross-Boundary Audits

> These sessions need two bundles because the issue lives at the seam between systems.

---

### 8 · Onboarding → Home Handoff
**Feed:** `onboarding` + `home`
**Purpose:** Verify the transition from onboarding completion to the correct home screen is airtight.

Audit the handoff between the onboarding flow and the home screens.The handoff point: OnboardingFlowView writes ExperienceType to AppState
and sets hasCompletedOnboarding, then ContentView routes to the tab bar,
and HomeView switches on experienceType to render the correct variant.Your job:
Confirm every ExperienceType case has a corresponding home view —
no case falls through to a default without a real screen
Check that AppState.experienceType is always set before
hasCompletedOnboarding is set to true
Find any home view that reads OnboardingData or assumes onboarding
state that may not be guaranteed
Check the guest/browsing path — can a user reach a home view
they shouldn't see without completing onboarding?
Find any timing issue where the home screen renders before
ExperienceType is fully written
Check HomeGateView — does it handle the case where ExperienceType
is set but UserProfile doesn't exist yet in SwiftData?

---

### 9 · Sync Completeness vs Data Models
**Feed:** `data_sync`
**Purpose:** Confirm every model that should be synced is synced, and nothing is silently dropped.

Audit the completeness of the sync layer against the data models.Your job:
For every @Model class, determine: is it synced to Supabase?
If yes, which SyncService handles it? If no, is that intentional?
Are there any models that should be synced but have no SyncService?
For each SyncService, check: does it handle all fields on the model,
or are some fields silently dropped during sync?
Check the retry mechanism in SyncManager — if a push fails and
is flagged for retry, what happens if the model is modified
before the retry fires?
Are there any models that get deleted locally but the deletion
is never pushed to Supabase?
Check Couple cascade delete — "deleting a Couple does NOT delete
the profiles" — is this enforced in SwiftData relationships
or just documented intent?

---

### 10 · Design Compliance (run once per feature)
**Feed:** `design_system` + ONE of `onboarding` / `home` / `sessions`
**Purpose:** Catch any feature screen that bypasses the design system or reinvents existing components.

Audit [FEATURE] screens for design system compliance.Your job:
Find any view that uses hardcoded Color(), font(), or padding values
instead of AppColors, AppFonts, or AppPalette tokens
Find any view that re-implements something that already exists
as a design component (e.g. rolling their own card style
instead of using CardStyle modifier)
Find any view that accesses @Environment(.theme) inconsistently
with how other views use it
Find any animation using magic number durations instead of
a shared constant
Find any component from Design/Components that this feature
should use but isn't
Find any one-off components defined inside feature files
that belong in Design/Components
Output as a table: file, line, issue type, current code, recommended fix.
---
---

## After Each Audit — Tracker Update

**Feed:** No code. Paste the raw audit output only.
**Purpose:** Reformat findings into FILE_TRACKER.md structure.

I just ran a codebase audit and got the following findings.
Organize them for my FILE_TRACKER.md:[PASTE AUDIT OUTPUT HERE]Format each finding into the correct table:
🚨 Critical Issues  (security / crash / data loss)
🗑️ Dead Code        (safe to delete)
⚠️ Code Quality     (smells, legacy patterns, structural issues)
🔧 Magic Numbers    (missing constants)
📊 Naming Issues    (convention violations)
Columns for each table: Item | File | Lines | Action | Priority (P0/P1/P2)
---
---

## Recommended Model by Session

| Session | Model | Reason |
|---|---|---|
| Dead code tracing | Claude 3.5 Sonnet | Deep reference tracing |
| Design token extraction | Claude 3.5 Sonnet | Precise find-and-replace |
| Naming consistency | GPT-4o | Strong Swift conventions |
| Services architecture | Claude 3.5 Sonnet | Best at Swift/actor/async |
| SessionView refactor | Claude 3.5 Sonnet | Full code output quality |
| Onboarding flow integrity | Claude 3.5 Sonnet | Stateful flow tracing |
| Theme completeness | Any | Small context, simple task |
| Cross-boundary (90+ files) | Gemini 1.5 Pro | Largest reliable context |
| Tracker consolidation | Any | Summarization only |

---

## Execution Order

Week 1 — Low risk, high signal
Theme completeness     foundation only          ~10 files
Dead code cleanup      foundation + design      ~57 files
Naming consistency     foundation + design      ~57 files
Week 2 — Architecture
4. Services layer         data_sync only           ~45 files
5. Sync completeness      data_sync only           ~45 files
6. Design tokens          design only              ~47 filesWeek 3 — Feature level
7. Onboarding integrity   onboarding only          ~55 files
8. SessionView refactor   sessions only            ~25 files
9. Design compliance ×3   design + 1 feature       ~70-100 filesWeek 4 — Cross-boundary
10. OB → Home handoff     onboarding + home        ~90 files
11. Update FILE_TRACKER   audit outputs only       no code
---

> **Rule:** Fresh conversation for every session. Prior context in a chat poisons the reasoning — the model pattern-matches what it already saw instead of reading carefully.

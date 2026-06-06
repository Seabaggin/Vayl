# Vayl — Session Progress

> Paste this at the start of every new chat alongside any relevant files.
> Update by asking the AI: "Generate an updated PROGRESS.md based on what we did today."

**Last updated:** 2026-05-16
**Current branch:** master

---

## Active Task

**NamePhase card deal animation — ready to implement.**

Implementation plan is at:
`docs/superpowers/plans/2026-05-16-namephase-card-deal-animation.md`

Design spec is at:
`docs/superpowers/specs/2026-05-16-statphase-to-namephase-deal-animation-design.md`

Use `superpowers:subagent-driven-development` to execute task by task.

---

## Recently Completed

- All OB phase stubs (routing verified)
- Theme system — all files updated with proper design tokens
- SplashScreenView — standalone brand screen, not part of OB flow
- VaylButton + border effect overhaul
- StatPhase — full implementation (matches old OB stat screen)
- TableSurfaceView — Canvas renderer, full table surface with topo lines, compass star, spectrum rim arc
- VaylCardBack — vertical (OB) and horizontal (session) variants
- VaylCardFace — near-final, works in OB and app contexts. Has `question` and `credential` params.
- OB sequence spec v2 — full design doc in Downloads

## Pending / Want to Revisit

- HoloShimmer — needs another pass
- Liquid Metal Button — needs spec before build

---

## OB Architecture (non-negotiable)

- Single persistent canvas — `OnboardingCanvasView` driven by `VaylDirector`. No NavigationStack inside OB.
- Everything is a phase overlay or renderer on the same ZStack. The table never leaves memory.
- `VaylDirector` is the only thing that advances phase. Views dispatch intents. Director decides.
- Phases are overlays, not screens. They never own persistent state.
- `OnboardingStore.commit()` creates `UserProfile` on completion. Never before.
- Vertical cards = OB / personal. Horizontal cards = session / shared. Never broken.

## OB Phase Sequence (current)

`.statView` → `.nameInput` → `.gender` → `.modeSelect` → `.contextView` → `.curiosityPicker` → `.cardSelect` → `.buildingPath` → `.founderLetter` → `.deckCeremony` → `.appArrival`

No calibration phase. No prescreen. Sequence begins at StatView.

## Key Files for NamePhase Work

| File | Role |
|------|------|
| `Vayl/Features/Onboarding/Phases/NamePhase.swift` | **Primary target** — currently a stub, full implementation needed |
| `Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift` | Needs `rimBurst: Double` parameter added |
| `Vayl/Features/Onboarding/Canvas/OBDeepCardFace.swift` | **New file** — Pensieve card face Canvas renderer |
| `Vayl/Design/Components/Cards/VaylCardBack.swift` | Existing — used for card back during deal |
| `Vayl/Design/Components/Cards/VaylCardFace.swift` | Existing — used post-expand for name input overlay |
| `Vayl/Features/Onboarding/Store/VaylDirector.swift` | Director — read to understand advance(to:) and onboardingData |

---

## What the New Session Should Do

1. Read the plan: `docs/superpowers/plans/2026-05-16-namephase-card-deal-animation.md`
2. Use `superpowers:subagent-driven-development` skill
3. Execute Task 1 first (rimBurst on TableSurfaceView) — it's the smallest and unblocks everything
4. Tasks must be done in order: 1 → 2 → 3 → 4 → 5
5. Test on physical device before marking complete — `.drawingGroup()` + animation feel cannot be verified in simulator

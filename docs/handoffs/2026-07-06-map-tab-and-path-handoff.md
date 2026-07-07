# Handoff — Map tab dashboard (shipped) + The Path feature (designed, not built)

Paste this as the first message in a new session.

---

I'm Bryan, building **Vayl** — a dark, premium SwiftUI iOS app for couples exploring
non-monogamy together. Repo: `/Users/bryanjorden/Documents/School/Code/Vayl`, branch
`design_finalized`. Read `CLAUDE.md` at the repo root first — it's non-negotiable
project rules (4-layer architecture, design token contract, animation feel contract,
presentation grammar, humility/discovery-not-assessment product principles). Read my
memory files too if you have access to them (auto-memory system) — there's a lot of
accumulated context there about how I like to work.

## What's already shipped (this session, fully built + reviewed + committed)

The **Map tab dashboard** — spec at
`docs/superpowers/specs/2026-07-05-map-tab-dashboard-design.md` — is built end to end:
the Me/Us lens system (name-toggle masthead, gated on pairing, a one-shot reveal
ceremony, ambient lens tint), the complete Pulse pillar (hero-sized aura for Me, a
split-orb hero for Us with a per-half unwritten/current/quiet state machine and a
custom ambient glow), and the Vault door card with a spin-open ceremony into the
existing `VaultSheet`. Built via a 10-task subagent-driven plan
(`docs/superpowers/plans/2026-07-05-map-tab-dashboard-plan.md`), every task
spec-reviewed and code-reviewed before merge. Also: Settings collapsed from a 5th tab
into a masthead gear + full-screen cover (Map only, not every tab), and a real bug fix
where `MapPulseHero`'s aura dimmed a full 3 days sooner than the Us orb for the same
Pulse reading (now both share `PulseStore.isPositionQuiet`, keyed off
`UsOrbState.quietAfterDays`).

**Don't re-litigate any of this** — it's settled, reviewed, and on device-testing
standby (Bryan runs the app himself; Claude compile-verifies only, never claims a
feel is correct without a device pass).

## What's designed but NOT built: The Path feature

Full design spec at **`docs/superpowers/specs/2026-07-06-path-feature-design.md`** —
read it in full before doing anything. It went through an adversarial review pass
(a dispatched agent stress-tested it for gaps) and the findings are already folded in.
High points: one style at launch (Swinging, 13 landmarks/5 phases, geometry ported
literally from `docs/prototypes/map-roadmap-swinging.html` — never redrawn or
approximated), five node states with a real mutual-confirmation rule on "already
ours," skip-as-removal with an Edit-your-path recovery screen, solo/couple/
active-support framing as one shared screen family (not parallel UIs), a quick-session
exception to the normal 3-card session floor that still requires real partner presence
(reuses `AirlockStore`'s presence signal, skips only the ceremony), and a partner-pill
session invite replacing the old `PendingSessionBanner` entirely.

**§0 of that spec explicitly excludes the Map dashboard's Path widget** — the
collapsed card a user taps to open the trail. I'm reconsidering the container (not
necessarily the `pathfs` full-bleed-trail-slice style shown in the family mockups).
That's unresolved and is probably the first thing to design once we're back in this.

**§9 of the spec lists open items still needing a decision** — read them before
planning an implementation. The two that need MY input specifically, not a default
guess: (5) does a solo user's private pre-partner landmark stance ever surface after
they pair up, and (6) the missing-discussion-card fallback exact behavior (depends on
real content coverage, decide once cards are actually authored).

## Process this project uses (follow it)

Brainstorm → spec (written to `docs/superpowers/specs/`, committed) → implementation
plan (`docs/superpowers/plans/`, task-by-task with file paths and done-conditions) →
build via `subagent-driven-development` (fresh subagent per task, spec-review then
code-review before moving on). Don't skip straight to code on anything nontrivial.

**Mockups**: HTML only (never SVG for UI/design-option visuals), written to
`docs/prototypes/`, using the established dark/spectrum (cyan→purple→magenta) visual
language already all over that folder. When a mockup is "the reference we're building
from," port its exact geometry/CSS values — don't approximate or reinterpret. I will
call it out directly if something drifts from a reference (I've done this multiple
times this session and it's always been a real fidelity gap, not me being picky).

**Verification**: Claude compile-verifies (`xcodebuild ... build`, add
`CODE_SIGNING_ALLOWED=NO` if codesign fights iCloud file-provider metadata — a known
repo quirk, not a real error) and runs any Swift tests. I run the app on device myself
for feel. Never claim something "works" or "feels right" without that distinction.

**Git**: commit only what you actually changed (never `git add -A`), NEVER touch
anything with `--force`/`--hard`/`--no-verify` without asking first, check
`git status` before anything destructive since I sometimes have work in progress
alongside yours.

## Likely next step

Either (a) design the Map dashboard's Path widget (the piece §0 deliberately left
out), or (b) start resolving the §9 open items and move to writing the Path
implementation plan. Ask me which before doing either — don't assume.

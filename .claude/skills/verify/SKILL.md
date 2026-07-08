---
name: verify (Vayl project)
description: How to verify a Vayl change. Build + test is the ceiling for Claude; on-device/simulator UI driving is explicitly reserved for Bryan.
---

# Verifying changes in Vayl

Vayl is a native SwiftUI iOS app (Xcode project, not a web app) — there is no
headless-browser/CLI/socket surface to drive automatically the way the generic
`verify` skill assumes.

**Standing project rule (confirmed repeatedly, not a one-off preference):**
Claude build-verifies only (compiles, runs the test suite). Bryan runs the app
on simulator/device himself and confirms feel. Do not launch a simulator,
attempt to screenshot the UI, or claim a UI/interaction verdict — that
surface is explicitly his, not something to work around with `xcrun simctl`
or similar.

## What "verify" means here, in order of strength

1. **Build**: `xcodebuild build -scheme Vayl -destination 'generic/platform=iOS Simulator'`
   from the repo root. Expect `** BUILD SUCCEEDED **`. Read the actual log,
   don't just check exit code — warnings matter.
2. **Tests**: `xcodebuild test -scheme Vayl -destination 'platform=iOS Simulator,name=<device>'
   -only-testing:VaylTests/<TestClass>` for whatever the change touches. This
   exercises real Store/Service logic end-to-end against real or mock
   transports — the closest thing to "driving the surface" available for
   non-UI logic. `VaylTests` is a manually-maintained `PBXGroup`; a new test
   file that isn't wired into `project.pbxproj` will silently match zero
   tests and report a vacuous pass — confirm the test actually ran (check the
   test count in the log), not just that the command exited 0.
3. **Code read-through**: for anything with a UI component, read the actual
   shipped files (not a summary of them) and cross-check against the design
   mockup / spec. This is the substitute for driving the GUI.

## Verdict framing for this project

- Build failing or tests failing → **FAIL**, unambiguous.
- Build + tests pass, but the change has a real UI/interaction surface
  (a new screen, a new gesture, a visual state) → the *code-level* verdict
  can be PASS, but explicitly say the UI/feel verdict is **BLOCKED —
  reserved for Bryan's device pass**, not a silent omission. Don't claim
  "verified" for anything you didn't actually run or read.
- A pure Store/Service/Model change with real test coverage → PASS is
  legitimate on its own, since the tests are exercising real code paths, not
  just "reading it and knowing it works."

## Gotchas specific to this repo

- `Vayl/` (the main app target) is a `PBXFileSystemSynchronizedRootGroup` —
  new files under it are picked up automatically, no manual pbxproj edit
  needed. `VaylTests/` is NOT synchronized — new test files need the 4-part
  manual wiring (PBXBuildFile, PBXFileReference, group children, Sources
  build phase). See any recent Path-feature commit for the exact pattern.
- Postgres RLS: a `DELETE`/`UPDATE` with no matching policy silently affects
  0 rows and returns success — a missing policy does not surface as a build
  or test failure. If a change adds a new write path against Supabase,
  explicitly check the migration includes a policy for every write the code
  performs, not just that the migration "ran."
- `docs/` is gitignored (design/planning docs untracked by policy) — don't
  assume a spec/plan file referenced in a commit message is present unless
  you actually check.

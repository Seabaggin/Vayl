# Fable One-Shot Plans — Shared Preamble

_This file is the shared header + format + context every plan in `docs/fable-plans/` inherits.
Each plan pastes the **ONE-SHOT LICENSE** block verbatim at its top, then follows the **FORMAT**._

---

## ⚡ ONE-SHOT LICENSE — convention override (paste verbatim at the top of every plan)

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

## FORMAT — every plan follows this shape

1. **Title + Goal** — one sentence describing what the finished pass produces.
2. **The ONE-SHOT LICENSE block** (verbatim, above).
3. **Context Fable needs** — 4–8 bullets: what this feature is, where it sits in the app, its current
   state (built / partial / todo, with evidence), and the **canonical patterns to imitate** (name the exact
   reference files, e.g. "model the Store on `PairingStore.swift`").
4. **Files** — a table with three sections: **Create** / **Modify** (with line anchors) / **Delete**, each row
   naming the file and its one responsibility.
5. **Build steps (segments)** — the feature broken into ordered segments for *readability*, but all built in
   one pass. Each segment: **one thing it does**, then the **exact changes** with **real Swift code blocks**
   that match the surrounding style and use real tokens, then a one-line **done** condition.
6. **Definition of Done (build-green)** — the consolidated behavioral checklist that must be true when the
   single pass is finished and the project compiles.
7. **Bryan verifies on device** — the checklist Bryan runs afterward (feel, two-device, etc.).
8. **Constraints / do-not-touch** — files that are off-limits, invariants that must hold.
9. **Open decisions** — anything genuinely needing Bryan's call, **each with a recommended default** so
   Fable is never blocked (it proceeds on the default and flags it).

**No placeholders.** Never write "add error handling", "TBD", "similar to above", or a step without the
code. If a step changes code, show the code. Repeat code rather than cross-referencing — Fable may read
segments out of order.

---

## Global context (true for the whole app)

- **App:** Vayl — a SwiftUI, iOS-26-SDK, Swift-5-mode couples app for non-monogamy discovery. Solo dev
  (Bryan). Dark-only. Aesthetic: void black + spectrum (cyan → purple → magenta) + glass.
- **Entry roots:** `VaylApp @main → AppRootView → { OnboardingCanvasWrapper, SignInView, AppShell tabs }`.
  Tabs: Home, Play (Cards), Map, Learn. Settings is a route, not a tab.
- **Token source of truth:** `Vayl/App/Theme/` — `AppColors`, `AppFonts` (`.display(_:weight:relativeTo:)`
  / `.body(...)`), `AppSpacing` (xxs 2 … xxl 48), `AppRadius`, `AppLayout` (`from(geo)`), `AppAnimation`,
  `AppGlows`, `AppElevation`. **Read the file before using a token.**
- **Presentation:** `Vayl/Design/Components/Navigation/VaylPresentation.swift` defines `.vaylCover` /
  `.vaylSheet`.
- **Copy rule:** **no em dashes** in any Vayl user-facing copy (use commas / periods / colons; hyphens in
  compounds are fine). This applies to any strings you write.
- **Persistence:** SwiftData (`SchemaV1` in `Vayl/App/ModelContainer.swift`) + Supabase (project
  `ynhjlabjzauamntbyxdp`). Services use `saveWithLogging()`, never bare `try? context.save()` where data
  loss matters. Supabase MCP is read-only from Claude; edge functions live in `supabase/functions/`.
- **Bryan does not run the sim from Claude/Fable.** Every plan ends by compiling green + handing Bryan a
  device checklist. Never claim a feature "works" from a build alone.
- **Solo vs couple:** V1 is couples-first but the solo lane must degrade gracefully (no dead ends, no
  hardcoded "Alex"). Some Stores have `#if DEBUG` overrides seeding a fake partner — do not let those leak
  into release behavior.

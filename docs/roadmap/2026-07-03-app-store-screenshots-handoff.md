# App Store Screenshots — Handoff

**Date:** 2026-07-03
**Scope:** Marketing/App Store screenshot set for Vayl (not a Swift implementation task, but surfaced two real code findings worth acting on — see §4 and §5)
**Status:** Screen 1 mocked and ready for review. Screen 2 not started. Screen 3 **blocked** — see §3.

---

## 1. Objective

Vayl gets 3 App Store screenshot slots. Strategy locked in this session:

1. **The Deck** — a card mid-session, real prompt visible, response controls showing
2. **Desire Map** — the mutual-match reveal moment (blurred → revealed)
3. **Pulse** — the capacity trend / check-in visual

Principle carried across all three: show the feature actually working (real screens, real copy, real data), not a text slide with an icon. Same caption typography and device framing across all three so they read as one strip in App Store search thumbnails.

---

## 2. Screen 1 — The Deck: done

**Artifact:** https://claude.ai/code/artifact/da28f81d-a010-479f-a768-d58633666637 (left panel; this half is still accurate)

Card shown: the intensity-4 prompt from `the-opener.json` — *"Where does communication between you two usually fall apart? What does that moment typically look like?"* — chosen over the intensity-7+ sensitive cards because it's emotionally resonant to anyone in a relationship, not just CNM-specific, and avoids App Review friction.

**Built at 1:1 token scale** — phone canvas sized to 402pt (iPhone point width) so `AppSpacing`/`AppRadius`/`AppFonts` values map directly to CSS pixels, not eyeballed. Fonts are the actual `.otf` files from `Vayl/Resources/Fonts/` (ClashDisplay-Medium/Semibold/Bold, Switzer-Regular/Medium/Semibold), inlined as base64 `@font-face`, not system substitutes.

### Real code gap found

`Vayl/Features/Sessions/SessionView.swift` currently renders the prompt as bare `Text` with `AppFonts.bodyText` — **no card chrome at all**. The polished spectrum-outline card look only exists today in Onboarding (`VaylCardFace`). The mockup shows what an elevated `SessionView` card would look like.

**Token boundary respected on purpose:** the mockup does **not** use `AppColors.void`, the OB `cardBg`, or `AppRadius.obCard` — CLAUDE.md and the token doc comments scope those to the Onboarding canvas only ("the table metaphor does not leave the OB boundary"). Instead it composes from `AppColors.cardBackground` + `AppRadius.lg` (16pt) + the universal `AppColors.spectrumBorder` gradient, which its own comment says is "applied to every prompt card and bordered surface" — i.e. meant for exactly this.

**Suggested follow-up (not yet started):** wire this card treatment into the real `SessionView.swift`. Scoped segment: files limited to `Features/Sessions/`, done condition = verified in simulator that the card renders with the spectrum border and matches the mockup.

---

## 3. Screen 3 — Pulse: BLOCKED

User flagged that the shipped/current Pulse feature "has been completely revamped" and doesn't match what's in this repo. Investigation this session:

### What's actually in the repo (confirmed, all branches)

- `Vayl/Features/Pulse/PulseGraph.swift` — a straight-line "EKG" chart (file header explicitly says "NO fill underneath — EKG not stock chart"), not an area/aura fill. 7-day window via `PulseWindow.oneWeek`. Line gradient: dark mode `accentPrimary → accentSecondary → accentTertiary` (cyan `#00C2FF` → purple `#6C3AE0` → magenta `#FF006A`).
- The closest thing to a data-encoding "orb" is the **breathing dot at the graph's last point** (`liveBreathingDot`, now inlined into `dotsOverlay`) — halo 28pt+breath, mid ring 18pt, core 12pt, color = `lineColors[2]` (`accentTertiary`/magenta), breathes on a 4.0s sine (`AppAnimation.ambientDrift`).
- `Vayl/Design/Components/Effects/GlowOrb.swift` exists but is **referenced nowhere** — dead code.
- `OrbLayer` in `HomeWidgetShell.swift` is ambient decorative background glow behind the Pulse widget — doesn't encode a value.
- Tier labels (`AppPulseEnums.swift`): "The Expansive/Sovereign/Friction/Protective Space", with sublabels e.g. "Grounded · Secure".
- **Two color systems for the same concept, unreconciled:** the graph (`PulseGraph.swift`, `PulseWidget.swift`) colors tiers via `accentPrimary/Secondary/Tertiary` + `safetyAccent`. A separate, purpose-built set of tokens — `AppColors.pulseTierExpansive/Sovereign/Friction/Protective` — exists and is used instead in `DailyCheckInView.swift` and `TierGuideSheet.swift`. Worth reconciling regardless of the screenshot work.

### Branches checked

- Current branch (`claude/vayl-app-store-screenshots-77kzcj`) — clean, matches the above.
- `master` — same.
- `origin/feat/home-redesign-onboarding-polish` (discovered mid-session via `git fetch`, not previously visible) — touches `PulseGraph.swift`, `PulseSheetView.swift`, `HomeWidgetShell.swift`, and several Home files. **Diffed line by line: every Pulse-related change on this branch is a pure refactor** (inlining `sampledDots`/`lastEntryDot`/`liveBreathingDot` into one `dotsOverlay`; inlining `primaryOrb`/`secondaryOrb` into `OrbLayer.body`). Every color, size, and animation value is byte-for-byte identical to current. No visual change.

### Conclusion

No branch, commit, or doc in this repository shows a Pulse design different from what's described above. If Pulse has genuinely been revamped, that work is not committed here — it's either ahead of this repo (a build on-device, a design file) or the user is picturing a different visual than what's built.

### Unblocks with

A screenshot or description of the actual current Pulse UI. Specifically need: is it still a line graph, or literally a single orb whose size/color encodes today's capacity; what "aura" refers to visually; any new tier/label copy.

**Superseded mockup:** the right panel of https://claude.ai/code/artifact/da28f81d-a010-479f-a768-d58633666637 was built from the repo state above — treat it as void until the real design is confirmed. Screen 1 (left panel) is unaffected and still valid.

---

## 4. Screen 2 — Desire Map: not started

No investigation done yet this session. Next step when picked back up: research `Features/Compatibility/` the same way Screens 1 and 3 were researched (real copy/content, actual reveal-state visuals, real tokens) before mocking.

---

## 5. Reusable technique for future token-accurate mockups

For any future "show me a token-accurate mockup" request:

1. Pull exact hex values from `Vayl/App/Theme/AppColors.swift` + `VaylPrimitives.swift` — don't approximate from memory.
2. Pull exact font weights/sizes from `Vayl/App/Theme/AppFonts.swift`.
3. The actual font files live at `Vayl/Resources/Fonts/*.otf` (ClashDisplay, Switzer) — base64-encode and inline as `@font-face` data URIs rather than using a system-font fallback. Sizes are small enough (~25-65KB per weight) that this is cheap.
4. Size the mockup canvas at 1:1 with iPhone point dimensions (e.g. 402×874) so `AppSpacing`/`AppRadius` values can be used directly as CSS px, not scaled/eyeballed.
5. Flag, in the mockup itself, anywhere the composition departs from what's actually wired up in the current View (e.g. Screen 1's `SessionView` card-chrome gap) and anywhere it deliberately avoids a scope-restricted token (e.g. OB-only `void`/`obCard`).
6. Before trusting any "this doesn't look right" feedback about a feature's current state, `git fetch` and check for branches beyond what's already checked out — this session found a relevant branch that wasn't visible until an explicit fetch.

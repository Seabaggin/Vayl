---
target: SettingsView (AI-slop check)
total_score: 32
p0_count: 0
p1_count: 1
timestamp: 2026-07-12T01-25-47Z
slug: vayl-features-settings-settingsview-swift
---
Method: dual-agent (A: general-purpose design/slop review · B: Explore native evidence sweep). Native SwiftUI target; web detector + browser overlay N/A, native source sweep substituted. No simulator driven.

## Verdict: NOT AI slop

SettingsView is a coherent, human-authored settings surface built on a real design system. The defining slop tells are absent: a genuine information architecture (You / Partner / App / Account & data / About / Membership), specific human copy (the delete-account consequence text, the composition "not a label on either of you" disclaimer), and the correct native controls in the load-bearing places (`Toggle`, `confirmationDialog`, `alert`, `vaylSafariSheet`). What holds it below "impeccable" is self-inflicted craft debt, not genericness.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Error alert exists; no visible progress on sign-out/delete; "Restore" is inert. |
| 2 | Match System / Real World | 4 | Copy is human and concrete; labels map to user language. |
| 3 | User Control and Freedom | 3 | Destructive actions cancelable; back-chevron-inside-a-sheet mixes push/modal models. |
| 4 | Consistency and Standards | 2 | Hand-rolled list vs iOS Form; youSection duplicates SettingsNavRow; custom Save bar + custom picker. |
| 5 | Error Prevention | 4 | Delete/sign-out/unlink all gated with clear consequence copy. |
| 6 | Recognition Rather Than Recall | 4 | Current values surfaced inline (composition, identity). |
| 7 | Flexibility and Efficiency | 3 | Adequate; no shortcuts needed at this scale. |
| 8 | Aesthetic and Minimalist | 3 | Clean, but spectrum hairline on every card + membership gradient over-decorate a task surface. |
| 9 | Error Recovery | 3 | Generic "Something went wrong"; notifications-denied deep-links to Settings (good). |
| 10 | Help and Documentation | 2 | "Support" row has an empty action; no help content. |
| **Total** | | **32/40** | **Good — bespoke and trustworthy; a few fixes from "disappears into the task."** |

## Anti-Patterns Verdict

**LLM assessment:** Not slop. Real IA, human copy, standard affordances where it counts. The near-black + purple-gradient + glass combo (the AI-saturated 2026 crutch) appears only on the membership CTA, where a gradient is arguably earned; everywhere else the spectrum is a restrained 1px hairline. The screen reads as "a designer chose a house style," not "a model filled a template."

**Native evidence sweep:** Contract discipline is strong. Clean on raw colors, raw fonts, iOS-26 banned APIs, presentation primitives (all 6 sub-screens correctly use `.vaylSheet`), hardware padding, and copy (no em dashes; uses `·`). The single `spectrumText` on text is at 24pt (meets the Earned-Spectrum ≥24pt rule — no violation). ~15 minor findings, concentrated in: reinvented list structure, raw numeric literals escaping tokens, and dead controls/code.

**Where A and B agree:** three tappable controls that do nothing (`Restore` :223, membership CTA :235, `Support` :488), and the hand-rolled list. B additionally found `spectrumBadge`/`plainBadge` (:168, :182) are dead code, never referenced repo-wide.

## What's Working

1. **Native controls where they matter** — Toggle, confirmationDialog, alert, vaylSafariSheet. VoiceOver + system behaviors come free.
2. **Human, careful copy** — delete-account text spells out exactly what's lost and what the partner keeps; composition copy twice insists it's "not a label on either of you."
3. **Decorative-a11y hygiene** — icons `.accessibilityHidden(true)` throughout, theme row uses combined element + custom label, composition rows carry `.isSelected`.

## Priority Issues

**[P1] `IdentityEditSheet` reinvents the sheet toolbar.** Custom Cancel/Save overlay at the bottom (`SettingsIdentityView.swift:126-140`) instead of a standard `.toolbar` (Cancel top-left / Save top-right). The archetypal native-reinvention tell, and swipe-to-dismiss conflicts with a custom Cancel. **Fix:** present with real `ToolbarItem(.cancellationAction)` / `.confirmationAction`. → `/impeccable polish`

**[P2] Three dead controls ship as live-looking affordances.** `Restore` (:223), membership CTA (:235), `Support` (:488) are tappable no-ops. A control that does nothing is a trust break, exactly what a fluent user pauses at. **Fix:** wire them, or disable/hide with a "coming soon" state. → `/impeccable harden`

**[P2] `youSection` duplicates `SettingsNavRow` inline** (lines 305-350). Internal inconsistency + drift risk. **Fix:** reuse the shared `SettingsNavRow` component like every other section. → `/impeccable polish`

**[P3] Membership card is over-decorated and mis-placed.** Gradient-fill + glass + glow hairline (:260-301), positioned last. Over-reaches the "gradient is earned" rule on a utility surface and buries the upsell. **Fix:** dial back toward the standard SettingsCard treatment; move Membership near the top (Settings.app puts Apple ID first). → `/impeccable quieter` + placement decision.

**[P3] Dead code + raw literals.** `spectrumBadge`/`plainBadge` unused (~27 lines); `AppSpacing.xxs + 3` (×2), raw icon frames (28/28, 32/32), raw `blur(radius:5)`, and 5 raw `.tracking(...)` values escape the token system. **Fix:** delete the dead helpers; promote the repeated literals to tokens or named constants. → `/impeccable polish`

## Persona Red Flags

**Jordan (first-timer):** Sections are plain-language and scannable, but Membership is at the very bottom so "how do I upgrade?" means scrolling past everything, and tapping Support/Restore does nothing (reads as broken).

**Sam (VoiceOver):** Strong baseline (native toggles, hidden icons, combined theme row). Gaps: `experiencePicker` rows announce no selected state; the "< Settings" control is visually a back chevron but functionally a sheet dismiss; sub-screens rely on a custom overlay Cancel/Save rather than the top toolbar actions VoiceOver users are trained to find.

**Fluent-iOS user:** Registers it as bespoke-but-legible, pauses at: sheets that look like drill-downs but behave as sheets with a back chevron (push/modal mismatch); the custom Save bar and picker instead of a Form; the manual Divider list where Form insets/separators would be automatic. Defensible given the no-NavigationStack-in-Settings contract, but it costs some of the "the tool disappears" familiarity.

## Minor Observations

- The colorize pass earlier this session edited `spectrumBadge` (:172), which turns out to be dead code — harmless, but the helper should just be deleted.
- Header relies on the surrounding cover for notch clearance (no `.topClearance`); fine as-is, worth confirming on device.

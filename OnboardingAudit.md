# ONBOARDING FLOW AUDIT — OPEN LIGHTLY

**Audit Date:** 2026-03-20
**Tech Stack:** SwiftUI (iOS native)
**Target:** iOS
**Flow:** 8 screens, dark-mode-only, sensitive subject matter (consensual non-monogamy exploration)
**Core Value Proposition:** A guided, shame-free tool for exploring identity and relationships
**Auditor:** Senior product audit — three lenses: Technical/Accessibility, Conversion Psychology, Structure/Design

---

## SCREEN 1: STAT VIEW — "1 in 5" Trust Trigger

> *Opens with a holographic statistic normalizing the app's subject matter*

### TECHNICAL & ACCESSIBILITY

- 🟢 **VoiceOver:** `StatNumberView` has a full-sentence `accessibilityLabel`. Citation button has proper label + hint toggling open/close state.
- 🟢 **Decorative elements:** `GlowFieldView` and blobs are properly `accessibilityHidden(true)`.
- 🟡 **Font:** `CitationTapView` uses raw `.font(.system(size: 9, weight: .bold))` on the "i" icon — violates the AppFonts design system. Minor since it's decorative.
- 🟡 **Citation tap target:** Visual button is tiny (~30pt tall), but `.padding(.vertical, 7)` + `.contentShape(Rectangle())` extends it to ~44pt. Borderline — the visual affordance undersells the actual hit area.
- 🟡 **Reduce motion:** 8 continuously animated blobs + holographic text shimmer don't check `UIAccessibility.isReduceMotionEnabled`. Users sensitive to motion will see intense movement.
- 🟡 **HomeIndicatorBar:** Custom home indicator bar mimics system UI — potentially confusing on devices with real home indicators.
- 🟢 **Animation timing:** CTA arrives at ~1.05s with spring — snappy. Time to interactive is reasonable.

### CONVERSION PSYCHOLOGY

- 🟢 **Normalization-first framing:** Leading with "1 in 5 Americans" immediately reduces shame and isolation. Textbook social proof. Benchmark: Calm opens with "100 million people" for the same reason.
- 🟢 **Research-backed credibility:** Citing Haupert et al., 2017 with sample size (8,718) builds trust. The expandable citation respects the user's level of curiosity without cluttering.
- 🟢 **"You're not alone. And this isn't new."** — Identity-based framing. The ethos line shifts from data to belonging. Strong.
- 🟡 **CTA copy:** "Explore" is good — low-commitment, curiosity-framing — but generic. Something like "See what's inside" would be slightly more specific.
- 🟡 **No skip/exit affordance:** Some privacy-conscious users may feel trapped on the very first screen.
- 🟢 **Cognitive load:** Very low. One idea, one CTA. Single-job screen.

**Drop-off Risk:** LOW — The stat is compelling, the screen is visually impressive, and the CTA is low-commitment.

### STRUCTURE & DESIGN

- 🟢 **Visual hierarchy:** Holographic "1 in 5" dominates → supporting text → CTA. Eye path is clear.
- 🟢 **Atmospheric design:** The holographic number treatment creates a premium, "this app is different" first impression.
- 🟡 **Citation scroll container:** `ScrollView` with `maxHeight: 160` inside an expandable section could clip on SE-sized devices with Dynamic Type.
- 🟡 **No progress indicator:** This is screen 1 but there's no progress bar or step count. The OnboardingNavBar is absent. Creates a disconnect when the nav bar appears on screen 3.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 7/10 | Solid a11y labels; needs reduce-motion check |
| Conversion Psychology | 9/10 | Textbook shame-reduction opener for sensitive content |
| Structure & Design | 8/10 | Premium feel; minor citation layout concern |
| **Screen Overall** | **8/10** | |

---

## SCREEN 2: BRAND VIEW — Auto-Advance Identity Moment

> *Animated wordmark reveal: "Open Lightly" with tagline, auto-advances after 3.5s*

### TECHNICAL & ACCESSIBILITY

- 🟢 **VoiceOver:** Hidden visual wordmark + separate combined accessibility element announcing "Open Lightly. Explore what's possible." — correctly implemented.
- 🟡 **Auto-advance at 3.5s:** VoiceOver users have no mechanism to pause, replay, or skip. The 3.5s window may not be enough time for the screen reader to announce the label before transition.
- 🟠 **Reduce motion:** 30+ animated state variables with no `UIAccessibility.isReduceMotionEnabled` check. Heavy motion screen with no static fallback.
- 🟡 **`DispatchQueue.main.asyncAfter` chains:** 12+ dispatched closures. If the app backgrounds mid-animation, timers continue firing against stale state.
- 🟡 **`drawingGroup()`:** Rasterizes the entire screen to a Metal texture. Verify VoiceOver still picks up the a11y overlay inside the drawing group.
- 🟡 **Custom fonts:** "Zodiak-Extrabold" and "GeneralSans-Regular" referenced here but loaded via OnboardingTokens, not AppFonts. If font bundles are missing, fallback is system — would look broken.

### CONVERSION PSYCHOLOGY

- 🟢 **Brand anchoring:** The staggered "Open... Lightly" reveal creates a micro-narrative — the brand name reads as an instruction. Clever copywriting embedded in animation design.
- 🟢 **Zero friction:** Nothing is asked of the user. Pure value delivery.
- 🟡 **Duration:** 3.5s is right on the edge. Users who've seen this before (reinstall) cannot skip past it. Consider tap-to-skip after 1.5s.

**Drop-off Risk:** LOW — Auto-advance means no decision point = no drop-off.

### STRUCTURE & DESIGN

- 🟢 **Choreography:** The 5-phase animation timeline is well-structured and narratively coherent.
- 🟢 **Exit design:** Wordmark scales up slightly as it fades — gives the exit direction. Full-screen fade creates a clean seam.
- 🟡 **Ambient loops start at 1s but screen exits at 2.8s:** The wisp/breath loops only get ~1.8s of runtime before the exit sequence begins. Consider whether the loops are worth the complexity.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 5/10 | VoiceOver timing risk; no reduce-motion path; DispatchQueue fragility |
| Conversion Psychology | 8/10 | Strong brand moment; zero friction |
| Structure & Design | 8/10 | Beautiful choreography; ambient loops slightly wasted |
| **Screen Overall** | **7/10** | |

---

## SCREEN 3: NAME VIEW — Name + Pronouns

> *First input screen: asks for first name (required) and pronouns (optional)*

### TECHNICAL & ACCESSIBILITY

- 🟢 **Keyboard behavior:** Auto-focuses name field after 0.6s delay (post-animation), `.submitLabel(.done)`, `.textInputAutocapitalization(.words)`, `.autocorrectionDisabled()` — all correct.
- 🟢 **Validation:** 1–20 characters, enforced by `onChange` truncation. `isValid` gate on CTA.
- 🟢 **Accessibility labels:** TextField has `accessibilityLabel("First name")` + `accessibilityHint("Required. 1 to 20 characters.")`. Floating label is `accessibilityHidden`. Pronouns section has group label.
- 🟢 **State restoration:** `restoreStateIfNeeded()` runs on every appear before the animation guard — back navigation correctly restores name and pronouns.
- 🟡 **No error messaging:** If the user tries to proceed with an empty name, the CTA is simply disabled. No visual error state or message explaining why.
- 🟡 **Keyboard-up layout on SE:** No ScrollView wrapping the content. The Spacer between card and CTA should compress, but not validated on SE-sized devices.
- 🟡 **Custom pronoun character limit:** No character limit on custom pronouns.

### CONVERSION PSYCHOLOGY

- 🟢 **"Let's get acquainted."** — Warm, conversational, non-clinical. The LivingText gradient treatment makes it feel alive.
- 🟢 **Pronouns as optional:** "so we get it right" is excellent micro-copy — frames pronoun collection as an act of respect, not bureaucracy.
- 🟢 **Low friction:** Only one required field. Pronouns are clearly optional.
- 🟡 **Progress bar says "1 of 6":** The user has already seen 2 screens. The progress bar starting at step 1 (not 3) could feel like a reset.
- 🟡 **No "why we ask" context:** Some privacy-conscious users may wonder why a relationship app needs their first name.

**Drop-off Risk:** LOW — One field, clearly optional pronouns, low cognitive load.

### STRUCTURE & DESIGN

- 🟢 **Floating label animation:** Clean elevation from placeholder to label on focus/content — standard pattern, well-executed.
- 🟢 **Card structure:** Name field + divider + pronouns in a glass card with subtle border — visually groups related inputs.
- 🟢 **Glow border on focus:** Spectrum border + cyan glow shadow when name field is active — clear focus state.
- 🟡 **OnboardingFooter inconsistency:** Missing from this screen but appears on screens 4, 5, 6, 8.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 8/10 | Strong a11y; needs keyboard-up layout check for SE |
| Conversion Psychology | 8/10 | Low friction, respectful pronoun framing |
| Structure & Design | 8/10 | Clean form design; floating label well-executed |
| **Screen Overall** | **8/10** | |

---

## SCREEN 4: MODE SELECT — Solo / Couple / Browsing

> *Three mode cards + experience level pills (Curious / Exploring / Experienced)*

### TECHNICAL & ACCESSIBILITY

- 🟢 **Mode cards:** Proper `accessibilityHint` with "Selected" / "Double-tap to select" toggling. Icon `accessibilityHidden`.
- 🟢 **Experience section:** Wrapped in `accessibilityElement(children: .contain)` with group label. Descriptor text has `.accessibilityAddTraits(.updatesFrequently)`.
- 🟡 **Intensity graduation concern:** The `.dim` / `.warm` / `.alive` intensity on experience pills visually suggests hierarchy. "Curious" looking dimmer than "Experienced" could read as lower-status.
- 🟢 **Progressive disclosure:** Experience section only appears after mode selection.
- 🟢 **ScrollView:** Content wraps in a ScrollView — handles long content on small devices.
- 🟡 **Back navigation:** `restoreVisibilityIfNeeded()` correctly shows experience section instantly on back nav, but doesn't restore scroll position.

### CONVERSION PSYCHOLOGY

- 🟢 **"How are you exploring?"** — Frames the question as exploratory, not definitional. "There's no wrong way to start" reinforces safety.
- 🟢 **Three clear modes:** Solo / Partner / Browsing covers the full spectrum. "Just browsing" is the critical escape hatch.
- 🟡 **"Just browsing" placement:** Third position (bottom) is correct psychologically, but could be interpreted as a less-valued option.
- 🟢 **"You can always change these later."** — Autonomy preservation. Reduces decision anxiety.
- 🟡 **Two decisions on one screen:** Mode + experience level. Progressive disclosure makes it ~1.5 decisions rather than 2. Acceptable.
- 🟡 **CTA "Let's go":** Enthusiastic but generic. "Show me my path" or "Personalize my experience" would better set expectations.

**Drop-off Risk:** MEDIUM — Two decisions creates more friction. Users unsure of their "experience level" may hesitate.

### STRUCTURE & DESIGN

- 🟢 **Card design:** Horizontal layout with icon + title + subtitle. Gradient border on selection with glow shadows.
- 🟢 **Dark pocket behind pills:** Creates visual depth separation. Subtle but effective.
- 🟡 **Icon choice:** All three mode cards use "✦" — identical icons provide no visual differentiation. Consider unique icons per mode.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 7/10 | Good a11y; intensity gradient may stigmatize beginners |
| Conversion Psychology | 7/10 | Strong framing; two decisions on one screen is borderline |
| Structure & Design | 7/10 | Clean progressive disclosure; identical icons miss an opportunity |
| **Screen Overall** | **7/10** | |

---

## SCREEN 5: CONTEXT VIEW — Relationship Context (Solo/Couple only)

> *Swipeable card stack presenting 3-4 relationship context options based on mode*

### TECHNICAL & ACCESSIBILITY

- 🟢 **VoiceOver support:** `accessibilityAdjustableAction` for swipe-up/down navigation, `accessibilityAction(named: "Select")` for confirmation, dynamic label/value/hint. Thorough.
- 🟠 **ContextCardStack frame:** Hardcoded at 300×340pt. Not responsive to screen width. On SE, cards may clip.
- 🟡 **Auto-advance after selection:** 0.8s delay before advancing — user has no confirmation step. If they accidentally tap, they're moved forward.
- 🟡 **Drag gesture threshold:** 10pt threshold to distinguish tap from drag. May cause accidental selections for users with motor impairments.
- 🟢 **State restoration:** `restoreSelectionIfNeeded()` restores confirmed context on back navigation.
- 🟡 **Reduce motion:** Card stack uses spring animations that don't check reduce-motion preference.

### CONVERSION PSYCHOLOGY

- 🟢 **Personalized headline:** Uses `data.displayName` when available — "Alex, you're exploring on your own." First use of name creates a moment of recognition.
- 🟢 **Context options are empathetic:** "It's complicated / I'm not sure how to bring it up" with detail "No pressure. We'll start with self-understanding." — Exceptional copy that validates without judgment.
- 🟢 **Card stack interaction model:** The physicality of cards creates a "choosing" metaphor that feels more intentional than radio buttons.
- 🟡 **Em dash in solo subhead:** "One thing that helps us personalize —" reads as grammatically incomplete to many users. User testing should validate.
- 🟢 **"No judgment on any answer."** — Crucial reassurance for sensitive content.
- 🟡 **Auto-advance removes agency:** After selection, the screen advances automatically after 0.8s. A "Continue" button would give more control for a deeply personal question.

**Drop-off Risk:** MEDIUM — Questions are personal and auto-advance may feel rushed.

### STRUCTURE & DESIGN

- 🟢 **Card stack visual design:** Depth via scale/rotation/offset creates a tangible browsing metaphor.
- 🟠 **Locked drag state:** When a card is confirmed, drag is blocked but there's no visual indicator. The card should visually settle to communicate finality.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 7/10 | Excellent VoiceOver; hardcoded card frame is a problem |
| Conversion Psychology | 8/10 | Deeply empathetic copy; auto-advance removes agency |
| Structure & Design | 7/10 | Card stack is compelling; locked state needs visual feedback |
| **Screen Overall** | **7/10** | |

---

## SCREEN 6: CURIOSITY PICKER — Interest & Intent Selection

> *Two-section multi-select pill grid with progressive disclosure*

### TECHNICAL & ACCESSIBILITY

- 🟢 **Dynamic Type:** `@Environment(\.dynamicTypeSize)` adapts grid from 2 columns to 1 column at `accessibility2` size. Good.
- 🟡 **Pill accessibility:** `CuriosityPill` buttons have no explicit `accessibilityAddTraits(.isSelected)`. VoiceOver will read the label text but won't announce selection state.
- 🟡 **"Tap to deselect" hint:** Marked `accessibilityHidden(true)` — correct for visual affordance only. VoiceOver users have no equivalent hint about how to deselect.
- 🟢 **Progressive disclosure:** Section 2 appears only after first Section 1 selection. Auto-scrolls to new sections. Well-choreographed.
- 🟢 **State restoration:** Handles all paths including browsing path mapping.
- 🟡 **No `hasAnimated` guard:** Uses `guard !headerVisible` instead of the `hasAnimated` pattern used on every other screen. Inconsistent.

### CONVERSION PSYCHOLOGY

- 🟢 **Section labels are context-aware:** 8 different configurations based on mode + relationship context. This level of personalization makes the user feel understood.
- 🟢 **Pill copy is identity-reflective:** "I don't know what I actually want" / "I keep ending up in the same place" — these read like thoughts the user has had. Recognition-based design, not checkbox-based.
- 🟡 **Two sections is a lot of content:** Some configs have 5 + 7 = 12 options. Significant scrolling required.
- 🟢 **"No wrong answers. You can always explore more later."** — Good reassurance placed where it's needed most.
- 🟢 **CTA "Show me my path"** — Specific, forward-looking, creates anticipation. Best CTA copy in the flow.
- 🟡 **Emphasized pills:** Some pills have a subtle cyan glow without explanation. Could confuse users about whether these are "recommended."

**Drop-off Risk:** MEDIUM-HIGH — This is the highest-friction screen. Many options, two sections, scrolling required.

### STRUCTURE & DESIGN

- 🟢 **Section divider:** Dotted circle pattern creates visual breathing room between sections.
- 🟢 **Pill design:** Checkmark icon on selection, color-coded borders, subtle scale effect. Clear feedback loop.
- 🟡 **CTA inside ScrollView:** The CTA is inside the scroll surface, not pinned to the bottom. Users may not realize there's a button below.
- 🟡 **Visual density:** On smaller screens, 2-column pills with 14pt padding creates a dense grid.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 7/10 | Good Dynamic Type; missing pill selection a11y traits |
| Conversion Psychology | 7/10 | Excellent personalization; too many options risks overwhelm |
| Structure & Design | 7/10 | Progressive disclosure works; CTA should be pinned |
| **Screen Overall** | **7/10** | |

---

## SCREEN 7: BUILDING PATH — Processing Animation

> *Auto-advance processing screen showing personalized path assembly (7.5s)*

### TECHNICAL & ACCESSIBILITY

- 🟢 **Accessibility overlay:** Hidden VoiceOver element with full summary text — correctly announces what's happening without requiring visual animation.
- 🟠 **7.5 seconds of non-interactive content:** User cannot skip, pause, or interact. Longest forced wait in the flow.
- 🟡 **30+ DispatchQueue.main.asyncAfter calls:** Extremely brittle timeline. App backgrounding could prevent the auto-advance callback from firing.
- 🟡 **Reduce motion:** No check. All animations fire unconditionally.
- 🟢 **Difficulty derivation:** `data.defaultDifficulty` is set based on `nmStage` before calling `onFinished` — correct timing.
- 🟡 **Inline progress bar:** Builds a progress bar manually instead of using `OnboardingProgressBar`. Duplicates the component and misses its accessibility features.

### CONVERSION PSYCHOLOGY

- 🟢 **Personalization theater:** Showing checkboxes filling in mirrors Duolingo's "finding your level" pattern — makes the user feel their inputs mattered.
- 🟢 **Name-based headline:** "Alex." (or "Your path.") centers the user's identity.
- 🟢 **Floating fragments:** Displaying the user's actual context ("Starting fresh", "Navigating with transparency") as ghost text reinforces that the app understood their inputs. Excellent detail.
- 🟡 **Duration tradeoff:** 7.5s is long. Duolingo's equivalent is ~4s. The content justifies ~5s; the remaining 2.5s feels padded.
- 🟢 **"Your path is ready."** — Tagline arrives last, lingers as the last thing read before exit. Good sequencing.

**Drop-off Risk:** LOW in theory, HIGH in practice — User can't drop off but may reach for the home button out of impatience.

### STRUCTURE & DESIGN

- 🟢 **Atmospheric layer:** 9 decorative elements create an emotionally climactic moment. The glow peak at 4.4s coincides with all items completing — visual matches the narrative.
- 🟢 **Build item design:** Circle indicator transitions from border ring to filled gradient with checkmark. Satisfying micro-animation.
- 🟡 **SE layout:** `Spacer()` based vertical layout could compress or overflow on small devices.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 5/10 | Brittle timeline; no skip; no reduce-motion; a11y overlay is good |
| Conversion Psychology | 7/10 | Strong personalization theater; 7.5s is too long |
| Structure & Design | 7/10 | Atmospheric peak is well-timed; inline progress bar should use component |
| **Screen Overall** | **6/10** | |

---

## SCREEN 8: GROUND RULES — Privacy & Ethical Frame

> *Three "promise cards" with honest framing of what the app is and isn't. No back button.*

### TECHNICAL & ACCESSIBILITY

- 🟢 **PromiseCard accessibility:** `.accessibilityElement(children: .combine)` merges icon, title, and detail into one element.
- 🟢 **Screen-level a11y:** `.accessibilityLabel("Before you dive in. Screen 8 of 8.")` + `.accessibilityAction(named: "I'm ready")`.
- 🟢 **ScrollView + fixed CTA:** Content scrolls while CTA stays pinned at bottom. Correct pattern for SE compatibility.
- 🟡 **Progress bar shows 6/6:** The "6 of 6" label is technically correct from the nav bar's perspective but inconsistent with 8 total screens.
- 🟡 **No back button:** Intentional — must-acknowledge gate. But users who made a mistake on a previous screen have no recourse except restarting onboarding.
- 🟡 **Animation timeline:** 12 dispatched closures in 0.48s total — very compressed. The animation essentially completes in <0.5s, which feels too fast for a screen meant to be read carefully.
- 🟢 **Completion data writes:** `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt` all set before `onFinished()` fires. Clean.

### CONVERSION PSYCHOLOGY

- 🟢 **Honest, non-defensive framing:** "They say money shows you more of who you are. This journey will do more of the same, if you see it through." — Bold, respectful copy that treats the user as an adult.
- 🟢 **Mode-specific pill 2:** Couple mode gets "This won't fix a relationship that's struggling"; solo gets "This won't resolve things you're running from." Excellent contextual copy.
- 🟢 **Therapy disclaimer:** "This is not therapy, and it's not trying to be." with "Professional support is always just a tap away." — Legally responsible and emotionally supportive.
- 🟢 **Lifeguard metaphor:** "Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one." — Best piece of copy in the entire flow. Defines the app's role while preserving user agency.
- 🟡 **No scroll-gate:** The user can tap "I'm ready" without scrolling through all three cards. For a "must-acknowledge" screen, this undermines intent.
- 🟡 **Ends on disclaimers:** No "welcome / you're in" payoff moment after onboarding. The last user experience before the main app is a series of caveats.

**Drop-off Risk:** LOW — User is at the end. Sunk cost works in the app's favor.

### STRUCTURE & DESIGN

- 🟢 **PromiseCard design:** Icon badge + title + detail in a glass card. Clean, scannable.
- 🟢 **Typography hierarchy:** Overline → screen title → body cards → italic gradient closer. Clear progression.
- 🟢 **Full completion progress bar with bloom effect:** Visual payoff for reaching the end. Achievement feeling.

### SCREEN RATING

| Dimension | Score /10 | One-Line Verdict |
|---|---|---|
| Technical & Accessibility | 7/10 | Good a11y; animation too fast; no scroll-gate for acknowledgment |
| Conversion Psychology | 9/10 | Exceptional copy; honest framing builds deep trust |
| Structure & Design | 8/10 | Clean card layout; SE needs scroll |
| **Screen Overall** | **8/10** | |

---

## TOTAL ONBOARDING FLOW ANALYSIS

### FLOW-LEVEL SCORES

| Dimension | Score /10 |
|---|---|
| Technical & Accessibility | 6/10 |
| Conversion Psychology & Conversion Readiness | 8/10 |
| Structure, Consistency & Design Principles | 7/10 |
| **OVERALL ONBOARDING FLOW RATING** | **7/10** |

### FLOW-LEVEL OBSERVATIONS

**Cognitive load curve:** Low (stat, brand, name) → Peak (mode select + context + curiosity picker) → Low (building path, ground rules). Screens 4-6 cluster three decision-heavy screens consecutively. The Curiosity Picker (screen 6) is the highest-friction point. Acceptable because the user has demonstrated intent by then, but the peak could be softened by reducing option count in the picker.

**Value delivery arc:** The user first feels the product's value at Screen 1 (normalization) and again at Screen 7 (personalization theater). Between screens 3-6 the user is giving data without receiving much value in return. The context-aware headings and empathetic copy partially offset this, but there's a value trough in the middle of the flow. Consider injecting a micro-value moment after Screen 5.

**Friction map:** Mid-loaded. Screens 4, 5, and 6 are all consecutive high-friction screens. The browsing path correctly skips Screen 5 — this is good segmentation.

**Consistency audit:**
- **Footer:** Appears on screens 4, 5, 6, 8 but not 1, 2, 3, 7. Should be present on all screens where data is collected (3+).
- **Progress bar:** `OnboardingNavBar` shows step counts starting at step 1 on screen 3. Screens 1-2 have no progress indicator. Screen 7 has an inline manually-built progress bar. Screen 8 uses the `OnboardingProgressBar` component with completion effect. Inconsistent.
- **Step numbering:** NavBar says "step X of 6" on solo/couple path, "step X of 5" on browsing. The user sees 8 total screens. Numbering only counts interactive screens — mathematically correct but may confuse users who count screens.
- **Entrance animation pattern:** All screens use staggered opacity+offset with 0.15-0.30s delays. Consistent.
- **Back button:** Present on screens 3-6, absent on 1-2 (auto-advance), absent on 7-8 (no-back-zone). Correct.

**Flow logic:** The current order is psychologically sound. One open question: should Ground Rules come before the processing animation? The current order means the user watches their "path being built" and THEN is told "this isn't therapy." If ground rules came before processing, expectations would be set before the emotional payoff, which could make the building screen feel more earned. Either order is defensible.

**Missing screens:**
1. **Welcome/payoff screen after Ground Rules:** The onboarding ends with disclaimers. No "You're in" or "Welcome to Open Lightly" moment. After 8 screens and ~60s+ of investment, the user deserves a brief celebration before entering the main app. Duolingo, Calm, and Headspace all have a "you're ready" screen.
2. **Notification permission screen:** No push notification opt-in. If the app uses notifications for prompts/check-ins (likely given the domain), this should be asked during onboarding while motivation is highest.

---

## PRIORITIZED IMPROVEMENT LIST

### 🔴 CRITICAL — Fix Before Launch

1. **No `prefers-reduced-motion` check anywhere in the flow** — All 8 screens — Heavy animations play unconditionally on users who have explicitly opted out. WCAG 2.1 AA violation. — **Fix:** Check `UIAccessibility.isReduceMotionEnabled` and provide static fallbacks for all animated screens. At minimum: disable GlowField animations, skip BrandView animation (show static wordmark + auto-advance at 1.5s), disable card stack spring animations, reduce BuildingPath to a simple progress bar.

2. **`textTertiary` (#666680) fails WCAG AA contrast** — Screens 3, 4, 5, 6, 8 — Used for "so we get it right", "No judgment", pronoun button text, reassurance copy. Ratio against `pageBg` (#030305) is ~3:1; WCAG AA requires 4.5:1 for normal text. — **Fix:** Lighten `textTertiary` to at least #8888A0 (~4.5:1) or use `textSecondary` for functional text.

3. **HoloCTAButton has no visible disabled state** — Screens 3, 4, 6 — When `isEnabled` is false, hit testing is disabled but the button still shows full glow, shimmer, and gradient. Users see an active-looking button that doesn't respond to taps. — **Fix:** When disabled, reduce opacity to 0.4, remove glow shadows, stop shimmer animation. Add `.isNotEnabled` accessibility trait.

4. **ContextCardStack frame is hardcoded (300x340)** — Screen 5 — Does not adapt to screen width. On iPhone SE (320pt width), cards will overflow or clip. — **Fix:** Use `GeometryReader` or relative sizing (e.g., 80% of screen width, with proportional height).

### 🟠 MAJOR — Fix in Next Sprint

5. **BuildingPath screen is 7.5 seconds with no skip** — Screen 7 — Longest forced wait in the flow. Industry benchmark (Duolingo, Headspace) is 3-4 seconds for equivalent screens. — **Fix:** Reduce total duration to ~4.5s. Add tap-to-skip after 2s. Compress exit sequence from 1.3s to 0.5s.

6. **BrandView auto-advance with no VoiceOver timing guarantee** — Screen 2 — Screen auto-advances at 3.5s regardless of VoiceOver announcement completion. — **Fix:** When VoiceOver is active, switch from timed auto-advance to a tap-to-continue model, or extend the timer to 6s.

7. **CuriosityPicker CTA is inside ScrollView, not pinned** — Screen 6 — Users may not discover the Continue button because it's below the fold. — **Fix:** Move CTA outside ScrollView with a fixed bottom position using `.safeAreaInset(edge: .bottom)`.

8. **OnboardingFooter uses hardcoded system font instead of AppFonts** — Screens 4, 5, 6, 8 — Privacy reassurance text uses raw `.font(.system(size: 12))` while all other text uses `AppFonts` tokens. — **Fix:** Replace with `AppFonts.caption` or create an `AppFonts.footnote` token.

9. **No scroll-gate on Ground Rules** — Screen 8 — Users can tap "I'm ready" without reading the three promise cards. — **Fix:** Require scroll-to-bottom before enabling the CTA, or add a checkbox ("I understand these ground rules") that gates the button.

10. **Missing welcome/payoff screen after onboarding** — After Screen 8 — The flow ends on disclaimers. No celebration, no transition moment. — **Fix:** Add a brief (~2s) "Welcome to Open Lightly, [Name]" screen with a warm animation before transitioning to the main app.

### 🟡 MINOR — Schedule for Backlog

11. **OnboardingTokens duplicates AppColors** — `OnboardingTokens.swift` defines duplicate cyan, purple, magenta, pink colors and uses different font families (Zodiak, GeneralSans) than AppFonts (Clash Display, Switzer). — **Fix:** Remove OnboardingTokens. Use AppColors + AppFonts exclusively. Add brand fonts (Zodiak) to AppFonts if needed.

12. **DispatchQueue.main.asyncAfter chains throughout** — Screens 1, 2, 7 — 50+ `asyncAfter` calls across the flow create brittle timelines. App backgrounding can desync them. — **Fix:** Migrate to SwiftUI `TimelineView` or `withAnimation(.delay())` where possible.

13. **Progress bar step counts don't match perceived screens** — All screens — User sees 8 screens but progress says "step X of 6." Nav bar appears on screen 3 but not 1-2. Screen 7 uses inline progress bar. — **Fix:** Either include all screens in the count (8 of 8) or make the unnumbered screens feel clearly distinct from the "steps."

14. **Mode card icons are identical** — Screen 4 — All three mode cards use "✦". Missed opportunity for visual differentiation. — **Fix:** Use distinct SF Symbols: `person.fill` (solo), `person.2.fill` (couple), `eyes` (browsing).

15. **No custom pronoun character limit** — Screen 3 — Users can enter arbitrarily long custom pronouns. — **Fix:** Add `onChange` truncation at 30 characters, matching the name field pattern.

16. **OnboardingGlowField missing `accessibilityHidden(true)` in component** — The component itself doesn't set accessibility hidden; callers must add it. — **Fix:** Add `.accessibilityHidden(true)` inside the component body.

17. **AppFonts has no Dynamic Type support** — All screens — Custom fonts are set at fixed sizes. iOS Dynamic Type preferences are ignored. — **Fix:** Use `UIFontMetrics` to scale custom fonts or implement `@ScaledMetric` property wrappers.

### 🟢 WINS — What's Working

1. **Shame-reduction copy throughout** — All screens — "You're not alone", "No judgment", "Every starting point is valid", "There's no wrong way to start" — best-in-class sensitive-topic onboarding copy. Preserve in every future iteration.

2. **Context-aware CuriosityScreenConfig** — Screen 6 — 8 unique content configurations based on mode + relationship context. The user sees options that reflect their specific situation. Significant engineering investment that directly serves conversion.

3. **Progressive disclosure on Mode Select and Curiosity Picker** — Screens 4, 6 — Experience pills appear only after mode selection. Section 2 and CTA appear only after first selections. Textbook progressive disclosure.

4. **Personalized headlines using displayName** — Screens 5, 7, 8 — "Alex, you're exploring on your own." / "Alex." / "Alex, the most important questions..." — Using the name creates a thread of recognition that makes the flow feel personal, not procedural.

5. **VoiceOver implementation on ContextCardStack** — Screen 5 — AdjustableAction for navigation, Select action for confirmation, dynamic label/value/hint. Makes a gesture-heavy component accessible without compromising the visual design.

6. **BuildingPath personalization theater** — Screen 7 — Displaying the user's actual inputs as floating text while "building" their path is an elegant way to validate that their choices were heard. Top-tier onboarding pattern.

7. **Ground Rules copy** — Screen 8 — The lifeguard metaphor, the honest "this won't fix" framing, and the therapy disclaimer are world-class product copy that builds genuine trust.

8. **State restoration on back navigation** — Screens 3, 4, 5, 6 — Every screen restores committed data from the binding on re-appear. Users can go back and forward without losing their inputs.

---

## QUICK WIN HIGHLIGHT

> **If you could only fix 3 things before your next release, fix these:**
> 1. **Add `prefers-reduced-motion` checks** — Wrap animation blocks in all 8 screens with `if !UIAccessibility.isReduceMotionEnabled`. Provide static fallbacks. This is an accessibility compliance issue.
> 2. **Add a visible disabled state to `HoloCTAButton`** — When `isEnabled` is false, set `opacity(0.4)`, remove glow shadows, and stop shimmer. Users currently see an active-looking button that doesn't respond.
> 3. **Reduce BuildingPath to ~4.5s and add tap-to-skip** — Cut the exit sequence, compress item timing, and allow a tap anywhere to skip after 2s. This is the single biggest UX frustration risk in the flow.

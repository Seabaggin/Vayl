# Open Lightly — Onboarding Audit
**Date:** 2026-03-20
**Scope:** 8-screen onboarding flow against Act 1 launch strategy
**Sources read:** DESIGN_DOC.md (full), PROJECT_SCOPE.md (full), all 8 onboarding Swift files (via prior audit session)
**Question this document answers:** "What does a new couple experience when they download this app tonight, and is that experience the best possible version of the Act 1 promise?"

> **Answer (executive summary):** Not yet, but close. The flow is well-built and emotionally coherent. The critical gaps are not structural — they're strategic: the onboarding never tells the couple what they're building toward, Screen 4 presents all three audience paths with equal weight, Screen 6 asks for significant investment before delivering any value, and Screen 8's Pill 2 plants a seed of doubt in users who aren't struggling. These are fixable without rebuilding anything. The bones are right.

---

## SECTION 1: WHAT EXISTS — SCREEN BY SCREEN INVENTORY

---

**SCREEN 1: StatView**
File: `OnboardingStatView.swift`
Type: Interactive — trust trigger, single CTA
Data collected: None
Current purpose: Establishes social proof ("1 in 5 people have explored CNM") before asking for anything, lowering the anxiety of a first-time user.
Act relevance: All acts — the stat is universal and context-agnostic
Serves Act 1 user: **Yes** — normalizes NM curiosity for a couple who may feel isolated in their interest; the expandable citation handles skeptics without cluttering the emotional moment.
Time cost: 15–30 seconds (faster if they skip the citation)
Verdict: **Keep as-is**

---

**SCREEN 2: BrandView**
File: `OnboardingBrandView.swift`
Type: Auto-advance (3.5 seconds, no interaction)
Data collected: None
Current purpose: Brand identity moment — wordmark reveal, visual tone-setting, premium signal.
Act relevance: All acts — brand entry is universal
Serves Act 1 user: **Yes** — the intimacy of the animation tells a new couple this is a considered, high-quality product before they've entered a single piece of data. That trust signal matters for Act 1.
Time cost: 3.5 seconds (fixed)
Verdict: **Keep as-is**

---

**SCREEN 3: NameView**
File: `OnboardingNameView.swift`
Type: Form — name (required), pronouns (optional)
Data collected: `displayName`, `pronouns`, `customPronouns`
Current purpose: Personalizes the experience from this screen forward; `displayName` is used in Screen 5 headline, Screen 7 headline, and Screen 8 subhead.
Act relevance: All acts
Serves Act 1 user: **Yes** — personalization creates investment. A new couple entering their name feels the app begin to respond to them specifically.
Time cost: 30–45 seconds (name entry + optional pronoun tap)
Verdict: **Keep as-is** — pronouns are optional and don't block progress; the screen is appropriately lightweight.

---

**SCREEN 4: ModeSelectView**
File: `OnboardingModeSelectView.swift`
Type: Two-stage progressive reveal — mode selection then experience level
Data collected: `explorationMode`, `nmStage`
Current purpose: Routes user to the correct path (solo/couple/browsing) and captures NM experience level.
Act relevance: All acts — this is the routing fork
Serves Act 1 user: **Partially** — the three mode cards ("On my own," "With a partner," "Just browsing") are rendered with identical visual weight. For a new couple opening this app, the option that is correct for them appears with no visual hierarchy relative to the other two. The experience level pills carry a documented tradeoff: the intensity graduation (dim → warm → alive) implies a value hierarchy that may cause curious couples to self-deprecate by picking "Curious" even if they've been discussing this for months.
Time cost: 30–45 seconds
Verdict: **Simplify** — visual hierarchy adjustment needed; "With a partner" should read as the primary choice at Act 1 launch without hiding the other paths.

---

**SCREEN 5: ContextView**
File: `OnboardingContextView.swift`
Type: Gesture-driven card stack — tap-to-confirm
Data collected: `relationshipContext`
Current purpose: Clarifies the specific relationship situation within the chosen mode (4 couple contexts: notTalked / talking / someExperience / needsReset).
Act relevance: **Act 1 primary** (couple context cards), Act 3 (solo context cards)
Serves Act 1 user: **Yes** — the four couple context cards are precisely calibrated to the Act 1 user's actual situation. The gesture mechanic makes the selection feel like an exploration rather than a form field. The reassurance text ("You're exploring together.") is the warmest emotional beat in the entire flow.
Time cost: 20–40 seconds
Verdict: **Keep as-is** — this screen earns its place. The infinite-scroll stack makes even a single selection feel intentional.

---

**SCREEN 6: CuriosityPickerView**
File: `OnboardingCuriosityPickerView.swift`
Type: Progressive disclosure multi-select — two sections, config-driven
Data collected: `communicationGoals`, `learningGoals`, `curiositySelections`
Current purpose: Captures interest areas to drive content personalization (CuriosityScreenConfig routes 8 configs based on explorationMode × relationshipContext).
Act relevance: All acts
Serves Act 1 user: **Partially** — this is the highest-friction screen in the flow for Act 1. A new couple lands here having delivered zero value from the product and is asked to select from 4–7 communication goals (Section 1) and 6–7 learning goals (Section 2). For the couple-curious user in an anxious moment, this reads as homework before the product does anything. The config system is technically sound but the Act 1 user doesn't yet know what they're personalizing toward.
Time cost: 60–120 seconds (two sections, multiple required selections, scroll behavior)
Verdict: **Simplify** — the config architecture stays intact; the framing, option count, and section 2 gate logic need adjustment for Act 1.

---

**SCREEN 7: BuildingPathView**
File: `OnboardingBuildingPathView.swift`
Type: Auto-advance (~7.5 seconds), non-interactive
Data collected: `defaultDifficulty` (derived from `nmStage` at handoff)
Current purpose: Processing animation that confirms the data collected matters, creates anticipation, and serves as an emotional bridge to the app proper.
Act relevance: All acts — the build items and floating fragments are data-derived and personalized
Serves Act 1 user: **Yes** — the animation communicates "we heard you" in a way that a confirmation screen never could. The four build items (starting point, experience level, what you want to explore, conversation style) land correctly for a new couple. The final tagline "Your path is ready." is a strong emotional close.
Time cost: 7.5 seconds (fixed)
Verdict: **Keep as-is**, with one targeted copy addition — see Section 7 and Change 4.

---

**SCREEN 8: OnboardingGroundRulesView**
File: `OnboardingGroundRulesView.swift`
Type: Must-acknowledge — no back button, no skip
Data collected: `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt`
Current purpose: Ethical framing, non-therapy disclaimer, honest expectation-setting before the product begins.
Act relevance: All acts — this screen exists for ethical and legal reasons that apply universally
Serves Act 1 user: **Partially** — Pill 1 (self-knowledge) and Pill 3 (not therapy) land cleanly for Act 1. Pill 2, coupled path: "This won't fix a relationship that's struggling" is wrong for the primary Act 1 user. A new couple who is curious but not in crisis may read this and wonder whether the app has diagnosed them with a struggling relationship. The framing assumes the user arrived because something is broken. Most Act 1 users arrived because something is interesting.
Time cost: 45–90 seconds (reading three PromiseCards + italic line + CTA)
Verdict: **Modify copy** — Pill 2 coupled path specifically. Structure, pattern, and screen position stay intact.

---

### Summary Table

| Screen | File | Act | Serves Act 1 | Verdict |
|--------|------|-----|--------------|---------|
| 1: StatView | OnboardingStatView.swift | All | Yes | Keep as-is |
| 2: BrandView | OnboardingBrandView.swift | All | Yes | Keep as-is |
| 3: NameView | OnboardingNameView.swift | All | Yes | Keep as-is |
| 4: ModeSelectView | OnboardingModeSelectView.swift | All | Partially | Simplify |
| 5: ContextView | OnboardingContextView.swift | 1/3 | Yes | Keep as-is |
| 6: CuriosityPickerView | OnboardingCuriosityPickerView.swift | All | Partially | Simplify |
| 7: BuildingPathView | OnboardingBuildingPathView.swift | All | Yes | Keep + minor add |
| 8: GroundRulesView | OnboardingGroundRulesView.swift | All | Partially | Modify copy |

---

## SECTION 2: THE ACT 1 CRITICAL PATH

### The Act 1 User

A couple. One or both curious about non-monogamy. They've had at least one conversation that felt clumsy or got stopped before it finished. One of them found this app — maybe in bed at 11pm, maybe after a podcast, maybe after a fight. They downloaded it together or one downloaded it and sent the link. They're opening it for the first time now.

Their emotional state: **cautiously hopeful, mildly anxious, and looking for a reason to trust this.**

Their goal: Understand what they want and be able to talk to their partner about it without it becoming a thing.

### Fastest Defensible Path — Current State

```
Screen 1 (StatView)       ~25s   trust trigger
Screen 2 (BrandView)      3.5s   brand entry
Screen 3 (NameView)       ~40s   name + pronouns
Screen 4 (ModeSelectView) ~40s   couple + curious
Screen 5 (ContextView)    ~30s   notTalked / talking / etc.
Screen 6 (CuriosityPicker) ~90s  2 sections, 4+ selections
Screen 7 (BuildingPath)   7.5s   processing animation
Screen 8 (GroundRules)    ~60s   must-acknowledge
↓
HOME DASHBOARD
                                                   ← WHERE IS THE DESIRE MAP?
```

**Total time to home: ~6–8 minutes**
**Time to first value moment (Desire Map): unknown — depends on home UI structure**

### Critical Observation

The Desire Map is never mentioned in the onboarding. The current flow ends at "Your path is ready" → Ground Rules → Home, with no bridge to the product's primary conversion moment. An Act 1 user who completes onboarding arrives at home not knowing that a mutual reveal mechanic is waiting for them, not knowing that their partner needs to complete the same flow, and not knowing what the first thing they should do together is.

This is the most significant strategic gap in the current onboarding. The flow is emotionally well-constructed but it leads to a vague destination.

### Screens on the Critical Path

All 8 screens are on the Act 1 critical path for the couple route. None can be removed without architectural impact. **The goal is not to remove screens but to make each screen earn its place and collectively point toward the same destination.**

### Where Friction Currently Exists

1. **Screen 4, equal visual weight** — a couple unsure which option is "for them" may pause, compare options, feel uncertainty about whether they belong here.
2. **Screen 6, pre-value ask** — the largest sustained investment in the flow before any result is delivered.
3. **Screens 7–8, vague destination** — "Your path is ready" and "I'm ready" are emotionally strong but don't tell the Act 1 couple what they're ready for.
4. **Post-onboarding, the Desire Map is not guaranteed to be the first thing they see.** The "instant personalized result → paywall" conversion mechanic is only effective if it's the first thing that happens.

### Revised Target Critical Path

```
Screen 1 (StatView)              ~25s    trust trigger
Screen 2 (BrandView)             3.5s    brand entry
Screen 3 (NameView)              ~40s    name
Screen 4 (ModeSelectView)        ~35s    couple + curious
  [Couple: visual emphasis on "With a partner"]
Screen 5 (ContextView)           ~30s    relationship context
Screen 6 (CuriosityPicker)       ~60s    simplified option set
Screen 7 (BuildingPathView)      7.5s    processing animation
  [Desire Map name-drop: brief anticipation line at end]
Screen 8 (GroundRules)           ~55s    honest framing
  [Pill 2 revised for exploratory couple]
↓
HOME → DESIRE MAP (immediate first action for couple path)
↓
[ONE FREE MATCH REVEAL]
↓
PAYWALL
```

**Target time to paywall moment: ~10–12 minutes from cold launch.** That is a reasonable funnel for this kind of product.

---

## SECTION 3: THE BRANCHING PROBLEM

### Are the Three Paths Presented with Equal Weight?

Yes. Screen 4 renders three mode cards — "On my own," "With a partner," "Just browsing" — in identical visual treatment: same cornerRadius, same border weight, same icon size, same typography. The only differentiation is the subtitle text. There is no visual hierarchy that says to a new couple: "this one is for you."

**Does this dilute Act 1?** Meaningfully, yes. A new couple opening the app for the first time sees three equidistant options and must correctly self-identify. The `subtitle` text for "With a partner" reads "We're in this together" — which is good, but it's set in `AppFonts.caption` at `textSecondary` opacity, which is the dimmest text weight in the system. The most important information for the primary user is the lowest-contrast text on the screen.

### "Just Browsing" — What Does It Lead To?

Per DESIGN_DOC.md: browsing skips Screen 5 (ContextView) and routes through all other 7 screens. In the CuriosityPickerView, browsing uses `browsingConfig` — 8 options in Section 1 only, no Section 2. It proceeds through BuildingPathView and GroundRulesView.

**What does "Just Browsing" lead to at home?** This is not documented. The onboarding architecture supports the path but the destination UX for a browsing user appears to be the same home dashboard as couple/solo users. If browsing users arrive at the same Desire Map prompt as couple users, that's wrong — the Desire Map requires a partner. If they arrive at a different home state, that logic needs to exist and be verified.

**Should it exist at V1.0?** It should remain in the architecture. It should not be marketed. The current equal-weight rendering on Screen 4 should be revised to subordinate it visually. There is a legitimate use case for a single person who downloads to investigate before bringing it to their partner — "Just Browsing" captures that user. But they are not the primary user and the screen shouldn't imply they are.

### The Solo Path — What to Do at Act 1 Launch

**Three options:**

**a) Fully present, not marketed (current approach)** — The solo path is architecturally complete: 3 context cards, solo-specific CuriosityScreenConfig instances, solo BuildingPathView floating fragments, solo Ground Rules Pill 2. It exists and works.

**b) Simplified to a holding pattern** — Replace the full solo path with a "coming soon" message. Risks: users who self-identify as solo mid-relationship (the "partnered but solo-using" user) would have no path. This is a real Act 1 user.

**c) Removed from onboarding, added back at Act 3 launch** — Highest disruption, unnecessary. The path is built.

**Recommendation: Option (a), with one adjustment.** Keep the solo path fully present and functional. Do not market it. Do not put "coming soon" messaging in it — that's patronizing and wrong given the path is fully built. What changes: on Screen 4, the visual hierarchy should signal that "With a partner" is the primary path for the current marketing moment without hiding "On my own." This can be achieved with subtle design adjustments (see Change 2) rather than copy changes. The solo user who finds their own way to "On my own" is a valid Act 2/3 early adopter, and a good solo path is a retention tool if they later bring a partner.

### ModeSelectView — Right Screen to Lead With?

Screen 4 is the right screen for this information — it must happen before Context (Screen 5) because ContextView is branched on `explorationMode`. The routing architecture requires this data before the card stack can be configured.

The problem is not the position. The problem is the rendering. Three equal-weight cards with no visual emphasis on the Act 1 option is a product-strategy inconsistency. The architecture is correct. The surface presentation needs one round of adjustments.

---

## SECTION 4: DATA COLLECTION AUDIT

| Data Point | Screen | Used For | Act 1 Essential? | Notes |
|---|---|---|---|---|
| `displayName` | 3 — NameView | Personalization throughout flow and in-app | **Yes** | Used on Screens 5, 7, 8 and presumably in app UI |
| `pronouns` | 3 — NameView | App UI personalization, content voice | **Partially** | Optional and non-blocking. Does not affect routing, Desire Map, or card deck selection at V1.0. Low cost to collect; low cost if skipped. |
| `customPronouns` | 3 — NameView | Same as pronouns | **No** | Optional field within optional section. Correct to keep; irrelevant to Act 1 conversion path. |
| `explorationMode` | 4 — ModeSelectView | Path routing (solo/couple/browsing), entire downstream configuration | **Yes** | Required before Screen 5 can be configured. Foundational. |
| `nmStage` | 4 — ModeSelectView | Content difficulty via `defaultDifficulty` derivation; CuriosityScreenConfig selection | **Yes** | Drives card deck depth. Critical for personalization quality. |
| `relationshipContext` | 5 — ContextView | CuriosityScreenConfig config selection; floating fragments in Screen 7 | **Yes** | Gates the specific CuriosityScreenConfig instance. Directly affects content relevance. |
| `communicationGoals` | 6 — CuriosityPickerView | Content personalization, conversation deck prioritization | **Partially** | At V1.0, it's unclear how granularly card deck selection uses these. If they drive thematic emphasis in the couple conversation decks, they're essential. If they're collected for future features only, collecting them in onboarding before any value is delivered is premature optimization. **Verify actual V1.0 usage before launch.** |
| `learningGoals` | 6 — CuriosityPickerView | Same as communicationGoals | **Partially** | Same note. Section 2 in CuriosityPickerView requires at least one selection before the CTA appears. If this data doesn't directly improve the V1.0 couple experience, the gate is unjustifiable friction. |
| `curiositySelections` | 6 (derived) | Derived union of above | **Partially** | Derived field — not a separate collection. |
| `defaultDifficulty` | 7 — BuildingPathView (derived) | Card deck difficulty starting point | **Yes** | Written at handoff. Derived from `nmStage`. No user input required. |
| `groundRulesAcceptedAt` | 8 — GroundRulesView | Consent/compliance timestamp | **Yes** | Legal and ethical requirement. |
| `onboardingComplete` | 8 — GroundRulesView | Gate between onboarding and app | **Yes** | Required flag. |
| `completedAt` | 8 — GroundRulesView | Analytics, personalization timing | **Yes** | Required. |

**Key finding on `communicationGoals` / `learningGoals`:** The CuriosityPickerView creates a hard gate — no Section 2 selection = no CTA. This is only justified if these data points meaningfully change what the Act 1 user sees next. If V1.0 card deck selection uses this data to change the sequence or framing of couple conversation decks, the gate is earned. If V1.0 uses a static card deck with no personalization beyond `nmStage` and `relationshipContext`, these fields are collecting data that doesn't pay back the user's investment during onboarding. This is the single most important data model question to answer before launch.

---

## SECTION 5: FRICTION AUDIT

---

**FRICTION POINT 1**
Screen: 4 — ModeSelectView
What causes it: Three equally-weighted mode cards with no visual hierarchy. "With a partner" is the Act 1 path but appears at equal prominence to "On my own" and "Just browsing."
Who feels it: A new couple who isn't 100% sure if this app is "for us" sees three options and hesitates. The hesitation isn't long but it plants a question: "Are we the right user for this?" That question is corrosive for Act 1. The app should answer it before they have to ask.
Severity: **Medium**
Fix: Render "With a partner" with subtly elevated visual treatment at Act 1 launch — not by hiding other options but by making the primary path feel like the default. Options: slightly higher card elevation, slightly bolder title weight, or a soft recommended label. All three options must remain present and fully selectable.

---

**FRICTION POINT 2**
Screen: 6 — CuriosityPickerView
What causes it: Section 1 presents 4–7 options immediately. Section 2 (6–7 more options) appears only after a selection. CTA appears only after a Section 2 selection. A couple who has not yet seen any product value is being asked to invest 60–120 seconds selecting interest categories before the app has done anything for them.
Who feels it: The Act 1 couple in an anxious moment reads this as a form they must complete correctly before they're allowed in. The progressive disclosure gates are technically elegant but emotionally they feel like checkpoints. The couple doesn't know what they're personalizing toward.
Severity: **High** — this is the screen most likely to cause abandonment for an Act 1 user.
Fix: Two options, not mutually exclusive. (1) Add a brief framing line at the top of Screen 6 that connects selections to a named outcome — "This shapes your first conversation deck." Not a feature pitch; a cause-and-effect sentence. (2) Reduce the required minimum to 1 selection in Section 1 and remove the hard gate on Section 2 — make Section 2 optional with a "Skip for now" that enables the CTA. The data from Section 2 is less critical for V1.0 than the retention risk from abandonment here.

---

**FRICTION POINT 3**
Screen: 8 — OnboardingGroundRulesView (Pill 2, coupled path)
What causes it: Pill 2 for coupled users reads: "This won't fix a relationship that's struggling." The detail adds: "The best it can do is give a healthy one more room to grow."
Who feels it: A couple who is curious but not in crisis reads the first sentence and is implicitly asked to evaluate whether their relationship is struggling. This question was not on their mind when they opened the app. They are here because they're curious, not because they're broken. The framing front-loads a negative evaluation of their relationship status in the final screen before the app begins.
Severity: **Medium-High** — this is the last emotional impression before the user enters the product. If it leaves them second-guessing themselves, it undermines the "confidently curious" state that Act 1 needs.
Fix: Reframe Pill 2 for the coupled exploratory path. The ethical point (don't use this as crisis intervention) can stay; the framing should lead with possibility, not deficit. Proposed direction: "This works best when you're both curious, not when one of you is trying to convince the other." Detail: "Come in with questions, not conclusions — that's when this does its best work." This preserves the honest expectation-setting while matching the emotional register of an exploratory couple.

---

**FRICTION POINT 4**
Screen: 7 → 8 → HOME transition
What causes it: "Your path is ready." transitions directly to the must-acknowledge ground rules screen, which transitions directly to Home with no indication of what happens next. The Act 1 couple completes onboarding not knowing the Desire Map is their first destination, not knowing their partner also needs to complete this flow, and not knowing what "Your path" consists of.
Who feels it: The Act 1 couple specifically — the Desire Map requires two people. If one partner completes onboarding before the other, they may spend time in the app without knowing to invite their partner before the Desire Map has meaning.
Severity: **High** — this is a conversion architecture gap, not just a UX friction point. The Desire Map's free-match mechanic only fires after both partners complete it. If the Act 1 user doesn't know this, the conversion moment may never occur.
Fix: A partner expectation-setting moment — either in BuildingPathView's final beat (a single line before "Your path is ready") or as a transitional moment immediately after Ground Rules. See Section 7 and Change 4.

---

**FRICTION POINT 5**
Screen: 4 — ModeSelectView, experience pills
What causes it: The intensity graduation of experience pills (dim → warm → alive, labeled "Curious" → "Exploring" → "Experienced") may cause Act 1 users to self-deprecate. A couple who has discussed NM extensively but not acted on it may feel "Curious" undersells them and "Exploring" oversells them. The visual hierarchy implies these are progress stages rather than equivalent self-description options.
Who feels it: The Act 1 couple who is overthinking their category. This is a small hesitation but for an anxious couple, picking the wrong box feels like it will break the personalization.
Severity: **Low** — this is documented as a known tradeoff in the codebase. The personalization downstream of `nmStage` is real and the friction is minor.
Fix: None required before launch. The documented tradeoff is acceptable. If data shows high rates of changing this selection (if that's trackable), revisit at V1.1.

---

**FRICTION POINT 6**
Transition: Download → First Value Moment (Desire Map)
What causes it: The entire onboarding is completed before the Act 1 user sees any result from the product. ~6–8 minutes of data input before the app does anything for them. The Desire Map — the first value moment — is somewhere in Home with no guaranteed prominence or timing.
Who feels it: Any Act 1 user who finishes onboarding and is dropped into a home dashboard without a clear "start here" call-to-action toward the Desire Map.
Severity: **High** — this is the conversion architecture problem. The paywall mechanic only works if the free reveal happens. The free reveal only happens if both partners complete the Desire Map. Neither of these steps is guaranteed by the current onboarding exit state.
Fix: Post-onboarding home state for couple path should immediately surface the Desire Map as the first action. This is a home dashboard decision, not an onboarding change — but it's the downstream consequence of onboarding's missing Act 1 destination signal.

---

## SECTION 6: THE GROUND RULES SCREEN AUDIT

### 1. Does the Content Serve the Act 1 User?

**Pill 1** (lightbulb — self-knowledge):
> "They say money shows you more of who you are. This journey will do more of the same, if you see it through."

This lands correctly for Act 1. It reframes the experience as revealing, not fixing. It sets an expectation of depth without implying pathology. The "if you see it through" is honest — it doesn't promise it will be easy. Keep exactly as written.

**Pill 2** (coupled path, heart — relationship realism):
> "This won't fix a relationship that's struggling. The best it can do is give a healthy one more room to grow."

This does not serve Act 1 users well. The coupled Act 1 user is curious, not in crisis. They arrive at the Ground Rules screen having made it through 7 screens of an emotionally coherent experience and are told, in the second of three promises, that their relationship needs to be healthy for this to work. This is not wrong advice — it is correct and responsible framing. But "fix a relationship that's struggling" places the Act 1 user in a diagnostic frame they didn't bring with them. Many will read "healthy" and wonder if they qualify. The framing assumes arrival from pain when Act 1 marketing promises arrival from curiosity.

**Pill 3** (hand.raised — not therapy):
> "This is not therapy, and it's not trying to be. This is a conversation tool, not clinical care. Professional support is always just a tap away when you need it."

This is correct and necessary. The TherapistLink below the CTA reinforces it. The framing is honest without being clinical. Keep exactly as written.

### 2. Pill 2 — Does the Coupled Version Create Unnecessary Anxiety?

Yes, in a specific way. "Struggling" is the word that causes the problem. A couple who is curious and mostly happy reads "struggling" and runs a quick diagnostic: *are we struggling?* If they answer "no," the next thought is *then why are we here?* — which triggers self-consciousness. If they answer "maybe," they enter the product with that thought already activated.

Neither outcome serves Act 1. The responsible message (don't use this as crisis infrastructure) should be reframed around the exploratory couple's actual context: come in curious, not convinced.

Proposed Pill 2 revision for coupled path:
- **Title:** "This works best when you're exploring together."
- **Detail:** "If one partner is pushing and the other is being dragged, this will surface that tension faster than it resolves it. Come in curious — both of you."

This preserves the honest expectation (requires genuine mutual buy-in) without diagnosing the relationship as struggling.

### 3. CTA Label "I'm Ready" — Does It Land Correctly for Act 1?

Yes. "I'm ready" is open-ended enough to work for any user state: curious, anxious, skeptical. It asks for nothing beyond a decision to proceed. It doesn't imply the user has signed a contract or made a commitment to an outcome. The lack of mode branching here is appropriate — "I'm ready" is the same for everyone.

If there's an upgrade available, it's not the label but the sub-text. A single line below the CTA — rendered in textSecondary — could acknowledge the couple specifically: "You and your partner will each complete this separately. Your answers stay private until you're both ready to see them together." This isn't a copy change to "I'm ready" — it's an addition that sets the Desire Map expectation at the last possible moment before home. See Change 5.

### 4. TherapistLink Below CTA — Appropriate Here?

Functionally and ethically: yes, it must be here. It's the direct implementation of the Moral Red Line's "professional support is always just a tap away."

Tonally for Act 1: it's the right information in a slightly awkward moment. A curious couple finishing onboarding does not want their first impression of the app to be "and here's how to find a therapist." The information needs to exist here; the visual weight should be quiet. Per DESIGN_DOC.md, `TherapistLink` appears below the CTA with `.padding(.top, 12)` — this is already the lowest-emphasis position available. No change recommended. The position is correct.

### 5. Recommendation

**Modify copy — Pill 2 coupled path only.** The structure, pattern, position, must-acknowledge behavior, animation system, PromiseCard component, and CTA are all correct. The single change is the framing of the Pill 2 message for users who selected "With a partner." Solo Pill 2 is appropriate and should stay untouched.

---

## SECTION 7: WHAT THE ONBOARDING IS MISSING FOR ACT 1

### 1. Partner Awareness

The Desire Map requires two partners. The current onboarding is built as a single-user experience — it personalizes around the individual completing it, with no mention that their partner will need to do the same.

**Is there currently a moment that sets this expectation?** No. Nowhere in the 8-screen flow is a partner mentioned after Screen 4's mode selection ("With a partner"). Screen 5 uses "together" language ("You're exploring together") but this refers to the relationship context, not to the app mechanic requiring two completions.

**Where should it be introduced?** Two options:

Option A — In Screen 7 (BuildingPathView), as a brief coda to the processing animation. After "Your path is ready." add one line: "Next step: invite [partner] to do the same." or "Your partner's path is the other half of this." This is the natural moment — the couple has just been told their path is built; it's the right beat to mention that their partner's path also needs to be built.

Option B — In Screen 8 (GroundRulesView), as a single line below the CTA above the TherapistLink. Less ideal because it's post-must-acknowledge and may be read after the commitment to proceed has already been made.

**Recommendation:** Option A. A single low-emphasis line in BuildingPathView's final beat costs almost nothing to implement and fixes the most significant conversion gap in the flow.

### 2. The Desire Map as Destination

The Desire Map mutual reveal is the first value moment — the conversion moment. It is never mentioned in the onboarding.

**Does the onboarding build toward this moment?** Not explicitly. The flow builds toward "your path" as a general concept. Screen 7's four build items ("Your starting point, your experience level, what you want to explore, your conversation style") are all true inputs to the Desire Map but the connection is never made.

**Should it be mentioned?** Yes — but carefully. "Desire Map" is a product term that means nothing to a new user before they've seen it. Naming it prematurely risks it reading as marketing copy inside an intimate onboarding. The right approach is not to name it but to *describe it*: "Next, you and your partner will each privately answer the same questions about what you want. Then you'll see what you have in common."

This description doesn't use product terminology, sets accurate expectations, and creates anticipation for a specific, shared experience — which is exactly what the Act 1 couple came for.

The natural location for this is BuildingPathView's final beat or a single transitional line in Screen 8.

### 3. Anticipation Building

BuildingPathView currently builds toward "Your path is ready." — which is correct but abstract. For an Act 1 couple, "your path" should feel like it's leading to something specific and imminent, not to a home dashboard.

The four build items ("Your starting point," "Your experience level," "What you want to explore," "Your conversation style") all describe inputs to a system. What the animation doesn't show is the output — the thing those inputs produce. For Act 1, the output is: a mutual reveal that shows both of them something true about what they want.

**Recommendation:** No visual changes to BuildingPathView (the animation is already at the upper limit of what the 7.5-second window can sustain). A single line of text after the "Your path is ready." tagline — fading in with the same easeOut pattern — that says "You're ready for your first conversation together." This bridges the abstract ("your path") to the concrete ("a conversation together") without naming the Desire Map or breaking the emotional tone.

### 4. The Paywall Moment

**Current post-onboarding flow:** Ground Rules → `onFinished()` → HOME

**When does the Act 1 user encounter the Desire Map?** This depends on the home dashboard UI — not documented in DESIGN_DOC.md at the level needed to audit it here. If the home dashboard for a newly onboarded couple immediately surfaces the Desire Map as the first action, the "instant personalized result → paywall on that result" mechanic works correctly. If the home dashboard is a generic dashboard and the Desire Map is discoverable but not prominent, the mechanic fails.

**Is the paywall placement correctly sequenced?** The principle is: both partners complete the Desire Map privately → one free match appears → full reveal behind paywall. This mechanic is architecturally correct per PROJECT_SCOPE.md. The risk is that onboarding doesn't guarantee the couple finds the Desire Map immediately after completing it.

**What needs to happen:** The home state for a newly onboarded couple (both partners, neither has yet completed the Desire Map) should surface the Desire Map as the primary first action — above the card decks, above any navigation, as the "start here" moment. This is a home dashboard implementation decision but it must be validated before launch. The onboarding can only point toward the Desire Map; the home state must surface it.

---

## SECTION 8: RECOMMENDED CHANGES — PRIORITIZED

---

**CHANGE 1**
Priority: **P0 — must do before launch**
Type: Copy change
What changes: Screen 8 (GroundRulesView), Pill 2, coupled path only. The `title` and `detail` strings inside the `PromiseCard` for the `heart.fill` icon, when `data.explorationMode == .couple`.
Current: Title: "This won't fix a relationship that's struggling." / Detail: "The best it can do is give a healthy one more room to grow."
Proposed: Title: "This works best when you're both curious." / Detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
What it fixes: Friction Point 3 — plants false diagnostic anxiety in an exploratory couple at the worst possible moment (final screen before app entry).
Effort: 30 minutes — single string change in `OnboardingGroundRulesView.swift`
Risk: Minimal. The ethical message (requires genuine mutual buy-in) is preserved. No structural changes.
Act 1 impact: New couple arrives in the product curious and supported rather than having just been told their relationship needs to be healthy enough to deserve the app.

---

**CHANGE 2**
Priority: **P0 — must do before launch**
Type: Screen simplification (visual hierarchy only)
What changes: Screen 4 (ModeSelectView), the three mode cards. "With a partner" receives a visually elevated treatment at Act 1 launch — specifically: title weight increased from `bodyMedium` to the equivalent of `bodyText` semibold, and a very low-opacity "Most couples start here" micro-label (AppFonts.overline, textTertiary, ~30% opacity) appears above or inside the card. The other two cards remain fully present and selectable with no visual degradation.
What it fixes: Friction Point 1 — Act 1 primary path has no visual advantage over Act 2/3 paths; a new couple hesitates about which option is "for them."
Effort: 3–4 hours — requires adding a conditional micro-label to the card and adjusting the title weight for one card ID.
Risk: Low. The change is additive and cosmetic. All three paths remain fully functional. The label can be a single string that is easy to remove when Act 2/3 marketing begins.
Act 1 impact: The couple who lands on Screen 4 sees their path slightly surfaced above the others without being told the other options don't apply to them.

---

**CHANGE 3**
Priority: **P0 — must do before launch**
Type: Screen simplification + copy change
What changes: Screen 6 (CuriosityPickerView). Two sub-changes:
(a) Add a single framing line directly below the screen headline — `AppFonts.caption`, `textSecondary` — that reads: "This shapes your first conversation deck." One sentence. No CTA copy. Establishes a cause-and-effect between their selections and an immediate, named outcome.
(b) Remove the hard Section 2 gate on the CTA. Make Section 2 optional: after a Section 1 selection, Section 2 appears as normal, but the CTA also becomes available immediately. Section 2 includes a persistent `AppFonts.caption` note: "The more you choose, the more tailored your path." Users who select Section 2 items do so voluntarily rather than as a required gate.
What it fixes: Friction Point 2 — Screen 6 is the highest-abandonment risk screen; the gate requires investment before value is visible.
Effort: 4–6 hours — the framing line is a string change; removing the Section 2 gate requires logic adjustments to the gate progression system in `OnboardingCuriosityPickerView.swift` (the `ctaHasAppeared` gate currently requires a Section 2 selection; this becomes `section1HasASelection || isRestoringState`).
Risk: Medium. The gate logic is documented and deliberate. Removing it means some users will skip Section 2 entirely, collecting less `learningGoals` data. This is acceptable if `learningGoals` is not a hard dependency for V1.0 card deck personalization.
Act 1 impact: An anxious couple can make two or three selections they recognize themselves in and move forward. The screen feels like customization rather than homework.

---

**CHANGE 4**
Priority: **P1 — should do before launch**
Type: New element (single text line in existing screen)
What changes: Screen 7 (BuildingPathView). After the "Your path is ready." tagline (which fades in at ~4900ms), add one additional line that fades in with a 400ms delay using the same easeOut 0.6s curve: "Next: invite your partner to complete theirs." This line uses `AppFonts.caption`, `textSecondary`, and applies only when `data.explorationMode == .couple`.
What it fixes: Section 7 finding — the onboarding never establishes that the Desire Map requires both partners, meaning one partner may complete onboarding and explore the app for days without understanding the core mechanic.
Effort: 2–3 hours — adding a conditional text element to the BuildingPathView timeline. The animation system already has the scaffolding for timed text reveals; this is an extension of the existing pattern.
Risk: Low. The line is mode-gated to `.couple` and adds no structural changes. If the copy needs refinement, it's a string change.
Act 1 impact: The couple who completes onboarding knows, before they reach home, that their partner also needs to complete the flow. This removes the ambiguity around the Desire Map's two-partner requirement.

---

**CHANGE 5**
Priority: **P1 — should do before launch**
Type: New element (below-CTA copy in Screen 8)
What changes: Screen 8 (GroundRulesView). Below the CTA button and above `TherapistLink`, add a single explanatory line for `.couple` mode only: "You and your partner each answer privately. You'll see what you have in common together." Uses `AppFonts.caption`, `textSecondary`, centered, same fade timing as CTA.
What it fixes: Sections 3 and 7 — the couple arrives at the terminal screen of onboarding with no knowledge of the Desire Map mechanic that is their primary first action.
Effort: 1–2 hours — a conditional text element in the already-complex Screen 8 layout. The CTA lives outside the ScrollView; this line also needs to live outside (or be the last item inside) to remain visible on SE-sized devices.
Risk: Low. Mode-gated, cosmetic, removable. The one layout risk is on small screens (375pt width) where adding another element below the CTA may push TherapistLink off-screen. Verify on iPhone SE simulator.
Act 1 impact: The couple enters the app knowing what to do first and that the first thing requires their partner. Conversion to Desire Map completion — the only meaningful success metric for Act 1 — improves when the user arrives knowing what they're about to do.

---

**CHANGE 6**
Priority: **P2 — nice to have**
Type: Copy change
What changes: Screen 6 (CuriosityPickerView). Audit and revise Section 2 option labels for the `coupleNotTalkedConfig` and `coupleTalkingConfig` — the two Act 1 primary couple-curious configs. Current labels are functional but some read as experienced-practitioner language. Options like "Navigating jealousy and compersion," "Building agreements," and "Understanding polycule dynamics" are Act 2/3 language showing up in an Act 1 config. These should be softened for curious couples.
What it fixes: Friction Point 2 (partial) — language familiarity reduces cognitive load.
Effort: 2–3 hours — string changes in `CuriosityScreenConfig.swift` for the two Act 1 primary configs.
Risk: Low. String changes. Configs are static instances.
Act 1 impact: A new couple doesn't have to decode "polycule dynamics" to know whether it applies to them.

---

**CHANGE 7**
Priority: **P2 — nice to have**
Type: Flow change (post-onboarding, not onboarding itself)
What changes: Home dashboard first-state for newly onboarded couple path. Verify and implement: the home dashboard for a couple where neither partner has yet completed the Desire Map should surface the Desire Map as the primary first action — before navigation, before other cards, as a clear "start here" moment. This is a home dashboard implementation decision.
What it fixes: Friction Point 6 and Section 7 finding — the "instant personalized result → paywall" mechanic only works if the Desire Map is the first thing a new couple does in the app.
Effort: Unknown — depends on current home dashboard implementation and how the routing post-onboarding is structured. Estimate 4–8 hours minimum.
Risk: Medium — if the home dashboard already does this, zero work. If it doesn't, it may require changes to `HomeViewCoupleNew.swift` and the routing logic in `ContentView.swift` or `AppState.swift`.
Act 1 impact: The entire conversion architecture depends on this. It is not optional if the Desire Map is the conversion moment.

---

### Summary Matrix

| Change | Priority | Type | Effort | Risk |
|--------|----------|------|--------|------|
| 1: Ground Rules Pill 2 copy | P0 | Copy change | 30 min | Low |
| 2: ModeSelectView hierarchy | P0 | Visual / copy | 3–4 hrs | Low |
| 3: CuriosityPicker gate + framing | P0 | Simplification + copy | 4–6 hrs | Medium |
| 4: BuildingPath partner line | P1 | New element | 2–3 hrs | Low |
| 5: Ground Rules Desire Map hint | P1 | New element | 1–2 hrs | Low |
| 6: Config label softening | P2 | Copy change | 2–3 hrs | Low |
| 7: Home first-state routing | P2 | Flow change | 4–8 hrs | Medium |

---

## SECTION 9: THE ONBOARDING AFTER CHANGES

### How Many Screens Remain

8 screens remain on the couple path. No screens are removed. The changes are surgical: copy, visual hierarchy, gate logic, and two additional text elements. The architecture is not touched.

### What Data Is Collected and When

| Screen | Data collected | Required |
|--------|---------------|----------|
| 3 — NameView | `displayName`, `pronouns` | name required, pronouns optional |
| 4 — ModeSelectView | `explorationMode`, `nmStage` | both required (routing depends on them) |
| 5 — ContextView | `relationshipContext` | required (drives Screen 6 config) |
| 6 — CuriosityPickerView | `communicationGoals` (required), `learningGoals` (optional) | Section 1: 1+ selection required; Section 2: optional |
| 7 — BuildingPathView | `defaultDifficulty` (derived) | automatic |
| 8 — GroundRulesView | `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt` | automatic on acknowledge |

### Revised Critical Path for an Act 1 Couple

```
Screen 1 — StatView
  [25s] "1 in 5 people." Normalize. Lower the guard.

Screen 2 — BrandView
  [3.5s] "Open Lightly." This is premium. This is private. You're safe here.

Screen 3 — NameView
  [40s] Name (required). Pronouns (optional, non-blocking).
  → App begins using your name immediately.

Screen 4 — ModeSelectView
  [35s] "With a partner" reads as the primary option.
  Select experience level. Progress.

Screen 5 — ContextView
  [30s] Which context fits right now? Tap to confirm.
  → First moment the app reflects their specific situation back to them.

Screen 6 — CuriosityPickerView
  [60s] "This shapes your first conversation deck."
  Section 1: 1+ selection (required). Section 2: optional, not gated.

Screen 7 — BuildingPathView
  [7.5s] Processing. The app has heard you.
  "Your path is ready."
  [couple mode] "Next: invite your partner to complete theirs."

Screen 8 — OnboardingGroundRulesView
  [55s] Three promises. Revised Pill 2 for exploratory couples.
  [couple mode, below CTA] "You and your partner each answer privately.
  You'll see what you have in common together."
  Tap: "I'm ready."
  → HOME (Desire Map surfaced as first action)
```

**Total time from cold launch to first value moment:** ~4–6 minutes to home (down from ~6–8 minutes with the Section 2 gate removed), then immediate Desire Map entry if Change 7 is implemented.

**Data collected:** Lean and purposeful. Every field directly affects either routing, content personalization, or the consent framework. The one optional relaxation (Section 2 of CuriosityPickerView) is the right tradeoff.

### What "Done" Looks Like

When onboarding completes, the Act 1 couple is in this state:
- `displayName` set, used throughout
- `explorationMode == .couple`, `nmStage` set
- `relationshipContext` selected from the couple-specific cards
- At least one `communicationGoal` selected
- `defaultDifficulty` derived and stored
- `groundRulesAcceptedAt` timestamp written
- `onboardingComplete == true`

They know: the app is private, it's not therapy, their partner also needs to complete this, and what they're about to do together.

They see: Home → Desire Map as primary first action.

### The Felt Experience — One Paragraph

It's 11pm. You've been talking about this for three weeks — short conversations that start well and end somewhere neither of you wanted to be. You found this app in a Reddit thread and sent the link to your partner without much preamble. Now you're both on the couch, one phone each, opening it for the first time. The first screen tells you one in five people have explored this — more than you thought. The wordmark comes in like it was designed for exactly this moment, which it was. You put in your name and it starts using it immediately. You pick "With a partner" because that feels exactly right, and you notice that option was slightly easier to find than the others. You describe where you are — "haven't talked about it yet" — and for the first time in three weeks, the app agrees that this is a valid place to be. You pick a few things you want to understand better; the screen doesn't make you pick everything. Something processes — your profile builds, your path forms — and it tells you you're ready. It tells you your partner needs to do the same thing. Not as a warning. As an instruction. You hand them the phone. They go through it in six minutes. Then you're both sitting there, each of you having answered privately, and the app tells you: *let's see what you have in common.* That's the moment you were both afraid to try to find on your own.

---

## SECTION 10: WHAT STAYS UNTOUCHED

The following elements must not change as a result of this audit:

**AppColors, AppFonts, all design tokens** — The entire design system is the product's visual identity. Changes here cascade across 99 files. Nothing in this audit requires a token change.

**Animation systems — entrances, breathing, particles, bloom** — These are what make the app feel premium and considered to a first-time user. They are the first impression. They are not responsible for any of the friction identified in this audit.

**OnboardingProgressBar architecture** — The bloom/shimmer/particle system in the progress bar is a technical achievement that contributes meaningfully to Screen 8's emotional weight. It's not involved in any of the identified friction.

**Accessibility implementations** — VoiceOver support across all 8 screens is correct and complete. This audit identified no accessibility gaps; none should be introduced.

**The three-path routing architecture** — Solo / Couple / Browsing paths must all remain in the code. Act 3 and the Just Browsing path are present by design. This audit recommends visual hierarchy changes on Screen 4, not removal of paths.

**Ground Rules must-acknowledge pattern** — The legal and ethical framing of Screen 8 is non-negotiable. The fact that it has no back button and cannot be skipped is a design rule, not a bug. Only the copy of Pill 2 for the coupled path is touched.

**DEBUG assert pattern on all callbacks** — These are safety checks that catch wiring failures during development. They have no user-facing effect and must not be removed.

**hasAnimated guard pattern** — Prevents stacking of repeatForever animations on re-appear. Required for stability on all screens that have entrance animations.

**State restoration pattern** — `restoreStateIfNeeded()` runs before `hasAnimated` guard on every appear to preserve back-navigation state. This is the correct architecture and must stay intact across all screens that collect data.

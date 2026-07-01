# 15 · Content Authoring — Launch Deck Set + De-Placeholder the Desire / Assessment / Pulse / Learn Corpus

**Goal:** Author the launch content to the mature JSON schemas already shipped, in Vayl's voice, so the app plays real decks and shows real discovery content on device. This pass DRAFTS content for Bryan to edit; it does not touch models, Stores, or the schema. The finished pass produces: a defined launch deck set with the first 3 decks fully drafted to `the-opener.json`'s exact card schema, a locked `desire_items.json`, a de-placeholdered `assessment_questions.json` (or its confirmed retirement), the Pulse question/tier copy locked, and the Learn seed list expanded, all loading through `ContentLoader` with no code changes.

---

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

> ## ✍️ CONTENT-SPECIFIC LICENSE ADDENDUM (this plan is copy, not code)
>
> Unlike the sibling plans, this plan's "one-shot" is **authoring text into existing JSON files**, not
> writing Swift. The rules above still hold for the ZERO code you write, but the real discipline here is
> **voice** and **schema-fidelity**:
>
> - **Match The Opener, not the legacy placeholders.** `Vayl/Resources/Decks/the-opener.json` is the
>   ONE good, tone-correct deck — every card you draft imitates its warmth, curiosity, and specificity.
>   The legacy `Vayl/Resources/Content/cards.json` literally says
>   `"context_note": "Placeholder — replace with clinical content"` on six cards. **That is the WRONG
>   direction.** Vayl is a discovery tool, not a clinic. Never write instructional, diagnostic, or
>   textbook copy ("Active listening means fully concentrating on…"). Write the way a warm, sharp friend
>   asks the real question.
> - **No em dashes. Anywhere. Ever.** This whole plan is copy, and the standing rule
>   (`CLAUDE.md` / memory `no_em_dashes`) bites hardest here: use commas, periods, colons; hyphens in
>   compounds are fine. The Opener itself violates this in a few `context_beat_copy`/`back_copy` strings
>   (it predates the rule); **do not copy that habit, and fix any em dash you touch.**
> - **Discovery, never assessment.** Per `CLAUDE.md` Product Principles: name what the user said, never
>   infer what they didn't. No card, no desire item, no quiz result may hand down a verdict about the
>   person. End every quiz at a door to content, never a conclusion.
> - **You draft; Bryan edits.** This is a starting draft he refines, not final shipping copy. Aim for
>   "80% there, tone-correct, schema-valid," not "perfect." Better to draft all of it decently than
>   polish two decks and leave the rest empty.
> - **Schema-exact or it won't decode.** `ContentLoader` uses `.convertFromSnakeCase`
>   (`Vayl/Core/Services/ContentLoader.swift:61,89`). Every field name, every enum rawValue
>   (`type`, `who_starts`, `register`, `category`, `gendered_for`) must match the model exactly or the
>   deck fails to load at runtime. Copy the field set from `the-opener.json` verbatim; change only values.

---

## Context Fable needs

- **What this is (roadmap C1 + C2 + C3):** the content-authoring pass. The engines are built; the corpus
  is mostly empty or stubbed. This plan fills it. It is **content-shaped**, not code-shaped: the only
  files that change are JSON under `Vayl/Resources/`. No `.swift` file is edited. The schemas are mature
  and frozen — you are pouring content into a finished mold.

- **The ONE good reference (imitate its tone + schema exactly):**
  `Vayl/Resources/Decks/the-opener.json` — 10 cards, warm and specific, correct card schema. Study every
  field. The card model is `Vayl/Core/Models/Card.swift` (struct `Card`); the deck model is
  `Vayl/Core/Models/Deck.swift` (struct `Deck`); the enums (`CardType`, `CardIntensity`, `WhoStarts`,
  `GenderDynamic`, `ContextBeatType`, `DeckCategory`) live in
  `Vayl/Core/Models/Enums/AppCardEnums.swift`. **Read those before drafting** so every enum value is real.

- **How decks load (verified):** the deck grid reads `Vayl/Resources/Decks/deck-catalog.json` via
  `DeckCatalogService.loadSummaries()` (`Vayl/Features/Play/Services/DeckCatalogService.swift:9` →
  `ContentLoader.load(DeckSummary.self, from: "deck-catalog")`); an individual deck's cards load on play
  from `Vayl/Resources/Decks/<id>.json` via `catalog.loadDeck(id:)`
  (`Vayl/Features/Play/Store/PlayStore.swift:100`). `deck-catalog.json` currently lists **14 decks** with a
  target `card_count` each. **`deck-index.json` has ZERO Swift consumers — it is dead.** Do not spend
  effort on it.

- **Current deck reality (verified 2026-07-01):** 16 files in `Resources/Decks/`. **`the-opener.json` is
  the only real deck (10 cards).** The other 13 deck JSONs (`the-check-in`, `boundaries`, `communication`,
  `trust-repair`, `right-now`, `before-tonight`, `desire-and-fantasy`, `jealousy-compersion`,
  `the-styles`, `metamour`, `the-audit`, `solo-prep`, `unfinished-business`) are **1-card seed stubs** —
  each has one on-voice seed card already (good starting tone) and the correct deck-level metadata
  (`act`, `intensity`, `is_locked`, `required_entitlement`, `sort_order`). The catalog's target
  `card_count` (10–24) is aspirational; the files don't have those cards yet.

- **Desire content is LIVE and load-bearing (be careful):** `desire_items.json` (**19 items**) loads via
  `ContentLoader.loadDesireItems()` and is consumed all over the Desire Map, Map tab, and Vault
  (`DesireMapStore.swift:97`, `DesireRevealStore.swift:223,227`, `MapStore.swift:190,260`,
  `VaultStore.swift:72,255`). The model `Vayl/Core/Models/DesireItem.swift` is **cohort-adaptive**:
  `tracks` says which cohort sees an item; `answers` holds 4 answer strings PER track in fixed weight
  order `[excitedAboutIt, openToIt, probablyNot, notForMe]` (`DesireRatingValue.allCases` order, defined
  `Vayl/Core/Models/Enums/AppDesireEnums.swift:64`). **Only the weight index syncs to matching; the string
  is cohort copy.** Current counts already match the cohort design: **curious = 18 items, established = 12
  items** (7 items are curious-only, 12 appear in both tracks, 0 established-only). No placeholder markers.

- **Assessment + legacy card content is DEAD (verified):** `loadCards()`, `loadCategories()`, and
  `loadAssessmentQuestions()` on `ContentLoader` (`Vayl/Core/Services/ContentLoader.swift:113,109,117`)
  have **ZERO call sites in the app.** So `cards.json` (6 "replace with clinical content" markers),
  `categories.json`, and `assessment_questions.json` (**20 questions**, Q1 flagged
  `"Placeholder — replace with validated content"`) are unreferenced legacy files superseded by the
  Deck/Card JSON system and `DeckCategory`. **The placeholder/clinical markers in the app all live in dead
  files.** Nothing consumes them. See Open Decision D2 for how to handle assessment content.

- **Pulse content is hardcoded in Swift, not JSON (verified):** the five check-in questions live in
  `Vayl/Core/Models/PulseAnswers.swift` (enum `PulseAnswers`, structs `CheckInQuestion` / `CheckInPill`),
  and the 4-tier capacity model lives in `Vayl/Core/Models/Enums/AppPulseEnums.swift`
  (`PulseCapacityColor` rose/magenta/indigo/cyan; `PulseQuadrant` expansive/sovereign/friction/protective
  with `spaceName` / `sublabel`). There is **no pulse question JSON file.** Locking pulse copy therefore
  means locking the strings in these two Swift files, which the license permits as content edits (they are
  data, not logic — you change only literal strings, never the axis math). Note a live copy drift:
  `Vayl/Features/Pulse/TierGuideSheet.swift:32` calls the fourth tier **"Contracted"** while
  `PulseQuadrant.spaceName` (`AppPulseEnums.swift:80`) and `MapPulseHero` call it **"Protective"** /
  **"Friction"**. Reconcile the name.

- **Learn content is LIVE with an async-refresh seam (verified):** `LearnStore`
  (`Vayl/Features/Learn/Store/LearnStore.swift`) loads seven JSONs from bundle at init, then calls
  `refresh()` which overrides `findings` / `lexiconTerms` / `mediaQuotes` from Supabase via
  `ContentService.shared.fetchFindings()/fetchGlossary()/fetchQuotes()`
  (`Vayl/Core/Services/ContentService.swift:24,39,54`, tables `research_findings` / `glossary_terms` /
  `media_quotes`). `HomeLexicon.swift:94-96` does the same `remote ?? bundled` fallback. **The tab UI is
  built; this pass only fills the seed lists.** Current seed counts: `research_findings` = **3**,
  `lexicon_terms` = **8**, `learn_media` = **4**, `voices` = **3**, `media_quotes` = **3**,
  `learn_quizzes` = **2** (metadata only, no questions), `support_resources` = **6**. `companion_cards.json`
  (3 tiers of post-match prompts) is LIVE via `CompanionCardStore.swift:18` and already on-voice.

- **Delivery model (recommendation, Open Decision D4):** ship content **in-bundle** for V1 (current
  approach) while keeping the Learn async-refresh seam warm. In-bundle is simplest and works offline; the
  `ContentService` seam already lets Learn corpus copy change server-side without an app update if needed.
  Decks and desire items stay in-bundle (they are structural, not editorial-churn content).

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Resources/Decks/the-check-in.json` (overwrite the stub) | Deck 2: 12 warm, low-intensity pulse-of-the-week cards |
| `Vayl/Resources/Decks/boundaries.json` (overwrite the stub) | Deck 3: 16 cards, boundary-as-yours framing (free deck) |
| _(no net-new files)_ | All targets already exist as stubs; you overwrite them in place |

### Modify

| File | Line anchor | Change |
|---|---|---|
| `Vayl/Resources/Decks/the-check-in.json` | whole file (currently 33 lines / 1 card) | Author to 12 cards |
| `Vayl/Resources/Decks/boundaries.json` | whole file (currently 33 lines / 1 card) | Author to 16 cards |
| `Vayl/Resources/Decks/communication.json` | whole file (1-card stub) | Author to ~10 cards (first Core deck draft) |
| `Vayl/Resources/Decks/deck-catalog.json` | `card_count` fields | Set each `card_count` to the real authored count; drop or `is_locked:true` any deck left as a stub |
| `Vayl/Resources/Content/desire_items.json` | whole file (19 items) | Lock copy: fix em dashes, tighten answer strings, confirm 18/12 split. **No id / track / weight-order changes.** |
| `Vayl/Resources/Content/assessment_questions.json` | Q1 `context_note` (line 10) | Either de-placeholder Q1 + retire the marker, OR delete the file if D2 = retire (dead, no consumers) |
| `Vayl/Resources/Content/research_findings.json` | append | Grow from 3 to ~8 findings (real, cited, honest-limitation) |
| `Vayl/Resources/Content/lexicon_terms.json` | append | Grow from 8 to ~16 terms/sentences |
| `Vayl/Resources/Content/learn_media.json` | append | Grow from 4 to ~10 curated items |
| `Vayl/Resources/Content/voices.json` | append | Grow from 3 to ~6 voices |
| `Vayl/Resources/Content/media_quotes.json` | append | Grow from 3 to ~6 adages |
| `Vayl/Core/Models/PulseAnswers.swift` | Q1-Q5 `text` + pill `label` strings only | Lock pulse question copy (see D3); axis deltas UNCHANGED |
| `Vayl/Core/Models/Enums/AppPulseEnums.swift` | `spaceName` / `sublabel` strings | Lock tier copy; reconcile "Friction/Protective" vs TierGuideSheet "Contracted" |
| `Vayl/Features/Pulse/TierGuideSheet.swift` | line 32 tuple | Rename the 4th tier string to match `PulseQuadrant.spaceName` (copy fix, not logic) |

### Delete

| File | Reason |
|---|---|
| `Vayl/Resources/Content/cards.json` | Legacy, `loadCards()` has zero callers, holds the "clinical" placeholder markers. Delete ONLY if Open Decision D1 = purge (recommended). |
| `Vayl/Resources/Content/categories.json` | Legacy, `loadCategories()` has zero callers, superseded by `DeckCategory`. Delete ONLY if D1 = purge. |
| `Vayl/Resources/Content/assessment_questions.json` | Legacy, `loadAssessmentQuestions()` has zero callers. Delete ONLY if D2 = retire (recommended). |
| `Vayl/Resources/Decks/deck-index.json` | Dead: zero Swift consumers. Delete ONLY if D1 = purge. |

> **Deletion guardrail:** the three legacy accessors still EXIST on `ContentLoader`
> (`loadCards`/`loadCategories`/`loadAssessmentQuestions`, lines 113/109/117). They compile but are
> unreferenced. If you delete the JSON, the accessors will still compile (they only throw at runtime when
> called, and nothing calls them). Deleting the accessor methods themselves is out of scope for a content
> plan — that belongs to the dead-code plan (`01-dead-code-purge.md`). Leave the methods; just remove the
> unreferenced files if D1/D2 say purge. **Do not delete a JSON file whose accessor has a live caller
> (`loadDesireItems`, `loadCompanionCards`) — those are load-bearing.**

---

## Build steps (segments)

### Segment 1 — Define the launch deck set + author Deck 2 (The Check-In)

**One thing:** decide the launch deck count and fully draft the second deck to The Opener's exact schema.

**Launch deck set (the recommendation Bryan confirms in D-decks):** ship **3 fully-authored free
foundation decks** for V1 — `the-opener` (done, 10 cards), `the-check-in` (this segment, 12 cards),
`boundaries` (Segment 2, 16 cards) — plus **1 drafted Core deck** (`communication`, Segment 3, ~10 cards)
as the paywall proof. The remaining 10 catalog decks stay listed but locked/stubbed for post-launch
authoring. **Three real free decks + one Core deck is the right V1 volume** — enough to prove the core loop
and the paywall without pretending Vayl is a content library. Do not let the 14-entry catalog or the 25
`CardType` cases set scope; most cases (`sharedCanvas`, `wordCloud`, `timeCapsule`, etc.) have no render
path yet and must NOT be used. **Only `prompt`, `reflect`, and `whisper` are safe card types for V1
authoring** (they are the types The Opener uses and the session engine renders).

**Schema contract (copy verbatim from `the-opener.json`, change only values):**
```jsonc
{
  "id": "<card-id like the-check-in-03>",
  "deck_id": "<parent deck id>",
  "text": "<the card copy. \\n\\n for stanza breaks. No em dashes.>",
  "highlight_words": ["<1-2 exact substrings from text to glow>"],
  "type": "prompt",                 // prompt | reflect | whisper ONLY for V1
  "intensity": 1,                   // Int 1-8 (CardIntensity rawValue), rises across the deck
  "who_starts": "partnerA",         // partnerA | partnerB | both  (NOT solo unless soloPrep deck)
  "is_sensitive": false,            // true only for sex/deep cards -> screenshot protection
  "can_skip": false,                // early anchor cards false; deeper cards true
  "register": "flexible",           // flexible | anxious | excited
  "context_beat_type": null,        // null | "banner" | "interstitial"
  "context_beat_copy": null,        // the beat text if type set, else null
  "back_copy": null,                // responsive follow-up after they answer, else null
  "is_gendered_card": false,
  "gendered_for": null,             // null | "mf" | "mm" | "ff" | "flexible"
  "sort_order": 3
}
```

**Draft `the-check-in.json` (12 cards).** The Check-In is the lowest-intensity foundation deck: a short,
warm weekly pulse, `category: "foundationEntry"`, free, `intensity: 1`. Keep intensity mostly 1-3, ending
soft. Here is the full authored deck as a starting draft (Bryan edits):

```json
{
  "id": "the-check-in",
  "title": "The Check-In",
  "subtitle": "A short, warm pulse.",
  "category": "foundationEntry",
  "act": 1,
  "intensity": 1,
  "is_locked": false,
  "required_entitlement": null,
  "tags": ["foundation", "free", "entry", "starter"],
  "sort_order": 2,
  "schema_version": 1,
  "cards": [
    { "id": "the-check-in-01", "deck_id": "the-check-in", "text": "Where are we, really, this week?", "highlight_words": ["really"], "type": "prompt", "intensity": 1, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 1 },
    { "id": "the-check-in-02", "deck_id": "the-check-in", "text": "What is one moment from this week that you keep coming back to?", "highlight_words": ["one moment"], "type": "prompt", "intensity": 1, "who_starts": "partnerB", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 2 },
    { "id": "the-check-in-03", "deck_id": "the-check-in", "text": "On a normal day, how full is your tank right now?\n\nWhat has been drawing from it?", "highlight_words": ["your tank"], "type": "prompt", "intensity": 2, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 3 },
    { "id": "the-check-in-04", "deck_id": "the-check-in", "text": "Is there anything small you have been meaning to tell me and just haven't found the moment for?", "highlight_words": ["haven't found the moment"], "type": "prompt", "intensity": 2, "who_starts": "partnerB", "is_sensitive": false, "can_skip": true, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 4 },
    { "id": "the-check-in-05", "deck_id": "the-check-in", "text": "When did you feel closest to me this week?", "highlight_words": ["closest"], "type": "prompt", "intensity": 2, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 5 },
    { "id": "the-check-in-06", "deck_id": "the-check-in", "text": "Was there a moment you felt a little distance, even briefly?\n\nNo blame here. Just naming it.", "highlight_words": ["a little distance"], "type": "prompt", "intensity": 3, "who_starts": "partnerB", "is_sensitive": false, "can_skip": true, "register": "anxious", "context_beat_type": null, "context_beat_copy": null, "back_copy": "If something specific came up, resist the urge to solve it right now. Just let each other be heard first.", "is_gendered_card": false, "gendered_for": null, "sort_order": 6 },
    { "id": "the-check-in-07", "deck_id": "the-check-in", "text": "What is one thing I could do more of that would make your week lighter?", "highlight_words": ["lighter"], "type": "prompt", "intensity": 2, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 7 },
    { "id": "the-check-in-08", "deck_id": "the-check-in", "text": "Take a breath before this one.\n\nWhat do you need from me right now that you haven't asked for?", "highlight_words": ["haven't asked for"], "type": "reflect", "intensity": 3, "who_starts": "partnerB", "is_sensitive": false, "can_skip": true, "register": "anxious", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 8 },
    { "id": "the-check-in-09", "deck_id": "the-check-in", "text": "What are you looking forward to together in the week ahead?", "highlight_words": ["looking forward to"], "type": "prompt", "intensity": 2, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "excited", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 9 },
    { "id": "the-check-in-10", "deck_id": "the-check-in", "text": "Name one thing you appreciated about me this week that you didn't say out loud at the time.", "highlight_words": ["didn't say out loud"], "type": "prompt", "intensity": 2, "who_starts": "partnerB", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 10 },
    { "id": "the-check-in-11", "deck_id": "the-check-in", "text": "If this week had a single word, what would yours be?", "highlight_words": ["a single word"], "type": "prompt", "intensity": 1, "who_starts": "both", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 11 },
    { "id": "the-check-in-12", "deck_id": "the-check-in", "text": "One quiet thing you want us to carry into next week.", "highlight_words": ["carry into next week"], "type": "whisper", "intensity": 2, "who_starts": "both", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 12 }
  ]
}
```

**done:** `the-check-in.json` decodes as a 12-card `Deck`, tone matches The Opener, zero em dashes, only
`prompt`/`reflect`/`whisper` types used.

### Segment 2 — Author Deck 3 (Boundaries, 16 cards)

**One thing:** draft the third free foundation deck, anchored on the boundary-is-yours framing The Opener
already teaches on card `opener-02`.

Boundaries is `category: "foundationEntry"`, free (`is_locked:false`, `required_entitlement:null`),
`intensity: 3`, `sort_order: 3`. The seed stub's single card (`"What's one line you'd want drawn before
anything new?"`) is a good opener, keep it as card 1. The core distinction to teach without preaching: **a
boundary is a limit you set for yourself, not a rule you set for the other person.** Use ONE
`interstitial` context beat (mirroring The Opener) to make that distinction, then let the cards do the
work. Draft 16 cards, intensity climbing 3 to 6, using `prompt`/`reflect` (one `whisper` closer). Full
draft (abridged here to the schema-critical fields; author all 16 fully):

```json
{
  "id": "boundaries",
  "title": "Boundaries",
  "subtitle": "The lines that keep this safe.",
  "category": "foundationEntry",
  "act": 1,
  "intensity": 3,
  "is_locked": false,
  "required_entitlement": null,
  "tags": ["foundation", "free"],
  "sort_order": 3,
  "schema_version": 1,
  "cards": [
    { "id": "boundaries-01", "deck_id": "boundaries", "text": "What's one line you'd want drawn before anything new?", "highlight_words": ["line"], "type": "prompt", "intensity": 3, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 1 },
    { "id": "boundaries-02", "deck_id": "boundaries", "text": "What does the word boundary actually mean to you?", "highlight_words": ["boundary"], "type": "prompt", "intensity": 3, "who_starts": "partnerB", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": "interstitial", "context_beat_copy": "Worth naming before you go on.\n\nA boundary is a limit you set for yourself, not a rule you set for someone else.\n\n\"I won't share a bed with someone new without telling you first\" is a boundary. It's yours. Your partner still gets to make their own choices, and now you both know where you actually stand.", "back_copy": null, "is_gendered_card": false, "gendered_for": null, "sort_order": 2 },
    { "id": "boundaries-03", "deck_id": "boundaries", "text": "Which of your boundaries are truly yours, and which ones are really requests you're making of me?", "highlight_words": ["truly yours"], "type": "reflect", "intensity": 4, "who_starts": "partnerA", "is_sensitive": false, "can_skip": false, "register": "flexible", "context_beat_type": null, "context_beat_copy": null, "back_copy": "Both are allowed. The point isn't to win the distinction, it's to know which is which so nobody feels controlled.", "is_gendered_card": false, "gendered_for": null, "sort_order": 3 }
    // ... author cards 04-16 in the same schema, intensity climbing to 6:
    // 04 who_starts partnerB: a boundary you're less sure about than you sound
    // 05 partnerA: a boundary of mine you've quietly found hard to hold
    // 06 partnerB: how you want me to tell you if a boundary of mine changes
    // 07 partnerA reflect: the boundary you'd be most hurt to see crossed
    // 08 partnerB: the difference between a boundary and a fear dressed as one
    // 09 partnerA banner beat "Boundaries can move. That's not weakness.": a boundary that has already shifted since we met
    // 10 partnerB: something you want that you've been afraid to name as a boundary
    // 11 both: a boundary we'd want to hold together, as a couple, not just individually
    // 12 partnerA reflect: what you need to feel safe saying no to me
    // 13 partnerB: how we'll handle it the first time we disagree on a line
    // 14 partnerA: the boundary you hope you never have to use
    // 15 both: one agreement we can make right now that we both actually believe
    // 16 both whisper is_sensitive false: one line I want you to know I will always hold for you
  ]
}
```

**done:** `boundaries.json` decodes as a 16-card `Deck`, the interstitial teaches boundary-as-yours in
Vayl's voice, zero em dashes, discovery-not-instruction throughout.

### Segment 3 — Draft the Core proof deck (Communication) + true up the catalog

**One thing:** draft one locked Core deck so the paywall has real content behind it, then make
`deck-catalog.json` honest.

Author `communication.json` to ~10 cards (`category: "relationshipCore"`, `is_locked: true`,
`required_entitlement: "core"`, `intensity: 2`, `sort_order: 4`). Keep the seed card 1 (`"When something's
wrong, how do you want me to ask?"`). Draft cards on: naming the moment talk breaks down, the repair
move each person needs, the thing that's hard to say, listening without fixing. Same schema, same
`prompt`/`reflect`/`whisper`-only rule, intensity 2 to 5.

Then **true up `deck-catalog.json`** so `card_count` reflects reality (verified current entries, set to
authored counts):

```jsonc
// set card_count to the REAL authored count for the four live decks:
{ "id": "the-opener",   ... "card_count": 10, "is_locked": false, ... },
{ "id": "the-check-in", ... "card_count": 12, "is_locked": false, ... },
{ "id": "boundaries",   ... "card_count": 16, "is_locked": false, ... },
{ "id": "communication",... "card_count": 10, "is_locked": true, "required_entitlement": "core" },
// every OTHER catalog entry is still a 1-card stub. Two honest options (pick per D-decks):
//   (a) leave them listed + locked, and set card_count to a realistic *target* (they show as "coming soon")
//   (b) trim the catalog to the 4 real decks for a tight V1 grid
// Recommended: (a) keep them, is_locked:true, so the grid looks alive but nothing free is empty.
```

> **Invariant:** never leave a **free** deck (`is_locked:false`) as a 1-card stub in the catalog — a free
> deck must be fully authored or removed, because a user can open it and hit a one-card deck. Locked decks
> may remain stubs (the paywall gates them). After this pass the only free decks are the-opener /
> the-check-in / boundaries, all authored.

**done:** `communication.json` has ~10 real cards; `deck-catalog.json` `card_count`s match the authored
decks; no free deck is a stub.

### Segment 4 — Lock the Desire Map content (do NOT reshape it)

**One thing:** finalize `desire_items.json` copy without touching identity, tracks, or weight order.

This file is **load-bearing and already shipped through D2** (`DesireMapStore`, `DesireRevealStore`,
`MapStore`, `VaultStore` all read it). Changing an item's `id`, its `tracks`, or the ORDER of its `answers`
array would desync stored ratings and force a recompute of every `desire_match`. So this segment is a
**copy-lock only**:

1. **Verify the split is unchanged:** curious = 18 items, established = 12 items (7 curious-only, 12 in
   both tracks). Do not add or remove items. Do not change any `id`.
2. **Weight direction stays cohort-independent:** in every `answers` array, index 0 = most-yes
   (`excitedAboutIt`), index 3 = the boundary (`notForMe`), for **both** tracks. The established copy must
   climb the same direction as the curious copy (index 0 = warmest, index 3 = firmest no). This is the
   contract that lets a mixed couple match on weight. Spot-check every established array against this.
3. **Fix any em dash** in `name` / `description` / answer strings (there are several, e.g. the `nre`
   description uses em-dash-style punctuation). Replace with commas/periods/colons.
4. **Tighten answer copy** for consistency of length and warmth, keeping each answer traceable to the item
   (discovery, not verdict). Example fix, `swinging` curious answers stay
   `["Yes, that excites me", "I'm curious to try it", "I'm nervous about it", "Not for me"]` (comma not
   em dash, warmest-to-firmest preserved).

> **Hard constraint (state it in the changeset):** because these items are already synced, this content is
> **frozen after this pass**. Any later change to a desire item's id/track/weight-order is a data migration,
> not a copy edit. Lock it here, before any further Desire hardening (roadmap D-follow-ups) touches it.

**done:** `desire_items.json` still has 19 items / 18-curious / 12-established, weight direction verified
identical across both tracks, zero em dashes, no id/track/order changes.

### Segment 5 — Assessment + legacy cleanup (per Open Decisions D1/D2)

**One thing:** resolve the placeholder-flagged `assessment_questions.json` and the dead legacy files.

The scan found placeholder/clinical markers in exactly three places, **all in dead files**:
- `assessment_questions.json:10` — Q1 `"context_note": "Placeholder — replace with validated content"`
- `cards.json` — six cards with `"context_note": "Placeholder — replace with clinical content"`
- (no others anywhere in `Resources/`)

Because `loadAssessmentQuestions()` and `loadCards()` have **zero call sites**, none of this reaches a user.
**Recommended (D2 = retire assessment):** delete `assessment_questions.json` and `categories.json` and the
legacy `cards.json` and the dead `deck-index.json`, leaving the unreferenced `ContentLoader` accessor
methods for the dead-code plan to remove. This eliminates every placeholder marker in the corpus in one
move and is safe (nothing decodes them).

If Bryan instead wants to KEEP an assessment for a future feature (D2 = keep), then de-placeholder Q1 in
Vayl's voice and clear the marker, e.g.:
```jsonc
{ "id": "Q1", "domain": "emotional_readiness",
  "text": "When something hard comes up between you two, how easily can you say it out loud?",
  "type": "scale", "options": null, "weight": 1.0, "sort_order": 1, "context_note": null }
```
and audit the other 19 for clinical phrasing. But note the whole file is dead until a feature consumes it,
so retiring is the lower-risk V1 move.

**done:** no content file under `Resources/` contains the strings "clinical", "Placeholder", or "placeholder"
(either the dead files are deleted, or Q1's marker is cleared and the file kept per D2).

### Segment 6 — Lock the Pulse copy (Swift strings, no logic)

**One thing:** finalize the five check-in questions + the four-tier capacity names, which are Swift data,
and reconcile the tier-name drift.

The pulse question set is `PulseAnswers.swift` (Q1-Q5, verified). The current copy is already warm and
on-voice; this segment **locks it** (marked "not final" in the roadmap → it feeds the T3 pulse schema, so
lock before that hardens). Edit ONLY the `text:` and `label:` strings; the `energy:`/`openness:` deltas and
the axis math are frozen. Recommended locked copy (minimal change from current, em-dash-safe):

- Q1 `nervousSystem.text`: "How is your nervous system right now?" (keep)
- Q2 `focus.text`: "Where is your focus naturally pulling you?" (keep)
- Q3 `feeling.text`: "What's the loudest feeling underneath?" (keep)
- Q4 `glowColor.text`: "How is your capacity to hold space today?" (drop "overall" for rhythm)
- Q5 `speed.text`: "What's the ideal speed for tonight?" (keep)

Then **reconcile the tier name drift** (verified): `PulseQuadrant.spaceName`
(`AppPulseEnums.swift:77-80`) = "The Expansive Space / The Sovereign Space / The Friction Space / The
Protective Space", while `TierGuideSheet.swift:32` labels its fourth tier "Contracted". Pick ONE fourth-tier
name and use it in both. **Recommended: use the code-canonical "Protective"** (already in `spaceName`,
`sublabel`, and `MapPulseHero`), and change `TierGuideSheet`'s row from
`("C", "Contracted", "Overwhelmed · Closed", ...)` to
`("P", "Protective", "Overwhelmed · Need Space", ...)` to match `PulseQuadrant.sublabel`. This is a copy
fix; the letter badge and color stay.

> **License note:** editing string literals in `PulseAnswers.swift`, `AppPulseEnums.swift`, and
> `TierGuideSheet.swift` is permitted here as *content*, because you change only user-facing copy, never
> the deltas, the quadrant math, the enum cases, or the tier thresholds. Do not touch anything but the
> quoted strings.

**done:** Q1-Q5 copy + tier `spaceName`/`sublabel` locked, zero em dashes, and the fourth tier reads the
same name in `TierGuideSheet` as in `PulseQuadrant`.

### Segment 7 — Expand the Learn seed content

**One thing:** grow the seven Learn JSONs from thin seed to launch seed, matching each file's existing
shape exactly.

The Learn tab is built and loads these via `LearnStore`; this is copy only. Match the exact field set of
each file (verified shapes):

- **`research_findings.json` (3 → ~8):** each finding needs
  `id, type, stat, headline, finding, bullets[], limitation, citation, author, year, topics[], connected[]`.
  The `limitation` field is doing real Product-Principle work: it keeps the tool honest (a finding, not a
  verdict). Add real, citable findings (attachment + CNM, jealousy-as-information, communication frequency,
  relationship satisfaction parity, disclosure practices). Keep `connected[]` ids pointing at real entries.
  **Do not invent citations** — draft with real papers Bryan can verify, or mark the citation clearly for
  him to confirm.
- **`lexicon_terms.json` (8 → ~16):** each is `id, kind ("term"|"sentence"), term, definition`, and
  `sentence` kind additionally has `example`. Add: hierarchy, non-hierarchy, primary/nesting partner,
  fluid bonding, don't-ask-don't-tell, solo poly, relationship anarchy, unicorn, triad, garden-party.
  One-sentence, plain, warm definitions (match the `compersion` entry's tone).
- **`learn_media.json` (4 → ~10):** each is
  `id, kind ("book"|"show"|"podcast"), title, creator, positioning, tier, platform, artwork_url, link`.
  Add real, well-known titles (Polywise, More Than Two, Opening Up, Making Polyamory Work, Normal Gossip's
  relevant episodes, etc.). Leave `artwork_url`/`link` null where you can't verify a real asset URL —
  never fabricate an image URL.
- **`voices.json` (3 → ~6):** `id, kind ("researcher"|"creator"), name, role, blurb, platform, link`. Add
  real, reputable CNM-affirming voices. `link` null unless verifiable.
- **`media_quotes.json` (3 → ~6):** `id, quote, author, kind ("adage")`. Add short, non-clinical adages.
- **`learn_quizzes.json` (2, metadata only):** leave as-is — these are quiz *entry cards*
  (`id, kind, title, subtitle, question_count`), and the quiz question banks are a separate feature not in
  this content pass. Do NOT author quiz questions here (out of scope; the quiz-taking UI isn't the target).
- **`support_resources.json` (6):** already complete and correct (crisis + ongoing tiers). Leave as-is.

**done:** the five growable Learn files roughly double in size, every entry matches its file's exact field
set, no fabricated URLs or citations, all decode via `LearnStore.load()`.

---

## Definition of Done (build-green)

The single pass is complete when the project **compiles green** and all of the following hold:

- [ ] **Launch deck set authored:** `the-opener` (10), `the-check-in` (12), `boundaries` (16) are fully
      authored free decks; `communication` (~10) is a drafted Core deck. Each decodes as a `Deck` via
      `ContentLoader.loadDeck(id:)`.
- [ ] **No free stub decks:** every `is_locked:false` entry in `deck-catalog.json` maps to a fully-authored
      deck file; no free deck is a 1-card stub.
- [ ] **Catalog is honest:** `card_count` in `deck-catalog.json` matches the real authored card count for
      the four live decks.
- [ ] **Only renderable card types used:** every authored card `type` is `prompt`, `reflect`, or `whisper`.
- [ ] **Desire content locked, not reshaped:** `desire_items.json` still has 19 items, 18-curious /
      12-established, identical ids/tracks/weight-order; copy em-dash-free; weight direction verified
      cohort-independent (index 0 warmest → index 3 boundary, both tracks).
- [ ] **Placeholders gone:** `grep -ri "clinical\|placeholder" Vayl/Resources/` returns nothing (dead
      files deleted per D1/D2, or Q1 marker cleared per D2-keep).
- [ ] **Pulse copy locked:** Q1-Q5 in `PulseAnswers.swift` and the tier `spaceName`/`sublabel` in
      `AppPulseEnums.swift` are final; the fourth tier reads the same name in `TierGuideSheet.swift` as in
      `PulseQuadrant`; no delta/threshold/enum-case changed.
- [ ] **Learn seed expanded:** `research_findings` (~8), `lexicon_terms` (~16), `learn_media` (~10),
      `voices` (~6), `media_quotes` (~6); each entry schema-exact; no fabricated URLs/citations; decodes via
      `LearnStore`.
- [ ] **No em dashes** in any string added or edited by this pass.
- [ ] **Zero code-logic changes:** only JSON files and user-facing string literals changed; no model,
      Store, Service, or view-logic edits.

---

## Bryan verifies on device

- [ ] Open **Play** → the grid shows the four live decks; the three free decks open and play end to end
      with the authored cards; the Core deck shows the paywall (T2 lock).
- [ ] Play **The Check-In** and **Boundaries** front to back — feel the intensity climb, confirm the
      boundary interstitial lands right, confirm no card feels clinical or preachy. 🎚️ (tone is Bryan's call)
- [ ] Confirm the drafted decks read like The Opener, not like a workbook — flag any card to rewrite.
- [ ] Open the **Desire Map** rater in both a curious and an established profile; confirm every item shows
      four warm answers in the right order and nothing desynced (existing ratings still resolve).
- [ ] Open a **Pulse check-in**; confirm Q1-Q5 copy reads well and the tier name after bloom matches the
      Tier Guide sheet (no "Contracted" vs "Protective" split).
- [ ] Open **Learn**; confirm the research directory, lexicon, media, and voices all populate from the
      expanded seed and read as curated, not padded.
- [ ] Decide the final launch deck count (D-decks) and whether stub Core decks stay listed or get trimmed.

---

## Constraints / do-not-touch

- **No schema changes.** `Card`, `Deck`, `DesireItem`, `PulseAnswers`, `PulseQuadrant`, and every Learn
  model struct are frozen. If content won't express in the current schema, cut the content, do not extend
  the schema.
- **No new card types.** Only `prompt`/`reflect`/`whisper`. The other 22 `CardType` cases have no V1
  render path; using one will render blank or crash the session.
- **`desire_items.json` is frozen on identity:** never change an `id`, a `tracks` array, or the ORDER of an
  `answers` array — that desyncs shipped data. Copy edits only.
- **Do not author quiz question banks** (`learn_quizzes.json` stays metadata-only) or companion-card pools
  (`companion_cards.json` is already good) — out of scope.
- **Do not delete `desire_items.json` or `companion_cards.json`** — their accessors have live callers.
- **Do not edit any Store/Service/View logic.** The only Swift touched is user-facing string literals in
  `PulseAnswers.swift`, `AppPulseEnums.swift`, and `TierGuideSheet.swift`.
- **`ContentLoader` uses `.convertFromSnakeCase`** — keep JSON keys snake_case exactly as in
  `the-opener.json`; a camelCase key or a wrong enum rawValue fails the whole file to decode at runtime.

---

## Open decisions (each with a recommended default — proceed on the default, flag it)

- **D-decks — how many decks ship for V1, and who authors the rest?**
  _Recommendation:_ ship **3 fully-authored free decks + 1 drafted Core deck** (this plan), keep the other
  10 catalog entries **listed but locked** as "coming soon." Author the remaining Core/NM decks
  **AI-draft-then-Bryan-edit** post-launch, one deck per pass, so voice stays consistent and Bryan is the
  final editor on every card. Do not block launch on a full 14-deck library — that would over-scope Vayl
  as a content app. _(Proceed on: 3 free + 1 Core drafted; rest locked.)_

- **D1 — delete the dead legacy content files (`cards.json`, `categories.json`, `deck-index.json`)?**
  _Recommendation:_ **yes, delete them.** They have zero consumers, hold the "clinical" placeholder
  markers, and are superseded by the Deck/Card system + `DeckCategory`. Leave the unreferenced
  `ContentLoader` accessor methods for the dead-code plan. _(Proceed on: delete the three files.)_

- **D2 — retire or keep the assessment?** `assessment_questions.json` (20 Qs) has no consumer.
  _Recommendation:_ **retire for V1** (delete the file) — an ENM "readiness assessment" that concludes a
  trait risks the assessment-not-discovery bright line in `CLAUDE.md`, and nothing renders it. If a future
  feature wants it, re-author it then as a discovery tool (rank/compare, never verdict). _(Proceed on:
  retire; if Bryan says keep, de-placeholder Q1 per Segment 5 and clear the marker.)_

- **D3 — is the Pulse copy final enough to lock?** The roadmap flags it "not final," and it feeds the T3
  pulse schema. _Recommendation:_ **lock the current wording** with the two tiny edits in Segment 6 (Q4
  trim + tier-name reconcile). It is already warm and on-voice; locking it now unblocks T3 hardening. Bryan
  can still tune single words on device. _(Proceed on: lock with Segment 6 edits.)_

- **D4 — ship content in-bundle or seed to Supabase?**
  _Recommendation:_ **in-bundle for V1.** It is the current model, works offline, and is simplest. The
  Learn corpus already has the async-refresh seam (`ContentService.fetch*` → Supabase tables
  `research_findings` / `glossary_terms` / `media_quotes`), so Learn copy CAN change server-side without an
  app update later if churn demands it. Decks and desire items stay in-bundle (structural, not editorial
  churn). _(Proceed on: in-bundle, Learn seam left warm.)_

- **D-fourth-tier-name — "Protective" vs "Contracted" vs "Friction" for the low-capacity zone.** There are
  currently three names in play: `PulseQuadrant` uses **Friction** (high-energy/closed) AND **Protective**
  (low-energy/closed) as two distinct quadrants, while `TierGuideSheet` collapses to a single **Contracted**
  fourth tier. _Recommendation:_ **keep the code-canonical four-quadrant names** (Expansive / Sovereign /
  Friction / Protective) everywhere and delete "Contracted" from `TierGuideSheet`, since the four-quadrant
  model is what the rest of the app renders. _(Proceed on: canonical quadrant names; fix TierGuideSheet.)_

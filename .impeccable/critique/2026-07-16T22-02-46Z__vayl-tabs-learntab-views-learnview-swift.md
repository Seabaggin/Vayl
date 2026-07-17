---
target: the Learn tab
total_score: 23
p0_count: 1
p1_count: 2
timestamp: 2026-07-16T22-02-46Z
slug: vayl-tabs-learntab-views-learnview-swift
---
Method: dual-agent (A: design review · B: deterministic evidence), isolated and parallel.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | `LearnStore.refresh()` fetches from Supabase with no loading state and silent failure; carousel dots are `.accessibilityHidden(true)`, so position is announced to nobody. |
| 2 | Match System / Real World | 3 | Two sections both named "hub"; otherwise plain language and real citations. |
| 3 | User Control and Freedom | 1 | `LearnView:48` does `showDatabase = false` when opening a finding — the database closes, and dismissing the detail dumps you on the front page with filters and scroll gone. "Connected research" swaps sheet content in place with no back. |
| 4 | Consistency and Standards | 2 | `.vaylCover` used to browse a reference (grammar reserves cover for protected/immersive); `ResearchSection.emptyState` hand-rolls what `VaylEmptyState` does 80 lines away; the same stat uses `spectrumPurple` in one place and `spectrumTextSafe` in two others. |
| 5 | Error Prevention | 3 | `link(_:)` guarding and the interlocking kind/topic filters are genuinely well-built. No guard on the connected-research dead end. |
| 6 | Recognition Rather Than Recall | 2 | Filters must be rebuilt from memory after every finding open; the carousel gives no count. |
| 7 | Flexibility and Efficiency | 2 | No search on a reference corpus; swipe-only carousel; the only route to a specific term is the cover plus a filter. |
| 8 | Aesthetic and Minimalist Design | 2 | A segmented control nested inside a segmented control over 8 items; two shimmering capsules above the fold; two identically-styled "hub" headers competing for the same rank. |
| 9 | Error Recovery | 3 | `loadErrorNotice` copy is honest and good. A failed server refresh is silent; an empty panel is blank space. |
| 10 | Help and Documentation | 3 | The Resources sheet is the best writing in the tab, and mandatory `limitation` on every finding is a principle made structural. Its door looks like a browse control. |
| **Total** | | **23/40** | **Acceptable — significant improvements needed** |

## Anti-Patterns Verdict

**Does this look AI-generated? At the component level, no. At the structural level, yes — and that's the worse of the two.**

**LLM assessment.** Every file carries a real decision with a stated reason: killing the 12s auto-advance as decorative motion, refusing to draw a chevron that promises nothing, collapsing two section accents into one surface. Those are anti-slop moves most generated tabs never make.

The slop is the **shape**, not the pixels. The real corpus is **21 entries**: 3 findings, 8 terms, 2 books, 1 show, 1 podcast, 3 voices, 3 quotes. Against that, Learn ships a masthead + shimmer pill, a second shimmer pill, a paging carousel with clone-and-reset seam logic and animated dots, a 4-way segmented control, a *nested* 2-way segmented control, a full-screen cover database with two chip rows, and a detail sheet with a connected-research graph. `ContentHubSection` builds a 4-segment control to gate **4 media items**. The Voices panel adds a second segmented control to split **3 people into 1 and 2**.

That is the category reflex exactly: Learn was built as *"a content tab"* (the shape of Spotify Browse or a wellness Discover) rather than *"a reference you consult."* A 21-entry reference wants a flat list and a search field. It has no merchandising to do, so the merchandising chrome is costume.

**DESIGN.md's own cliché test is the one Learn fails.** It explicitly rejects "dark mode with purple gradient + neon + glass everywhere" and says "glass is one canonical surface, not decoration sprinkled everywhere." `learnCard()` now makes glass **the default surface of the whole tab**, purple the default accent of every chip/label/stroke/stat, with shimmer on two navigation capsules and the spectrum gradient spent on a 17pt glyph and 6pt dots. Learn is closer to the rejected cliché than any tab in the app — reached not by reflex but by a defensible local decision at each step ("unify the accent" → all purple; "unify the card" → all glass). Both of those were my calls this session.

**Deterministic scan.** The bundled detector was run and returned `[]` / exit 0: it parses HTML/CSS and matched zero files against a Swift target. **Deterministic HTML/CSS scan unavailable (native Swift target)** — substituted the native rule engine (CLAUDE.md's contracts) via grep, plus a compile-only build.

Build: **SUCCEEDED**, 0 errors, 0 warnings in Learn files (the one warning is `SupportLinks.swift:41`, unrelated).

**Fully clean (9/15 categories):** raw colors · raw fonts · raw animation values and token arithmetic · ambient-motion rules (no loops at all) · iOS 26 bans · presentation-grammar primitives (no raw `.sheet`/`.fullScreenCover`) · hardware padding · tap contract (0 empty actions — the earlier dead-affordance fix holds) · dark-only V1.

**Violations found:**

| Rule | Count | Location |
|---|---|---|
| Missing empty state | 5 | `ContentHubSection:88,159,159,212` (books/watch/listen/voices), `ResourcesOverlayView:41` |
| Touch target < 44pt | 2 | `LearnView:98-112` "Resources" pill, `ResearchSection:37-51` "Browse" pill — both ≈33pt |
| Hand-rolled card chrome | 2 | `FindingDetailView:79`, `ResourcesOverlayView:56-61` |
| Raw SF Symbol | 1 | `FindingDetailView:35` `systemImage: "circle.fill"` — while `AppIcons.circleFill` exists and the same file uses it correctly at :88 |
| Spacing literal | 2 | `FindingDetailView:71`, `ResourcesOverlayView:47` — `VStack(spacing: 1)` |
| Dead store members | 4 | `mediaQuotes`, `featuredFinding`, `carouselFindings`, `findingCount` — zero readers app-wide |
| Dangling data ref | 1 | `rubel.connected` names `"johnson"`, which doesn't exist; silently dropped |
| Filter inconsistency | 1 | `reference(_:)` doesn't filter by `kind`, so 3 `.sentence` entries render as terms and are counted as "terms" |
| Stale comment | 1 | `LearnView:38` credits `TabContentWrapper` for clearance; `AppShell`'s `.safeAreaInset` owns it |

**Where the detector-substitute caught what the design review missed:** the raw `systemImage:` (my earlier polish grepped `systemName:` only and missed it), both sub-44pt pills, hand-rolled chrome in two files, and four dead store members including `mediaQuotes` — which fires a live Supabase fetch on every init and discards the result.

**Visual overlays:** not applicable. Native iOS target; no DOM, no localhost URL, no injection path. No overlay is available and none is claimed.

**No visual verification of the rendered tab was performed** — per project protocol, simulator UI driving is Bryan's call, not automation's.

## Overall Impression

The mechanical layer is genuinely disciplined — the token, animation, iOS 26, presentation-primitive, safe-area, and dark-only contracts are **100% clean**, which is rare and worth stating plainly. The craft shows at the component and copy layer.

The problem is one tier up, and it's the same problem twice: **the tab's chrome is sized for a library it doesn't have, and its most important interaction is dead on real data.** Both assessments landed on this independently. The single biggest opportunity is not a visual fix — it's deleting navigation machinery until what's left matches 21 entries, and populating 7 URLs.

## What's Working

**1. The `link(_:)` guard and its affordance removal.** Rows without links render as plain content — no tap target, no arrow — and the arrow that does appear is `arrowUpRight`, not a chevron, because these leave the app. Refusing to draw an affordance that lies, and distinguishing "leaves" from "descends," is the discipline that separates a designed product from a generated one.

**2. `limitation` as a mandatory corpus column.** Every finding carries one; `FindingDetailView` renders it under "One honest limitation." The product's bright line ("name what the user said, never infer what they didn't") is enforced at the **schema**, not at the copy layer where it could drift. It is structurally impossible to ship a finding that overclaims. This is the best idea in the tab.

**3. The Resources sheet copy.** "Not to keep you from the deep end, but to throw you a line if you ever need one." It earns trust because it offers rather than prescribes, and the gold-is-sacred rule is honored inside it.

## Priority Issues

### [P0] The Content Hub is a 4-segment browse UI over 8 items, none of which are reachable
**What:** `link` is null in **100%** of records — `learn_media.json` 0/4, `voices.json` 0/3. Combined with the (correct) `link()` guard, the entire hub renders as a read-only shelf with **zero tap targets**. Two levels of segmented control, four panels, an AsyncImage cover shelf, and a Creators/Researchers filter, all navigating between panels of 1–3 non-interactive rows. Every `accessibilityHint("Opens in Safari")` sits on a branch that is dead on real data.

**Why it matters:** This is the tab's end state, so it owns the peak-end score. The section's stated purpose — "where to go deeper" — is unfulfillable in every path. It's also the clearest AI tell in the app: elaborate chrome wrapped around content that isn't there. A user works through four segments to find *Polysecure* and gets a cover, a positioning line, and no door.

**Fix:** (1) Populate `link` on all 7 records — public URLs, a content task, and the views already work. (2) Then cut the chrome to fit: with 4 media and 3 voices, delete the 4-way `HubTab` control and the nested `voiceFilter`, and render one titled list (Read 2 / Watch 1 / Listen 1 / Voices 3) in a single card. Reinstate a segmented control only when one group exceeds ~6 items. (3) If links can't ship, cut the hub from V1 — a section that cannot do its job isn't humble, it's decoration.

**Suggested command:** `/impeccable distill`

### [P1] Opening a finding destroys the database you opened it from
**What:** `LearnView:48` dismisses the cover (`showDatabase = false`) and opens a sheet. Dismissing that sheet returns you to the **Learn front page** — filters cleared, scroll gone, browsing session erased. Compounding it, `FindingDetailView`'s "Connected research" rows swap the sheet's content in place with no back affordance; with all 3 findings mutually connected, you can hop haupert → conley → rubel → haupert and only escape by dismissing.

**Why it matters:** The only mental model this screen supports is "I'm browsing a reference, I'll open this, then keep browsing," and the implementation contradicts it. Every finding costs the user their place.

**Fix:** Keep the detail inside the database's context — `NavigationStack` + push. "Connected research" becomes a real push with a real back, and browse state survives because it was never torn down. Delete the `showDatabase = false` line.

**Suggested command:** `/impeccable harden`

### [P1] `.vaylCover` is the wrong grammar for browsing a reference
**What:** `ResearchDatabaseView` is presented via `.vaylCover(confirmOnExit: false)` and hand-rolls a `‹ Learn` back button because a cover gives it no nav chrome.

**Why it matters:** The contract is explicit — `.vaylCover` means "entering a protected, immersive mode" (Card Session, raters, OB). A research library is the *least* protected surface in the app. CLAUDE.md's own mental-state table routes "drilling a real hierarchy — Learn → research → finding" (named verbatim) to **push**. A hand-rolled back chevron impersonating a nav bar is the tell that presentation is fighting content; `confirmOnExit: false` is the same signal — a cover whose guard is off isn't a cover.

**Fix:** `NavigationStack` + `.navigationDestination` into database, then finding. Deletes `backButton` and `vaylDismiss`, gets swipe-back free, and resolves the P1 above as a side effect.

**Suggested command:** `/impeccable harden`

### [P2] Five surfaces have no empty state, and two are one bad fetch from blank
**What:** `ContentHubSection`'s books/watch/listen/voices panels and `ResourcesOverlayView`'s tier lists are bare `ForEach`. Today Watch and Listen have exactly **1 item each**, and Voices defaults to `.creator`, which has exactly **1** record. A server refresh returning a corpus without shows renders **blank space inside the glass card** — no icon, no headline, no explanation. The contract requires an empty state on every data screen; `ResearchSection` and `ResearchDatabaseView` comply, the hub doesn't.

**Why it matters:** `LearnStore.refresh()` overrides content from Supabase on every init, so this isn't hypothetical — it's one deploy away.

**Fix:** `VaylEmptyState` on each panel. Also replace `ResearchSection.emptyState`'s hand-rolled icon+headline+sub-label with `VaylEmptyState`, which `ResearchDatabaseView` uses correctly in the same tab.

**Suggested command:** `/impeccable harden`

### [P2] The `.sentence` lexicon kind is silently collapsed into `.term`
**What:** `LexiconTerm` documents two kinds: `.term` (word leads) and `.sentence` (a usage quote leads, then the term + meaning). `ReferenceItem.term` discards the kind; `termRow` renders word-first unconditionally and chips all 8 entries "TERM". The 3 `.sentence` entries — whose `example` strings are the whole point ("Our polycule has a group chat now.") — render as ordinary definitions with a quote tacked on. `reference(_:)` also doesn't filter by kind, so `countLabel` miscounts them as terms.

**Why it matters:** This is the tab's most product-aligned idea, unbuilt. A usage sentence teaches vocabulary the way vocabulary is actually learned — hearing it used — which is precisely "maps, vocabulary, and mirrors," and precisely not a glossary. A cautious user learning to say "metamour" out loud needs the sentence, not the definition. 3 of 8 entries are silently downgraded.

**Suggested command:** `/impeccable craft`

### [P3] Contrast and spectrum-budget slips
**What:** `ResearchSection.chip` renders `AppFonts.label` (**11pt**) in `spectrumPurple` (`#6C3AE0`) on a 10%-purple capsule over glass — roughly 3:1, failing AA for text that small. `findingCard` uses raw `spectrumPurple` for the stat while `ResearchDatabaseView` and `FindingDetailView` both correctly use `spectrumTextSafe` **with a comment explaining why** — same stat, three places, two right. And the gradient is spent on 6pt carousel dots and a ~17pt lifepreserver glyph, below the Earned Spectrum Rule's stroke/display/≥24pt bar.

**Fix:** `spectrumTextSafe` for the stat; `textSecondary` for chip labels (keep purple on the capsule fill); single-accent cyan for dots and glyph.

**Suggested command:** `/impeccable audit`

## Persona Red Flags

**Sam (accessibility)** — `InfiniteCarousel(height: 212)` is a **fixed literal** while the cards inside use `.fixedSize(vertical: true)` on findings up to 134 chars; `AppFonts` scales via `relativeTo:`, so at Accessibility XL the content grows and the frame doesn't — text clips. The component's own header concedes "a fixed height is required." Carousel dots are `.accessibilityHidden(true)` with nothing replacing them: a VoiceOver user swiping gets no "3 of 5," no position, no extent. The 11pt purple chips fail AA. Credit where due: 44pt and `.isSelected` traits are respected in the database and hub rows.

**Riley (stress tester)** — first tap is a no-op (all links null). No empty state on any hub panel. `voiceRow`'s `Text(v.name).lineLimit(1)` truncates "Dr. Heath Schechinger" on a 375pt device before Dynamic Type is raised. `AsyncImage` in `bookCover` has **no failure branch** — a 404 leaves a bare grey slab on a shelf whose entire visual payload is covers. `refresh()` reshuffles the carousel under your thumb mid-swipe with no loading state.

**Jordan (first-timer)** — lands on two things called "hub," identical rank, identical style; nothing says which is the tab's answer to "what is Learn for." Can't tell what's tappable: a finding card is a `Button`, a term card deliberately isn't, and they are the **same glass surface, same hairline, same padding, same chip**. Two of five preview cards are duds with no visual warning. The carousel hides 60% of the preview with no count and no peek — Jordan sees one finding and concludes Learn has one.

**"The 1am reader"** (project-specific: the curious-cautious partner, alone, after a conversation that went sideways) — the masthead greets them with **"Build your frame before you need it."** They arrived *because* they needed it; the one imperative in the tab forecasts a crisis to someone already in one. The Resources door — the one control that might matter at 1am — is styled **identically** to the "Browse" pill one section below: same shimmer capsule, same hairline, same size, same rank, differing only by a gradient glyph. Gold-is-sacred is honored inside the sheet and abandoned at its door. And their session ends at a shelf they can't touch.

## Minor Observations

- `FindingDetailView`'s header still says **"STUB layout."** It's the tab's emotional peak, at `heightFraction: 0.85`, with no `VaylCloseButton`.
- `ContentHubSection.HubTab.accent` returns the same purple for all four cases and the type also holds a `private let accent` with the same value — a vestige of the killed per-tab sweep; the enum property can go.
- Two `HolographicShimmer` capsules render simultaneously above the fold. DESIGN.md scopes shimmer to `SelectablePill`; here it's on navigation chrome, in the tab whose job is reading. "Calm at rest" — two pills shimmering atop a research page aren't.
- `InfiniteCarousel.jump(to:)` hard-codes `Task.sleep(for: .seconds(0.45))` to outrun the paging animation — a raw duration racing an uncontrolled system animation.
- `mediaQuotes` fires a live Supabase fetch every init and is read by nobody.
- `voices.json` lists Jessica Fern as a researcher; she also wrote *Polysecure* on the Books shelf. Correctly not cross-linked (per "don't reach to connect features"), but it means the Creators segment contains exactly one human.
- `ResearchSection.swift` is named for a section that now owns the glossary too.

## Questions to Consider

1. **What is Learn's one job?** It has two co-equal ones, both called "hub." If a user opens Learn once and closes it forever, what should they leave with — a word they can now say out loud, or a book they're going to read? Answer that and one section becomes the tab and the other becomes a row in it.
2. **Would you have built a carousel, a 4-way segmented control, and a nested 2-way filter if the corpus had been handed to you as a printed page of 21 entries?** Or did the shape arrive before the content did? What would have to become true — 50 findings? 30 books? — before this chrome earns its rent?
3. **The Content Hub's job is to send people out of Vayl, and every link is null.** Unfinished data task, or the product quietly admitting it doesn't want to hand off? "The best thing on this topic isn't in this app, here it is" is the humility principle at its strongest, and it's the one thing the tab currently can't do.
4. **Glass is now Learn's default surface and purple its default accent — the exact thing DESIGN.md rejects.** The unification was the right move, but did it unify Learn with the house, or into the cliché the house was written to avoid? What's the opaque reading surface that would make the glass mean something again?
5. **A term card looks exactly like a finding card and does nothing when tapped.** "No tap target without a destination" is right, but it was enforced in the tap layer and not the visual one. If a term has no depth, should it be a card at all — or a line of text, the way a glossary actually reads?
6. **The subtitle tells the user to build a frame before they need it; the Resources sheet says there's a lifeguard if they ever do.** Both describe the same future moment. One prescribes, one offers. Which one is Vayl?

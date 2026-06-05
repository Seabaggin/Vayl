# Refined Onboarding — Strategic Design

---

## How This OB Serves Users With the Data They Give Us

Vayl is a relationship optimization platform. The card game is the first delivery mechanism — but not the last. Every tool that follows (journaling, check-ins, communication frameworks, guided reflection, partner alignment tools) needs to know who this person is and what they're working on. The OB is where that foundation gets laid.

The user gives us something genuinely vulnerable: their relationship, their desires, their struggles, the gap between where they are and where they want to be. In exchange, they should feel the product understand them — immediately, and better over time.

The OB earns that exchange by doing three things:

**1. Building a stable user profile that every tool can reference.**
Mode, gender, age, tenure, experience level — these don't change session to session. Collected once, used forever. Every new tool Vayl ships starts from this baseline instead of starting cold.

**2. Establishing a "where they started" snapshot.**
The OB captures the user's baseline. That baseline becomes the "before" in a before/after arc that makes progress feel real. A user who opened the app because "something keeps coming up and getting stuck" and later plays a session where that thing resolves — that arc is only visible if we know where they started. The OB is the timestamp on the beginning.

**3. Routing users to the right experience at the right depth.**
Experience level, mode, tenure, and situation signals tell the deck who to be for this person on their first session. Not a generic couples deck. Not a safe beginner deck for someone who's been at this for years. The profile makes the first experience feel specific — which is what earns continued trust.

### How This Scales as the Platform Grows

The OB profile is a routing layer, not just a personalization input for one feature.

| OB Signal | Card Game | Future: Check-in Tool | Future: Communication Framework | Future: Partner Alignment |
|---|---|---|---|---|
| Mode (solo/together) | Card phrasing, session structure | Solo vs. shared prompts | Individual vs. couple exercises | Requires together mode |
| Experience level | Difficulty curve, depth | Calibrates emotional depth of questions | Complexity of framework offered | Baseline for alignment gap |
| Relationship tenure | Topic relevance, card assumptions | "How has this shifted lately?" | Early-relationship vs. established patterns | How long they've navigated this together |
| Age | Life stage content relevance | Age-appropriate framing | Career/parenting/health as context | Generational communication patterns |
| Situation signals (session-start) | Deck content selection | Real-time check-in calibration | Which framework surfaces this session | Where the gap is right now |
| Intent signals (session-start) | Tone, session opening | What the check-in optimizes for | What skill to build | What to align on |

The richer the profile, the more useful every tool is from the first interaction. A user who completes OB once gets a personalized experience across everything Vayl ever ships. That's the long-term value of doing this right now.

---

## What Changed and Why

### The Core Problem With the Old Back Half

The old OB (ContextPhase → CompassPhase → CuriosityPhase) was trying to collect two fundamentally different kinds of data in the same flow using the same ceremony:

- **Stable profile data** — who they are, their baseline. Doesn't change.
- **Dynamic needs data** — what's live for them right now. Changes every session.

Collecting dynamic data once in OB means the deck is personalized to a moment in their relationship that's already months old by their fifth session. It goes stale. And the ceremony designed around that data collection felt like a survey — meaningful disclosures dressed up with card animations.

### The Structural Fix

**OB collects stable profile only.**
Everything the product needs to know about who they are. Set once, used everywhere, never goes stale.

**Session-start collects dynamic needs.**
Before every session, the dealer asks where they're starting from tonight. Fresh signal every time. The deck for Session 10 reflects where they actually are at Session 10, not where they were when they downloaded the app.

This also means OB stays short. Ceremony is reserved for genuine identity disclosures — moments that earn it — not preference surveys.

---

## Refined OB Sequence

### Phase 0 — Stat
**Job:** Establish stakes. Why this exists.
"1 in 5 couples say they never talk about what they actually want."
The opener isn't about Vayl. It's about the problem. Stakes first, product second.

### Phase 1 — Demo *(new)*
**Job:** Show the product before asking for anything.

One real session card dealt to the table with more ceremony than anything else in OB. Face-down. Rises slowly from center. The dealer goes quiet.

*"Before we do anything else — this is what you're here for."*

User taps to flip. The card reveals a real question — the kind that lands in the body, not the head. 4 seconds of held silence. The silence is intentional — it's the product. Then a hold interaction: press the card, it warms, haptic, releases. Nothing recorded. Just the physical acknowledgment of being present with something real.

*"That's the only kind of question we ask here."*

Card pockets to the corner deck. First time they've seen the corner deck. The dealer pivots.

*"Now let's build one that's yours."*

**Why it earns its place:** Duolingo doesn't explain language learning — they make you do a lesson. Headspace doesn't describe meditation — Andy makes you meditate. This makes you feel one card land before you've told the app anything about yourself. Every disclosure that follows now has a referent. The ceremony after this point earns trust because the product already proved itself.

**The demo card:** Needs to be written carefully. Must be universally resonant before any mode or gender data is known. Safe enough for a stranger, not so safe it's toothless. Current candidate: *"What would it feel like to stop keeping score?"*

### Phase 2 — Name
**Job:** Who are you. First personal disclosure.
Typewriter mechanic (existing). Dealer types first, then the user types their name. Intimate, deliberate, earned by the demo that preceded it.

### Phase 3 — Mode Select
**Job:** Solo or Together. Sets the structural context for everything.
Two cards (existing). The choice changes card phrasing, session structure, and which tools are available to them.

### Phase 4 — Gender
**Job:** Identity and pronouns. Personalizes all copy across every tool.
Slot machine mechanic (existing). Solo: one card dealt center. Together: two cards, one per partner — same pass mechanic as the existing spin 1 / spin 2.

**Age folds here:** After the gender card settles, a second lightweight input appears on the same card or immediately after — age bracket selection. Not a separate phase. 4 options (Under 25 / 25–35 / 35–45 / 45+). One tap. Cards don't deal for this — it's part of the gender card's resolution, not its own ceremony.

### Phase 5 — Tenure *(new, lightweight)*
**Job:** How long together. Strongest single routing signal for deck content.
One card dealt to the table after gender. Face-up immediately — no flip ceremony, this isn't an identity disclosure. Four options on the card face, user taps one:

- *We're still in the early stage*
- *Finding our shape (1–3 years)*
- *Long-term, something's shifted*
- *Starting over*

Solo users: card reads "In your relationship history" — the tenure of their most significant relationship, not current status. Still useful for content routing.

### Phase 6 — Experience Level
**Job:** How familiar are they with this kind of content and conversation.
Candle mechanic (existing). Drives card difficulty curve and deck depth on first session.

### Phase 7 — Build Deck
**Job:** Ceremony payoff. The earned cards from each phase materialize into a deck.
The cards collected throughout OB — one per phase — assemble. The foil appears. The deck is real. This is the emotional payoff of every disclosure they made.

### Phase 8 — Founder Letter
**Job:** Humanization and trust for vulnerable content.
Before they play their first session, they know who built this and why. This is load-bearing for an app that asks people to be vulnerable — they need to trust the human behind it, not just the product.

---

## Session-Start Model (Dynamic Layer)

Replaces all dynamic data collection that was in the old OB back half.

Runs before every session — not once. The dealer asks where they're starting from tonight. Two quick moments:

**Situation (3 cards max, swipe right if true right now)**
Active states in present tense. Examples:
- "We've stopped talking about it"
- "I'm carrying something I haven't said yet"
- "We want the same things but don't know how to start"
- "Something keeps coming up and getting stuck"
- "We're doing well and want to go deeper"
- "We're exploring what kind of relationship we want"
- "One of us is more ready than the other"
- "Still in the early stage of figuring each other out"

**Intent (1 card, tap to select)**
What they want tonight to do.
- *Talk about something we've been avoiding*
- *Get closer without it being heavy*
- *Understand something about myself*
- *Figure out something we've been circling*
- *Just see where it goes*

Together mode: both partners swipe Situation independently if they want — union of right-swipes routes content; divergence surfaces as interesting territory for the deck.

**Why this is better than OB collection:**
The deck for Session 5 reflects where they actually are at Session 5. The deck for Session 12 knows how the relationship has evolved. Dynamic data collected dynamically produces adaptive personalization. Dynamic data collected once in OB produces a snapshot that goes stale.

---

## What Was Cut and Why

**ContextPhase (carousel)** — relationship archetype selection was the weakest signal in OB. It asked users to self-diagnose at an abstraction level most aren't equipped for. The useful signal (situational register) is now inferred from session-start Situation swipes, which are more honest and more current.

**CompassPhase** — three abstract calibration questions (agency, motivation, emotional register) asked cold before the user has experienced anything. Theoretical signal at best. Emotional register is now inferred from session-start patterns over time. Agency and motivation reveal themselves through engagement behavior — asking cold doesn't produce reliable data.

**Old CuriosityPhase (picker)** — two-section pill grid. The mechanic worked but the frame was wrong. "What are you curious about?" captures interest, not urgency. Session-start Situation swipes capture what's actually live — which is what routes content, not abstract curiosity. The picker content lives on in the session-start card set, reframed as present-tense active states.

---

## Data Map — What Each Field Does

| Field | Source | Used For |
|---|---|---|
| `displayName` | NamePhase | Copy personalization everywhere |
| `appMode` | ModeSelectPhase | Card phrasing, tool availability, session structure |
| `genderA` / `genderB` | GenderPhase | Pronoun-aware copy across all tools |
| `ageRange` | GenderPhase (inline) | Life stage content routing, topic relevance |
| `relationshipTenure` | TenurePhase | Deck assumptions, topic depth, tool calibration |
| `nmStage` | ExperienceLevelPhase | Difficulty curve, first session depth |
| `situationSignals[]` | Session-start | Deck content selection, topic routing |
| `intentSignal` | Session-start | Session tone, opening card, depth calibration |

The first six fields are stable — collected once, used forever, transfer to every future tool. The last two are dynamic — refreshed every session, always current.

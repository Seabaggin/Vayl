# Open Lightly — Project Scope
**Last Updated:** March 20, 2026 (three-act strategy restructure)
**Developer:** Bryan Jorden
**Platform:** iOS 26 (SwiftUI, SwiftData, Supabase)

---

## 1. What Is Open Lightly

Open Lightly is a privacy-first iOS app built for couples navigating the gap between "we're curious about non-monogamy" and "we've had the conversations and know where we stand." At launch, it is a focused tool for one thing done extremely well: helping new NM couples have the conversations they've been putting off.

**Launch identity — Act 1:**
> *"The tool couples have been looking for since the first conversation they couldn't finish."*

The core product: guided conversation card decks and a mutual Desire Map reveal. Both partners complete the Desire Map independently; one matched item surfaces free; the full compatibility picture is behind the paywall. That moment — *your first glimpse of what you actually have in common* — is the conversion event.

**Core premise:** Conversations that would be awkward to start become natural when framed as a game.

**What this app is NOT:** See Section 4 — Moral Red Line.

### The Three-Act Reveal

This is not a pivot sequence. It is a reveal sequence. The product expands in a way that feels inevitable to users rather than scattered.

| Act | When | Who | Tagline |
|-----|------|-----|---------|
| **Act 1** | Launch | New NM couples | *"The tool couples have been looking for since the first conversation they couldn't finish."* |
| **Act 2** | V1.1 | Experienced ENM practitioners | *"For people doing non-monogamy intentionally."* |
| **Act 3** | V1.2+ | Solo explorers | *"For people who take relationships seriously. All kinds of relationships."* |

The Act 3 tagline is the destination. Every architecture decision now should allow the product to arrive there without a rewrite. The architecture supports all three user types from day one — what changes at each act is the marketing focus, not the codebase.

### How It Works

```
PAIR    → QR scan (in person), verbal code (same room), or share link (remote)
ASSESS  → Each partner privately answers 20 questions
REVEAL  → Sit together, see combined Readiness Score
EXPLORE → Work through guided conversation cards by category
MAP     → Privately rate 40+ intimacy items — one match revealed free, full reveal behind paywall
DECIDE  → Informed decision based on mutual understanding
```

Over time, logged check-ins, reflections, and emotional data compound into a personal relationship intelligence layer — the app gets more valuable the longer someone uses it.

---

## 2. Target Users — Three Acts, One Architecture

Open Lightly serves all four relationship populations from day one. The architecture supports everyone; the marketing reveal is sequential. Each act has a primary user, a pain point, and a clear build priority.

### Act 1 — Primary User at Launch: The New NM Couple

**Who:** Two people in a committed relationship, curious about ENM, haven't fully navigated the conversation yet. Usually one partner initiated. Ages 25–40.

**Primary pain:** "We tried to talk about it and it went sideways. We don't know how to start without it feeling like an accusation."

**What they need:** Structure that makes hard conversations feel like a game, not a fight. A mutual reveal that gives both partners a safe way to say what they want without having to say it directly first.

**Build priority:** Build for them first. Market to them exclusively at launch. Every Act 1 decision is a front-door decision.

### Act 2 — Secondary User (Present at Launch, Not Marketed): The Experienced ENM Practitioner

**Who:** Couples actively practicing ENM — swinging, polyamory, relationship anarchy, any flavor. They know the landscape. They're downloading because a friend recommended it or they saw a review.

**Primary pain:** "We've been doing this for years with no operational infrastructure. We've built our own systems from scratch, most of which are informal and inconsistent."

**What they discover:** Daily pulse, jealousy mapping, agreements vault, connection cards. The "aha" is: *this isn't just for people figuring it out — it's for people living it.*

**Build priority:** Tools present in architecture and discoverable. Not marketed until V1.1 Act 2 expansion.

### Act 3 — Secondary User (Routing Exists, Not Marketed): The Solo Explorer

**Who:** Singles, solo poly people, people navigating ENM without a primary partner. They belong here — they've always belonged here. The product now explicitly invites them.

**Primary pain:** "Every ENM resource assumes I have a partner to do this work with. I'm doing it alone."

**What they discover:** The app was never about having a partner. It was always about doing the work of non-monogamy intentionally. Solo users were always going to belong here.

**Build priority:** Solo path fully routed in architecture. Not marketed at launch. Front-door marketing shift happens at V1.2.

### Persona Tags (internal, never shown to user)

Each person must feel like the app was built for them specifically. The persona filter (set at onboarding via `nmStage`) routes them to a personalized roadmap, tailored prompt voice, and curated education — all from one shared content library.

### Persona Tags (internal, never shown to user)

| Selection | Tag | App Experience |
|-----------|-----|---------------|
| Solo + Curious | `solo-curious` | Self-discovery → preparation → "How to find & start an NM relationship" |
| Solo + Experienced | `solo-experienced` | Self-maintenance → advanced tools → community navigation |
| Coupled + Curious | `coupled-curious` | Graduated exposure roadmap → first experiences |
| Coupled + Experienced | `coupled-experienced` | Communication tune-ups → advanced scenarios → repair tools |

### Tone Shift Between Populations

| Element | Curious Tone | Experienced Tone |
|---------|-------------|-----------------|
| Vocabulary | Plain language, define everything | Community language, no hand-holding |
| Pacing | Slow, gentle, "it's okay" | Direct, efficient, respects their time |
| Assumed knowledge | Zero | Full |
| Emotional register | Warm, reassuring, validating | Honest, challenging, growth-oriented |
| Prompt complexity | One question at a time | Multi-layered, asks for nuance |
| Example | "What's one thing about NM that excites you? Just one." | "What pattern keeps showing up that you haven't fully addressed?" |

If a curious user sees experienced content → overwhelmed, unready. If an experienced user sees curious content → patronized, deletes the app. **The persona filter is the difference between "this app gets me" and "this app isn't for me."**

### Solo ↔ Coupled Transition

When a solo user finds a partner:
- Solo journal entries are NEVER shared (privacy is sacred)
- Shared journey starts fresh
- Solo stages completed inform where the coupled roadmap begins (skip already-done self-work)

---

## 3. The Problem We Solve


The #1 problem isn't jealousy. It's that people don't know how to START. The gap between curiosity and first conversation is where most NM journeys die.

### The 9 Pain Points (in customer journey order)

| # | Problem | Who | Urgency | What They'd Pay |
|---|---------|-----|---------|-----------------|
| 1 | "I can't even start the conversation" | Solo curious | Critical | $30–60 |
| 2 | "We tried to talk about it and it went badly" | Coupled curious | Critical | $40–60 |
| 3 | "I don't know what I actually want" | All curious | High | $25–40 |
| 4 | "We can't set boundaries that work" | Coupled (all stages) | Critical | $40–60 |
| 5 | "Jealousy is eating me alive" | All practitioners | Critical | $25–50 |
| 6 | "Something went wrong — crisis" | Coupled, active | Critical | $50+ |
| 7 | "I can't find a therapist who gets this" | Everyone | High | $40–60 |
| 8 | "I don't know anyone else who does this" | Everyone, esp. new | Moderate | $20–30 |
| 9 | "We've been doing this for years and we're stuck" | Experienced | Moderate | $40–60 |

### Why Existing Solutions Fail

- **Books/podcasts** — Information overload, consumed solo, no partner involvement
- **Reddit** — Contradictory crowd-sourced advice, no structure
- **Therapy** — $150–300/session, 2–6 week waitlists, most therapists aren't NM-informed and some actively pathologize it
- **"Just be honest"** — Radical honesty without structure = emotional flooding
- **Winging it** — How boundary violations happen. Not because people are bad, but because they never agreed on where the lines were.

### What the Market Actually Wants

1. **Structure over information** — They're drowning in content. They need a PROCESS for turning it into conversations.
2. **Partner involvement** — Every resource is single-player. NM is a two-person journey. Mutual reveal mechanics are the product-market fit.
3. **Normalization over pathologization** — They don't want clinical language. They want to feel like this is a legitimate, navigable life choice.
4. **Accessibility over expertise** — 70% of what a good NM therapist provides, available tonight, for the price of a book.
5. **Privacy over community** — Most NM-curious people want a PRIVATE space to figure this out first.

---

## 3.5. V1.0 Feature Set

Features are organized by act ownership. Act 1 features are front-door — marketed, prioritized, and polished first. Act 2 features ship at V1.0 but are discovered, not marketed. Act 3 features ship in architecture and routing only at V1.0; marketing focus shifts at V1.2.

### The Desire Map: Primary Conversion Architecture

The Desire Map mutual reveal is not a feature gate. It is the revenue mechanic.

1. **Both partners complete the Desire Map independently** — 17 items, ~4.5 minutes, fully private. Neither sees the other's ratings.
2. **One matched item is revealed free** — the instant personalized result. The first glimpse of what they actually agree on creates the demand the paywall fulfills.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product. The free match is the proof it works.

This is "instant personalized result → paywall on that result." The mechanic works because the result is real, immediate, and deeply personal. It cannot be replicated by any other app because it requires both partners to have already completed the assessment.

### Feature Matrix

| Feature | Act | V1.0 Ships | Notes |
|---------|-----|-----------|-------|
| Onboarding flow — all three paths | 1/2/3 | ✅ | All routes present; Act 1 path marketed at launch |
| Conversation card decks (Coupled Curious) | 1 | ✅ | Core product, front-door |
| Desire Map — 17 items, mutual private rating | 1 | ✅ | Primary conversion moment |
| Desire Map — 1 free match reveal | 1 | ✅ | Free tier hook |
| Desire Map — full reveal | 1 | ✅ | Behind paywall |
| Readiness Assessment | 1 | ✅ | Front-door |
| Partner pairing (QR, code, link) | 1 | ✅ | Front-door |
| Solo Reflection gate (post-onboarding) | 1/2/3 | ✅ | All paths |
| Graduated exposure roadmap (Coupled Curious) | 1 | ✅ | Front-door |
| Home dashboard + Today view | 1 | ✅ | Front-door |
| Safe word (always accessible) | 1 | ✅ | Front-door |
| Screenshot protection | 1 | ✅ | Front-door |
| Drop Box — AI message translation (100 msgs) | 1 | ✅ | Communication Pack |
| Coupled Experienced roadmap | 2 | ✅ | Present, not marketed at launch |
| Advanced scenario cards | 2 | ✅ | Present, not marketed at launch |
| Agreement foundation prompts | 2 | ✅ | Present, not marketed at launch |
| Solo Curious roadmap | 3 | ✅ | Architecture present, not marketed |
| Solo Experienced roadmap | 3 | ✅ | Architecture present, not marketed |
| Bridge cards (solo user with partner) | 3 | ✅ | Architecture present, not marketed |
| Connection Cards / Partner Roster | 2 | V1.1 | Infrastructure for pulse, vault, check-ins |
| Daily Relationship Pulse | 2 | V1.1 | 30-second daily habit; data compounds retention |
| Insight Engine — pattern surfacing | 2 | V1.1 | Needs logged data to work |
| Emotional Texture Calendar | 2 | V1.1 | Needs pulse data |
| Jealousy Mapping | 2 | V1.2 | Dedicated in-the-moment tool |
| Agreements Vault | 2 | V1.2 | Requires connection roster first |
| Anonymous Community Feed | 2/3 | V1.5 | Moderation cost too high pre-scale |
| Your Year, Lightly | 2/3 | V2.0 | Needs 6+ months of active logged data |

---

## 4. Moral Red Line

**This app is not therapy. This is non-negotiable.**

Open Lightly is a communication tool and an educational resource. It facilitates structured conversations between partners. It provides research-backed frameworks for exploring difficult topics. It does NOT diagnose, treat, or replace professional mental health care.

As a future therapist building this product: no dollar is worth an ethical violation. The moment this app crosses from "guided conversation tool" into "therapy substitute," it causes harm — to users who deserve real clinical care, and to the credibility of the therapeutic profession.

### What This Means in Practice

**The app WILL:**
- Frame itself as a conversation tool, not a clinician
- Surface crisis resources (988, Crisis Text Line, National DV Hotline) when language suggests distress
- Include "Find a Therapist" resources with NM-informed directories
- State on Ground Rules screen: "We're not a therapist. If things get heavy, we'll point you to people who can help."
- Position AI features as communication SKILLS education, never clinical interpretation

**The app will NEVER:**
- Diagnose relationship patterns ("this is stonewalling," "this is anxious attachment")
- Use clinical terminology in user-facing output (no Gottman labels, no attachment framework language)
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Compare partners ("Partner A communicates better than Partner B")
- Provide unsolicited feedback on communication quality
- Frame NM as something that needs to be "fixed" or "managed"
- Replace the recommendation to seek professional help when situations exceed the app's scope

> **New features boundary:** Jealousy Mapping logs feelings, not diagnoses. Compersion Tracker celebrates moments, not prescribes them. The Insight Engine surfaces observations ("You tend to feel X after Y"), never evaluations ("Your jealousy is getting worse"). Pattern data is a mirror. The user draws their own conclusions.

### The Line Between Education and Therapy

| Education (we do this) | Therapy (we never do this) |
|------------------------|---------------------------|
| "Here's another way to express that" | "You're using criticism, a predictor of divorce" |
| "Many couples find it helpful to..." | "Based on your pattern, you should..." |
| "Research suggests that direct requests..." | "Your communication style indicates..." |
| Offer alternative phrasings, user chooses | Prescribe interventions |
| Cite communication principles | Apply clinical frameworks to user behavior |

### The Three Rules

**Rule 1: Facilitate, Never Diagnose**
- Wrong: "Based on your responses, you have an anxious attachment style."
- Right: "You mentioned feeling worried when your partner is distant. What does that worry need?"
- The first is a clinical judgment. The second is a mirror. The user draws their own conclusion.

**Rule 2: Open Doors, Never Push Through Them**
- Wrong: "It's important that you confront your jealousy. Let's work through it."
- Right: "Jealousy showed up. Want to explore what it's telling you? [Yes] [Not tonight]"
- A therapist can push — they have informed consent, a treatment plan, malpractice insurance. We have none of those. The app offers the door. The user decides.

**Rule 3: Credit the User, Not the Tool**
- Wrong: "Our evidence-based approach helped you identify your core needs."
- Right: "You just named something important."
- The app showed up with the right question at the right time. The user did the work.

### Language Guide

| Therapeutic language (avoid) | Companion language (use) |
|------------------------------|--------------------------|
| "Your assessment indicates..." | "You mentioned..." |
| "Let's work on..." | "Want to explore..." |
| "This exercise will help you..." | "Some people find it useful to..." |
| "You should discuss this with your partner" | "If this feels worth sharing, you'll know when" |
| "Processing your trauma" | "Sitting with what came up" |
| "Treatment plan" | "Your path" |
| "Session goals" | "Tonight's intention" |

### The Bar Conversation Test

Every card should pass this: Could a really wise, well-read friend say this to you over a drink without it feeling clinical?
- ✅ "What's one thing you want that you haven't said out loud yet?"
- ❌ "Identify an unmet relational need and articulate it to your partner."
- ✅ "When jealousy shows up, where do you feel it in your body?"
- ❌ "Describe the somatic manifestation of your jealousy response."

Same insight. Same evidence base. Completely different relationship with the user.

### Using Clinical Frameworks Without Crossing the Line

The app draws on Gottman, attachment theory, CBT, NVC, EFT, and motivational interviewing. The difference is framing:

| Framework | What a therapist does | What this app does |
|-----------|----------------------|-------------------|
| Gottman's Four Horsemen | Diagnoses communication dysfunction, assigns treatment plan | Card: "Notice when you're criticizing vs. complaining. What's the difference feel like?" |
| Attachment theory | Assesses attachment style, restructures interaction patterns | Reflection: "When your partner pulls away, what's the first thing you feel?" |
| CBT restructuring | Identifies and challenges distorted thought patterns | Card: "The story I'm telling myself about this is ___. What's another version?" |
| EFT | Guides couples through de-escalation cycles | Prompt sequence: surface reaction → underlying emotion → need → request |
| Motivational interviewing | Strategic questioning to move through stages of change | Card phrasing mirrors MI — open questions, affirmations, reflective framing |
| Expressive writing (Pennebaker) | Prescribed journaling for trauma processing | Free-text reflection with "Only you see this" |

Same intellectual DNA. Completely different claim.

### Where the Line Gets Tested

| Scenario | What therapy does | What this app does |
|----------|------------------|-------------------|
| Suicidal ideation in a reflection | Clinician assesses risk, activates safety protocol | Surface crisis resources immediately. Don't try to help. Route to professionals. |
| Partner describes abuse | Clinician reports, creates safety plan | Surface DV hotline. Don't counsel. Don't notify the partner. |
| User in distress after a session | Clinician de-escalates, extends session | "That was heavy. You don't have to carry this alone." + therapist finder + grounding exercise |
| Couple in active conflict during session | Therapist mediates | Card design avoids inflammatory prompts at low depth levels. The depth slider is the safety valve. |

**The rule: when it gets clinical, get out of the way and point to clinicians.** The app handles the 95% of moments where two curious people want a better conversation. The 5% where real crisis shows up is not our jurisdiction.

### Crisis Detection

Keyword-based detection (not ML). If solo reflection or session text contains crisis language:
- Surface resources immediately (988, Crisis Text Line, National DV Hotline)
- Non-blocking — resources shown, user continues at their discretion
- Always accessible in Settings → Get Support
- False positives are acceptable. Missing someone who needs help is not.

### The Philosophical Frame

This app is closer to a **really good book of questions** than it is to therapy. Think Esther Perel's card games, The School of Life conversation cards, the 36 Questions to Fall in Love. All draw on deep psychological research. None are therapy.

- A **book of questions** assumes two capable adults who want to grow.
- **Therapy** assumes something is broken and someone trained needs to help fix it.

This app assumes the first. It says: "You're not broken. You're exploring. Here are better questions than the ones you've been asking yourselves."

### Positioning

> "We're not therapy. We're what you use when you can't find a therapist who gets it — or between sessions with one who does."

### Legal Disclaimer (accessible but not obnoxious)

> "[App name] is a conversation companion, not a therapist. It's informed by relationship science and designed to help you explore — but it's not a substitute for professional support. If you're in crisis or experiencing abuse, please reach out to [resources]."

Present in: App Store listing, Settings → About, Onboarding Ground Rules. One line. Not a wall of legal text.

---

## 5. AI Ethics & Communication Coaching

### Guiding Principle

> "We don't tell you what you said wrong. We show you other ways you could say what you meant."

### AI Can / Cannot

✅ **AI CAN:**
- Identify linguistic patterns (you-statements, absolutes, questions vs. statements)
- Offer alternative phrasings (not interpretations)
- Show speaking time balance
- Highlight questions asked (encourages curiosity)
- Note moments of agreement/alignment
- Translate messages in the Drop Box (anonymous, non-judgmental rephrasing)

❌ **AI CANNOT:**
- Label emotions ("you sounded angry")
- Attribute blame ("you interrupted 7 times")
- Diagnose patterns ("this is stonewalling")
- Apply clinical frameworks in output
- Provide unsolicited feedback
- Show one partner's analysis without the other present
- Train on users' private conversations

### AI Implementation Levels

| Level | What It Actually Is | Difficulty | Cost | When |
|-------|-------------------|-----------|------|------|
| **1. System Prompt** | GPT-4o/Claude with a detailed role prompt + user context injection (assessment data, desire map, session history). Not retrained — role-playing well. | Easy | ~$20/mo API | Launch (Drop Box) |
| **2. RAG** | Source material (NM books, NVC, Gottman research, your content) chunked into embeddings, stored in vector DB. User question → semantic search → relevant chunks injected as context → grounded response. | Medium | ~$50–100/mo | Month 4–6 (AI Coach) |
| **3. Fine-Tuning** | Retrain a model on hundreds of example conversations in your voice/tone. Learns your specific framing. | Medium-Hard | $500–2K training | Month 12+ (if enough data) |
| **4. From Scratch** | Don't. OpenAI and Anthropic spent the billions. Stand on their shoulders. | — | — | Never |

**RAG tech stack:**

| Component | Tool | Cost |
|-----------|------|------|
| LLM | OpenAI GPT-4o or Claude | ~$0.01–0.05/turn |
| Vector DB | Supabase pgvector (already in stack) | Free tier |
| Embedding | OpenAI text-embedding-3-small | Pennies |
| Orchestration | LangChain or LlamaIndex | Free (open source) |

**AI Coach feature map:**

| Feature | What It Does |
|---------|-------------|
| Ask the Coach | Freeform chat for questions that don't fit prompts. Context-aware via assessment + desire map data. |
| Jealousy First Aid | Real-time CBT reframing: identify thought → examine evidence → find distortion → reframe → action plan. Personalized to their archetype, attachment signals, and agreements. |
| Post-Conversation Processing | "We just had a hard conversation. Help us make sense of it." |
| Scenario Expansion | After a hypothetical, "What if [variation]?" — AI generates new angles dynamically. |
| Assessment Interpreter | "What does our score actually mean for [specific situation]?" |
| Drop Box Translation | Anonymous AI rephrasing: say what you mean without the loaded language. |

**AI implementation phases:**

| Phase | When | What | Method |
|-------|------|------|--------|
| Launch | Day 1 | Drop Box (100 AI translations) | Level 1 — system prompt |
| Month 4–6 | AI Coach v1 | Ask the Coach + Jealousy First Aid | Level 1 with context injection |
| Month 7–9 | AI Coach v2 | RAG upgrade — responses grounded in curated NM content | Level 2 |
| Month 12+ | Voice refinement | Fine-tune on anonymized Drop Box patterns | Level 3 (if data exists) |

### Communication Coaching Models (Late Feature — Batch 24+)

| Model | What It Is | When |
|-------|-----------|------|
| **Pattern Library** | Browsable library of common communication patterns with research-backed alternatives. No recording, no surveillance. Users self-identify. | Batch 24–26 |
| **Post-Conversation Replay** | Couple opts in to record a session. Together, they tap any line to see alternative phrasings. No judgment on which is "better." | Batch 29+ |
| **Hybrid Analysis** | Linguistic structure analysis (not emotional/clinical). Alternatives sourced from NVC, Gottman soft startup research, active listening frameworks. | Batch 30+ |

### Consent Architecture (for recording features)

- Opt-in PER SESSION (not global)
- BOTH partners must consent (double opt-in)
- Either partner can delete at any time
- On-device processing or E2E encrypted
- Clear disclosure before recording begins

### Transparency

Public documentation of:
1. What we analyze (linguistic structure, speaking balance, conversational flow)
2. What we don't analyze (emotional tone, who's "right," clinical categories)
3. Where alternatives come from (NVC, Gottman published research, active listening frameworks)
4. Every suggestion has a "This doesn't fit" button
5. Model never trains on private conversations

---

## 6. Psychology & Emotional Design

### Shame Reduction Architecture

Every design decision passes through: "Does this reduce shame or increase it?"

- **Onboarding stat screen** ("1 in 5 Americans") — normalizes before asking anything personal
- **"No judgment on any answer"** — explicit on relationship status screen (the partnered_hidden option carries shame)
- **Skip is always real** — no guilt copy, no "Are you sure?", no re-prompting
- **Jealousy is data, not failure** — reframed as information about unmet needs, not proof something is wrong
- **Every outcome is valid** — including "We explored this and decided it's not for us"

### Desire Map Assessment — Core 17 Items

The Desire Map is a mutual-reveal compatibility tool. Both partners rate 17 items independently; results are compared only when both complete. The 17 items cover all 7 of Moors' (2024) clinical assessment dimensions for CNM couples.

| # | Item | Category | Sensitivity | Source |
|---|------|----------|-------------|--------|
| 1 | Opening Our Relationship | Structure | 1 | Conley 2017 |
| 2 | Swinging or Playing Together | Structure | 1 | Rubel & Bogaert 2015 |
| 3 | Dating Separately | Structure | 2 | Moors 2017 |
| 4 | Polyamory — Loving More Than One | Structure | 2 | Fern 2020, Haupert 2017 |
| 5 | Our Relationship Comes First | Structure | 2 | Fern 2020 (hierarchy) |
| 6 | Emotional Connections With Others | Emotional | 2 | Mogilski 2017 |
| 7 | New Relationship Energy (NRE) | Emotional | 2 | Easton & Hardy 2017 |
| 8 | Your Partner Falling in Love | Emotional | 3 | Conley 2017 |
| 9 | Group Sexual Experiences | Sexual | 2 | Lehmiller 2018 |
| 10 | Safer Sex Boundaries | Health | 1 | Moors 2024, Fern 2020 |
| 11 | Overnight Stays With Others | Logistics | 2 | Sheff 2014 |
| 12 | Time and Attention | Logistics | 2 | Moors 2024, Mogilski 2017 |
| 13 | Veto Power | Logistics | 2 | Easton & Hardy 2017 |
| 14 | Full Disclosure — Knowing Everything | Communication | 2 | Mogilski 2017, Deri 2015 |
| 15 | Meeting Your Partner's Other Connections | Communication | 1 | Sheff 2014 |
| 16 | Who Knows About Us | Social | 1 | Sheff 2014, PMC 2025 |
| 17 | Handling Jealousy Together | Emotional | 2 | Veh et al. 2025 |

**Why 17, not 15:** The 3 clinically-mandated additions (safer sex, hierarchy, social disclosure) can't replace existing items without creating a gap. 17 items × 15 seconds = ~4.5 minutes. Under the 5-minute threshold.

**Clinical coverage:**

| Moors (2024) Dimension | Items |
|------------------------|-------|
| Structural agreement | 1–4 |
| Emotional boundaries | 5–8 |
| Sexual health agreements | 10 |
| Disclosure preferences | 14 |
| Time management | 11–12 |
| Social identity management | 16 |
| Conflict resolution style | 17 |

**Key clinical insights informing the design:**
- **Gottman:** ~70% of couple problems are perpetual. The Desire Map doesn't solve disagreements — it identifies which are perpetual (need ongoing dialogue) vs. solvable. That reframe shapes item descriptions.
- **Fern (2020):** Hierarchy is the most common unspoken assumption. Partners who disagree on #5 build their CNM structure on a fault line.
- **Sheff (2014):** Closeting stress is the #1 predictor of long-term CNM burnout. Partners often disagree sharply on outness (#16).
- **Veh et al. (2025):** Jealousy management is the strongest predictor of CNM satisfaction. Item #17 is the only item measuring a PROCESS (how you deal with feelings) vs. a PREFERENCE (what you want).

### Archetype System (Post-Reflection Classification)

Solo reflection text is embedded and compared against 8 archetype centroids:

| Archetype | Signals | Content Path |
|-----------|---------|-------------|
| The Curious | "wondering," "thinking about it" | Foundational, exploratory |
| The Anxious | "scared," "worried about losing" | Reassurance-first, attachment-focused |
| The Wanting | "desire," "something missing" | Desire exploration, permission-giving |
| The Going-Along | "partner wants," "they asked me" | Autonomy-focused |
| The Processing | "jealousy," "struggling" | Emotional processing tools |
| The Stuck | "been doing this but," "not working" | Advanced mechanics, renegotiation |
| The Communicator | "don't know how to talk about" | Communication frameworks |
| The Builder | "rules," "structure," "boundaries" | Practical tools, agreements |

Classification is **invisible infrastructure**. The system tags a user as `anxious` internally for content routing. The user never sees that label. They see cards that happen to address their experience. The user experience is just: "Wow, this app gets me." Use the science to build the engine. Let the user experience feel like wisdom, not treatment.

### Emotional Pacing

- Onboarding screens 1–7: logistics (setup energy)
- Screen 8 (Ground Rules): ethical frame (trust energy)
- Screen 9 (Priming): emotional threshold — everything after is personal
- Solo Reflection: first vulnerable moment — earns the right to personalize

### Ground Rules Resurfacing

| Moment | What Appears |
|--------|-------------|
| First couples session | "No scorecards. This is exploration, not evaluation." |
| Cards touching conflict | Footer: "This isn't about right or wrong." |
| Post-session checkout | "How did that feel? (Just for you — your partner sees their own.)" |
| Settings → About | Full ground rules + crisis resources |
| 14+ days inactive | No guilt. At most: "Still here when you're ready." |

---

## 7. Marketing & Positioning

### Core Positioning

Don't sell "an NM app." Sell the solution to specific pain points. The app is ONE product. The marketing speaks to NINE different moments of pain.

### Pain-Point Marketing Hooks

| Hook | Problem It Targets |
|------|-------------------|
| "How to bring up non-monogamy without your partner thinking you want to cheat" | #1 — Can't start |
| "Your first NM conversation went badly. Here's what to do next." | #2 — Went badly |
| "Swinging? Polyamory? Open? How to figure out what YOU actually want" | #3 — Don't know what I want |
| "The boundary-setting conversation most NM couples skip (and regret)" | #4 — Boundaries |
| "What to do when jealousy hits and 'just sit with it' isn't working" | #5 — Jealousy |
| "It's 11pm and your partner's date ran late. Here's how to handle tonight." | #6 — Crisis |
| "When your therapist doesn't get non-monogamy" | #7 — Therapist gap |
| "You're not the only couple figuring this out" | #8 — Isolation |
| "Been doing NM for years? When's the last time you audited your agreements?" | #9 — Experienced but stuck |

### Price Psychology

- **$14.99 Core** = less than a physical card deck ($25–45), less than one therapy session, less than dinner out
- **$34.99 Complete** = the "I'm all in" option — feels like buying a book, not renting access
- **$6.99/mo AI Coach** = less than one coffee/week, justified by real per-message API costs
- Expansion packs feel earned — couples hit them naturally as they progress

### Buyer Journey

```
$0 (Free) → "Let me just see what this is"
  ↓ Assessment blows their mind
$14.99 (Core) → "This is actually good, $15 is nothing"
  ↓ Complete Phase 1, feel momentum
+$9.99 (Communication) → "I NEED the Drop Box — I can't say this out loud"
  ↓ Hit message limit, want more
$6.99/mo (AI Coach) → "Unlimited Drop Box + a coach? For $7/mo? Yes."
  ↓ Using insights, reports, coaching regularly
Total: ~$35 one-time + $7/mo for active AI features
```

### Revenue Projections (Conservative)

| Timeframe | Downloads | Free→Core (15%) | Core→Bundle (30%) | AI Coach (10% of paid) | Monthly Revenue |
|-----------|-----------|-----------------|-------------------|----------------------|----------------|
| Month 3 | 3,000 | 450 | 135 | — | ~$9,900 (one-time) |
| Month 6 | 8,000 | 1,200 | 360 | 120 | ~$26,400 + $839/mo |
| Month 12 | 20,000 | 3,000 | 900 | 300 | ~$72,000 + $2,100/mo |

---

## 8. Design System

### Colors — `AppColors`

| Token | Hex | Usage |
|-------|-----|-------|
| `cyan` | #00C2FF | Primary accent, cool spectrum |
| `purple` | #6C3AE0 | Mid-spectrum, transitions |
| `magenta` | #FF006A | Emotion accent, hot spectrum |
| `pink` | #FF2D8A | Shimmer gradients |
| `deepBlue` | #0078FF | Atmospheric floor washes |
| `gold` | #C8960A | Safety ONLY (safe word, warnings) |
| `pageBg` | #030305 | Page backgrounds |
| `cardBg` / `card` | #050507 | Card interiors |
| `surfaceBg` | #08080C | Elevated surfaces |
| `textPrimary` | #E8E8F0 | Headings, prompt text |
| `textSecondary` | #AAAABC | Labels, descriptions |
| `textTertiary` | #666680 | Timestamps, meta |
| `border` | white @ 6% | Subtle card borders |
| `spectrumGradient` | cyan→purple→magenta | Hot border, prompt cards |

### Typography — `AppFonts`

All tokens use two factory functions: `display(size, weight:)` (Clash Display) and `body(size, weight:)` (Switzer).

| Token | Font | Size |
|-------|------|------|
| `heroTitle` | Clash Display Bold | 42 |
| `cardTitle` | Clash Display Semibold | 22 |
| `screenTitle` | Clash Display Semibold | 24 |
| `bodyText` | Switzer Regular | 16 |
| `bodyMedium` | Switzer Medium | 15 |
| `caption` | Switzer Regular | 13 |
| `ctaLabel` | Switzer Semibold | 16 |
| `buttonLabel` | Switzer Semibold | 14 |

### Shared Modifiers

| Modifier | What it does |
|----------|-------------|
| `.cardStyle()` | `background + clipShape(RoundedRectangle) + border stroke` |
| `.pillBorder()` | Neon gradient stroke (cyan→purple→magenta) with blur + shadow layers |
| `.screenshotProtected()` | Prevents screenshots on sensitive content |

### Design Rules

1. **Color is earned** — Gradient only on interactive/prompt cards. Static UI uses muted surfaces.
2. **Gold = safety only** — Never decorative. Safe word, warnings, exit actions.
3. **Hot border = prompt cards only** — Spectrum gradient stroke reserved for PromptCard.
4. **Zero hardcoded values** — All colors via `AppColors`, all fonts via `AppFonts`.

---

## 9. Architecture

### Tab Architecture

The Roadmap is the spine. Tab layout adapts based on persona:

```
Coupled:  Home  |  Roadmap  |  Us ∞    |  You
Solo:     Home  |  Roadmap  |  Journal ✦  |  You
```

| Tab | Coupled Users | Solo Users |
|-----|--------------|------------|
| **Home** | Tonight's check-in, roadmap position, quick play | Same |
| **Roadmap** | Visual journey map. Current stage expanded with Deck + Learn + Pre/Post. All stages browsable (not locked). | Same structure, different roadmap |
| **Us / Journal** | Mutual reveals, session history, partner roadmap progress, saved cards | Private reflections, personal growth timeline, bookmarked prompts, "Questions to ask a future partner" |
| **You** | Profile, settings, safe word config, pairing | Same (minus pairing) |

Learn/Education lives inside each Roadmap stage AND as a browsable section under a "More" area.

### Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI | SwiftUI (iOS 26) | |
| Persistence | SwiftData | Local-first — all session data stays on device |
| Architecture | MVVM | `@Observable`, `@AppStorage`, `@Environment` |
| Backend | Supabase (Free tier) | Postgres, Realtime, Edge Functions, RLS, Auth |
| Auth | Sign in with Apple → Supabase Auth | |
| Purchases | StoreKit 2 | |
| Security | CryptoKit (encryption), Keychain (tokens/keys), LocalAuthentication (biometrics) | |
| Fonts | Clash Display (headings), Switzer (body), Zodiak + GeneralSans (brand) | |
| External deps | Supabase Swift SDK (only external dependency) | |

**Supabase tier: Free ($0/mo)**
- 50,000 monthly active users included
- 500 MB database
- Unlimited API requests
- Upgrade to Pro ($25/mo) only when exceeding 50K MAU

### Project Structure

```
App/
  Open_LightlyApp.swift        — Entry point, auth gate, SwiftData container
  ContentView.swift             — Root router: onboarding vs. tabbed app
  Theme/
    AppColors.swift             — Single source of truth for all colors
    AppFonts.swift              — Font factory functions + semantic tokens
    AppTheme.swift              — ThemeMode enum, AppPalette (light/dark/AMOLED)
    ThemeManager.swift          — Observable theme state
    ThemeModifiers.swift        — .themedRoot() modifier

Features/
  Auth/SignInView.swift
  Home/HomeView.swift
  Sessions/SessionView.swift
  Compatibility/DesireMapView.swift
  Progress/ProgressDashboardView.swift
  Settings/
    SettingsView.swift
    ThemePickerView.swift
    ThemeTestView.swift
  Onboarding/
    OnboardingFlowView.swift    — Coordinator / screen sequencer
    Views/                      — StatView, BrandView, NameView, ModeSelection, PairingFork
    Data/                       — OnboardingData, OnboardingTokens, ExperienceLevel

Design/
  Components/
    Buttons/                    — GradientButton, HoloCTAButton, CriticalButton, SafeWordButton
    Cards/                      — PromptCard, SettingsCard, CategoryTileView
    Input/                      — InteractiveField, RatingButtonGroup, ToggleRow
    Progress/                   — ProgressBar, ProgressRingView, ScoreRing, SpectrumBar
    Effects/                    — GlowFieldView, HolographicShimmer, GlowOrb
    Text/                       — GradientText
    Modifiers/                  — PillBorder, ScreenshotProtectionModifier
    SectionHeader.swift

Core/Services/
  AuthService.swift             — Sign in with Apple + Supabase session
  SupabaseManager.swift         — Shared Supabase client
  SyncManager.swift             — Retry pending syncs on launch
  ContentLoader.swift           — JSON prompt loading
  Config.swift                  — API keys, environment config
  ProfileService.swift          — User profile CRUD
  PairingService.swift          — Couple pairing codes + Realtime
  SessionSyncService.swift      — Session data sync
  AssessmentSyncService.swift   — Assessment results sync
  DesireSyncService.swift       — Desire map ratings sync

Data/Store/
  DataStore.swift               — Central persistence layer
  ModelContainer.swift          — SwiftData container config

Models/
  Content/                      — Prompt, Card, ContentCard, ContentCategory, DesireItem
  Enums/AppEnums.swift          — All enums (PromptCategory, PromptDifficulty, etc.)
  Persistence/                  — SessionRecord, RatingRecord, StreakRecord
  Progress/                     — UserProfile, AssessmentResult, Couple, DesireMatch
```

---

## 10. Onboarding Flow (v2.0)

**Goal:** App Store download → first meaningful moment in 60–90 seconds (Solo/Couple) or 45–60 seconds (Browsing).

**Design principles:**
- Trust before ask: normalization (Stats) before data collection
- Progressive disclosure: simple asks first, deeper questions after investment
- Breathing room: auto-advance screens provide mental breaks
- Self-honesty before partner performance: Solo Reflection happens first, even for couples
- Clear value exchange: user understands why each question matters
- No dead ends: every path leads to value

### Screen Sequence (8 screens)

| # | Screen | File | Type | Data Collected | Purpose |
|---|--------|------|------|---------------|---------|
| 1 | StatView | `OnboardingStatView.swift` | Interactive | None | "1 in 5" stat — normalize, reduce shame |
| 2 | BrandView | `OnboardingBrandView.swift` | Auto (3.5s) | None | Brand identity — mental break before first ask |
| 3 | NameView | `OnboardingNameView.swift` | Form | `displayName`, `pronouns`, `customPronouns` | Personalization seed, lowest-stakes first ask |
| 4 | ModeSelectView | `OnboardingModeSelectView.swift` | Two-stage | `explorationMode`, `nmStage` | Primary branch: Solo / Couple / Just Browsing |
| 5 | ContextView | `OnboardingContextView.swift` | Card stack | `relationshipContext` | Relationship situation — **skipped for Browsing** |
| 6 | CuriosityPickerView | `OnboardingCuriosityPickerView.swift` | Multi-select | `curiositySelections`, `communicationGoals`, `learningGoals` | Interest + intent picker — drives content personalization |
| 7 | BuildingPathView | `OnboardingBuildingPathView.swift` | Auto (~7.5s) | Derives `defaultDifficulty` from `nmStage` | Processing animation — pacing beat, reveals path is personal |
| 8 | OnboardingGroundRulesView | `OnboardingGroundRulesView.swift` | Must-acknowledge, ScrollView | `groundRulesAcceptedAt`, `onboardingComplete`, `completedAt` | Honest framing — what this is and isn't. Terminal screen. No back button. |

**Then:**
```
→ HOME (first visit)
→ Solo Reflection Card  ← one-time gate, applies to ALL paths
→ HOME DASHBOARD
```

### Path Variations

| Path | Screens | Notes |
|------|---------|-------|
| **Solo** | All 8 | ContextView shows 3 relationship-context cards |
| **Couple** | All 8 | ContextView shows 4 relationship-context cards; pairing prompt deferred to Settings |
| **Just Browsing** | 7 (skips ContextView) | Education tab unlocked; sessions locked until upgrade |

### Act-Ownership Routing Logic

The onboarding routing is intentional and permanent — not a placeholder to be replaced, but the architecture that enables the three-act reveal sequence. No onboarding screens change between acts; only the marketing focus shifts.

| Onboarding Selection | Act | Marketing Status at Launch |
|---------------------|-----|---------------------------|
| Coupled + Curious (`nmStage`: curious / exploring) | **Act 1** | Marketed — primary front-door path |
| Coupled + Experienced (`nmStage`: experienced) | **Act 2** | Present, not marketed — experienced tools surface first; these users discover the operational infrastructure organically |
| Solo (any `nmStage`) | **Act 3** | In architecture, not marketed — full routing present; excluded from launch marketing; front-door shift at V1.2 |

When Act 2 marketing begins at V1.1, experienced users have always had a complete path. When Act 3 marketing begins at V1.2, solo users have always had a complete path. The routing is the strategy encoded in code.

### User Modes

```swift
enum UserMode: String, Codable {
    case solo      // Self-discovery, partner optional
    case couple    // Joint exploration, paired via code
    case browsing  // Learn first, no sessions yet
}
```

### Experience Levels (collected in ModeSelectView, stage 2)

```swift
enum ExperienceLevel: String, Codable {
    case curious     // Brand new → defaultDifficulty: "warm"
    case exploring   // Some context → defaultDifficulty: "medium"
    case experienced // Knows what they want → defaultDifficulty: "hot"
}
```

### Relationship Context Options (ContextView)

**Solo (3 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `single` | "I'm single" | ember |
| `partneredOpen` | "I have a partner (they know)" | spark |
| `partneredHidden` | "It's complicated" | blaze |

**Couple (4 cards):**
| ID | Title | Intensity |
|----|-------|-----------|
| `notTalked` | "Haven't really talked about it" | ember |
| `talking` | "We've been talking" | flame |
| `someExperience` | "We've tried some things" | inferno |
| `needsReset` | "We need a reset" | nova |

### Curiosity Categories (CuriosityPickerView, multi-select)

- Communication & Dirty Talk
- Sensation & Touch
- Power Dynamics
- Fantasy & Role Play
- Trust & Vulnerability
- Romance & Connection
- Adventure & Novelty
- Bondage & Restraint
- Not sure yet — surprise me *(mutually exclusive with all others)*

### Navigation Logic

```swift
// Implemented in OnboardingFlowView.swift as advance(to:)
// All transitions: .easeInOut(duration: 0.5), .opacity only

func advance() {
    switch currentStep {
    case .stat:          advance(to: .brand)
    case .brand:         advance(to: .name)           // auto-advance at 3.5s
    case .name:          advance(to: .modeSelect)
    case .modeSelect:
        // Browsing skips context — goes directly to curiosity picker
        advance(to: explorationMode == .browsing ? .curiosityPicker : .contextSelect)
    case .contextSelect: advance(to: .curiosityPicker)
    case .curiosityPicker: advance(to: .buildingPath)
    case .buildingPath:  advance(to: .groundRules)    // auto-advance at ~7.5s
    case .groundRules:
        // Writes: groundRulesAcceptedAt, onboardingComplete, completedAt
        // Then calls onFinished → coordinator marks onboarding done → HOME
        onFinished?()
    }
}

func goBack() {
    // .stat, .brand — no back (brand already played)
    // .groundRules, .buildingPath — no back button (terminal + auto-advance)
    switch currentStep {
    case .name:            advance(to: .modeSelect)   // back goes forward to avoid re-playing brand
    case .modeSelect:      advance(to: .name)
    case .contextSelect:   advance(to: .modeSelect)
    case .curiosityPicker:
        // Browsing went modeSelect → curiosity, so back goes to modeSelect
        advance(to: explorationMode == .browsing ? .modeSelect : .contextSelect)
    default: break
    }
}
```

### Data Model

```swift
struct OnboardingData {
    // Screen 3
    var displayName: String = ""
    var pronouns: [PronounOption] = []

    // Screen 4
    var userMode: UserMode?               // solo / couple / browsing
    var experienceLevel: ExperienceLevel? // curious / exploring / experienced

    // Screen 5 (Solo/Couple only)
    var relationshipContext: RelationshipContext?

    // Screen 6
    var curiositySelections: [String] = []

    // Derived during BuildingPathView
    var defaultDifficulty: String {
        switch experienceLevel {
        case .curious:    return "warm"
        case .exploring:  return "medium"
        case .experienced: return "hot"
        default:          return "warm"
        }
    }

    // Completion
    var onboardingComplete: Bool = false
    var onboardingCompletedAt: Date?
}
```

### Partner Pairing (Couple Mode — deferred to Settings)

Pairing is no longer a mandatory onboarding screen. Couple users complete their own onboarding individually, then pair via Settings. This removes the blocking dependency on a partner being present at signup time.

Three pairing methods remain available in Settings:
| Method | When | How |
|--------|------|-----|
| **QR Code** | Same room | Partner A shows QR → Partner B scans |
| **Verbal Code** | Same room, different device | Format: `WORD + 2-digit number` (e.g. "SPARK 42") |
| **Share Link** | Remote | iMessage/text deep link |

---

### Solo Reflection Card (Post-Onboarding Gate)

Appears on first HOME visit for **all paths** (Solo, Couple, Browsing). One-time, non-repeating.

**Prompt:** *"What brought you here tonight?"*

- Text stays on-device; only archetype tags sync to Supabase
- Skip is non-punitive and prominent — no guilt
- Even skipped users read the question (seed is planted)
- Couples: both partners complete independently before shared sessions unlock

**Why this prompt:**
1. Forces self-honesty before partner performance
2. Creates a private artifact they'll return to later
3. Establishes the app's voice: "We're not here to perform. We're here to be honest."

**Data stored:**
```swift
struct SoloReflectionEntry: Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var prompt: String = "What brought you here tonight?"
    var response: String         // Empty string if skipped
    var wordCount: Int
    var skipped: Bool = false
}
```

---

## 11. Content Structure & Roadmaps

### The Roadmap is the Spine

The Roadmap is the primary navigation — a visual journey map (not a checklist, not a progress bar). Each persona gets a different roadmap. Each stage has three layers:

| Layer | What It Is |
|-------|-----------|
| **Conversation Deck** | 8–12 prompts specific to this stage |
| **Education Module** | Curated resources (books, podcasts, Reddit threads, videos) contextual to this stage |
| **Pre/Post Processing** | Before: "What are we hoping to feel? What are we afraid of?" / After: "What actually happened? What surprised us?" |

### Coupled Curious Roadmap — Graduated Exposure

This is **systematic desensitization** (Wolpe, 1958) applied to NM exploration. Each step increases only ONE variable (observation → participation → emotional → physical → autonomy). Each step has a natural pause-and-process point. Regression is expected and normalized.

| Stage | Anxiety | What It Tests | Clinical Parallel |
|-------|:---:|---------------|-------------------|
| 1. Curiosity | 1/10 | Can we even have this conversation? | Psychoeducation / imaginal exposure |
| 2. Fantasy Together | 2/10 | Can we be sexual while acknowledging others exist? | Imaginal exposure |
| 3. Observation | 3/10 | Can we be in a sexually charged environment together? | In-vivo exposure (observation) |
| 4. Mild Participation | 4/10 | Can I see my partner receiving attention from someone else? | In-vivo exposure (mild) |
| 5. Controlled Experience | 5/10 | Can we involve a third party in a boundaried way? | In-vivo exposure (controlled) |
| 6. Emotional Connection | 5/10 | Can we handle emotional attention from others? | In-vivo (emotional domain) |
| 7. Low-Stakes Dating | 6/10 | Can we handle our partner on a date? | In-vivo (social/romantic) |
| 8. Raising Stakes | 7/10 | Can we handle escalation? | Graded exposure |
| 9. Full Experience | 8–9/10 | The real thing, together or separately | Full exposure (with safety) |
| 10. Autonomy | 10/10 | Maximum trust | Full autonomy |

**Framing: descriptive, not prescriptive.** "Many couples find that starting with low-stakes observation helps them gauge comfort" — NOT "You should start with strip clubs." No required order. A guide, not a gate. You can stop anywhere. Every stage is an arrival, not a waypoint.

**Evidence basis:** No peer-reviewed research on this exact sequence for swinging. But the underlying framework is massively validated: graduated exposure (Wolpe 1958), processing with partner improves outcomes (Gottman, Johnson), psychoeducation before novel experiences reduces negative outcomes (health psych), autonomy at each step predicts satisfaction (Deci & Ryan + Moors et al.), emotional regulation improves with practice (Gross 2015).

### Solo Curious Roadmap

| Stage | Focus |
|-------|-------|
| 1. Understand Yourself | What do I want? What am I afraid of? What does commitment mean to me? |
| 2. Learn the Landscape | NM styles, structures, terminology. What resonates? |
| 3. Process Your Feelings | Internalized monogamy, shame, fear. What stories am I telling myself? |
| 4. Prepare to Date | Profiles, disclosure timing, vetting NM partners |
| 5. Build Your World | Community, support, who do I tell? How? |
| 6. Start Dating | First conversations, first dates, processing what comes up |
| 7. Navigate Your First NM Relationship | Communication, boundaries, NRE — "It's real now" |

### Coupled Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. State of the Union | How are WE doing? Honest check-in. What's working? What's friction? |
| 2. Agreement Audit | Review every rule and boundary. "Does this still serve us or just protect us?" |
| 3. Unfinished Conversations | Things you've been avoiding. Resentments, unspoken desires, fears. |
| 4. Advanced Scenarios | NRE management, unequal situations, evolving structures |
| 5. Repair Shop | When trust was damaged. Specific incident processing framework. |
| 6. What's Next | Deeper exploration, new structures. "Where do we want to be in a year?" |

### Solo Experienced Roadmap

| Stage | Focus |
|-------|-------|
| 1. Check In With Yourself | Where am I? What patterns keep showing up? |
| 2. Sharpen Your Tools | Communication upgrade, boundary audit |
| 3. Go Deeper | Attachment patterns in NM, jealousy triggers, compersion cultivation |
| 4. Navigate Complexity | Multiple relationships, time, energy, hinge skills, metamour dynamics |
| 5. Handle Hard Stuff | Breakups, transitions, restructuring, repair |
| 6. Sustain & Thrive | Long-term NM wellness, preventing burnout, maintaining joy |

### Content Ratio: Shared vs. Unique

Not four apps — one content library with four paths:

| Content Type | Shared | Unique per path |
|-------------|--------|-----------------|
| Education library (books, podcasts, links) | 80% | 20% path-specific curation |
| Glossary (~50 terms) | 100% | Highlights terms relevant to current stage |
| Conversation prompts | 30% (reframed per persona) | 70% unique |
| Roadmap stages | 0% | 100% unique journeys |
| Pre/Post processing | 40% shared framework | 60% unique prompts |
| Emotional tools (jealousy, NRE) | 50% shared concepts | 50% unique prompts |

**Same topic, four framings (example — jealousy card):**

| Persona | How the card reads |
|---------|-------------------|
| Solo Curious | "When you imagine a future partner being with someone else, what comes up? Sit with that feeling." |
| Solo Experienced | "Think about the last time jealousy showed up. What was the trigger underneath the trigger?" |
| Coupled Curious | "Read this to each other: 'When I imagine you being with someone else, I feel ____.' Just listen." |
| Coupled Experienced | "When was the last time jealousy surprised you — a situation where you thought you'd be fine but weren't?" |

### Content Volume Estimate

| Path | Unique prompts | Shared (reframed) | Total |
|------|---------------|-------------------|-------|
| Solo Curious | ~80 | ~40 | ~120 |
| Solo Experienced | ~70 | ~40 | ~110 |
| Coupled Curious | ~90 | ~40 | ~130 |
| Coupled Experienced | ~75 | ~40 | ~115 |
| **Total** | **~315 unique** | **~40 × 4 = 160** | **~475 prompt variations** |

### Launch Content Priority

**Phase 1 (Launch):** Solo Curious + Coupled Curious = ~295 prompts + glossary + curated education

**Phase 2 (Month 2–3):** Add Experienced paths = ~145 additional prompts

**Phase 3 (Month 4+):** Style-specific roadmaps (polyamory, relationship anarchy, kink+NM intersection)

### Prompt Phases (purchase tiers)

| Phase | Content | Tier |
|-------|---------|------|
| 0 | Relationship Strengthening | Core |
| 1 | Foundation Conversations (40+ prompts) | Free (3) + Core |
| 2 | NM Education Modules | Education Pack |
| 3 | Hypothetical Scenarios | Scenarios Pack |
| 4 | After First Experience | Scenarios Pack |

### Prompt Model

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | The prompt question |
| `highlightWords` | [String] | Keywords highlighted via GradientText |
| `category` | PromptCategory | .prompt, .reflect, .ultimate, etc. |
| `difficulty` | PromptDifficulty | .easy → .ultimate (6 levels) |
| `isSensitive` | Bool | Triggers screenshot protection |
| `canSkip` | Bool | Whether user can skip |
| `whoStarts` | WhoStarts | .partnerA, .partnerB, .both |

### Education Library

Attached to each roadmap stage (contextual, not standalone). Also browsable as a top-level section.

```
LEARN
├── ⭐ Recommended for You (3–4 based on persona + current stage)
├── 📚 Books (curated per persona — same library, different "Start Here")
├── 🎙️ Podcasts (We Gotta Thing, Normalizing NM, Room 77, Front Porch Swingers)
├── 📺 Videos (curated playlist)
├── 💬 Communities (Reddit, lifestyle sites, local finding guide)
├── 📋 Glossary (universal — highlights terms relevant to current stage)
└── 🧭 Where Do I Start? (different entry point per persona)
```

Resources are curated, not created. The app doesn't write textbooks — it organizes the best existing resources and surfaces them at the moment they're needed.

---

## 12. Revenue Model

### Primary Conversion Architecture — The Desire Map Paywall

> **This is not a feature gate. This is the business model.**

The Desire Map mutual reveal is the primary revenue mechanic at launch. The structure:

1. **Both partners complete the Desire Map free** — 17 items, ~4.5 minutes, fully private.
2. **One matched item is revealed free** — both partners see one thing they agree on. This is the "instant personalized result" that creates the demand.
3. **Full mutual reveal unlocked at paywall** — the complete compatibility picture is the product being purchased.

The free match reveal is the hook. It proves the product works before asking for money. It is personally relevant, immediately gratifying, and impossible to replicate without completing the assessment — which means any user who sees the free match has already invested in the product. The paywall lands at peak intent.

**Where it sits in the pricing tier:** The full Desire Map reveal unlocks with Core Edition ($14.99) or the Complete Bundle ($34.99). It is the primary reason couples upgrade from free.

---

### Pricing Tiers

| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | Onboarding, assessment preview, 3 prompts, desire map teaser |
| Core Edition | $14.99 | Full scores, Phase 0+1, full desire map, boundary workshop |
| Communication Pack | +$9.99 | Drop Box (100 AI-translated messages), communication profiles |
| Education Pack | +$9.99 | Phase 2 modules, quizzes, STI resources |
| Scenarios Pack | +$14.99 | Phase 3+4, advanced boundary tools |
| Complete Bundle | $34.99 | Everything. All future content updates. |
| AI Coach (subscription) | $6.99/mo | Unlimited Drop Box, AI coach, jealousy first aid, insights, reports |

### Why One-Time + Subscription

Static content is yours forever — buying a book, not renting access. The ONLY subscription is for AI features that cost real money per use (every chat message, every transcription, every analysis). Users understand that.

### Future Freemium Consideration

The Flo Health model suggests a compelling alternative: free tier creates the habit and the data, premium unlocks the value of the data already collected. For Open Lightly this could mean:

| Free Tier | Premium |
|---|---|
| Basic check-ins (last 10 entries) | Full check-in history + pattern insights |
| Up to 3 connection cards | Unlimited connections |
| Basic jealousy log | Full jealousy history + pattern dashboard |
| 5 daily pulse entries | Full pulse history + emotional calendar |
| Community prompts (read) | Full prompt library + custom |

**Decision deferred to post-V1.0 data review.** The current one-time + subscription model ships first. Conversion to freemium considered only if D30 retention data suggests the data-compounding model would produce stronger LTV.

### Subscription Features Breakdown

| Feature | Why Subscription | Cost Driver |
|---------|-----------------|-------------|
| Unlimited Drop Box | $0.02–0.08 per AI translation, heavy users send 50+/month | Per-message API cost |
| Conversation Insights | Recording → transcription → analysis per session | Whisper + GPT per session |
| Monthly Reports | AI-generated relationship health reports | Accumulated data analysis |
| Evolving Compatibility | Quarterly re-assessment with trend analysis | Embedding + comparison |

---

## 13. Build Progress

Act 1 batches ship before Act 2 batches are polished before Act 3 batches are completed.

| Batch | Act | Scope | Status |
|-------|-----|-------|--------|
| 1–3 | 1/2/3 | Project setup, data models, enums | Done |
| 4 | 1/2/3 | Theme — AppColors, AppFonts, AppTheme, ThemeManager | Done |
| 5 | 1/2/3 | Navigation — ContentView, 5-tab structure | Done |
| 6 | 1 | Components — PromptCard, GradientText, SafeWordButton, ProgressRingView | Done |
| 7 | 1 | Feature screens — Home, Session, DesireMap, Progress, Settings | Done |
| 8 | 1/2/3 | SwiftData persistence — sessions, ratings, streaks | Done |
| 9 | 1/2/3 | Auth (Sign in with Apple + Supabase), partner pairing, sync services | Done |
| 10 | 1/2/3 | Theming (light/AMOLED), sync retry on launch | Done |
| — | 1/2/3 | Codebase audit & refactor (design tokens, shared components, dead code) | Done |
| 11 | 1/2/3 | Onboarding flow (all three-act paths + solo reflection gate) | **In Progress** |
| 12 | 1 | Content authoring — Act 1 prompts, card decks, education modules | Planned |
| 13 | 1 | Assessment / archetype classification (post-first-session) | Planned |
| 14 | 1 | Communication Pack — Drop Box + AI translation | Planned |
| 15 | 1 | AI Coach Membership | Planned |
| 16 | 3 | Bridge Cards (solo user with partner path) | Planned |
| 17 | 3 | Journal / notes system (solo path) | Planned |
| 18 | 2 | Jealousy Mapping — structured logging/decoding tool | Planned |
| 19 | 2 | Compersion Tracker — emotional logging | Planned |
| 20 | 2 | Connection Cards / Partner Roster — visual relationship network | Planned |
| 21 | 2 | Solo/Couple Check-In Rituals — structured pre/post-date check-ins | Planned |
| 22 | 2 | Daily Relationship Pulse — 30-second micro-check-in | Planned |
| 23 | 2 | Contextual Resource Library — trigger-based education | Planned |
| 24–26 | 2 | Communication Pattern Library (browsable, no recording) | Planned |
| 27–28 | 2 | Opt-in recording, transcription, alternative phrasing engine | Planned |
| 29+ | 2 | Post-conversation replay, transparency documentation | Planned |
| 30+ | 2 | Hybrid linguistic analysis (with full consent architecture) | Planned |

---

## 14. Guiding Principles

1. **This is not therapy.** It is a conversation tool. A communication skills resource. An educational framework. The line is non-negotiable. See Section 3.
2. **Privacy is the product.** Local-first. Solo reflections never shared. Screenshot protection on sensitive content. No social graph. No accounts linked to social media.
3. **The couple is the user.** Every feature asks: does this bring them closer or create friction?
4. **Buy content, subscribe to AI.** Static content is yours forever. Subscription only for features that cost real money per use.
5. **Color is earned.** The UI rewards engagement with visual richness.
6. **Safety is sacred.** Gold means stop. The safe word is always accessible, never hidden.
7. **Skip is real.** No guilt, no nagging, no re-prompting. Every "skip" is a valid choice.
8. **Normalize, don't pathologize.** The voice is a thoughtful friend, not a clinician. Every outcome — including "this isn't for us" — is valid.
9. **Structure over information.** They have enough information. They need a process for turning it into conversations.
10. **No dollar is worth an ethical violation.** If a feature could cause harm, it doesn't ship. Period.

> **The Compounding Data Principle:** Every check-in, every journal entry, every jealousy log should feel like it's building something — a picture of yourself and your relationships that gets more accurate and more valuable the longer you stay. The moment a user thinks "this app knows me better than I know myself" — that's when retention becomes organic.

---

## 15. Session System

### Card Actions

Replaces the original thumbs up/down design:

| Action | Button | What It Means | Signal |
|--------|--------|---------------|--------|
| **We Discussed This** | ✅ Primary gradient CTA | Partners talked about this card | Completion |
| **Not Ready** | ⏩ Secondary | Not ready for this topic yet | Honest signal, no shame |
| **Bookmark** | 🔖 Icon button | Save to revisit later | High intent |

**Rationale for removing thumbs up/down:**
- `CardStatus` enum (`.discussed` / `.skipped` / `.bookmarked`) tracks the meaningful signals
- "Did you talk about it?" matters more than "Did you like the card?"
- The conversation IS the engagement, not the rating tap
- Skip/bookmark data is more actionable for content improvement than 👍👎

### Card Layout (per card in session)

```
┌──────────────────────────────────────┐
│          1 of 5 • Category           │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ "Prompt text here..."          │  │
│  │                                │  │
│  │ Take turns sharing.            │  │
│  │ Listen without judgment.       │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌──────────────┐  ┌──────┐         │
│  │ ⏩ Not Ready  │  │ 🔖  │         │
│  └──────────────┘  └──────┘         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ✅ We Discussed This          │  │
│  └────────────────────────────────┘  │
│                                      │
│           🛑 Safe Word               │
└──────────────────────────────────────┘
```

### Session Summary

- Cards discussed count
- Cards skipped count ("no pressure")
- Cards bookmarked count ("saved for later")
- Feeling emoji check-in
- Encouragement text

---

## 16. Data Models

### Architecture

```
UserProfile A          UserProfile B
│                      │
└──────┐  ┌────────────┘
       │  │
       ▼  ▼
      Couple
      ├── cardProgress[]
      ├── sessionRecords[]
      └── kinkMatches[]
```

Individual data (assessment answers, kink ratings) lives on `UserProfile`.
Shared data (sessions, card progress, kink matches) lives on `Couple`.
Deleting a `Couple` does NOT delete the `UserProfile`s.

### Couple Model

```
Couple
├── id: UUID
├── createdAt: Date
├── partnerA: UserProfile?
├── partnerB: UserProfile?
├── sharedSafeWord: String          (default: "red")
├── matchesRevealed: Bool           (default: false)
├── cardProgress: [CardProgress]
├── sessionRecords: [CoupleSessionRecord]
└── kinkMatches: [KinkMatch]
```

### UserProfile Model

```
UserProfile
├── id: UUID
├── name: String
├── createdAt: Date
├── pronouns: String
├── sexualOrientation: String
├── rolePreference: String
├── userMode: String                ("solo", "couple", "curious")
├── experienceLevel: String         ("new", "some", "experienced")
├── defaultDifficulty: String       ("warm", "medium", "hot", "blazing")
├── nmFlavor: NMFlavor?
├── curiositySelections: [String]
├── surpriseMeEnabled: Bool
├── hasCompletedOnboarding: Bool
├── hasCompletedAssessment: Bool
├── mythBusterComplete: Bool
├── mythBusterSkipped: Bool
├── onboardingDropoffScreen: String?    (analytics)
├── accountId: String?                  (Sign in with Apple)
├── accountCreated: Bool
├── pairingCode: String
├── isLinked: Bool
├── partnerLabel: PartnerLabel?
├── assessmentResponses: [AssessmentResponse]
└── kinkRatings: [KinkRating]
```

---

## 17. Scoring & Matching

### Two Separate Rating Systems

| Model | Purpose | Data Type | Owner | Privacy |
|-------|---------|-----------|-------|---------|
| **RatingRecord** | Prompt card reactions during sessions | String (`"discussed"` / `"skipped"` / `"bookmarked"`) | `SessionRecord` | Shared — written together |
| **KinkRating** | Individual kink/BDSM map answers | Typed `Rating` enum (`.love` / `.curious` / `.neutral` / `.hardNo`) | `UserProfile` | Private — Hard No NEVER revealed |

`KinkRating` feeds into `KinkMatch`. `RatingRecord` feeds into session history and progress stats. They are completely separate systems.

### Hard No Protection (Defense in Depth)

Hard No ratings must **NEVER** be visible to a partner. Enforced at three levels:

| Level | Protection |
|-------|-----------|
| **Database (RLS)** | `kink_ratings` table: only owner can query. Partner cannot access this table at all. |
| **Server (Edge Function)** | `compute_kink_matches()` filters out any row where either rating = `hardNo` BEFORE writing to `kink_matches` table. |
| **Client (Swift)** | `KinkRating` model is local-only for `hardNo` items. Only `.love` / `.curious` / `.neutral` are ever sent to server for matching. `hardNo` items never leave the device. |

---

## 18. Privacy Rules

| Rule | Detail | Enforcement Level |
|------|--------|-------------------|
| Individual assessment answers | Encrypted locally. Never synced raw. Partner never sees them. | Device + Database (never uploaded) |
| Kink Hard No's | Never revealed. Never stored on server. Never queryable by partner. | Device + Server (Edge Function filter) + Database (RLS) |
| Safe word usage | Not logged. Not surfaced in stats. Not stored anywhere. | App code (no tracking call) |
| Session notes | Local only. Never synced to Supabase. | Device only |
| Push notifications | No sensitive content in notification text. | Server (Edge Function templates) |
| Backend data | Only: pairing data, completion status, domain-level scores (not raw answers), positive kink matches. | Database (RLS on every table) |
| Cross-user access | No user can query another user's data except through couple relationship. | Database (RLS policies) |
| Unauthenticated access | Zero. All queries require valid Sign in with Apple JWT. | Database (RLS) + Supabase Auth |
| Service role key | Server-side only. Never in client code. Never in git. | Code review + audit checklist |
| Encryption at rest | Kink ratings and assessment answers encrypted via CryptoKit before any storage. | Device (CryptoKit + Keychain) |

### Data Classification

| Data | Sensitivity | Storage | Encrypted | Synced to Supabase |
|------|-------------|---------|-----------|-------------------|
| Display name | Low | SwiftData + Supabase | No | Yes |
| Pronouns | Low | SwiftData + Supabase | No | Yes |
| NM Flavor | Medium | SwiftData + Supabase | No | Yes |
| Pairing code | Low (ephemeral) | Supabase only | No | Yes (expires 24h) |
| Assessment answers (raw) | High | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Assessment domain scores | Medium | SwiftData + Supabase | No | Yes (aggregated, not raw) |
| Kink ratings (individual) | Critical | SwiftData (encrypted) | Yes (CryptoKit) | Only non-hardNo, encrypted, for matching |
| Kink Hard No items | Critical | SwiftData ONLY | Yes (CryptoKit) | NO — never leaves device |
| Kink matches (positive) | Medium | SwiftData + Supabase | No | Yes (only mutual positives) |
| Session notes | High | SwiftData ONLY | No | NO — never leaves device |
| Session card statuses | Low | SwiftData + Supabase | No | Yes (discussed/skipped/bookmarked) |
| Safe word usage | Critical | NOT LOGGED | N/A | NO — never recorded anywhere |

---

## 19. Database Security Plan

### Why This Matters More for This App

This app stores the most sensitive data possible — sexual preferences, kink ratings, intimate conversation history, partner pairing status, psychological assessment answers. A breach for a to-do app is embarrassing. A breach for this app ruins lives.

### The 7 Mistakes We Will Not Make

| # | Mistake | What Happens | Our Mitigation |
|---|---------|-------------|----------------|
| 1 | No Row Level Security (RLS) | Anyone with Supabase URL reads/writes ALL data | RLS enabled on EVERY table at creation, BEFORE any data is inserted |
| 2 | API keys in frontend code | Anyone can extract keys from app bundle | Only anon key in app (safe with RLS). Service role key NEVER in client code. |
| 3 | No auth required for queries | Unauthenticated users read entire database | Sign in with Apple required before any DB access. No anonymous queries. |
| 4 | Service role key in the app | "God mode" key shipped to users | Service role key exists ONLY in Supabase Edge Functions (server-side) |
| 5 | No policies on sensitive tables | Kink ratings, messages readable by anyone | Every table has explicit USING/WITH CHECK policies per row |
| 6 | Client-side validation only | User modifies request, bypasses checks | All security enforced at database level via RLS. Client validation is UX only. |
| 7 | No encryption for sensitive fields | Breach exposes plaintext data | Kink ratings encrypted with CryptoKit before upload. Even a breach yields encrypted blobs. |

### Row Level Security Policies

**Every table gets RLS enabled and policies written BEFORE any data is inserted.**

```sql
-- ============================================
-- USER PROFILES: Only own profile accessible
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- KINK RATINGS: Private — ONLY the owner
-- ============================================
ALTER TABLE kink_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Private kink ratings"
  ON kink_ratings FOR ALL
  USING (auth.uid() = owner_id);

-- Partner can NEVER query this table for the other user.
-- Matching is done via Edge Function (server-side) that
-- filters out Hard No before returning results.

-- ============================================
-- COUPLES: Only the two linked partners
-- ============================================
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple members only"
  ON couples FOR SELECT
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

CREATE POLICY "Couple members update"
  ON couples FOR UPDATE
  USING (
    auth.uid() = partner_a_id
    OR auth.uid() = partner_b_id
  );

-- ============================================
-- KINK MATCHES: Only the couple, positive only
-- ============================================
ALTER TABLE kink_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views matches"
  ON kink_matches FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );

-- ============================================
-- ASSESSMENT STATUS: Own data + partner completion flag
-- ============================================
ALTER TABLE assessment_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Own assessment data"
  ON assessment_status FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Partner completion check"
  ON assessment_status FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
-- NOTE: Partner can see is_complete flag, NOT individual scores or answers.

-- ============================================
-- ENTITLEMENTS: Both partners read
-- ============================================
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couple views entitlements"
  ON entitlements FOR SELECT
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE partner_a_id = auth.uid()
         OR partner_b_id = auth.uid()
    )
  );
```

### Key Management

| Key | Where It Lives | Who Can Access |
|-----|---------------|----------------|
| Supabase URL | App config (public) | Anyone (by design — safe with RLS) |
| Supabase anon key | App config (public) | Anyone (by design — safe with RLS) |
| Supabase service role key | Supabase Edge Functions ONLY | Server-side only. NEVER in client code. NEVER in git. |
| User encryption key | iOS Keychain (per device) | Only the device owner via biometric auth |
| JWT tokens | iOS Keychain | Only the authenticated user |

### Pre-Launch Security Audit Checklist

```
□ RLS enabled on every Supabase table (check dashboard badges)
□ Every table has explicit SELECT/INSERT/UPDATE/DELETE policies
□ Test: unauthenticated request to any table returns 0 rows
□ Test: User A authenticated, query User B's kink_ratings → 0 rows
□ Test: User A authenticated, query User B's assessment → 0 rows
□ Test: User A in Couple 1, query Couple 2 data → 0 rows
□ Test: Query kink_matches for a couple → no Hard No items present
□ Search entire Xcode project for service role key → 0 results
□ Search entire git history for service role key → 0 results
□ Supabase anon key is the ONLY key in client code
□ Sign in with Apple is required before any database operation
□ Kink ratings encrypted before any network transmission
□ Hard No items never included in any Supabase write operation
□ Push notification text contains no sensitive content
□ Screenshot protection active on: assessment, kink map, results, notes
□ App lock (Face ID / Touch ID) enabled by default
□ Privacy policy accurately describes data handling
□ Run Supabase security advisor (dashboard tool)
```

### Incident Response Plan

If a security issue is discovered:
1. Immediately revoke all active sessions (Supabase dashboard)
2. Immediately rotate the anon key and service role key
3. Assess what data was exposed and for how long
4. Notify affected users within 72 hours (GDPR/CCPA requirement)
5. Document the root cause and fix
6. Post-mortem — update security policies to prevent recurrence

---

## 20. Supabase Cost Projections

### Cost by User Scale

| Monthly Active Users | Plan | Base | MAU Overage | Est. Total/mo | Revenue Needed to Cover |
|---------------------|------|------|-------------|--------------|------------------------|
| 0 – 50,000 | Free | $0 | $0 | $0 | Nothing |
| 50,001 – 100,000 | Pro | $25 | $0 (100K included) | ~$25–35 | 2–3 paid users |
| 100,001 – 250,000 | Pro | $25 | 150K × $0.00325 = $488 | ~$525 | 53 paid users |
| 250,001 – 500,000 | Pro | $25 | 400K × $0.00325 = $1,300 | ~$1,400 | 140 paid users |
| 500,001 – 1,000,000 | Pro/Team | $25–599 | 900K × $0.00325 = $2,925 | ~$3,000–3,500 | 350 paid users |

### Hidden Cost Triggers

| Resource | Free Limit | Pro Limit | Overage Cost | When It Bites |
|----------|-----------|-----------|-------------|--------------|
| Database size | 500 MB | 8 GB | $0.125/GB | ~100K users with kink ratings + sessions |
| Bandwidth (egress) | 5 GB | 250 GB | $0.09/GB | Real-time sync for couples is chatty |
| File storage | 1 GB | 100 GB | $0.021/GB | Only if profile photos added later |
| Compute | Shared CPU | $10 credit | Varies | If real-time pairing feels slow |

### Break-Even Context

At Y1 target of 2,000–5,000 paying couples:
- Supabase cost: **$0** (well under 50K MAU)
- App revenue: $50,000–$80,000
- Backend costs are irrelevant until app is already profitable

> **Note:** Free tier projects pause after 1 week of inactivity — upgrade to Pro ($25/mo) before any real users to prevent this.

---

## 21. Expansion Roadmap — Acts 2 & 3

Each expansion is a marketing shift as much as a feature release. The tools are largely present in architecture at V1.0; what changes at each act milestone is the front-door story and who we tell it to.

### Act 2 Expansion — V1.1 (30–60 days post-launch)

**Marketing shift:** *"For people doing non-monogamy intentionally."* Experienced ENM practitioners who downloaded the app out of curiosity discover it has operational infrastructure they've never had. This expansion surfaces what was already present.

| Feature | User Type | Rationale |
|---|---|---|
| Connection Cards / Partner Roster | Both | Infrastructure — other features (vault, check-ins, logs) link to connections |
| Solo Date Check-In / Self Check-In | Both | Structured post-date ritual. Natural evolution of solo reflection. |
| Compersion Tracker | Both | Low-friction emotional logging. Counterweight to jealousy work. |
| Daily Relationship Pulse | Both | 30-second daily habit. Data compounds → retention compounds. |
| Smart Contextual Notifications | Both | Personalized nudges based on logged data. Max 1/day, all user-adjustable. |
| Contextual Resource Library | Both | Education surfaced at the right moment — triggered by logging activity. |
| Insight Engine — Pattern Surfacing | Both | Weekly/monthly insights from logged data. Core retention mechanic. Needs data from V1.0 usage to work. |
| Emotional Texture Calendar | Both | Calendar layer showing emotional color per day. Needs pulse data. |

### Act 2 Continued — V1.2 (60–120 days post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Jealousy Mapping | Both | Dedicated in-the-moment tool. Treats jealousy as information, not failure. |
| Agreements Vault | Partnered | Structured, per-partner agreement storage. Requires connection roster first. |
| Discovery Journal | Solo | Prompted private journal for self-discovery. Extends reflection system. |
| Non-Negotiables Document | Solo | Personal values/boundaries document. Living reference, not one-time fill. |

### Act 3 Expansion — V1.2+ (Marketing shift accompanies feature polish)

**Marketing shift:** *"For people who take relationships seriously. All kinds of relationships."* Solo users are explicitly invited. The product reveals it was never about having a partner — it was always about doing the work intentionally. The solo path has existed since V1.0; this is when we tell that story publicly.

Solo-specific polish, bridge cards, and expanded solo roadmap content ship as part of the Act 3 marketing push. No architectural changes required — the routing has always been there.

### V1.5 (4–8 months post-launch)

| Feature | User Type | Rationale |
|---|---|---|
| Anonymous Community Feed | Both | Context-mapped social layer. Requires Pulse + logging features at critical mass first. Moderation cost too high pre-scale. |
| Relationship Report (Exportable) | Both | PDF summary for therapist/coach use. Only meaningful with significant logged history. |

### V2.0+ (Far Future Considerations)

| Feature | Notes |
|---|---|
| Your Year, Lightly | Annual cinematic retrospective. Spotify Wrapped for your relational year. Hidden from users with < 6 months active logging — surfaces when earned, not unlocked. Not named in scope yet. |
| Multi-Partner Calendar | Scheduling + emotional texture overlay. High complexity. |
| NRE Navigator | Second-order feature for active new connections. |
| Polycule Network Visualizer | Requires populated roster. |

---

## 22. Anonymous Community Feed — V1.5 Design Principles

> The feed is not a forum bolted onto a tracking app. It is where people who already know themselves — because the app taught them — come to locate their experience within a larger map of human ENM life.

### The Core Differentiator From r/nonmonogamy

Reddit's problem: posts are the atomic unit. Every new person with a jealousy spiral creates a new post, gets 12 replies saying "communicate with your partner," and the collective knowledge never compounds. Open Lightly's feed inverts this.

**The post is a last resort. The default action is finding yourself in what already exists.**

### Pre-Post Mapping Flow

When a user opens "Share something," they don't get a text field. They get a short framing funnel:

1. *What kind of thing is this?* — Processing something difficult / Sharing a win / Asking for perspective / Something I've never seen discussed
2. *What's at the center of it?* — Tags drawn from the app's vocabulary (jealousy, compersion, NRE, bandwidth, agreements, endings, metamour dynamics, etc.)

The app then surfaces: **"Here's what others have shared from a similar place"** — a visual cluster of existing posts mapped by emotional similarity, not keyword match. If a user finds themselves in an existing post, they react and they're done. They found their people without adding noise.

Only if nothing matches does the compose screen open — with nearby posts visible, relevant tags pre-suggested, and a prompt: *"What's the angle nobody's captured yet?"*

### Post Context Layer

Posts optionally carry relational context the app already knows:
- *"Writing from: 8 months into ENM, coupled primary structure, recently added a new connection"*
- No name, no photo — but structural context that makes advice actually calibrated

This is the thing Reddit can never replicate: people arriving with language and self-knowledge the app built for them.

### Feed Structure

- **Resonance clustering** — not chronological, not upvote-ranked. Posts bookmarked by users at similar stages cluster to the surface.
- **"Still true" signal** — users can mark a post weeks or months later when it still reflects something real. Posts with sustained "still true" signals become the durable knowledge base.
- **Sections:** Processing / Wins / Never discussed this before / Questions
- **Reactions:** Heart / Resonate only — no downvotes, no public reply counts on individual posts

### Access Model

- Read-only on free tier
- Posting unlocked on Premium or V1.5+ active user tier
- Moderation architecture designed before launch, not after

---

## 23. Your Year, Lightly — V2.0 Design Principles

> Spotify Wrapped works because it makes you the protagonist of a story you were already living. Open Lightly's version carries real emotional weight: you processed jealousy 14 times, logged compersion 9 times, your bandwidth was lowest in October, you added three connections and closed one with grace.

### Eligibility Gate

The feature does not exist for ineligible users — no locked state, no teaser. It surfaces when earned:
- ≥ 6 months of active logging (not installs)
- ≥ 20 check-ins or session completions
- ≥ 1 connection card with meaningful history

### The Experience Arc

A cinematic scroll — one reveal at a time, each screen its own moment. Opens not with stats but with a tone read:

> *"2025 was a year of expansion for you. You moved toward things that scared you — and most of them were worth it."*

Derived from actual log data: net emotional trajectory, connections opened vs. closed, jealousy trend, bandwidth patterns. The app already knows this. It just hasn't said it out loud yet.

### Postcard System

Each significant moment gets its own designed postcard — shareable, beautiful, optionally private. Not a screenshot of a log. A *designed artifact* that transforms data into memory.

**Milestone cards** — first-of-kind events the user tagged or the app inferred:
- First new connection added to an existing relational structure
- First agreement renegotiation the user initiated
- First time logging compersion after previously only logging jealousy
- Sexual and experiential milestones the user tagged (first club night, first moresome, etc.) — app never labels or assumes; only celebrates what the user explicitly logged

**Emotional arc cards:**
- Jealousy patterns: frequency, most common triggers, and whether the pattern shifted over the year
- Compersion log highlights: the moments that made the list
- Bandwidth rhythm: highest and lowest capacity months

**Connection cards** — one per active relationship:
- Time together logged, sessions run, most-used card category
- A pulled quote from a reflection they wrote (their words, their meaning)

**The numbers card:**
- Check-ins completed / Reflection entries written / Agreements created or revised
- Connections active at start vs. end of year
- Emotional arc summary in one line

### Sharing Design

- **Private first** by default — the full experience is personal
- **Shareable postcards** designed to carry meaning without requiring context. *"I logged compersion 23 times in 2025"* means everything to ENM people and reads as emotional growth to everyone else
- **Partner share** option — send your Year card to a partner so they can see your year from the inside. No comparison, no leaderboard. Just: *"here's what this year looked like for me"* — a conversation starter no other app can create

### Name

**Your Year, Lightly** — the app handing something back to you, not performing for you.

---

## 22. Professional-Grade Engineering — Guardrails for Vibe Coders

> **Context:** This section exists because vibe coding + AI assistants can produce apps that look finished but have silent, catastrophic failure modes. This app stores the most sensitive data users will ever hand an app. The bar is higher than a to-do list. These rules are the difference between a hobby project and a shippable product.

---

### The Core Problem With Vibe Coding

AI writes code that works for the happy path. It doesn't write code that handles the 37 things that can go wrong. You have to know what questions to ask — and this section gives you those questions.

**The pattern to break:**
```
❌ Vibe: Write code → it works in simulator → ship it
✅ Professional: Write code → ask "what happens when this fails?" → handle failure → test edge cases → then ship
```

---

### 1. Error Handling — The #1 Vibe Coder Blind Spot

AI-generated code almost always has this pattern:
```swift
// What AI writes (dangerous)
let data = try await supabase.from("profiles").select().execute()

// What it should be
do {
    let data = try await supabase.from("profiles").select().execute()
} catch {
    // Log it. Show user something meaningful. Don't crash silently.
    logger.error("Profile fetch failed: \(error.localizedDescription)")
    await MainActor.run { self.errorState = .networkFailure }
}
```

**Every network call needs:**
- A success path
- A failure path
- A loading state
- A retry mechanism (or at least a retry button)

**The three states every async view needs:**
```
.loading   → show skeleton / spinner
.loaded    → show content
.error     → show "Something went wrong" + retry button (NOT a blank screen)
```

A blank white screen when the network fails isn't UX — it's a bug that looks like a feature.

---

### 2. SwiftData Safety — Silent Data Destruction

SwiftData schema changes are the most dangerous thing you can do to existing users. A model change that worked fine in your simulator will wipe a real user's data if migrated wrong.

**The rule: Every SwiftData model change that isn't purely additive requires a migration plan.**

| Change Type | Safe? | What to Do |
|-------------|-------|-----------|
| Add a new optional property | ✅ Safe | Just add it |
| Add a new required property | ⚠️ Dangerous | Must provide default value or migration |
| Rename a property | ❌ Destructive | Write a `MigrationPlan` with `MigrationStage` |
| Change a property type | ❌ Destructive | Write a migration |
| Delete a property | ⚠️ Careful | Data is gone — intentional? |
| Rename a model | ❌ Destructive | Write a migration |

**What a migration looks like:**
```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]

    static var stages: [MigrationStage] = [
        migrateV1toV2
    ]

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            // transform data here
        }
    )
}
```

**Before shipping any model change:** Delete the app from your simulator, reinstall fresh, verify the new schema works from scratch. Then verify migration from the old schema works.

---

### 3. Main Thread Violations — The Crash You Won't See in Testing

SwiftUI requires UI updates on the main thread. Supabase callbacks and async operations often return on background threads. Violating this crashes the app — sometimes immediately, sometimes randomly in production.

```swift
// ❌ Crashes in production (fine in simulator sometimes)
func fetchProfile() async {
    let profile = try await profileService.fetch()
    self.userProfile = profile  // ← UI update on background thread
}

// ✅ Correct
func fetchProfile() async {
    let profile = try await profileService.fetch()
    await MainActor.run {
        self.userProfile = profile
    }
}
```

**The rule:** Any property marked `@Published` or that drives SwiftUI views must only be mutated on `@MainActor`. Mark your ViewModels `@MainActor` at the class level to prevent the entire class of bugs:

```swift
@MainActor
class SessionViewModel: ObservableObject {
    @Published var cards: [PromptCard] = []
    // All mutations here are automatically main-thread safe
}
```

---

### 4. The Empty State Problem

Every list, every collection, every result set can be empty. Vibe coders handle the case where data exists. Professional apps handle all three cases:

| State | What to Show |
|-------|-------------|
| Loading | Skeleton / spinner |
| Empty (no data yet) | Helpful message + CTA ("No sessions yet — start your first one") |
| Empty (no results for filter) | Explanation ("Nothing matches") |
| Error | "Something went wrong" + retry |
| Has data | The actual content |

A `ForEach` over an empty array shows nothing. Users think the app is broken.

```swift
// Always wrap lists with state awareness
if cards.isEmpty && !isLoading {
    EmptyStateView(message: "No cards yet. Start a session to explore.")
} else {
    ForEach(cards) { card in CardView(card: card) }
}
```

---

### 5. Sensitive Data Must Never Hit the Console

Xcode's console and `print()` statements are your friend during development. They are a data breach in production.

**Never log:**
- Kink ratings or any assessment answers
- User names paired with relationship data
- Authentication tokens or session IDs
- Pairing codes
- Any property from `UserProfile` beyond `id`

**Use a proper logger:**
```swift
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "Sessions")

// Safe — category only, no user data
logger.info("Session started")

// NEVER do this
print("User \(user.name) rated kink item \(kinkItem.title) as \(rating)")
```

**Before shipping:** Search the entire codebase for `print(` and audit every single one. Remove or replace with `logger`. Build for release and check the console — if sensitive data appears there, it's a bug.

---

### 6. Git Hygiene — One Mistake That Can't Be Undone

Secrets pushed to git are compromised, full stop. Rotate them immediately. Deleting the commit doesn't help — git history is forever, and bots scrape GitHub for secrets within minutes of a push.

**Your `.gitignore` must include:**
```
# Secrets
Config.xcconfig
*.xcconfig
.env
Secrets.plist

# Xcode noise
*.xcuserstate
xcuserdata/
DerivedData/

# OS junk
.DS_Store
```

**The `Config.xcconfig` pattern for secrets:**
```
// Config.xcconfig (git-ignored)
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

```swift
// Config.swift — reads from build settings, never hardcodes
struct Config {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
}
```

**Branching strategy (simple, actually follow it):**
```
main          → only tested, working code. Never commit directly.
dev           → integration branch. Test here before merging to main.
feature/xxx   → one branch per feature. Merge via PR to dev.
```

---

### 7. Two Environments: Dev and Production

The #1 way vibe coders corrupt real user data: running development builds against the production database.

**You need two Supabase projects:**
- `openlightly-dev` — your sandbox. Blow it up, reset it, experiment freely.
- `openlightly-prod` — real users. Touch only for intentional releases.

**How to switch:**
```
// Dev scheme → points to openlightly-dev Supabase
// Prod scheme → points to openlightly-prod Supabase

// In Xcode: Product → Scheme → Manage Schemes
// Create "Open Lightly Dev" and "Open Lightly Prod"
// Each scheme uses a different Config.xcconfig
```

**The rule:** Run the Dev scheme 99% of the time. Switch to Prod only for TestFlight builds and releases. If you're ever unsure which environment you're pointed at, check before touching the database.

---

### 8. StoreKit Testing — Don't Find Out at Submission

StoreKit is the most "works in simulator, breaks in production" layer in iOS development.

**Testing checklist before submission:**
```
□ Test purchase flow with StoreKit sandbox (not simulator mock)
□ Test restore purchases on a fresh device (users WILL do this when they get a new phone)
□ Test what happens when a purchase is interrupted (network drops mid-transaction)
□ Test subscription expiry — does the app correctly downgrade access?
□ Test family sharing (does one family member's purchase unlock for others? Is that intended?)
□ Verify receipt validation happens server-side, not just client-side
□ Test with a StoreKit sandbox account, not your Apple ID
```

**Receipt validation:** If you validate purchases client-side only, users can spoof receipts and get paid content for free. For this app's scale, client-side validation is acceptable at launch — but document it as a known limitation to address before scaling.

---

### 9. App Store Submission — Common Rejection Reasons

Apple rejects apps for predictable reasons. Know them before you submit.

| Rejection Reason | How to Avoid |
|-----------------|-------------|
| **Guideline 1.1.6** — Dating/social apps must have content moderation | This is NOT a dating app — make sure the App Store listing, screenshots, and app description are clear about that. |
| **Guideline 5.1.1** — Privacy policy required | Write one before submission. It must accurately describe all data collected and how it's used. |
| **Guideline 3.1.1** — All digital goods sold via IAP | You cannot use Stripe, PayPal, etc. for in-app purchases. StoreKit only. |
| **Guideline 2.1** — App crashes or has major bugs | Test on a real device (not just simulator). Test every purchase flow. |
| **Guideline 5.1.2** — Sensitive data handling | Must have a privacy policy link in the App Store listing AND in the app. |
| **Guideline 2.3.3** — App description misleading | Screenshots must show actual app UI, not mockups. |
| **Guideline 4.2** — Minimum functionality | Free tier must have enough functionality to demonstrate value. |
| **Metadata rejection** — screenshots too similar | Every screenshot must show clearly different content. |

**Before submitting, run your App Store listing through this lens:**
> "Does this sound like a hook-up app, a therapy app, or a sex app?"

It must sound like none of those. It's a conversation tool for couples. Review every word of the listing with that framing.

---

### 10. Memory Management — Retain Cycles

SwiftUI and `@Observable` handle most memory management automatically. But `async`/`await` and closures can still create retain cycles that silently grow your app's memory footprint.

**The pattern to watch:**
```swift
// ❌ Potential retain cycle — self holds task, task holds self
func loadCards() {
    Task {
        self.cards = await fetchCards()  // strong capture of self
    }
}

// ✅ Weak capture when appropriate
func loadCards() {
    Task { [weak self] in
        guard let self else { return }
        self.cards = await fetchCards()
    }
}
```

**How to detect:**
- In Xcode: Debug → Memory Graph Debugger during a session
- Look for objects that should have been deallocated still showing up
- Use Instruments → Leaks for a full leak report before submission

---

### 11. Accessibility — Not Optional

Apple reviews for accessibility. Users with disabilities use your app. And VoiceOver users in the NM community exist.

**Minimum requirements:**
```swift
// Every interactive element needs a label
Button(action: skipCard) {
    Image(systemName: "forward.fill")
}
.accessibilityLabel("Skip this card")

// Images that convey meaning need descriptions
Image("desire-map-result")
    .accessibilityLabel("Desire map showing high compatibility in emotional connection")

// Images that are decorative should be hidden
Image("background-gradient")
    .accessibilityHidden(true)
```

**Test with VoiceOver (Settings → Accessibility → VoiceOver):** Navigate the entire onboarding flow without looking at the screen. If you can't complete it, real users can't either.

**Dynamic Type:** Go to Settings → Accessibility → Display & Text Size → Larger Text → max out the slider. Run your app. If text clips, overlaps, or disappears, you have layout bugs.

---

### 12. Offline Behavior — Design for No Connection

Users will open this app in a cabin, on a plane, in bed with their phone on airplane mode. The app must not be useless offline.

**Local-first architecture (already your model) means:**
- App loads from SwiftData without network → show local data immediately
- Network sync happens in background
- If sync fails → local data is still visible → show a subtle "Sync pending" indicator
- Never show a loading spinner indefinitely — set a timeout (10-15 seconds) and show an error state

**The offline checklist:**
```
□ Turn on airplane mode
□ Open the app
□ Does it load? (It should — from SwiftData)
□ Can you start a session? (Yes — cards are local)
□ What happens when you complete a card? (Queues for sync)
□ Turn wifi back on
□ Does queued data sync? (SyncManager handles this)
□ Is nothing lost? (The answer must be yes)
```

---

### 13. Testing — The Minimum You Actually Need

You don't need 100% test coverage. You need tests for the things that will ruin your users' experience if they break.

**Write tests for:**

| What | Why |
|------|-----|
| Hard No never included in kink match payload | The #1 privacy guarantee. If this breaks silently, you've violated user trust catastrophically. |
| Pairing code format validation | Bad codes cause failed pairings. Users blame the app. |
| Assessment score calculation | Wrong scores feed wrong content routing. The whole personalization engine breaks. |
| SwiftData model persistence | Basic smoke test: save a UserProfile, restart the container, verify it's still there. |
| StoreKit entitlement checks | Verify paid content gates work. Verify free users can't access paid content. |

```swift
// Example: The most important test in the app
func testHardNoNeverIncludedInMatchPayload() {
    let ratings = [
        KinkRating(itemId: "item1", rating: .love),
        KinkRating(itemId: "item2", rating: .hardNo),  // Must never appear in payload
        KinkRating(itemId: "item3", rating: .curious),
    ]
    let payload = KinkMatchService.buildPayload(from: ratings)
    XCTAssertFalse(payload.contains(where: { $0.itemId == "item2" }),
                   "Hard No item must never be included in sync payload")
}
```

**How to run:** Cmd+U in Xcode. Run before every TestFlight build.

---

### 14. Crash Reporting — Know When Your App Breaks in the Wild

You won't be there when real users hit bugs. You need to be notified.

**At minimum: Enable Xcode Organizer crash reports**
- Xcode → Window → Organizer → Crashes
- Apple sends you symbolicated crash reports automatically for App Store builds
- Check this weekly after launch

**Better: Add a free crash reporter**
- [Crashlytics (Firebase)](https://firebase.google.com/products/crashlytics) — free, industry standard
- Zero data privacy concerns (just crash stack traces, no user data)
- Setup is ~30 minutes: add SDK, one line in `AppDelegate`/`App.swift`, done
- You get an email every time a new crash type is discovered

**The rule:** Never go more than a week post-launch without checking crash reports.

---

### 15. Performance — Profile Before It's Too Late

Slow apps get deleted. The simulator lies — it runs on a Mac CPU. Real iPhones, especially older models (iPhone 12, iPhone 13), will expose performance issues the simulator hides.

**Test on a real device — specifically:**
- The oldest iPhone you want to support
- iPhone with low storage (< 5GB free) — storage pressure slows SwiftData
- While other apps are running in background

**Instruments (Xcode → Open Developer Tool → Instruments):**

| Instrument | What It Catches |
|------------|----------------|
| Time Profiler | Functions taking too long (scroll lag, slow loads) |
| Core Data / SwiftData | Slow fetches, N+1 query problems |
| Leaks | Objects that should be freed but aren't |
| Network | Unnecessary requests, slow API calls |

**The one SwiftData performance mistake to avoid:**
```swift
// ❌ N+1 problem — fetches each card separately in a loop
for session in sessions {
    let cards = session.cards  // Each access triggers a fetch
}

// ✅ Fetch everything you need upfront with a predicate
@Query(sort: \.createdAt, order: .reverse) var sessions: [SessionRecord]
// SwiftData pre-fetches relationships when declared this way
```

---

### 16. The Vibe Coder Anti-Pattern Checklist

Run through this before every significant PR or TestFlight build:

```
SECURITY
□ No hardcoded API keys, passwords, or secrets anywhere in the code
□ `Config.xcconfig` is in .gitignore and not in the git history
□ `print()` statements don't log any user data
□ Service role key is not in any client-side file

DATA SAFETY
□ No SwiftData model changes without a migration plan
□ Tested fresh install (delete app, reinstall, verify onboarding works)
□ Tested upgrade from previous version (don't delete, just update)
□ Hard No kink ratings never included in any server payload

ERROR HANDLING
□ Every async function has a do/catch or .catch handler
□ Every view has a loading state, empty state, and error state
□ No force-unwrap `!` on values that could realistically be nil
□ Network failures show a user-facing message, not a blank screen

UI/UX
□ Tested with airplane mode on
□ Tested with Dynamic Type at maximum size
□ Tested with VoiceOver on (at least onboarding)
□ Tested on a real device (not just simulator)
□ All lists handle empty state gracefully

PERFORMANCE
□ No blocking operations on the main thread (no `Thread.sleep`, no heavy sync work)
□ Heavy work (JSON parsing, encryption, sync) runs on background Task
□ Scrollable lists use lazy loading (LazyVStack, LazyVGrid, not VStack)

STORE
□ Tested purchase flow with StoreKit sandbox
□ Tested restore purchases on a fresh install
□ All paid content correctly gated behind entitlement check

BEFORE TESTFLIGHT
□ Build in Release configuration (not Debug)
□ Run on a real device in Release mode
□ Check Xcode Organizer for any existing crash reports
□ Run Cmd+U — all tests pass
```

---

### 17. The Questions to Ask Claude/AI When Vibe Coding

AI assistants write code that works. Your job is to ask the questions that surface what breaks. Add these to any prompt where you're implementing something real:

```
After every code generation, ask:
1. "What happens if this network call fails?"
2. "What happens if the user has no internet connection?"
3. "What happens if this data is nil or empty?"
4. "Is there any user data being logged or printed here?"
5. "Does this run on the main thread? Should it?"
6. "What happens if the user leaves this screen mid-operation?"
7. "Is there any way this could expose one user's data to another user?"
8. "What's the migration path if I need to change this SwiftData model later?"
```

These 8 questions, asked consistently, are worth more than a CS degree for shipping a safe, reliable app.

---

### 18. The Honest Scale of What You're Building

This isn't meant to intimidate — it's meant to calibrate:

| App Category | Consequences of a Bug |
|-------------|----------------------|
| To-do app | User re-enters a task |
| Social app | User sees wrong posts |
| **This app** | User's kink preferences exposed to their partner, therapist, family, employer |

The stakes are genuinely high. The data is genuinely sensitive. That's not a reason not to build it — it's a reason to build it right.

The professional bar isn't about having a CS degree. It's about knowing which questions to ask and building the habits (error handling, environment separation, testing the unhappy path) that prevent silent failures.

You have something most CS graduates don't: you understand your users deeply, you've thought carefully about ethics, and you have domain knowledge that can't be taught in a classroom. The technical guardrails above can be learned. The judgment you bring to the product is harder to acquire.

**Build carefully. Ship confidently.**

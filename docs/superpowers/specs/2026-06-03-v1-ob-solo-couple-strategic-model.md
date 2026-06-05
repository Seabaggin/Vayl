# Vayl V1 — OB & Solo/Couple Strategic Model

**Date:** 2026-06-03
**Status:** Approved (strategic synthesis — anchors the OB-sequence + solo-loop specs)

This is a strategic-design synthesis, not a code task list. It fills the big-picture
gaps for onboarding (OB): how it makes the **couples** experience data-rich, how
**solo** gets a clear identity, what the OB's personalized-deck payoff actually
*does*, and the **optimal build path** for V1.

The model corrects one earlier instinct: the standalone solo "exploration game"
(map / territory / lore / branching scenarios) is a **second content engine for
experienced explorers** — it is explicitly **Vayl 2.0**, not the solo answer for V1.

---

## 1. V1 Scope & Positioning — "narrow the product, not the door"

- **Target market:** new / newer-NM couples who need help transitioning. The
  more-ready partner often arrives first — sometimes hesitant (fear/shame),
  sometimes already in it together.
- **V1 = ONE journey, end to end:** the new-NM couple — *including its
  hesitant-solo on-ramp*. Solo is not a third audience; it is the **front door of
  the one audience**.
- **Gate effort + story, not access.** Anyone can sign up; the entire V1
  (onboarding, content, marketing, first-run) is built for the target. Experienced
  / no-drama-solo users get the couple journey **as-is, with zero bespoke
  features** — capture their behavior to inform 2.0.
- **Deferred to 2.0:** the standalone solo exploration game; depth for experienced
  couples; the broader "relationship toolbox for all experience levels."
- **Don't pre-announce the expansion.** Ship quietly; let traction earn it.
- **The moat is the journey, not the format.** "NM Paired with better features" is
  a strong, legible launch identity — but the defensibility is the **guided
  transition + the earned solo→couple arc + the Desire Map**, not the couples-app
  wrapper. Do not skimp on the journey to look like Paired.

---

## 2. The Data Layers (where richness lives)

| Layer | What it holds | Notes |
|---|---|---|
| **Individual OB** (self-only, identical for all) | name, gender + pronouns, age, experience level (`NMStage`), etc. | **One gender spin only** — partner self-provides via pairing. Builds the stable personal profile + the starter deck. |
| **Desire Map** (existing feature) | the couple-level data no individual profile holds | **This is the real couple ceremony.** Both partners privately rate desires (`yes`/`curious`/`notForUs`; `notForUs` never leaves device); reveal shows `mutual`/`adjacent` matches. Couple richness lives here. |
| **Pairing** | the account link | **No ceremony of its own** — the Desire Map is the ceremony, and (for new couples) the first couple deck follows it. |
| **Profile settings** | relationship structure, tenure, NM stage | The **updatable** layer — these evolve over time and shouldn't be frozen in OB. |
| **Session-start** | present-tense situation + intent | Dynamic layer, refreshed every session (per existing refined-OB plan). |

Self-only impact: `OnboardingData.genderB/pronounsB` get populated **via pairing**,
not OB spin 2 — the second spin is removed.

---

## 3. The Card / Deck Model & the Starter-Deck Payoff

**Ground truth in the codebase:** `Deck` is **authored JSON** (e.g. "the-opener" =
hand-written cards with context beats, gendered NM cards, closing rituals).
`CardSession` is **couple-owned** ("sessions belong to a couple, not individuals").
`PlayView` is still a stub. `VaylDirector.evaluateOpenerDeckType()` **already** maps
OB curiosity data → an `OpenerDeckType`, and the OB reveal already foil-wraps a deck
you tear open.

**The starter deck = SELECT, don't generate.** The OB collects enough to assemble a
personalized 5-card starter deck by **selecting real authored cards** (extend
`evaluateOpenerDeckType()` / register + intensity + gender filters), so it stays
on-craft. No text synthesis.

**Selection keys off `NMStage`, not just emotional register.** `OpenerDeckType` today
is only `.anxious` / `.excited` (a tone/stakes split) — **both implicitly new-couple
content**, framed *anticipatorily* ("what insecurities do you *expect*," "jealousy
*will* show up"). Experienced couples need a **reflective** stance (what you've
renegotiated, what surprised you, a jealousy moment you handled). This is the *one*
piece of experienced-couple consideration worth a little V1 effort, because a
condescending opener actively **repels** the very users we want to capture for 2.0
signal. Decision — **light reflective swap (NMStage-gated):** keep the evergreen
relationship cards, swap the ~4 anticipatory NM-primer cards (the-opener 06/07/08/10)
for retrospective ones. The same NMStage-keyed selection also prevents the individual
**starter deck** from handing experienced users beginner framing. A full reflective
opener deck remains 2.0.

**How the 5 cards are used — _(recommendation: playable first session)_:**
- The starter deck is a **playable first session**, not a mirror or a teaser.
- **Solo** plays a **reflection-weighted** cut (skew toward `reflect`-type and
  "understand yourself" cards — genuinely playable alone, never awkward, never a
  locked tease).
- The **same deck becomes the couple's opener when they pair** — solo work carries
  forward, nothing wasted.

**Two-tier ceremony:**
1. **Personal starter deck** — torn open at the end of individual OB (about *you*).
2. **Couple's first deck** — earned *after* the Desire Map (about *us*, grown from
   both starter decks + match data).

---

## 4. Solo Identity — "Get ready to bring it up"

- **Solo = the pre-couple on-ramp** for the more-ready partner
  (`appMode.solo` = "in a relationship, conversation hasn't happened yet").
- **Core promise:** clarify what you actually want, work through the fear/shame,
  build the language + confidence to have the conversation with your partner.
- **Win condition = the partner invite, EARNED.** It mirrors the Desire Map reveal
  as the couple payoff: a celebrated, earned milestone — **not** a time-based nag.
  This is the answer to the friction problem (value gated behind both partners
  buying in): solo delivers standalone value *and* manufactures the desire to bring
  the partner in.
- **Everything carries forward** — starter deck, reflections, optionally
  pre-filled *private* Desire Map ratings — so the couple starts further along.
  This is also why "best case, they sign up de facto together" still works: the
  couple just begins further down the path.
- **Affirmation lives in research, not praise:** "this is real, studied,
  navigable" — a scoped-down version of the "lore" idea — makes the hesitant user
  feel normal and informed without building the full 2.0 exploration engine.

**Detailed spec:** `docs/superpowers/specs/2026-06-03-solo-onramp-conversation-prep-design.md`
— the "get ready to bring it up" loop (read the fear → clarify your ask →
partner-context read → craft + rehearse the words → pre-mortem/reframe → earned
invite). Identity is locked; exact loop still needs an on-device feel pass before
Swift (per the Build Protocol).

---

## 5. The OB Sequence (principles; exact phase list deferred)

There are **competing in-flight specs** — `docs/refinedonboarding.md` (more
aggressive: cuts Context + Compass, adds Demo + Tenure) vs.
`docs/superpowers/specs/2026-06-03-ob-flow-compass-review-redesign.md` (drops
Compass only, keeps Context). **Reconcile these in a dedicated OB-sequence spec**;
this document only sets the principles they must satisfy:

- **Self-only**, identical for everyone (one gender spin).
- **Stable profile only** — dynamic needs move to session-start.
- **Short**; ceremony reserved for genuine identity disclosures, not surveys.
- **Payoff = tear open the personalized starter deck.**
- **Demo phase _(recommendation: keep as "the promise")_** — one universal card
  lands *before* any disclosure, and the end-of-OB reveal fulfills it ("now here
  are 5 that are yours"). Low-cost to cut if it doesn't test well on device.

---

## 6. Recommended Build Path (V1 sequencing)

1. **Reconcile + finalize the OB-sequence spec** (self-only, two-tier ceremony,
   starter-deck payoff) — resolves the two competing docs.
2. **Starter-deck assembly** — extend `evaluateOpenerDeckType()` to *select* a
   personalized 5-card deck; define the solo reflection-weighted cut.
3. **Solo on-ramp loop** — the "get ready to bring it up" arc + earned-invite
   ceremony (its own spec first; feel-verified before Swift).
4. **Carry-forward plumbing** — solo artifacts persist and seed the couple
   experience on pairing (incl. optional private pre-filled Desire Map ratings).
5. **Couple path polish** — Desire Map as the ceremony, couple's first deck after
   it; `PlayView` / session flow off the stub.

Each step follows the Build Protocol: one named segment, a done condition verified
on device ("feel is correct," not "build succeeds"), and timing/feel proven in a
reference before being written into Swift.

---

## 7. Validation (how we know it worked)

Validated by **metrics + device feel**, not unit tests:

- **Thesis metric — solo→paired conversion:** does the gamified on-ramp actually
  earn the invite? The single number that proves the model.
- **Couple retention** through the first authored decks.
- **Desire Map completion rate** per couple.
- **On-device feel passes** on the OB reveal and the solo earned-invite moment —
  the ceremony has to *land*, per the Build Protocol.

---

## Out of Scope (V1) / Vayl 2.0

- Standalone solo **exploration game** (map / territory / lore / branching
  scenarios + adaptive depth).
- **Depth for experienced** couples and singles.
- Broader **relationship toolbox** across all experience levels.
- Public **expansion announcements** — earned by traction, not promised up front.

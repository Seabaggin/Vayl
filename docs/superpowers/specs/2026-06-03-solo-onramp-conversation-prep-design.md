# Solo On-Ramp — "Get Ready to Bring It Up" (Conversation Prep)

**Date:** 2026-06-03
**Status:** Design (conceptual — needs on-device feel pass before Swift, per Build Protocol)
**Parent:** `docs/superpowers/specs/2026-06-03-v1-ob-solo-couple-strategic-model.md`

---

## Purpose

The V1 solo experience for the **more-ready, hesitant partner** in a new/newer-NM
couple. Its job: help someone who is *scared to bring NM up with their partner*
clarify what they want, build the words, rehearse the conversation, and walk in
prepared — then **earn the partner invite** as the win condition.

This is the answer to the core friction ("value gated behind both partners buying
in"): solo delivers standalone value *and* manufactures the desire + readiness to
bring the partner in. Everything carries forward so the couple starts further along.

---

## Conditional routing — who gets this loop

**Not universal.** It fires only for `mode = solo` **AND** a newer/hesitant signal
(experience level + a hesitancy read). It must **NOT** fire for:
- Already-together couples (`mode = together`) — they're past this.
- Experienced solo users whose partner simply isn't into the app (no drama) — coaching
  them through conversation anxiety would feel insulting.

Those users skip straight to the standard experience. Branch on **(mode × experience
× hesitancy)**.

---

## The Beats

All beats run on the **existing `Card` system + dealer motif** — no new content engine.

1. **Read the fear** *(gender-aware, self-select survey).* Deal a few cards; the user
   picks what's true: *"they'll think I want to leave" / "they'll feel not enough" /
   "I don't have the words" / "it's never come up & they're more traditional" / "I'm
   not sure what I want yet."* Routes everything after it.

2. **Clarify your own ask.** Curious-and-want-to-explore vs. I-actually-want-to-open-up
   are very different openings. Also the seed data that carries into the couple layer.

3. **Partner-context read.** A short read *about the partner* so rehearsal is tailored,
   not generic:
   - handles vulnerable topics (*goes quiet & needs time / defensive / talks it through*)
   - security in the relationship (drives the "not enough" risk)
   - openness signals (*has it come up? reaction to others doing it? jokes vs. judgment?*)
   - conflict style (*avoidant / direct / processes out loud*)

   **Guardrails (profiling a non-user):**
   - Framed as **"your read," not fact** — it's fear-colored, and the real conversation
     tests it. That framing is both honest and useful.
   - **Stays the solo user's private prep — NEVER shown to the partner on pairing.**
     "Here's what your partner guessed about you" is a trust landmine.

4. **Craft the words → rehearse.** Two chained moves:
   - **Guided draft (their words):** principles + opener frames + fill-in prompts; the
     user assembles and personalizes *their own* opening, saved to keep. Helps the
     wordless user without scripting them — it still sounds like them.
   - **Rehearse:** anticipate the partner's likely responses (from beat 3) and practice
     replies, so they walk in having "done it once."

5. **Pre-mortem + reframe.** Show the failure modes *and* defuse each. Backbone line:
   **the goal of the first conversation is to open the door, not to get a yes.**
   - *Strong negative first reaction* → first reactions are emotional, not final.
   - *"You want to leave / I'm not enough"* → the #1 misread; fix = lead with what's
     **not** changing.
   - *"Not now"* → readiness info, not a closed door.
   - *Genuinely, durably not interested* → the app is honest this is possible; the work
     becomes what you do with a no. (Honesty here earns trust — not promising NM for all.)

   **Honesty calibration (decided): Honest + reroute the goal.** When the partner read
   looks hard (traditional / conflict-avoidant / reacted badly before), name it gently
   ("this looks like a longer road") and switch strategy from *make the ask* →
   *plant a seed / open the topic over time* (lower-stakes opener, no pressure for an
   answer). Honest about difficulty, still hopeful, protects against a doomed swing.

6. **Earned readiness → real conversation → invite (two-staged).** The in-app invite
   comes *after* the real-world talk goes okay:
   - App marks them **ready**, they have the talk.
   - **"How did it go?" check-in** routes next steps.
   - Good → surface the **pairing invite** (the win condition).
   - **"It didn't go well" branch = the retention lifeline.** The likeliest churn moment
     (a rough conversation) is exactly when the app catches them with the reframe + a
     "here's how to regroup" path. Build this branch deliberately.

---

## Gender-aware content

Fears and reframes are driven by **user-gender × partner-gender**, built on the
existing rail (`Card.isGenderedCard` + `genderedFor: GenderDynamic`) — **self-select,
never prescriptive** (offer the relevant fears; the user picks what's true).

Recognized, underserved pattern to author for: **het woman → man** hesitancy carries
specific fears (triggering his jealousy/ego, being judged/labeled, the double-standard
"reads differently," landing as "you're not enough"). The inverse (**man → woman**) and
queer dynamics each carry their own. Author the fear/reframe content per dynamic.

---

## Carry-forward (into the couple experience)

- The user's **clarified ask** + (optionally) **private pre-filled Desire Map ratings**
  seed the couple layer so pairing starts further along.
- The **partner-context read does NOT carry forward to the partner** (privacy).
- Reinforces "best case, they sign up de facto together" — the couple just begins
  further down the path.

---

## Constraints

- Existing `Card` system + dealer motif only — **no new content engine** (the
  map/territory/lore exploration game is Vayl 2.0).
- Tone = knowledgeable guide, not clinical intake; affirmation = "this is real,
  studied, navigable," not "you're doing great."
- All design tokens per `CLAUDE.md` (no raw colors/fonts/spacing/animation).
- **Feel before Swift:** every ceremony beat (the survey deal, the earned-ready moment,
  the invite) proven in a reference and verified on device before implementation.

---

## Open items / next

- Exact "how did it go?" check-in mechanics + the regroup path content.
- Content-authoring scope: fears × reframes × gender dynamics is real writing work.
- How each beat renders in the dealer/card motif (feel — device-verified).

## Out of scope

- Anything for experienced couples / standalone-solo explorers (Vayl 2.0).
- Showing partner-context data to the partner, ever.

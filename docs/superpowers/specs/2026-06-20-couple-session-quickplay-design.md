# Vayl — Couple Card Session: Quickplay (Design Spec)

**Date:** 2026-06-20
**Status:** Design — spine locked, several decisions open (see §7)
**Scope:** The in-person, two-device **quickplay** session launched from Home. This is the premiere product. Builder/curation (Play tab), LDR/Dynamic-Island, and solo derivation are explicitly **out of scope** here.
**Maps to build plan:** Phase **C** (entry + airlock) + Phase **D** (player). Phases A (data) + B (realtime) already built.

> Annotation convention (matches the paywall wireframe): plain component name = exists / reuse; `Name*` = to build or proposed. Component names are best-effort against the live design system — verify during build.

---

## 1. The model in one paragraph

Two partners, in the same room, each on their own phone. They pick a **preset** (or resume the most-recent), cross an **airlock** — a deliberate friction gate that primes them with house rules, reads each person's bandwidth, and takes a mutual hold-to-confirm — then **put their phones down and look up**. In session, they alternate **drawing** a card, **reading it aloud**, and both answering the **same** prompt, with the listener reflecting before the next card. Cards run **shallow → deep**, the session is **bounded**, and a **pass / re-center** exit is always available. The screen is a glanceable prompt, never a thing to stare into — eyes stay on each other.

This is grounded in relationship science (§8): reciprocal turn-taking disclosure (Sprecher/Aron), partner responsiveness as the active ingredient (Reis–Shaver/Gable), graduated escalation (Aron/EFT), and a bounded container.

---

## 2. Locked decisions

- **Reciprocal, same card.** Both partners answer the *same* prompt in back-and-forth — not separate cards.
- **The listener does something.** After an answer: reflect / validate / one follow-up before advancing. Light, taught up front in the guidebook, never a therapy script.
- **Read aloud.** The drawer voices the card — it's a "bid," it blocks skimming, and it's what makes eyes-up possible (the partner *hears* it).
- **Eyes-up / phones-down** baked into V1 (glanceable, minimal card). Dynamic Island is the eventual best form — deferred to post-launch.
- **The airlock stays** (friction is a feature). Container = the gate; content = the guidebook. Assembled: **house rules + bandwidth + 3-sec hold + both confirm → phones down, look up.** Presence/consent handshake (Phase B) runs underneath.
- **Escalation:** cards ordered shallow → deep. **Bounded:** finite session. **Pass:** always available.
- **Presets = `SessionPlan`s** — not a new system (`isPreset` + `lastUsedAt` already in the model). Quickplay surfaces most-recent + 2–3 presets.

---

## 3. The screen ribbon

```
Home quickplay ──► AIRLOCK ──────────────► transition ──► IN-SESSION LOOP ──► CLOSE
   (Screen 0)      (1A rules)               (Screen 2)     (Screen 3 standard)  (Screen 7)
                   (1B bandwidth+hold)                     (Screen 4 advance)
                                                           (Screen 5 whisper)
                                                           (Screen 6 re-center)
```

`.vaylCover` (protected · dismiss-disabled · confirm-on-exit) wraps everything from the airlock through close.

---

## 4. Screens

### Screen 0 — Home · quickplay entry

```
┌─────────────────────────────────────┐
│  ◐ Alex          present        ⚙︎  │
│                                      │
│        Pick up where you             │
│           left off                   │
│   ┌───────────────────────────┐      │
│   │  ✦  THE OPENER            │      │
│   │     8 cards · ~15 min     │      │
│   │     last played Tuesday   │      │
│   │        [  Continue  ]     │      │
│   └───────────────────────────┘      │
│                                      │
│   Or start something                 │
│   ╭────────╮ ╭────────╮ ╭────────╮   │
│   │Reconnect│ │Go deep │ │Wind    │   │
│   │ ~10 min │ │ ~20 min│ │down    │   │
│   ╰────────╯ ╰────────╯ ╰────────╯   │
└─────────────────────────────────────┘
```
**Components:** `PartnerPill` (STATUS, read-only) · `VaylCardFace` (hero) · `VaylButton` · `PresetCard*` ×3 · cog → Settings
**Behavior:** tap hero or preset → **Airlock** (`.vaylCover*`). Hero = most-recent `SessionPlan` by `lastUsedAt`; presets = author-seeded `SessionPlan`s.
**Open:** preset *spine* — occasion vs depth (#1). Labels above are placeholder.

---

### Screen 1A — Airlock · the guidebook (house rules)

```
┌─────────────────────────────────────┐
│              ✦ settle in             │
│                                      │
│   Before you start — the house       │
│   rules. Read them out loud,         │
│   together.                          │
│                                      │
│   ◦ Take your time. Silence is fine. │
│   ◦ Both of you answer — every card. │
│   ◦ Listen first. Say what you heard │
│     before your turn.                │
│   ◦ No fixing, no judging — just     │
│     get each other.                  │
│   ◦ What's said here stays here.     │
│   ◦ You can always pass.             │
│                                      │
│         [  We're ready  ]            │
└─────────────────────────────────────┘
```
**Components:** `.vaylCover*` chrome (reuse `OBSheetChrome`) · `LivingText` · `SpectrumBulletRow` ×6 · `VaylButton`
**Behavior:** full the **first** session (and on-demand later); compressed to a one-line "settle in" on repeat (just-in-time teaching). This is the airlock's *content*, not a separate flow.
**Open:** confirm/edit the 6 rules (#4); add an eyes-up/"phones down except to read" rule?

---

### Screen 1B — Airlock · bandwidth + lock in

```
┌─────────────────────────────────────┐
│        how much have you got         │
│           for each other?            │
│                                      │
│   tonight I'm…                       │
│   light  ◦──────●──────◦  deep       │
│                                      │
│   ┌───────────────────────────┐      │
│   │      ✦ hold to lock in     │      │
│   │            ●              │      │
│   │   ◐ Alex is holding…      │      │
│   └───────────────────────────┘      │
│                                      │
│    both in → phones down, look up    │
└─────────────────────────────────────┘
```
**Components:** `BandwidthSlider*` (writes `LockInSession`) · `HoldToConfirm*` (3-sec, `SpectrumBorderGlow`) · presence via `RealtimeSessionService` · "waiting for Alex…" state
**Behavior:** each sets bandwidth **privately**; **both** complete the 3-sec hold; bandwidth sets the session's depth ceiling (honors "never push the unready"). Both locked → **Transition**.
**Open:** bandwidth form — slider vs low/med/high; informs vs hard-caps depth (#8).

---

### Screen 2 — Transition · phones down

```
┌─────────────────────────────────────┐
│                                      │
│                                      │
│          put your phones             │
│             down.                    │
│                                      │
│        look at each other.           │
│                                      │
│               ✦                      │
│                                      │
└─────────────────────────────────────┘
```
**Components:** `AppColors.void` + `AtmosphereView` · breathing `✦` (`.ambientAnimation`)
**Behavior:** ~2–3s held beat → Card 1. The eyes-up primer. Reduce-Motion → static mark.

---

### Screen 3 — In-session · standard card  *(the heart)*

```
┌─────────────────────────────────────┐
│  Card 3 · 8       ◦ deepening    ⏸  │
│                                      │
│                                      │
│   "What's something you've           │
│    wanted to ask me but              │
│    never have?"                      │
│                                      │
│                                      │
│   ✦ Alex's draw — read it aloud      │
│                                      │
│              · · ·                   │
│                                      │
│   pass             [ we're ready → ] │
└─────────────────────────────────────┘
```
**Components:** `VaylCardFace` (prompt) · `SessionProgressBar*` · depth chip · `PauseButton*` (⏸ → re-center) · turn cue · `pass` (text button) · `VaylButton` (Ready)
**The loop:** drawer reads aloud → drawer answers → partner **reflects + answers the same card** → either taps **we're ready** → "waiting for Alex" → **both ready** advances · alternate who draws.
**Eyes-up:** prompt dominates, minimal chrome, **no countdown**. `pass` skips this card gracefully.
**Open:** advance gate — both-ready (shown) vs either-advances (#3); responsiveness beat weight (#5).

---

### Screen 4 — In-session · advance gate (inline micro-state)

```
   ✦ you're ready
   ◌ waiting for Alex…
            [ ready ]
```
**Components:** presence · `RealtimeSessionService.advance(expectedIndex:)` (conditional update)
**Behavior:** server-authoritative; simultaneous taps cannot double-advance. Not a full screen — an inline state on Screen 3.

---

### Screen 5 — In-session · whisper card  *(the rare one, ≤1/deck)*

```
┌─────────────────────────────────────┐
│  Card 6 · 8        ✦ whisper         │
│                                      │
│   This one's private.                │
│   Type it on your own phone —        │
│   you'll reveal together.            │
│                                      │
│   ┌───────────────────────────┐      │
│   │ ›                         │      │
│   └───────────────────────────┘      │
│                                      │
│   ◐ Alex is writing…                 │
│                                      │
│         [  seal my answer  ]         │
└─────────────────────────────────────┘
```
**Components:** `WhisperField*` · presence (content hidden) · `reveal_state` (jsonb) · simultaneous-reveal Broadcast · `.screenshotProtected()`
**Behavior:** neither sees the other until **both** seal → 3-2-1 → simultaneous reveal. Answers exchanged at reveal, not stored unless consented.

---

### Screen 6 — Pause · re-center  *(the "chill pill" — AI-specced, Bryan to finalize)*

```
┌─────────────────────────────────────┐
│            ◦ take a breath           │
│                                      │
│   No pressure to keep going.         │
│   Pick one, then come back.          │
│                                      │
│   ╭───────────────────────────╮      │
│   │ 🤍 a 6-second hug         │      │
│   ╰───────────────────────────╯      │
│   ╭───────────────────────────╮      │
│   │ ✦ say one thing you love  │      │
│   ╰───────────────────────────╯      │
│   ╭───────────────────────────╮      │
│   │ ◦ just sit a minute       │      │
│   ╰───────────────────────────╯      │
│                                      │
│   [ resume ]           [ end well ]  │
└─────────────────────────────────────┘
```
**Components:** `ReCenterSheet*` (`.vaylSheet*`) · move cards · `VaylButton` ×2
**Behavior:** reached from the in-card ⏸. "End well" = graceful dual exit (writes a clean close, not `abandoned`). Replaces the "safe word" frame.
**Open:** whole screen is `*` — move list + framing are yours to finalize at session-sequence build time.

---

### Screen 7 — Close · post-session

```
┌─────────────────────────────────────┐
│            ✦ that's a wrap           │
│                                      │
│   You went 8 cards deep together.    │
│                                      │
│   Before you put it down —           │
│   one word for how that felt?        │
│   ┌───────────────────────────┐      │
│   │ ›                         │      │
│   └───────────────────────────┘      │
│                                      │
│   how full are you now?              │
│   drained ◦────────●───◦ full        │
│                                      │
│   [ save this session ]    [ done ]  │
└─────────────────────────────────────┘
```
**Components:** `PostSessionView*` · reflection field → `CardSession` · post-bandwidth capture → `LockInSession` · `VaylButton` ×2
**Behavior:** writes `CardSession` / `CardResult` / `DeckProgress`; offers save-as-`SessionPlan` (reuse); updates Home's "most recent." Confirm-on-exit per the cover contract.
**Open:** the close is Phase F — depth of reflection capture TBD (#9).

---

## 5. The in-session loop (per standard card)

1. **Draw** — drawer's phone shows the card; drawer **reads it aloud**.
2. **Share (drawer)** — drawer answers first (models vulnerability, breaks ice for the quieter partner).
3. **Respond + share (partner)** — partner reflects a beat ("what landed was…"), then answers the **same** card.
4. **Respond (drawer)** — drawer reflects a beat.
5. **Advance** — both tap *ready* → server-authoritative advance → next card, **alternate who draws**.
- Ordering shallow → deep across the session · `pass` skips a card · ⏸ opens re-center.
- Responsiveness (steps 3–4) is **taught in the guidebook**, surfaced in-card only as a soft turn cue — keeping the screen light.

---

## 6. Cross-cutting rules

- `.vaylCover` from airlock → close: dismiss-disabled, confirm-on-exit (most protected experience).
- `.screenshotProtected()` on whisper + any private input.
- Keep-awake + dim-after-idle via `connectedScenes` (no `UIScreen.main`).
- Reduce-Motion fallbacks on transition + any looping mark (`.ambientAnimation`).
- Design tokens only; OB card faces stay 1D outline + spectrum + `.drawingGroup()`.

---

## 7. Open questions

**Whiteboard (quick):**
1. **What the 2–3 presets *are*** — occasion vs depth. *(Biggest, but shapes Home + authoring, not the in-session build.)*
2. **Default card count** for a quickplay session.
3. **Advance gate** — both tap Ready (mutual) vs either advances.
4. Confirm / edit the 6 house rules.

**Decide on device, by feel:**
5. Responsiveness beat's weight + placement.
6. Airlock gesture/form (how rules present; the hold).
7. In-session screen layout (eyes-up minimal).
8. Bandwidth form (slider vs low/med/high; informs vs caps depth).

**Later beats:**
9. The close / post-session depth (Phase F).
10. Public-facing name for the airlock (cosmetic).

> **None of these block building the heart.** Screen 3 (in-session player, one device, debug bypass) needs only a default card count (#2).

---

## 8. Evidence base

- **Reciprocal turn-taking beats one-sided disclosure** — Sprecher, Treger, Wondra et al. (2013, *J. Experimental Social Psychology*; 2013, *JSPR*; 2015, *Personal Relationships*): immediate back-and-forth on the *same* prompt produced more liking/closeness than one person disclosing then the other, **even at equal total airtime**. → both answer the same card.
- **The "Fast Friends" structure** — Aron, Melinat, Aron, Vallone & Bator (1997, *PSPB*): sustained, **escalating, reciprocal** self-disclosure generates closeness; the gradient + mutual answering are load-bearing, not the specific questions. → shallow→deep, both answer, bounded.
- **Partner responsiveness is the active ingredient** — Reis & Shaver (1988); Laurenceau, Feldman Barrett & Pietromonaco (1998, *JPSP*); Reis, Clark & Holmes (2004). Disclosure becomes intimacy only when the partner is perceived as understanding + validating + caring. → the listener must *do* something.
- **Capitalization / active-constructive responding** — Gable, Reis, Impett & Asher (2004, *JPSP*); Gable & Reis (2010). Passive "that's nice / next" is a *missed-intimacy event*, not neutral. → reflect / follow-up beat.
- **Active listening raises felt understanding** — Weger et al. (2014, *Int'l J. Listening*). → a single reflect-back is worth prompting.
- **Graduated vulnerability, never the deep end first** — EFT / *Hold Me Tight* (Johnson); meta-analysis (Rathgeber et al., 2019, *JMFT*) shows large effects; one digital program *harmed* couples by pushing depth on the unready. → bandwidth gate + escalation + pass.
- **Boundary condition (honest):** scripted active-listening fails in *conflict* (Gottman et al., 1998). Our register is positive disclosure, not conflict — so keep the responsiveness beat light, never a mediation script.

*Caveat: Aron/Sprecher tested strangers' transient closeness (couples are an extrapolation); Laurenceau is correlational; EFT is the strongest couples-specific evidence. Every arrow points the same way.*

---

## 9. Build mapping + Segment 1

**Exists:** `Card`, `Deck`, `DeckProgress`, `CardSession`, `LockInSession`, `Couple`, `ContentLoader`, `CardCarousel`, thin `SessionStore`/`SessionView`, `RealtimeSessionService` (A+B), `SessionPlan` (built), `curated_sessions` table, `ScreenshotProtectionModifier`, `SafeWordButton`, `SpectrumBulletRow`, `VaylCardFace`, `VaylButton`.

**To build (this spec):** `.vaylCover/.vaylSheet*` helpers · `AirlockStore/AirlockView*` (1A+1B) · `BandwidthSlider*` · `HoldToConfirm*` · `CuratedPlayerStore*` + Screen 3 player · `SessionProgressBar*` · `PauseButton*`/`ReCenterSheet*` · `WhisperField*` · `PostSessionView*` · `PresetCard*` (Home).

**Segment 1 — In-session player (Screen 3), one device, debug bypass**
- *Does:* render the synced card + the draw/read/answer/advance loop on one device, behind a debug button that skips the airlock.
- *Build:* `CuratedPlayerStore*` + extend `SessionView`; render `card_ids[current_index]`; Next/advance → conditional update; completion writes `CardSession`.
- *Done (on device):* a stub session of N cards plays start→finish; advancing feels right; the prompt reads as glanceable/eyes-up; completion persists. **Feel is correct, not build-succeeds.**
- *May not touch:* airlock/transport interfaces, `PlayView`, `VaylCardFace` shell, `couple_session_records` (legacy), Onboarding.
- *Needs only:* a default card count (#2).

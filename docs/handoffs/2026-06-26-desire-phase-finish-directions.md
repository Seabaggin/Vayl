# Desire-Map Moment → 100% — finish directions

**Date:** 2026-06-26
**Phase goal (the finish line):** the cohort-adaptive Desire Map works end-to-end on a real paired couple — rate (right track + wording) → sync → compute match → reveal vs partner — plus the Home activation (Path) telling the truth. Couple-symmetric V1.

**Where you are:** ~80% done. D1/D2/D3/DR (backend), D4 (reveal UI), D5 (Map+Vault compare), DA (Getting Started Path) are all code-complete. The genuine remaining code is **T1** (flip Home to the real state machine) and **DB** (Moments + solo funnel). The rest is on-device feel confirmation, which is the build-protocol "done" gate.

**Out of scope for phase 100% (deferred, do NOT let these block it):** the hidden-desire "request"/consent exchange (Seg 4, the `openAConversation` placeholder in `VaultDesireSection`), the bridge-card "talk about this" companion card (Seg 3), the Vault/Map cohesion sweep (T3/Seg 6), and the test-coverage DI seam (a quality follow-up from the 2026-06-26 audit). DC card-face flame is CUT.

Do these in order. Each is done only when it runs on device and the feel is right, not when it compiles.

---

## Step 1 — T1a: Flip Home to the real state machine (the keystone, unblocks everything)

The `#if DEBUG` block in `HomeStore.init` (`Vayl/Features/Home/Store/HomeStore.swift:93-101`) hardcodes `myMapComplete = true`, `partnerMapComplete = true`, `revealDone = true`, `postReflectionDone = true`, `partnerName = "Alex"`. So dev builds jump past the real flow and it has never been exercised.

1. Replace the unconditional override with a launch-arg opt-in so the real machine drives by default but you keep a quick-jump when you want it:
   - Wrap the body in `if ProcessInfo.processInfo.arguments.contains("-forceHomeComplete") { ... }` (matching the existing `-forceHome` diagnostic recipe), or just delete the block outright.
2. Build + run on device with a REAL (fresh) account, no launch arg.
3. **Done (device):** a new user lands on the `.gated` dashboard with the real Getting Started Path, no auto-jump. Expect gating bugs to surface here that the override was hiding — fix them as they appear (this is the expected T1 debugging tail).

---

## Step 2 — T1b: Device-verify the whole real flow, two paired devices (covers D4 + rater + DA + the handoff)

This single pass confirms the bulk of the already-built work. Pair two devices, then walk the flow on each:

1. **Rater (Phase 2):** Begin → spectrum-bloom entrance; rate 17 with the depth-push + the answer star rising in sync with the question receding; charted finish (flair → hesitant lines → "Your map is charted") and confirm **tap-to-skip** works.
2. **First finisher** → solo mirror (screen 4, every answer grouped incl. Not-for-me); close, reopen → the **Ready bar** ("Alex finished. Your map is ready.").
3. **Second finisher** → on rater close the **reveal auto-presents** (the handoff fix); confirm there is no dashboard detour.
4. **Reveal ceremony:** free star ignites + sparkles → locked teasers stagger in → paywall rises; tap a free star → detail sheet; tap a locked star → paywall; grant Core (admin path until M2) → **unlock in place**, the whole sky lights, the hero (free) star reads larger.
5. **Map "Us" layer + Vault Desire section** both show the shared desires (mutual magenta / adjacent purple) and the locked-more row, gated on Core.
6. **Reduce Motion ON:** the rater, the ceremony, and the hesitant lines all collapse to static/instant end-states; still purchasable.
7. **Edge cases:** already-Core couple skips straight to the lit sky (no paywall); a couple with exactly one match (0 locked) gets a gentle lit close (no empty paywall).

**Done (device):** the phase goal works on real devices and the feel is right across the rater, reveal, and Map/Vault. Log real hours against D4 / DA.

---

## Step 3 — DB: Moments + solo funnel (the last genuine code)

**3a. Moments.** Replace `TODO(Moments)` in `Vayl/Features/Home/Views/HomeRouterView.swift:267` (`handleStep`): when a Getting Started step advances (e.g. map → invite), fire ONE warm beat. No points / XP / badges. Reuse the `MapCompletionBeatView` one-shot-over-dashboard pattern already wired for map completion. Keep it rare and warm ("therapist, not video game").

**3b. Solo funnel.** An unpaired user can already open + complete the rater (the entry card renders for solo). Add:
- After a solo user completes, "bank" the map and frame the reveal as waiting on a partner ("invite someone to see what you share").
- Home funnels toward pairing (a clear, non-pushy CTA to the Map/pairing surface).
- The honest off-ramp stays ("not now / not for me" is a respected outcome — humility principle).

**Done (device):** advancing a step shows a warm Moment; an unpaired user completes the map and is gently funneled to pairing, with the reveal framed as the payoff.

---

## Step 4 — T1c: Close the remaining Home audit debt (if still open)

From the 2026-06-23 contract audit fixlist (`docs/audits/`), confirm which remain and land them:
- Reflection presentation `.sheet` → `.vaylSheet`.
- Home font-token cleanup (any raw `.font(...)`).
- `PulseStore` `@MainActor`.

(The rater's `.fullScreenCover` → `.vaylCover` item from that list is already done.)

**Done:** no raw `.sheet`/`.fullScreenCover` in Home; tokens clean; compiles + a quick device sanity check.

---

## Step 5 — D5: Confirm the compare surfaces (verification, likely no code)

`VaultDesireSection` and the Map "Us" layer are built. On device, confirm both render the shared desires + the locked-more row and gate on Core. The `openAConversation` consent block is a Seg-4 placeholder — leave it. If either surface is visibly stubbed, wire it to `VaultStore.align` / the shared `DesireMapListView`; otherwise this is just a confirmation.

**Done (device):** Map Us-layer + Vault Desire section both show the compare correctly.

---

## Step 6 — Mark the phase complete (roadmap truth-up)

In `docs/roadmap/vayl-build-roadmap.html` (`BUILD_ROADMAP` block), set: D4 `done` (+ actual hours), DA `done`, D5 `done` (desire-phase scope), T1 `done`, DB `done`. Advance `meta.current` to the next phase (`money`). Add a one-line note on each that the Seg 3/4 items (request/consent, bridge cards, cohesion) are deferred so they are not lost. Verify the block still node-parses.

**Phase 100% =** Steps 1-6 done, the goal confirmed on two real devices, deferred items logged.

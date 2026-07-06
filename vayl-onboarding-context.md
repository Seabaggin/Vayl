# Vayl — Onboarding Build-Deck Context

> Generated: 2026-07-04 01:33:58 PDT
>
> **Active segment:** Onboarding — Build-Deck ceremony
>
> **What this covers:**
>   Phase & orchestration — BuildDeckPhase, BuildDeckCeremony, VaylDirector
>   Visuals               — MetallicCaseView, DeckWrapView, VaylDeckStack,
>                          TableSurfaceView, OnboardingCanvasView
>   Models                — WelcomeDeck, FoilTear
>   Tokens                — AppAnimation, AppLayout, AppRadius
>
> Files marked MISSING = wrong path or stub to create.

---

## Table of Contents

  1. [`Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift`](#file-vayl-features-onboarding-phases-builddeckphase-swift)
  2. [`Vayl/Features/Onboarding/Director/BuildDeckCeremony.swift`](#file-vayl-features-onboarding-director-builddeckceremony-swift)
  3. [`Vayl/Features/Onboarding/Canvas/VaylDirector.swift`](#file-vayl-features-onboarding-canvas-vayldirector-swift)
  4. [`Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift`](#file-vayl-design-components-effects-foilopen-metalliccaseview-swift)
  5. [`Vayl/Features/Onboarding/Components/DeckWrapView.swift`](#file-vayl-features-onboarding-components-deckwrapview-swift)
  6. [`Vayl/Design/Components/Cards/VaylDeckStack.swift`](#file-vayl-design-components-cards-vayldeckstack-swift)
  7. [`Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift`](#file-vayl-features-onboarding-canvas-tablesurfaceview-swift)
  8. [`Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift`](#file-vayl-features-onboarding-canvas-onboardingcanvasview-swift)
  9. [`Vayl/Features/Onboarding/Models/WelcomeDeck.swift`](#file-vayl-features-onboarding-models-welcomedeck-swift)
  10. [`Vayl/Features/Onboarding/Models/FoilTear.swift`](#file-vayl-features-onboarding-models-foiltear-swift)
  11. [`Vayl/App/Theme/AppAnimation.swift`](#file-vayl-app-theme-appanimation-swift)
  12. [`Vayl/App/Theme/AppLayout.swift`](#file-vayl-app-theme-applayout-swift)
  13. [`Vayl/App/Theme/AppRadius.swift`](#file-vayl-app-theme-appradius-swift)

---

## File: `Vayl/Features/Onboarding/Phases/BuildDeckPhase.swift` {#file-vayl-features-onboarding-phases-builddeckphase-swift}

```swift
//
//  BuildDeckPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Build Deck (renders OBPhase.buildDeck).
/// The forge ceremony, per the 2026-06-10 ceremony spec:
///   Beat 1 · the confirmed deck MELTS down through the felt (their truths go
///            under the table)
///   Beat 2 · the TABLE performs — its spectrum rim oscillates while it works
///   Beat 3 · the cased deck lies FLAT and lifeless, lifts to vertical, the
///            camera dollies in, and the hex material wakes on arrival
///   Beat 4 · stillness, dealer invitation — the case ARMS
///   Beat 5 · crack ceremony — three strikes (the locked Pincer), escalating
///            light + haptics, third → overload + honeycomb UN-KNIT: the shell
///            disassembles along its hex lattice, uncovering the deck behind it
///            (taps forward to director.ceremony.addFoilTear)
///   Beat 6 · the forged deck stands revealed — browse, then the exit CTA
///   Beat 7 · founder letter sheet-peek exit
///
/// Timing values are AppAnimation tokens (OB Ceremony Tokens section, tokenized
/// 2026-07-03, values verbatim). Re-tune the tokens directly after a device feel
/// pass — never by re-introducing raw values here.
struct BuildDeckPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize
    /// The table's spectrum rim — phases drive it (NamePhase/GenderPhase
    /// pattern). During the forge it oscillates: the TABLE is the performer.
    @Binding var tableRimBurst: Double
    /// Topo-line sway — the felt's contour lines breathe while the table works.
    @Binding var tableForgeEnergy: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // sequence state
    @State private var started:    Bool = false
    // Long-lived task handles — cancelled on disappear so the knock loop, the beat
    // sequence, and the spark-field retirement never outlive the phase.
    @State private var sequenceTask:    Task<Void, Never>? = nil
    @State private var knockTask:       Task<Void, Never>? = nil
    @State private var sparksClearTask: Task<Void, Never>? = nil
    @State private var deckShown:  Bool = true
    @State private var deckMelt:   Double = 0       // 0 intact → 1 fully under the felt
    @State private var meltDone:   Bool = false     // haptic trigger
    @State private var caseShown:  Bool = false
    @State private var caseOpacity: Double = 0      // dissolve-up reveal
    // .distantFuture = mounted lying FLAT, lifeless — the lift is assigned later.
    // (nil would mean "full float pose" and causes the double-rise bug.)
    @State private var caseRiseStart: Date? = .distantFuture
    @State private var latticeWake: Date = .distantFuture  // hex wakes AFTER the zoom
    @State private var caseFloat:  Bool = false     // felt → float position

    // crack ceremony (Beat 5) — taps forward to director.ceremony.addFoilTear
    @State private var caseArmed:    Bool = false   // invitation landed; taps live
    @State private var caseDissolve: Date = .distantFuture  // third crack → shatter
    // Segment 2 — the charged core: the deck's energy contained inside the shell.
    // 0 = dark; lights to a baseline when the case arms, climbs per tap (the
    // release premise's charge floor rising toward the break).
    @State private var coreEnergy:   Double = 0
    // directional recoil — the case is KNOCKED, yawing away from the strike
    @State private var kickDeg:  Double = 0
    @State private var kickAxis: (x: CGFloat, y: CGFloat) = (0, 1)
    // spectrum motes knocked loose into the air per strike
    @State private var sparkBursts: [SparkBurst] = []
    // the knock from inside — anticipation while armed and untouched
    @State private var knockStart: Date = .distantFuture
    @State private var knockSeed:  UInt64 = 0
    @State private var knockCount: Int = 0
    // the burst — full-screen flash + stage punch as the flood erupts
    @State private var burstFlashOpacity: Double = 0
    @State private var stagePunch: Bool = false

    // founder letter sheet-peek (Beat 7)
    @State private var peekShown:     Bool = false
    @State private var sheetExpanded: Bool = false
    @State private var peekPressed:   Bool = false
    @State private var sheetDrag:     CGFloat = 0
    private let peekHeight: CGFloat = 100   // shows the grabber + "A note from the founder" with presence

    // Beat 6 — the reveal (the forged deck presents and browses). The exit is a
    // bottom CTA, not a swipe: this deck is the user's to KEEP, so there's no
    // hand-it-back gesture. User-paced — it only leaves when they tap.
    @State private var revealShown:    Bool = false
    @State private var revealExiting:   Bool = false   // Beat 1: the deck fades out + sinks as the user hands off
    @State private var revealHeaderShown: Bool = false // deck name + purpose land AFTER the shell is gone
    @State private var ctaShown:       Bool = false    // "Take your deck" fades in after the deck lands
    @State private var revealPhysics   = CarouselPhysics(count: WelcomeDeck.placeholderCards.count)   // match ContextPhase's init
    private var welcomeDeck: WelcomeDeck { WelcomeDeck.of(director.openerDeckType) }

    // Mirrors ConfirmationPhase.cardWidth(in:) — the deck arrives at FAN-card
    // scale (the collapse never grows the cards). The size change to the hero
    // case happens as a camera zoom during the float, not object growth.
    private var deckW:    CGFloat { min(screenSize.width * 0.32, 230) }
    private var deckSize: CGSize  { CGSize(width: deckW, height: deckW * 1.5) }

    /// Camera dolly-in during Beat 3c: the case scales up WHILE the felt
    /// recedes beneath it — object-up + background-away reads as the camera
    /// moving closer, never as the object inflating. Feel-tunable.
    private let floatZoom: CGFloat = 2.0
    private var feltCenter:  CGPoint { CGPoint(x: screenSize.width / 2, y: AppLayout.obTableCardCenterY(in: screenSize.height)) }
    private var floatCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.42) }

    var body: some View {
        ZStack {
            // No background — the persistent canvas (void + atmosphere + FELT) shows through.

            // Beat 1 — the confirmed deck, melting down through the felt.
            // The table itself reacts (rim oscillation via tableRimBurst) —
            // no overlay props on the felt.
            if deckShown {
                VaylDeckStack(size: deckSize)
                    .modifier(MeltThroughFelt(progress: deckMelt, size: deckSize))
                    .position(feltCenter)
            }

            // Beat 6 — the forged deck. Mounted BEHIND the shell (earlier in
            // this ZStack) the moment the un-knit wave starts, so the
            // disassembling case genuinely UNCOVERS it — object continuity,
            // no cross-fade, no void (Segment 3). Browse freely once standing.
            if revealShown {
                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xs) {
                        Text(welcomeDeck.name)
                            .font(AppFonts.screenTitle)
                            .foregroundStyle(LinearGradient(
                                colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                                startPoint: .leading, endPoint: .trailing))
                        Text(welcomeDeck.purpose)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textBody)
                    }
                    // the header waits for the shell to finish un-knitting — the
                    // uncovered deck stands alone first, THEN is named
                    .opacity(revealHeaderShown ? 1 : 0)
                    VaylCardCarousel(
                        count:    WelcomeDeck.placeholderCards.count,
                        cardSize: deckSize,
                        physics:  revealPhysics,
                        content: { index, isFront in
                            let c = WelcomeDeck.placeholderCards[index]
                            VaylCardFace(
                                content: .context(number: c.number, title: c.title,
                                                  subtitle: c.subtitle, detail: c.detail),
                                isFront: isFront, confirmed: false
                            )
                        }
                    )
                    .frame(height: deckSize.height * 1.3)
                }
                .frame(maxWidth: .infinity)
                .position(x: screenSize.width / 2, y: screenSize.height * 0.42)
                // Beat 1 — the deck exits: fade out + a small downward sink.
                .opacity(revealExiting ? 0 : 1)
                .offset(y: revealExiting ? AppSpacing.xl : 0)
                .transition(.opacity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Your \(welcomeDeck.name) deck")
                .accessibilityHint("Swipe left or right to browse your cards.")

                // The exit — a bottom CTA. The deck is the user's to keep, so a
                // TAP (not a hand-it-back swipe) presents the founder letter.
                // Hidden once the deck begins exiting (revealExiting).
                if ctaShown && !revealExiting {
                    VStack {
                        Spacer()
                        VaylButton(label: "Take your deck") { presentLetter() }
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.bottom, AppSpacing.xxl)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                }
            }

            // Beat 3 — the cased deck: lies flat and lifeless where the cards
            // went under, lifts to vertical, then the camera dollies in; the
            // hex material wakes only after the zoom lands.
            // Beat 5 — once the invitation arms it, taps crack the foil:
            // the view forwards face-UV strikes to the director (sole owner of
            // crack state); the dealer's words are the affordance.
            if caseShown {
                // Segment 2 — the charged core glows from WITHIN: coreGlow lights
                // the case's own hex SEAMS (in MetallicCaseView's shader), so the
                // energy reads as coming through the deck's structure, not a halo
                // behind it. Lights at arm, climbs per tap toward the break.
                MetallicCaseView(
                    riseStart: caseRiseStart,
                    latticeWakeStart: latticeWake,
                    tears: director.ceremony.foilTears.map {
                        CaseTear(id: $0.id, faceUV: $0.faceUV, seed: $0.seed,
                                 struck: $0.struck, angleDeg: $0.angleDeg)
                    },
                    dissolveStart: caseDissolve,
                    onFaceTap: caseArmed && caseDissolve == .distantFuture
                        ? { uv in director.ceremony.addFoilTear(atFaceUV: uv) }
                        : nil,
                    knockStart: knockStart,
                    knockSeed: knockSeed,
                    coreGlow: coreEnergy
                )
                    .frame(width: deckSize.width, height: deckSize.height)
                    .rotation3DEffect(.degrees(kickDeg),
                                      axis: (x: kickAxis.x, y: kickAxis.y, z: 0),
                                      perspective: 0.5)
                    .scaleEffect(caseFloat ? floatZoom : 1.0)
                    .position(caseFloat ? floatCenter : feltCenter)
                    .opacity(caseOpacity)
                    .accessibilityLabel("Your sealed deck")
                    .accessibilityHint(caseArmed ? "Tap three times to let it out" : "")
                    .accessibilityAddTraits(caseArmed ? .isButton : [])
            }

            // sparks knocked loose by the strikes — float free in screen space,
            // above the case, never intercepting taps
            if !sparkBursts.isEmpty {
                SpectrumSparkField(bursts: sparkBursts)
                    .frame(width: screenSize.width, height: screenSize.height)
            }

            // the room shakes: brief full-screen flash riding the flood
            // (skipped under Reduce Motion — never flash a photosensitive user)
            if burstFlashOpacity > 0 {
                Rectangle()
                    .fill(.white)   // flash white — intentionally untinted
                    .ignoresSafeArea()
                    .opacity(burstFlashOpacity)
                    .allowsHitTesting(false)
            }

            // Beat 7 — founder letter peek: the exit affordance IS the destination
            if peekShown {
                FounderLetterSheet { EmptyView() }
                    .frame(maxWidth: .infinity)
                    .frame(height: screenSize.height - expandedTopInset)
                    .offset(y: sheetOffset)
                    .scaleEffect(peekPressed && !sheetExpanded ? 0.99 : 1.0)
                    .sensoryFeedback(.impact(weight: .light), trigger: sheetExpanded)
                    .onTapGesture { expandSheet() }
                    .gesture(peekDragGesture)
                    .transition(.move(edge: .bottom))
                    .accessibilityLabel("A note from the founder")
                    .accessibilityHint("Opens the founder letter")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(stagePunch ? 1.05 : 1.0)   // the whole stage jolts on each strike + the burst
        .sensoryFeedback(.impact(weight: .medium), trigger: meltDone)   // the deck goes under
        .sensoryFeedback(.impact(weight: .heavy),  trigger: caseFloat)  // the case takes the air
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: knockCount)
        // crack ceremony — strikes escalate light, medium, heavy (the ritual arc)
        .sensoryFeedback(trigger: director.ceremony.foilTears.count) { old, new in
            guard new > old else { return nil }
            switch new {
            case 1:  return .impact(weight: .light,  intensity: 0.8)
            case 2:  return .impact(weight: .medium, intensity: 0.9)
            default: return .impact(weight: .heavy,  intensity: 1.0)
            }
        }
        .onChange(of: director.ceremony.foilTears.count) { _, count in
            guard count > 0, let strike = director.ceremony.foilTears.last?.faceUV else { return }
            // If the idle peek already rose and the user then commits to the
            // ritual, retract it — the knock-cued strike wins. Two exit
            // affordances must not coexist (and the peek's low edge could
            // otherwise intercept a strike tap near the bottom of the case).
            if count == 1, peekShown, caseDissolve == .distantFuture {
                withAnimation(AppAnimation.fast.reduceMotionSafe) { peekShown = false }
            }
            // every strike hits HARDER — bigger recoil + a stage jolt = weight
            recoil(from: strike, degrees: 4.0 + 1.8 * Double(count - 1))
            spawnSparks(at: strike, count: 16 + 10 * (count - 1))
            if count < 3 {   // count 3 is the shatter — its own jolt handles that frame
                withAnimation(AppAnimation.strikeJolt) { stagePunch = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 90))
                    withAnimation(AppAnimation.strikeJoltSettle) { stagePunch = false }
                }
            }
            // each release vents a burst, but the shell is more compromised — the
            // steady core glow climbs toward the break (Segment 2 charge floor).
            withAnimation(AppAnimation.standard.reduceMotionSafe) {
                coreEnergy = 0.40 + 0.30 * Double(count)
            }
            if count >= 3 { beginShatter() }
        }
        .accessibilityLabel("Build deck phase")
        .onAppear {
            guard !started else { return }
            started = true
            runSequence()
        }
        .onDisappear {
            sequenceTask?.cancel()
            knockTask?.cancel()
            sparksClearTask?.cancel()
            sparkBursts = []
            // Hard-stop the table bindings the forge oscillated. A repeatForever
            // (startRimOscillation) can survive the Beat 3c settle; force them to 0
            // with animations disabled so the felt can't keep oscillating behind the
            // founder-letter void strip.
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                tableRimBurst = 0
                tableForgeEnergy = 0
            }
        }
    }

    // MARK: - Crack ceremony (Beat 5)

    /// The case is KNOCKED by each strike — it yaws away from where the finger
    /// landed and springs back. Directional recoil is the tap contract's press
    /// state, expressed as physics (a uniform scale dip reads as UI, not impact).
    private func recoil(from uv: CGPoint, degrees: Double) {
        let dx = uv.x - 0.5, dy = uv.y - 0.5
        let length = max(0.08, (dx * dx + dy * dy).squareRoot())
        kickAxis = (x: -dy / length, y: dx / length)   // torque axis: r × (into screen)
        withAnimation(AppAnimation.fast.reduceMotionSafe) { kickDeg = degrees }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(AppAnimation.strikeRecoilReturn.reduceMotionSafe) {
                kickDeg = 0
            }
        }
    }

    /// Spectrum motes knocked loose into the air at the strike point. Origin is
    /// the strike's UV mapped through the case's frame (tilt ignored — airborne
    /// particles don't need surgical registration).
    private func spawnSparks(at uv: CGPoint, count: Int = 14,
                             style: SparkBurst.Style = .strike) {
        guard !reduceMotion else { return }
        let scale: CGFloat = caseFloat ? floatZoom : 1.0
        let center = caseFloat ? floatCenter : feltCenter
        let origin = CGPoint(x: center.x + (uv.x - 0.5) * deckSize.width * scale,
                             y: center.y + (uv.y - 0.5) * deckSize.height * scale)
        sparkBursts.removeAll { $0.started.timeIntervalSinceNow < -SparkBurst.lifespan }
        sparkBursts.append(SparkBurst(origin: origin, count: count, style: style))
    }

    // MARK: - The knock from inside (pre-strike anticipation)

    /// While the case is armed and untouched, the deck inside KNOCKS every few
    /// seconds: a physical twitch + soft haptic + a seam glimmer in the case
    /// view — anticipation that doubles as the tap cue. Stops at first strike.
    private func startKnocking() {
        guard !reduceMotion else { return }
        knockTask = Task { @MainActor in
            while knockCount < 24,
                  director.ceremony.foilTears.isEmpty,
                  caseDissolve == .distantFuture {
                try? await Task.sleep(for: .seconds(3.5))
                guard director.ceremony.foilTears.isEmpty, caseDissolve == .distantFuture else { break }
                knock()
            }
        }
    }

    private func knock() {
        knockCount += 1           // haptic trigger
        knockSeed = .random(in: .min ... .max)
        knockStart = .now         // seam glimmer in the case view
        // the twitch — a small kick about a random axis, then settle
        let angle = Double.random(in: 0...(2 * .pi))
        kickAxis = (x: CGFloat(cos(angle)), y: CGFloat(sin(angle)))
        withAnimation(AppAnimation.fast.reduceMotionSafe) { kickDeg = 1.0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(AppAnimation.knockReturn.reduceMotionSafe) {
                kickDeg = 0
            }
        }
    }

    /// Third crack — OVERLOAD (0.45s: every crack flares white, the drift
    /// freezes, the held breath), then the UN-KNIT (Segment 3): the shell
    /// disassembles cell by cell along its hex lattice, UNCOVERING the forged
    /// deck already mounted behind it — no cross-fade, no void gap.
    /// Segment 6: the release beat leans on the wave's own weight — a
    /// restrained flash + one jolt at the break, and the essence motes STREAM
    /// out through the opening lattice (two ventings) instead of detonating.
    private func beginShatter() {
        guard caseDissolve == .distantFuture else { return }
        caseDissolve = .now
        Task { @MainActor in
            // overload holds — must match MetallicCaseView.overloadSpan
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.45))
            // The deck mounts BEHIND the still-covering shell as the wave starts;
            // the un-knit does the revealing. The short fade only covers the
            // sliver of carousel peek that outreaches the case silhouette.
            withAnimation(AppAnimation.enter.reduceMotionSafe) { revealShown = true }
            if !reduceMotion {
                burstFlashOpacity = 0.4   // restrained — the wave carries the weight
                withAnimation(AppAnimation.burstFlashDecay) { burstFlashOpacity = 0 }
                withAnimation(AppAnimation.shatterJolt) { stagePunch = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(160))
                    withAnimation(AppAnimation.shatterJoltSettle) { stagePunch = false }
                }
            }
            // first venting — essence escaping as the lattice opens
            spawnSparks(at: CGPoint(x: 0.5, y: 0.5), count: 24, style: .burst)
            // second, softer venting mid-wave — it STREAMS, not detonates
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.55))
            spawnSparks(at: CGPoint(x: 0.5, y: 0.5), count: 12, style: .strike)
            // Retire the spark field once the motes age out, so its
            // TimelineView(.animation) stops redrawing through the user-paced reveal.
            sparksClearTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(SparkBurst.lifespan))
                sparkBursts = []
            }
            // Unmount the shell once the wave has consumed it (unknitSpan 1.25
            // + the sliver fade; 0.55 elapsed above). Nothing visible remains —
            // the deck is simply standing where the case was.
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.85))
            caseShown = false
            caseOpacity = 0
            // the uncovered deck stands alone a beat, THEN is named…
            withAnimation(AppAnimation.enter.reduceMotionSafe) { revealHeaderShown = true }
            // …and the exit CTA follows
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.9))   // FEEL-GATE: tune on device
            withAnimation(AppAnimation.enter.reduceMotionSafe) { ctaShown = true }
        }
    }

    /// CTA exit — the deck is the user's to keep, so a TAP (not a swipe) hands
    /// off. The founder letter auto-rises from the bottom to full, then advances
    /// behind the covering sheet (the curtain). User-paced: only fires on tap.
    private func presentLetter() {
        guard !revealExiting, !sheetExpanded else { return }
        // Beat 1 — the deck exits: cards + title + CTA fade out and sink.
        withAnimation(AppAnimation.deckExitSink.reduceMotionSafe) { revealExiting = true }
        Task { @MainActor in
            // Beat 2 — tightly behind it, the founder letter rises from the
            // bottom to full. The gap is short (slight overlap with Beat 1's
            // fade) so the two beats read as one smooth handoff, not a stutter.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 220))   // FEEL-GATE: the 1→2 gap
            peekShown = true
            try? await Task.sleep(for: .milliseconds(20))   // one frame at the bottom edge so the rise has a "from"
            withAnimation(AppAnimation.letterRise.reduceMotionSafe) {
                sheetExpanded = true
                sheetDrag = 0
            }
            try? await Task.sleep(for: .milliseconds(500))   // rise settle ≈ the rise curve
            director.advance(to: .founderLetter)
        }
    }

    // MARK: - Sequence (Beats 1–4 + interim peek)

    private func runSequence() {
        sequenceTask = Task { @MainActor in
            // settle — the deck just arrived from confirmation; let it sit.
            // FEEL-GATE: trimmed 0.8 → 0.4 now that Confirmation holds its exit
            // until the gather spring is fully still (exitSpan 2.0). The deck
            // arrives already settled, so a long second settle here only sagged.
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.4))
            // Holds are computed from type time (the `…` now costs a real beat
            // since the ellipsis cadence fix — a fixed hideAfter clipped the
            // hold to ~0.4s). Line holds ~0.6s, then is GONE ~0.4s before the
            // melt — the deck's exit gets full attention, no text competing.
            let line1 = "From everything you've shown me…"
            let t1 = Double(AppDealerTyping.typeDuration(line1)) / 1000.0
            director.projector.showDealerLine(line1, hideAfter: t1 + 0.6)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : t1 + 1.0))

            // Beat 1 — the deck melts down through the felt; the table's rim
            // begins its working oscillation (the table is the performer)
            withAnimation(AppAnimation.deckMeltDown.reduceMotionSafe) { deckMelt = 1 }
            startRimOscillation()
            // haptic at VISUAL submersion — the absorption band swallows the
            // last sliver ~0.25s before the curve's mathematical end
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 2.35))
            meltDone = true
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.25))
            deckShown = false

            // breath — the table works alone for a moment
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.4))

            // Beat 2 — the dealer speaks over the working table. Hold computed
            // from type time so "yours alone" (the thesis) always lands; the
            // total is ~1s tighter than the old fixed 4.8s, which left ~2s of
            // dead hold on the dark table before the case mounts.
            let line2 = "…I'm building a deck that's yours alone."
            let t2 = Double(AppDealerTyping.typeDuration(line2)) / 1000.0
            director.projector.showDealerLine(line2, hideAfter: t2 + 0.6)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : t2 + 1.0))

            // Beat 3a — the cased deck lies flat where the cards went under —
            // no animation, no life yet (rise pending, lattice asleep)
            caseShown = true
            withAnimation(AppAnimation.caseFadeIn.reduceMotionSafe) { caseOpacity = 1 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.8))

            // Beat 3b — the lift: face-on flat → the standing ¾ box (pose
            // driver in the case view). The table stays put for the whole rise —
            // flat → pause → stand → THEN the felt lets go (user-confirmed order).
            caseRiseStart = .now
            // The hex material wakes AS IT RISES (the shader's own intent): the
            // stand-up's big tilt-sweep drives the band across the now-awake
            // lattice, so the honeycomb IGNITES and animates through the rise
            // instead of powering on flat after the zoom has already landed.
            latticeWake = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.0))

            // Beat 3c — the rise has landed: the camera dollies in, the case
            // takes the air and scales up WHILE the felt recedes beneath it
            // (zoom, not growth); the rim settles as the table lets it go
            withAnimation(AppAnimation.caseFloatLift.reduceMotionSafe) { caseFloat = true }
            director.recedeTableForForge()
            withAnimation(AppAnimation.forgeSettle.reduceMotionSafe) {
                tableRimBurst = 0
                tableForgeEnergy = 0
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 1.0))

            // The hex finished powering on during the rise; a short settle so the
            // lit, floating case holds a beat before the invitation types.
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.3))

            // Beat 4 — stillness already passed; the invitation. Projected ABOVE
            // the floating case — at 2× zoom the case covers the horizon anchor
            // and the line would type invisibly behind it.
            let invite = "It's ready. Tap to let it out."
            let inviteMs = AppDealerTyping.typeDuration(invite)
            director.projector.showDealerLine(invite, hideAfter: Double(inviteMs) / 1000.0 + 2.0,
                                    anchorYFrac: AppLayout.forgeFloatTextYFrac)

            // Arm WITH the words landing, not as they start — a fast tap mustn't
            // strike the case mid-sentence (the motion peak shouldn't preempt the
            // line that summons it).
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : inviteMs + 250))
            caseArmed = true
            startKnocking()   // the deck inside wants out
            // the core lights: the deck's energy is now contained and straining
            withAnimation(AppAnimation.coreCharge.reduceMotionSafe) { coreEnergy = 0.40 }
            // The reveal now owns the path forward: striking the case blooms into
            // the forged deck (beginShatter → reveal), and the bottom CTA hands
            // off to the letter. A pre-reveal idle peek is wrong — the knock cue
            // carries the wait until the user acts.
        }
    }

    /// The table works: the spectrum rim glow and the topo-line sway oscillate
    /// together while the forge is active (TableSurfaceView is Animatable, so
    /// the repeatForever genuinely interpolates). Reduce Motion: steady mid
    /// glow, still lines.
    private func startRimOscillation() {
        if reduceMotion || AppAnimation.lowPower {
            tableRimBurst = 0.3
        } else {
            // 0.8 ceiling — the work has to survive phone scale; at 0.55 the
            // oscillation read as dead air in the recording, not a performance
            withAnimation(.easeInOut(duration: AppAnimation.forgeRimOscillation).repeatForever(autoreverses: true)) {
                tableRimBurst = 0.8
            }
            withAnimation(.easeInOut(duration: AppAnimation.forgeSwayOscillation).repeatForever(autoreverses: true)) {
                tableForgeEnergy = 1.0
            }
        }
    }

    // MARK: - Sheet peek mechanics (Beat 7)

    /// The expanded sheet rests inset from the top (a card sheet, One Year
    /// grammar) — MUST equal FounderLetterPhase.topInsetFrac so the peek→full
    /// phase swap exchanges identical geometry.
    private var expandedTopInset: CGFloat { screenSize.height * 0.15 }

    /// Top of the sheet in screen space: peeking at the bottom edge → resting at
    /// the inset line. Drag adjusts from the resting detent; never above the inset.
    private var sheetOffset: CGFloat {
        let resting = sheetExpanded ? expandedTopInset : screenSize.height - peekHeight
        return max(expandedTopInset, resting + sheetDrag)
    }

    private var peekDragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                peekPressed = true
                guard !sheetExpanded else { return }
                sheetDrag = v.translation.height   // negative = pulling up
            }
            .onEnded { v in
                peekPressed = false
                guard !sheetExpanded else { return }
                if v.translation.height < -60 {
                    expandSheet()
                } else {
                    withAnimation(AppAnimation.spring.reduceMotionSafe) { sheetDrag = 0 }
                }
            }
    }

    /// Expand FULLY, then advance — the swap to FounderLetterPhase happens
    /// while the sheet covers the screen (the curtain).
    private func expandSheet() {
        guard !sheetExpanded else { return }
        // Fade the deck out as the sheet rises (manual-pull path; the CTA path
        // sequences this as a 1-2 beat in presentLetter).
        withAnimation(AppAnimation.enter.reduceMotionSafe) { revealExiting = true }
        withAnimation(AppAnimation.enter.reduceMotionSafe) {
            sheetExpanded = true
            sheetDrag = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550)) // expansion settle
            director.advance(to: .founderLetter)
        }
    }
}

// MARK: - Beat 1: melt-through mask

/// The deck sinks straight down through the felt: a fixed clipping window
/// whose bottom edge IS the entry line — the deck genuinely translates
/// downward and is clipped as it passes under, with a soft absorption fade
/// over the last stretch so the edge melts rather than slices.
private struct MeltThroughFelt: ViewModifier {
    var progress: Double   // 0 intact → 1 fully under
    var size: CGSize

    func body(content: Content) -> some View {
        // Container includes the deck stack's layer spread (offsets reach
        // ~8pt past the top card) — at rest NOTHING is clipped or faded, so
        // the deck is pixel-identical to ConfirmationPhase's landed cards.
        let H = size.height + 12
        // Absorption band fades IN as the melt begins; fully opaque at rest.
        let bandTop = 1.0 - 0.15 * min(1.0, progress * 6.0)
        content
            .offset(y: CGFloat(progress) * H * 1.1)
            .frame(width: size.width + 14, height: H, alignment: .top)
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.00),
                        .init(color: .black, location: bandTop),
                        .init(color: progress > 0.001 ? .clear : .black, location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}

```

---

## File: `Vayl/Features/Onboarding/Director/BuildDeckCeremony.swift` {#file-vayl-features-onboarding-director-builddeckceremony-swift}

```swift
//
//  BuildDeckCeremony.swift
//  Vayl
//
//  Manages the foil tear composition and shatter logic for BuildDeckPhase.
//

import SwiftUI

@Observable
@MainActor
final class BuildDeckCeremony {
    
    var foilIntegrity: Double = 1.0
    var foilTears: [FoilTear] = []
    
    private var strikeSequenceIndex: Int = 0
    private var strikeMirrored: Bool = false
    
    private static let strikeSequences: [[(zone: CGPoint, angleDeg: Double)]] = [
        [(CGPoint(x: 0.28, y: 0.233),  10),
         (CGPoint(x: 0.74, y: 0.480), 125),
         (CGPoint(x: 0.45, y: 0.747),  85)],
         
        [(CGPoint(x: 0.25, y: 0.230), 45),
         (CGPoint(x: 0.75, y: 0.770), 45),
         (CGPoint(x: 0.50, y: 0.500), 45)],
         
        [(CGPoint(x: 0.70, y: 0.787), 175),
         (CGPoint(x: 0.26, y: 0.467),  80),
         (CGPoint(x: 0.52, y: 0.200),  35)],
    ]
    
    func runEntry() {
        foilIntegrity = 1.0
        foilTears = []
        
        // Locked to "The Pincer"
        strikeSequenceIndex = 1
        strikeMirrored = false
    }
    
    func addFoilTear(atFaceUV uv: CGPoint) {
        guard foilIntegrity > 0.5, foilTears.count < 3 else { return }
        
        let spec = Self.strikeSequences[strikeSequenceIndex][foilTears.count]
        var zone = spec.zone
        var angle = spec.angleDeg
        
        if strikeMirrored {
            zone.x = 1 - zone.x
            angle = 180 - angle
        }
        
        let pulled = CGPoint(x: uv.x + (zone.x - uv.x) * 0.75,
                             y: uv.y + (zone.y - uv.y) * 0.75)
        let dx = pulled.x - zone.x
        let dy = pulled.y - zone.y
        let offset = (dx * dx + dy * dy).squareRoot()
        let maxOffset: CGFloat = 0.10
        let strike = offset <= maxOffset ? pulled
            : CGPoint(x: zone.x + dx / offset * maxOffset,
                      y: zone.y + dy / offset * maxOffset)
                      
        foilTears.append(FoilTear(faceUV: strike, angleDeg: angle))
        
        if foilTears.count >= 3 {
            withAnimation(AppAnimation.foilDissolve.reduceMotionSafe) {
                self.foilIntegrity = 0
            }
        }
    }
}

```

---

## File: `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` {#file-vayl-features-onboarding-canvas-vayldirector-swift}

```swift
// Features/Onboarding/Canvas/VaylDirector.swift

import SwiftUI
import SpriteKit

@Observable
@MainActor
final class VaylDirector: OnboardingStage {

    var phase: OBPhase = .stat

    var tableCards:      [VaylCardModel] = []
    var cornerDeckCards: [VaylCardModel] = []
    var inFlightCards:   [VaylCardModel] = []
    var muckCards:       [VaylCardModel] = []

    var onboardingData: OnboardingData = OnboardingData()
    var openerDeckType: OpenerDeckType = .anxious

    /// Which credential the ConfirmationPhase is currently editing. Drives the
    /// edit half-sheet hosted at OnboardingCanvasWrapper (outside the canvas,
    /// which forbids .sheet). nil = no sheet open.
    var editingCredential: OBCredential? = nil

    /// Drives the single-user couples-first greeting sheet, hosted OUTSIDE the canvas (the
    /// canvas forbids .sheet — same pattern as editingCredential). Set when the user confirms
    /// "I'm single" in ContextPhase; the greeting's Continue commits the pending conclusion.
    var showSingleGreeting: Bool = false
    @ObservationIgnored private var pendingSingleConclusion: (RelationshipContext, SituationalRegister)?

    var tableFade:          Double = 0.0
    var dealPointIntensity: Double = 0.0

    // Lazy — deferred until first access so previews and unit tests that
    // create VaylDirector() don't spin up a SpriteKit scene unnecessarily.
    // @ObservationIgnored is safe because the scene object never changes;
    // only its contents mutate (handled internally by CardFlightScene itself).
    @ObservationIgnored lazy var cardFlightScene: CardFlightScene = CardFlightScene()


    // MARK: - Gender Phase  (extracted → GenderSequencer)
    //
    // All gender state + the autonomous sequence now live in GenderSequencer. The director
    // holds it (same @ObservationIgnored lazy pattern as cardFlightEngine) and conforms to
    // OnboardingStage so the sequencer can record its result into onboardingData.
    @ObservationIgnored lazy var gender = GenderSequencer(stage: self)

    @ObservationIgnored lazy var projector = DealerProjector()
    @ObservationIgnored lazy var curiosity = CuriositySequencer(stage: self)
    @ObservationIgnored lazy var ceremony = BuildDeckCeremony()

    // Name phase orchestration — extracted from NamePhase. NamePhase reads `director.name.*`
    // and forwards taps/gestures to it. Concrete director ref (it needs dealSingleCard /
    // cardFlightScene / receiveCredential / advance, beyond the OnboardingStage surface).
    @ObservationIgnored lazy var name = NameSequencer(director: self)

    // Demo phase orchestration — extracted from DemoPhase, same pattern as `name`.
    // DemoPhase reads `director.demo.*`; it calls commitDemoSnapshot / advance through here.
    @ObservationIgnored lazy var demo = DemoSequencer(director: self)



    var deckPulse: Bool = false

    private var sequenceAttempt:   Int = 0

    @ObservationIgnored lazy var cardFlightEngine: CardFlightEngine = CardFlightEngine(director: self)

    /// True when the final commit failed (incomplete data or save error). Observable
    /// hook for the terminal phase to surface an error / retry. finishOnboarding()
    /// resets it on each attempt. Failure is non-destructive — the user stays in OB.
    var commitFailed: Bool = false

    func start() {
        phase = .stat
        handlePhaseEntry(.stat)
    }

    private var isTransitioning: Bool = false

    func advance(to next: OBPhase) {
        guard !isTransitioning else { return }
        isTransitioning = true
        // No dealer line outlives its phase: hide it AT advance and invalidate
        // any pending hide timer. The next phase may show its own line from
        // entry — an outgoing phase's teardown (onDisappear fires ~300ms later,
        // mid cross-fade) must never be the thing that clears the canvas line,
        // or it wipes the incoming phase's copy.
        
        projector.hideDealerLine()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50)) // advance debounce — double-fire guard only
            phase = next
            handlePhaseEntry(next)
            isTransitioning = false
        }
    }

    private func handlePhaseEntry(_ phase: OBPhase) {
        switch phase {
        case .stat:            break
        case .demo:            runDemoEntry()
        case .name:            runNameEntry()
        case .modeSelect:      runModeSelectEntry()
        case .gender:          gender.runEntry()
        case .experienceLevel: runExperienceLevelEntry()
        case .context:         runContextEntry()
        case .curiosity:       curiosity.runEntry()
        case .confirmation:    runConfirmationEntry()
        case .buildDeck:       runBuildDeckEntry()
        case .founderLetter:   runFounderLetterEntry()
        }
    }

    private func runNameEntry() {
        cardFlightEngine.resetSlotPool()
        Task { @MainActor in
            // One breath after the cross-fade, then the felt blooms. easeOut so
            // the table is perceptible immediately — easeIn held it at near-zero
            // for the first half and the world arrived after the dealer spoke.
            try? await Task.sleep(for: .milliseconds(200))
            // DemoPhase now owns the table fade-in (it precedes name). If the felt
            // is already up, don't re-animate to the same value — guard so the
            // carry-over from demo stays seamless. Re-fading 1.0→1.0 is a visual
            // no-op, but the guard keeps the intent explicit.
            guard tableFade < 1.0 else { return }
            withAnimation(AppAnimation.cinematicFade) { tableFade = 1.0 }
        }
    }

    /// DemoPhase entry — owns only the table fade-in (moved off name). The full
    /// scene (intro lines → deal → flip → tap-lift → compose → swipe-seal) is
    /// driven by DemoPhase itself, mirroring how NamePhase owns runDealerIntro.
    private func runDemoEntry() {
        cardFlightEngine.resetSlotPool()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(AppAnimation.cinematicFade) { tableFade = 1.0 }
        }
    }

    /// Called by DemoPhase when the snapshot seals (card landed in the deck).
    /// Derives the EmotionalRegister from verb × noun, writes the snapshot data,
    /// and credits the corner deck. The phase owns the visual seal/dissolve/pocket
    /// and fires the advance to .name after its closing beat.
    func commitDemoSnapshot(verb: DemoVerb, noun: String) {
        let trimmed = noun.trimmingCharacters(in: .whitespaces)
        onboardingData.demoVerb          = verb.rawValue
        onboardingData.demoNoun          = trimmed
        onboardingData.emotionalRegister = DemoDictionary.register(verb: verb, noun: trimmed).rawValue
        receiveCredential(.snapshot)
    }

    private func runModeSelectEntry() {
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
        // Speech bubble handled by ModeSelectPhase directly
    }
    private func runExperienceLevelEntry() {
        // Controller is View-owned (@State in ExperienceLevelPhase); nothing to reset here.
    }

    /// The single path for crediting the corner deck. Appends a freshly-collected
    /// credential card and plays the "deck receives a card" pulse. Phases call this
    /// instead of mutating `cornerDeckCards` / `deckPulse` directly — keeps card-state
    /// ownership in the director (Views never write card models).
    func receiveCredential(_ credential: OBCredential) {
        let card = VaylCardModel()
        card.credential = credential
        cornerDeckCards.append(card)
        withAnimation(AppAnimation.deckReceive) { deckPulse = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            deckPulse = false
        }
    }

    /// Called by ExperienceLevelPhase on confirm. Writes nmStage, adds the collected
    /// card to the corner deck (so the "X / 6" count grows), pulses the deck, then advances.
    func commitExperienceLevel(_ intensity: CandleIntensity) {
        onboardingData.nmStage = intensity.nmStage

        receiveCredential(.experienceLevel)
        // NOTE: advance to .context is NOT fired here. This method is the "receive"
        // step — it must coincide with the winner card landing in the deck. The phase
        // advance flows from ExperienceLevelPhase's `.done` state observer, after the
        // controller has cleared the two discards and held a settle beat.
    }
    private func runContextEntry() {
        cardFlightEngine.resetSlotPool()
        // Entrance copy + table recede are sequenced by ContextPhase.onAppear, so the
        // felt carries over from ExperienceLevel and only dissolves once the dealer
        // headline has greeted (earned transition, not an abrupt yank).
    }

    /// Bridging line that opens ContextPhase. Fires on the clean, still-present
    /// felt. No hide timer — ContextPhase holds for the returned copy's type
    /// time, then sequences the recede/assembly and hides the line itself.
    /// Built here, never raw from View.
    @discardableResult
    func showContextHeadline() -> String {
        let copy = DealerDictionary.contextHeadline(appMode: onboardingData.appMode)
        projector.showDealerLineManual(copy)
        return copy
    }

    /// Selection-dependent exit line shown at the end of ExperienceLevelPhase,
    /// before the phase advances to Context. Fires on the clean table after the
    /// deck pulse. Director-owned — never raw in the View. No hide timer: the
    /// phase holds for the returned copy's type time, then advance() fades the
    /// line into the cross-fade. Returns the copy so the caller can compute
    /// that hold via AppDealerTyping.typeDuration.
    @discardableResult
    func showExpLevelExitLine(_ intensity: CandleIntensity) -> String {
        let copy = DealerDictionary.experienceLevelExitLine(intensity: intensity)
        projector.showDealerLineManual(copy)
        return copy
    }

    /// Fades the felt fully out so the context carousel reads as suspended *away
    /// from* the table. Safe to call from `ContextPhase.onAppear` as well as
    /// `runContextEntry()` — guarantees the fade regardless of how the phase was
    /// entered (real advance vs. direct phase set). The table (and corner deck)
    /// re-emerge at exit when the confirmed card is pocketed (see commitContext).
    func recedeTableForContext() {
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 0.0 }
    }


    /// Called by ContextPhase once the cards have begun their exit. Writes the
    /// chosen relationship context + situational register, adds the `.context`
    /// credential to the corner deck, re-emerges the felt, projects a dealer line
    /// that responds to the choice, then advances to CuriosityPhase after a copy beat.
    /// `advance` stays the sole phase gate.
    func concludeContext(relationshipContext: RelationshipContext,
                         situationalRegister: SituationalRegister) {
        onboardingData.relationshipContext = relationshipContext.rawValue
        onboardingData.situationalRegister = situationalRegister.rawValue

        // Felt re-emerges; the responsive line types over it.
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
        let reply = DealerDictionary.contextResponse(for: situationalRegister)
        projector.showDealerLineManual(reply)

        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            // Deck credit waits for the felt to be back on stage — the corner
            // deck is tableFade-gated, so an instant pulse fired on a deck that
            // was barely visible. 400ms ≈ mid-recede, deck clearly present.
            try? await Task.sleep(for: .milliseconds(400))
            guard current == self.sequenceAttempt else { return }
            receiveCredential(.context)

            // Hold for the reply to land + a read beat; advance() fades the
            // line into the cross-fade toward Curiosity.
            try? await Task.sleep(for: .milliseconds(
                AppDealerTyping.typeDuration(reply) + 300
            ))
            guard current == self.sequenceAttempt else { return }
            advance(to: .curiosity)
        }
    }

    /// Show the couples-first greeting before concluding (single only). The pending
    /// (context, register) is committed when the user taps Continue in the sheet.
    func presentSingleGreeting(context: RelationshipContext, register: SituationalRegister) {
        pendingSingleConclusion = (context, register)
        withAnimation(AppAnimation.standard.reduceMotionSafe) { showSingleGreeting = true }
    }

    /// Continue from the greeting → conclude the context as normal (felt returns, the dealer
    /// replies, advance to Curiosity).
    func continueFromSingleGreeting() {
        withAnimation(AppAnimation.standard.reduceMotionSafe) { showSingleGreeting = false }
        guard let (context, register) = pendingSingleConclusion else { return }
        pendingSingleConclusion = nil
        concludeContext(relationshipContext: context, situationalRegister: register)
    }

    /// Dealer line that responds to the chosen situational register. Dealer voice = "I",
    /// never "we" / "let's" — the OB always addresses the individual.

    private func runConfirmationEntry() {
        // Confirmation reviews the deck on the table — ensure the felt is present
        // so the credential cards deal onto it. The cards themselves are rendered
        // by ConfirmationPhase (its own VaylCardFace symbol cards).
        withAnimation(AppAnimation.tableBloom.reduceMotionSafe) { tableFade = 1.0 }
    }
    /// BuildDeck entry. Pins the felt to 1.0 EXPLICITLY rather than relying on the
    /// carry-over from Confirmation — so the forge always mounts on a present table,
    /// even if Confirmation's exit ever changes to recede the felt. Then arms the
    /// ceremony state (foil sequence). The phase itself drives the melt/forge beats.
    private func runBuildDeckEntry() {
        tableFade = 1.0
        ceremony.runEntry()
    }

    // MARK: - OnboardingStage Protocol Conformance (Dealer Projector Forwarding)

    func showDealerLineManual(_ text: String, anchorYFrac: CGFloat) {
        projector.showDealerLineManual(text, anchorYFrac: anchorYFrac)
    }

    func hideDealerLine() {
        projector.hideDealerLine()
    }

    func recedeTableForForge() {
        withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 0.0 }
    }
    private func runFounderLetterEntry() {
        // Terminal phase entry. Commit no longer fires here — completion is an
        // explicit user action via finishOnboarding(), so it reflects intent rather
        // than a side effect of arriving at the phase. FounderLetter visuals are a
        // later design pass; they invoke finishOnboarding() and read commitFailed.
        //
        // Restore the felt INSTANTLY behind the now-opaque letter sheet. The forge
        // receded the table (Beat 3c) and nothing brought it back — so the curtain
        // pull-down had nothing to reveal, and finishOnboarding's cinematicFade
        // animated 0→0 (a no-op; the OB ended on a black frame). With the felt
        // present behind the sheet, the pull-down reveals the warm table and the
        // cinematicFade genuinely dissolves it as routing carries the user home.
        tableFade = 1.0
    }

    /// Called by FounderLetterPhase when the user finishes onboarding.
    /// Commits through the store (gated by isReadyToComplete; surfaces errors). On
    /// success the felt recedes and reactive routing (AppRootView reads AppState)
    /// carries the user out of onboarding. On failure the user stays put — nothing
    /// is lost — and commitFailed is set for the View to surface a retry.
    func finishOnboarding(using store: OnboardingStore) {
        commitFailed = false
        guard store.commit(data: onboardingData) else {
            commitFailed = true
            return
        }
        sequenceAttempt += 1
        let current = sequenceAttempt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100)) // post-commit settle
            guard current == self.sequenceAttempt else { return }
            // The set changes behind the descending letter: the warm felt
            // (restored in runFounderLetterEntry) dissolves to void as reactive
            // routing swaps in Home. (No deckPulse here — it was an orphan write
            // that never reset and pulsed a corner deck that isn't on stage.)
            withAnimation(AppAnimation.cinematicFade.reduceMotionSafe) { self.tableFade = 0 }
        }
    }



    // MARK: - Card Flight Engine Forwarding

    @MainActor
    func dealSingleCard(screenSize: CGSize, scale: CGFloat) async -> (offset: CGSize, angle: Double, flightID: String)? {
        await cardFlightEngine.dealSingleCard(screenSize: screenSize, scale: scale)
    }

    func claimLandingSlot(screenSize: CGSize) -> CardLandingSlot.Resolved {
        cardFlightEngine.claimLandingSlot(screenSize: screenSize)
    }

    func sailCard(
        cardID:       String,
        image:        UIImage,
        from:         CGPoint,
        to:           CGPoint,
        sceneSize:    CGSize,
        duration:     TimeInterval = 0.92,
        initialAngle: CGFloat      = -0.24,
        finalAngle:   CGFloat      = 0.0314,
        zPosition:    CGFloat      = 0
    ) async -> (CGPoint, CGFloat) {
        await cardFlightEngine.sailCard(
            cardID: cardID, image: image, from: from, to: to,
            sceneSize: sceneSize, duration: duration,
            initialAngle: initialAngle, finalAngle: finalAngle, zPosition: zPosition
        )
    }

    func evaluateOpenerDeckType() {
        // NMStage-keyed opener selection. Mode-independent BY DESIGN — keys on
        // experience + register + curiosity, never appMode.
        let register = SituationalRegister(rawValue: onboardingData.situationalRegister ?? "") ?? .flexible
        let stage    = onboardingData.nmStage
        let richCuriosity = onboardingData.curiositySelections.count >= 4

        switch (stage, register) {
        case (.experienced, .anxious):
            openerDeckType = .reflectiveCalm
        case (.experienced, _):
            openerDeckType = .reflectiveOpen
        case (_, .anxious) where !richCuriosity:
            openerDeckType = .anxious
        default:
            openerDeckType = .excited
        }
        onboardingData.openerDeckType = openerDeckType
    }




}

```

---

## File: `Vayl/Design/Components/Effects/FoilOpen/MetallicCaseView.swift` {#file-vayl-design-components-effects-foilopen-metalliccaseview-swift}

```swift
//
//  MetallicCaseView.swift
//  Vayl
//
//  FoilOpen module — Layer 1 (reusable, content-agnostic).
//
//  The sealed deck's 3D tuck-box: near-void anodized metal with the card back's
//  hex lattice DEBOSSED into the front face. A `Canvas` projects the box (front +
//  visible side + top faces, painter-sorted, per-face brightness = the 3D read);
//  the `hexFoilSurface` shader maps pixels into face-local UV over the projected
//  front quad and lights the groove flanks with one tilt-driven anisotropic band
//  in the deck's colorway (`FoilDeckTheme`). Light lives in the carved structure —
//  flats stay dark. The deck name is embossed low on the face in ClashDisplay,
//  same emboss recipe as the VaylCardBack wordmark.
//
//  Drawing the box in a Canvas (rather than nested rotation3DEffect, which SwiftUI
//  can't composite into a shared 3D scene) means the later crack/disintegrate pass
//  draws in the SAME projected face-space → cracks stay ISOLATED on the deck.
//
//  Everything tunable lives as a stored property below — tinker on device.
//

import SwiftUI
import UIKit
import Darwin

/// A crack in the sealed case, anchored in FACE-LOCAL UV (0…1 across the front
/// face) so it sticks to the case through float and tilt. The FoilOpen module's
/// own currency — consumers map their tear records into this.
struct CaseTear: Identifiable, Equatable {
    let id: UUID
    let faceUV: CGPoint
    let seed: UInt64
    /// When the strike landed — the crack propagates outward from this moment.
    let struck: Date
    /// Dominant orientation of the main fracture (degrees; 0 = horizontal).
    let angleDeg: Double
}

struct MetallicCaseView: View {

    // MARK: - Tunables

    var depthFrac:      CGFloat = 0.30   // box depth as a fraction of face width (full-deck heft; ~0.26 thinner)
    var tiltAmplitude:  Double  = 6      // float tilt amplitude (deg) — subtle
    var floatSpeed:     Double  = 0.7
    var perspective:    Double  = 600    // smaller = more convergence/foreshortening (photographic; 820 = flat/CAD)
    var saturation:     Double  = 0.95   // richer base (the holo iridescence adds the electric pop)
    var metalDarkness:  Double  = 0.52   // how dark the metal base sits (solid deep colour, not black)
    var ambient:        Double  = 0.28   // floor brightness on faces away from light (low = box reads in 3D)
    var frontLightAnchor: Double = 1.0   // hold the FRONT face's VALUE steady as the box tips flat→¾.
                                         // The hue is already anchored (caseGeometry.hueDeg) so the metal
                                         // never recolours on the rise — but its brightness wasn't, so the
                                         // hero face darkened 0.72→~0.41 and the eye read that as a hue
                                         // shift. 1 = fully steady · 0 = pure normal lighting (old behaviour).
    var hueOffset:      Double  = 90     // pick the single metal colour (deg) — ≈ deep purple
    var hueShift:       Double  = 1.4    // how much that one colour shifts as it tilts
    var boxScale:       CGFloat = 0.70   // box size as fraction of the fitting square

    // Foil surface — debossed hex lattice (hexFoilSurface). Light lives in the
    // carved structure: groove flanks ignite in the deck colorway as one
    // tilt-driven band sweeps the face. No noise, no time-driven animation.
    var cornerSoftness: Double  = 0.06   // rounding of the box SILHOUETTE — low = crisp/boxy deck case,
                                         // high = pillowy. ~0.04 very boxy · ~0.10 soft tuck-box (was 0.14, too round)
    var flatScale:      CGFloat = 1.0    // footprint while FLAT on the felt — fills the frame, matching the deck that melted
    var latticeColumns: Double = 13      // hex columns across the face width
    var grooveWidth:    Double = 0.10    // groove half-width in cell units
    var bandSharpness:  Double = 10      // band specular exponent
    var bandGain:       Double = 0.9     // band strength
    var glintGain:      Double = 0.5     // per-cell glint strength
    var bandTravel:     Double = 0.35    // band phase per degree of Y tilt
    var grainGain:      Double = 0.15    // anodized micro-grain amplitude on the flats (0 = flat mockup)
    var grainScale:     Double = 200     // grain frequency across the face width (higher = finer)
    var fresnelGain:    Double = 0.12    // #2 grazing-edge rim brightening (panel border catches the room)
    var envGain:        Double = 0.30    // #3 two-tone vertical environment the metal reflects (cool top → deep bottom)
    var edgeCatchGain:  Double = 0.55    // #1 edge catch-light intensity on the silhouette + front panel (0 = off)
    var edgeCatchTint:  Double = 0.25    // 0 = full cool blue-purple (colorway) · 1 = white. Hue of the catch-light.
    var frameOpacity:   Double = 0.6     // spectrum-border colorway opacity (was 0.27 — muted by the metal effects)
    var frameWidth:     Double = 1.3     // spectrum-border crisp line width
    var frameGlow:      Double = 0.7     // spectrum-border glow-pass strength (0 = crisp line only)
    var frameGlowRadius: Double = 4      // spectrum-border glow blur radius
    var theme: FoilDeckTheme   = .vayl

    // Arrival pose (ceremony spec Beat 3): nil = full float pose (default for
    // previews and any consumer that doesn't choreograph an arrival). Set to a
    // Date to drive the rise from that moment: FACE-ON flat on the felt (the
    // table's card grammar — matching the deck that melted) tipping back into
    // the floating ¾ box. Material stays asleep until latticeWakeStart.
    var riseStart:    Date?  = nil
    var riseDuration: Double = 1.4

    /// When the hex lattice + band WAKE (ceremony: "start the hex animation
    /// upon zoom-in"). `.distantPast` (default) = awake from the first frame;
    /// `.distantFuture` = asleep (plain anodized metal) until the caller
    /// assigns a real date, after which the material fades in over ~1.2s.
    var latticeWakeStart: Date = .distantPast

    /// Cracks on the sealed case (Beat 5 ceremony) — rendered in face space
    /// with colorway light-bleed that escalates per tear.
    var tears: [CaseTear] = []

    /// When the shatter begins (third crack): `.distantFuture` = sealed.
    /// Assigning a real date runs OVERLOAD then the UN-KNIT — the shell
    /// disassembles cell by cell along its own hex lattice, uncovering whatever
    /// the consumer mounted behind the view (formation-in-reverse, not confetti).
    var dissolveStart: Date = .distantFuture

    // Un-knit timeline + wave shape (module tunables — tinker on device).
    var overloadSpan: Double = 0.45   // held breath: cracks flare, nothing moves
    var unknitSpan:   Double = 1.25   // the wave front crossing the whole shell
    var unknitBand:   Double = 3.2    // wave front thickness (lattice units) — cells actively departing

    /// Tap-to-crack: when set, taps landing on (or near) the FRONT FACE are
    /// converted to face-local UV at tap time — the inverse-bilinear of the
    /// projected quad — and forwarded. The consumer routes them to its store;
    /// the module never owns crack state.
    var onFaceTap: ((CGPoint) -> Void)? = nil

    /// The KNOCK FROM INSIDE (pre-strike anticipation): each new date plays a
    /// brief seam glimmer — light trying a few hex grooves from within. The
    /// consumer pairs it with a physical twitch + soft haptic.
    var knockStart: Date = .distantFuture
    var knockSeed:  UInt64 = 0

    /// CORE GLOW from within (Segment 2): the contained energy leaking through the
    /// hex groove network. 0 = sealed/dark; climbs as the deck strains toward the
    /// break. Lights the lattice SEAMS in the colorway — light from the case's own
    /// structure, not a backdrop. Generic intensity (module stays content-agnostic).
    var coreGlow: Double = 0

    /// FLAT static mode (grids / thumbnails): locks the rise pose to 0 (face-on,
    /// full footprint) and renders ONCE — no TimelineView — so many instances on
    /// screen stay cheap. The full animated 3D case is the default (flat == false).
    var flat: Bool = false

    init(theme: FoilDeckTheme = .vayl,
         flat: Bool = false,
         riseStart: Date? = nil,
         riseDuration: Double = 1.4,
         latticeWakeStart: Date = .distantPast,
         tears: [CaseTear] = [],
         dissolveStart: Date = .distantFuture,
         onFaceTap: ((CGPoint) -> Void)? = nil,
         knockStart: Date = .distantFuture,
         knockSeed: UInt64 = 0,
         coreGlow: Double = 0) {
        self.theme = theme
        self.flat = flat
        self.riseStart = riseStart
        self.riseDuration = riseDuration
        self.latticeWakeStart = latticeWakeStart
        self.tears = tears
        self.dissolveStart = dissolveStart
        self.onFaceTap = onFaceTap
        self.knockStart = knockStart
        self.knockSeed = knockSeed
        self.coreGlow = coreGlow
    }


    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Per-frame geometry

    /// Everything the Canvas closure AND the foil shader need each frame.
    /// Computed once per frame in `foilLayer` so the shader's front-quad
    /// uniforms always match the Canvas-drawn box exactly.
    private struct CaseGeometry {
        let rx: Double           // X tilt (radians)
        let ry: Double           // Y tilt (radians)
        let ryDeg: Double        // Y tilt (degrees) — drives the band phase
        let hueDeg: Double       // hue driver — anchored at the float's resting yaw
                                 // through flat + rise so the metal NEVER changes
                                 // colour as it stands; only the float drift shifts it
        let boxFit: Double       // face width after the pose-mixed scale — one source for draw + culling
        let proj: [CGPoint]      // 8 projected corners
        let frontQuad: [CGPoint] // front face TL, TR, BR, BL (proj[0...3])
    }

    /// 0 = lying flat on the felt · 1 = full float pose. Smoothstep-eased from
    /// `riseStart`; Reduce Motion (motion == false) snaps to the final pose.
    /// A caller that wants the case to MOUNT flat passes `.distantFuture` and
    /// later assigns the real lift moment.
    private func risePose(t: Double, motion: Bool) -> Double {
        if flat { return 0 }                  // grid/thumbnail: lock face-on flat
        guard let riseStart else { return 1 }
        guard motion else { return 1 }
        let elapsed = t - riseStart.timeIntervalSinceReferenceDate
        let p = min(1, max(0, elapsed / riseDuration))
        return p * p * (3 - 2 * p)
    }

    /// 0 = lattice asleep (plain anodized metal) · 1 = fully awake.
    /// Reduce Motion: snaps to the terminal state (awake unless still pending).
    private func latticeWake(t: Double, motion: Bool) -> Double {
        if latticeWakeStart == .distantFuture { return 0 }
        guard motion else { return 1 }
        let e = (t - latticeWakeStart.timeIntervalSinceReferenceDate) / 1.2
        let p = min(1, max(0, e))
        return p * p * (3 - 2 * p)
    }

    private func caseGeometry(size: CGSize, t: Double, motion: Bool, pose: Double,
                              calm: Double = 0) -> CaseGeometry {
        // float — biased to a clear 3/4 view (static angle shows the 3D), with only a
        // gentle drift on top so it reads as floating without "moving too much".
        // `pose` mixes from the flat-on-the-felt arrival to the floating ¾ view.
        // FLAT follows the table's card grammar: a card lying on the felt is a
        // FACE-ON flat graphic (rx = ry = 0, full footprint) — exactly how the
        // melted deck looked — never a real-3D edge-on sliver. The rise tips it
        // back into the ¾ view: the flat printed thing stands up into a 3D box.
        let osc = (motion ? 1.0 : 0.0) * pose * (1.0 - calm)
        let restYawDeg = 21.0                // the float's resting ¾ yaw
        let ryDeg = restYawDeg * pose
                  + osc * tiltAmplitude        * dsin(t * 0.42 * floatSpeed)
        let rxDeg = -16.0 * pose
                  + osc * tiltAmplitude * 0.4 * dcos(t * 0.31 * floatSpeed)
        let rx = rxDeg * .pi / 180, ry = ryDeg * .pi / 180
        // Hue rides the RESTING yaw, not the rise sweep — the flat case is the
        // same purple it will float at; standing up never reads as a recolour.
        let hueDeg = ryDeg + restYawDeg * (1.0 - pose)

        // box dimensions — flat fills the frame (the deck's footprint), the
        // floating pose settles to boxScale so the tilt has margin to swing in
        let scaleMix = Double(flatScale) + (Double(boxScale) - Double(flatScale)) * pose
        let fit = Double(min(size.width, size.height / 1.5)) * scaleMix
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]
        let proj = corners3D.map { project(rotate($0, rx: rx, ry: ry), center: center) }
        return CaseGeometry(rx: rx, ry: ry, ryDeg: ryDeg, hueDeg: hueDeg, boxFit: fit,
                            proj: proj, frontQuad: Array(proj[0...3]))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Group {
                if reduceMotion || flat || AppAnimation.lowPower {
                    foilLayer(size: size, t: 0, motion: false)
                } else {
                    TimelineView(.animation) { tl in
                        foilLayer(size: size, t: tl.date.timeIntervalSinceReferenceDate, motion: true)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    handleTap(value.location, size: size)
                },
                including: onFaceTap == nil ? .none : .all
            )
        }
    }

    /// The shatter timeline, two acts from `dissolveStart`:
    ///   OVERLOAD (0…overloadSpan) — every crack flares white-hot, the light
    ///   inside maxes out, nothing moves: the held breath before the shell gives.
    ///   UN-KNIT (overloadSpan…+unknitSpan) — the shell disassembles cell by
    ///   cell along its hex lattice; `flood` 0→1 is the wave's progress.
    /// Reduce Motion snaps both to done (the shell is simply gone — the content
    /// behind stands revealed with no motion).
    private func dissolvePhases(t: Double, motion: Bool) -> (overload: Double, flood: Double) {
        if dissolveStart == .distantFuture { return (0, 0) }
        guard motion else { return (1, 1) }
        let e = t - dissolveStart.timeIntervalSinceReferenceDate
        let overload = min(1, max(0, e / overloadSpan))
        let f = min(1, max(0, (e - overloadSpan) / unknitSpan))
        return (overload, f * f * (3 - 2 * f))
    }

    /// Convert a tap in view space to face-local UV via the inverse-bilinear of
    /// the CURRENT projected front quad (same geometry path the renderer uses),
    /// then forward it. Taps near the face edge are clamped in — during the
    /// ceremony "the case" is the target, not a precise quad.
    private func handleTap(_ point: CGPoint, size: CGSize) {
        guard let onFaceTap else { return }
        let motion = !reduceMotion
        let t = motion ? Date.now.timeIntervalSinceReferenceDate : 0
        let pose = risePose(t: t, motion: motion)
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose)
        guard let uv = invBilinear(point, quad: geo.frontQuad),
              (-0.18...1.18).contains(uv.x), (-0.18...1.18).contains(uv.y) else { return }
        onFaceTap(CGPoint(x: min(max(uv.x, 0.04), 0.96),
                          y: min(max(uv.y, 0.04), 0.96)))
    }

    @ViewBuilder
    private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
        let pose = risePose(t: t, motion: motion)
        let wake = latticeWake(t: t, motion: motion)
        let (overload, flood) = dissolvePhases(t: t, motion: motion)
        // the world holds its breath: the float drift damps to stillness
        // through the overload — nothing sways while the cracks scream
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose, calm: overload)
        ZStack {
        // BEHIND the shell: the glowing interior, revealed through erased wounds.
        // Carries the through-cracks (Segment 5) and drains as the un-knit
        // sweeps, handing the reveal to whatever the consumer mounted behind.
        if !tears.isEmpty {
            Canvas { ctx, _ in
                drawInterior(&ctx, geo: geo, t: t, motion: motion, flood: flood)
            }
        }
        Canvas { ctx, _ in
            drawCase(&ctx, size: size, geo: geo)
            drawKnock(&ctx, geo: geo, t: t, motion: motion)
            drawTears(&ctx, geo: geo, overload: overload, t: t, motion: motion)
            eraseUnknit(&ctx, geo: geo, flood: flood)
        }
            // Debossed hex foil — the band phase is driven by the FLOAT TILT, not
            // time, so the light only moves because the box moves (and Reduce
            // Motion freezes both together). No absolute timestamps reach the GPU.
            .colorEffect(ShaderLibrary.hexFoilSurface(
                .float2(geo.frontQuad[0]),
                .float2(geo.frontQuad[1]),
                .float2(geo.frontQuad[2]),
                .float2(geo.frontQuad[3]),
                .color(theme.colorway.c0),
                .color(theme.colorway.c1),
                .color(theme.colorway.c2),
                .float(Float(geo.ryDeg * bandTravel)),
                .float(Float(latticeColumns)),
                .float(Float(grooveWidth)),
                .float(Float(bandSharpness)),
                .float(Float(bandGain)),
                .float(Float(glintGain)),
                .float(Float(wake)),
                .float(Float(grainGain)),
                .float(Float(grainScale)),
                .float(Float(fresnelGain)),
                .float(Float(envGain)),
                .float(Float(coreGlow))
            ))
            // The shell is REMOVED cell by cell by eraseUnknit — no whole-object
            // fade. A final sliver fade cleans up the fold strips the lattice
            // wrap can't reach (wrapPoint dies past 90% of the depth).
            .opacity(flood > 0.92 ? max(0, (1 - flood) / 0.08) : 1)

            // UN-KNIT pieces: the freed cells at the wave front, drawn in a
            // plain Canvas (no foil shader) so they read as solid metal lifting
            // clear, plus the seam pre-glow where the lattice is about to give.
            if flood > 0.001, flood < 0.999 {
                Canvas { ctx, _ in
                    drawUnknitPieces(&ctx, geo: geo, flood: flood)
                }
            }
        }
    }

    // MARK: - Draw

    private func drawCase(_ ctx: inout GraphicsContext, size: CGSize, geo: CaseGeometry) {
        let rx = geo.rx, ry = geo.ry

        // ONE metal colour for the whole case (shifts slowly as it tilts — anodized).
        let caseHue = hueOffset + geo.hueDeg * hueShift
        // single light, mostly FRONTAL (high +z) so the front + top read bright and the side
        // panels go genuinely darker — that contrast is what makes the 3D box legible as it moves.
        let light = SIMD3(-0.20, -0.62, 0.72)

        // box dimensions — needed locally for face culling (rotated corner depth);
        // geo.boxFit carries the pose-mixed scale so culling matches the projection
        let fit = geo.boxFit
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2

        // 8 corners (front face = +z)
        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]

        let proj = geo.proj

        // faces: corner indices, outward normal (one colour for all — they differ by lighting)
        struct Face { let idx: [Int]; let n: SIMD3<Double>; let isFront: Bool }
        let faces: [Face] = [
            Face(idx: [0,1,2,3], n: SIMD3(0,0, 1), isFront: true),   // front
            Face(idx: [1,5,6,2], n: SIMD3( 1,0,0), isFront: false),  // right
            Face(idx: [4,0,3,7], n: SIMD3(-1,0,0), isFront: false),  // left
            Face(idx: [4,5,1,0], n: SIMD3(0,-1,0), isFront: false),  // top
            Face(idx: [3,2,6,7], n: SIMD3(0, 1,0), isFront: false),  // bottom
            Face(idx: [5,4,7,6], n: SIMD3(0,0,-1), isFront: false),  // back
        ]

        // visible faces (rotated normal toward camera), painter-sorted back→front
        let visible = faces
            .map { face -> (f: Face, rn: SIMD3<Double>, cz: Double) in
                let rn = rotate(face.n, rx: rx, ry: ry)
                let cz = face.idx.reduce(0.0) { acc, i in acc + rotate(corners3D[i], rx: rx, ry: ry).z } / 4
                return (face, rn, cz)
            }
            .filter { $0.rn.z > 0.001 }
            .sorted { $0.cz < $1.cz }

        // soft tuck-box silhouette: gently round the convex hull of the projected corners and
        // clip to it → soft outer corners with NO gaps; the panel folds inside stay crisp.
        ctx.clip(to: roundedFacePath(convexHull(proj), softness: cornerSoftness))

        for v in visible {
            let pts = v.f.idx.map { proj[$0] }
            var face = Path()
            face.move(to: pts[0])
            for p in pts.dropFirst() { face.addLine(to: p) }
            face.closeSubpath()

            // per-face brightness from a single light → top bright, front mid, side dark = 3D
            var brightness = max(ambient, (v.rn * light).sum())
            // Anchor the FRONT face's value across the rise (the twin of the hue
            // anchor): without this the hero face darkens as its normal tips off
            // the frontal light and reads as a recolour. Side/top faces stay
            // normal-lit — they carry the 3D.
            if v.f.isFront {
                let faceOn = max(ambient, light.z)   // front normal (0,0,1) · light
                brightness += (faceOn - brightness) * frontLightAnchor
            }
            let shading = metalShading(caseHue: caseHue, brightness: brightness,
                                       a: pts[0], c: pts[2])
            ctx.fill(face, with: shading)
        }

        // Edge catch-light (#1): a bright, top-lit rim on the silhouette and the
        // front panel edge — the chamfer catching the overhead key. The single
        // strongest "solid metal object" cue vs a flat fill. Brightest up top
        // (the light sits high), fading down. Additive (plusLighter) so it reads
        // as a highlight, not paint.
        if edgeCatchGain > 0 {
            let ys = proj.map(\.y)
            let top = ys.min() ?? 0, bot = ys.max() ?? 0
            let cx = size.width / 2
            // Catch-light hue: a cool blue-purple from the colorway's cool end, not
            // pure white — white reads as plastic / pasted-on against the saturated
            // metal. This reflects the cool "sky" of the two-tone, so the edge
            // belongs to the scene. edgeCatchTint lifts it toward white for pop.
            let coolStop = mix(Self.components(theme.colorway.c0),
                               Self.components(theme.colorway.c1), 0.5)
            let rimColor = color(mix(coolStop, SIMD3(1, 1, 1), edgeCatchTint))
            let rimShade = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: rimColor.opacity(edgeCatchGain), location: 0.0),
                    .init(color: .clear,                          location: 1.0),
                ]),
                startPoint: CGPoint(x: cx, y: top),
                endPoint:   CGPoint(x: cx, y: top + (bot - top) * 0.5))
            var rim = ctx
            rim.blendMode = .plusLighter
            rim.stroke(roundedFacePath(convexHull(proj), softness: cornerSoftness),
                       with: rimShade, lineWidth: 1.6)
            var frontPath = Path()
            let fq = geo.frontQuad
            frontPath.move(to: fq[0])
            for p in fq.dropFirst() { frontPath.addLine(to: p) }
            frontPath.closeSubpath()
            rim.stroke(frontPath, with: rimShade, lineWidth: 1.1)
        }

        // embossed brand layer (deck name + hairline frame) on the front face
        if let front = visible.first(where: { $0.f.isFront }) {
            drawBrand(&ctx, quad: front.f.idx.map { proj[$0] })
        }
    }

    /// Convex hull (monotone chain) of the projected box corners → the outer silhouette.
    private func convexHull(_ input: [CGPoint]) -> [CGPoint] {
        let pts = input.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        guard pts.count >= 3 else { return pts }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [CGPoint] = []
        for p in pts {
            while lower.count >= 2, cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        var upper: [CGPoint] = []
        for p in pts.reversed() {
            while upper.count >= 2, cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        lower.removeLast(); upper.removeLast()
        return lower + upper
    }

    // MARK: - Metallic shading

    /// Flat anodized faces — per-face brightness carries the 3D, the hex foil
    /// shader owns ALL the light play (band, glints, grooves). The old white
    /// specular streak predated the lattice and is gone for good.
    private func metalShading(caseHue: Double, brightness b: Double,
                              a: CGPoint, c: CGPoint) -> GraphicsContext.Shading {
        let core  = Self.metalHue(caseHue / 360)               // the single metal hue
        let grey  = (core.x + core.y + core.z) / 3
        let desat = mix(core, SIMD3(grey, grey, grey), 1 - saturation)
        let metal = mix(desat, Self.anchorDark, metalDarkness)
        let lit   = metal * b                                  // face brightness = the 3D read
        let lo    = lit * 0.88                                  // gentle edge falloff (no dark corners)
        return .linearGradient(
            Gradient(stops: [
                .init(color: color(lo),  location: 0.0),
                .init(color: color(lit), location: 0.5),
                .init(color: color(lo),  location: 1.0),
            ]),
            startPoint: a, endPoint: c)
    }

    // MARK: - Brand layer (embossed deck name + hairline frame)

    private func drawBrand(_ ctx: inout GraphicsContext, quad: [CGPoint]) {
        guard quad.count == 4 else { return }
        let edgeW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard edgeW > 1 else { return }

        // — hairline inset frame, colorway gradient, PERSPECTIVE-CORRECT —
        // Built in unit-face space, then every point mapped through the TRUE
        // projected quad (bilerp) instead of an affine parallelogram. The affine
        // map ignored the BR corner, so the bottom edge SAGGED under the tilt.
        let inset = 9.0 / edgeW                   // matches the card back's 9pt inset
        let x0 = inset, x1 = 1 - inset
        let y0 = inset * (2.0 / 3.0), y1 = 1 - inset * (2.0 / 3.0)
        let rx = 0.03, ry = 0.02                  // corner radius (u, v) — small, like the card back
        var unit: [CGPoint] = []
        let seg = 5
        func corner(_ cx: Double, _ cy: Double, _ from: Double, _ to: Double) {
            for k in 0...seg {
                let a = from + (to - from) * Double(k) / Double(seg)
                unit.append(CGPoint(x: cx + rx * dcos(a), y: cy + ry * dsin(a)))
            }
        }
        corner(x0 + rx, y0 + ry, .pi,       1.5 * .pi)   // TL
        corner(x1 - rx, y0 + ry, 1.5 * .pi, 2.0 * .pi)   // TR
        corner(x1 - rx, y1 - ry, 0.0,       0.5 * .pi)   // BR
        corner(x0 + rx, y1 - ry, 0.5 * .pi, .pi)         // BL
        var frame = Path()
        let mapped = unit.map { bilerp(quad, Double($0.x), Double($0.y)) }
        frame.move(to: mapped[0])
        for p in mapped.dropFirst() { frame.addLine(to: p) }
        frame.closeSubpath()
        // Two-pass spectrum border (glow + crisp), OB card-face grammar — the
        // single thin stroke got muted once the grain / env / fresnel enriched the
        // metal. The blurred additive glow lifts the colorway back off the surface.
        let frameShade = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: theme.colorway.c0.opacity(frameOpacity), location: 0.0),
                .init(color: theme.colorway.c1.opacity(frameOpacity), location: 0.5),
                .init(color: theme.colorway.c2.opacity(frameOpacity), location: 1.0),
            ]),
            startPoint: bilerp(quad, x0, 0.5),
            endPoint:   bilerp(quad, x1, 0.5))
        if frameGlow > 0 {
            var glow = ctx
            glow.blendMode = .plusLighter
            glow.opacity = frameGlow
            glow.addFilter(.blur(radius: frameGlowRadius))
            glow.stroke(frame, with: frameShade, lineWidth: frameWidth * 2.2)
        }
        ctx.stroke(frame, with: frameShade, lineWidth: frameWidth)

        // — embossed deck name, screen space at the projected anchor (low-center) —
        let cx = (quad[0].x + quad[1].x + quad[2].x + quad[3].x) / 4
        let cy = (quad[0].y + quad[1].y + quad[2].y + quad[3].y) / 4
        let anchor   = CGPoint(x: cx, y: cy + edgeW * 0.52)
        let fontSize = edgeW * 0.085

        func nameText(_ fs: CGFloat) -> Text {
            Text(theme.deckName)
                .font(AppFonts.display(fs, weight: .medium, relativeTo: .title))
                .tracking(fontSize * 0.45)
        }

        // emboss passes — same recipe as the VaylCardBack wordmark
        var shadowPass = ctx
        shadowPass.addFilter(.blur(radius: 0.8))
        shadowPass.draw(nameText(fontSize).foregroundStyle(Color.black.opacity(0.55)),
                        at: CGPoint(x: anchor.x + 0.8, y: anchor.y + 0.9), anchor: .center)

        var highlightPass = ctx
        highlightPass.addFilter(.blur(radius: 0.6))
        highlightPass.draw(nameText(fontSize).foregroundStyle(Color.white.opacity(0.45)),
                           at: CGPoint(x: anchor.x - 0.7, y: anchor.y - 0.8), anchor: .center)

        var corePass = ctx
        corePass.clipToLayer(opacity: 0.90) { clip in
            clip.draw(nameText(fontSize).foregroundStyle(Color.white),
                      at: anchor, anchor: .center)
        }
        let bounds = CGRect(x: anchor.x - fontSize * 4, y: anchor.y - fontSize,
                            width: fontSize * 8, height: fontSize * 2)
        corePass.fill(
            Path(bounds),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: theme.colorway.c0, location: 0.0),
                    .init(color: theme.colorway.c1, location: 0.4),
                    .init(color: theme.colorway.c2, location: 1.0),
                ]),
                startPoint: CGPoint(x: bounds.minX, y: anchor.y),
                endPoint:   CGPoint(x: bounds.maxX, y: anchor.y)
            )
        )
    }

    // MARK: - Crack ceremony (tears + bloom-flood)

    /// The knock from inside: a 0.7s seam glimmer — light tries a few hex
    /// grooves from within, somewhere mid-face. Plays once per `knockStart`
    /// date; deterministic per `knockSeed`. Reduce Motion: none.
    private func drawKnock(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           t: Double, motion: Bool) {
        guard motion, knockStart != .distantFuture else { return }
        let age = t - knockStart.timeIntervalSinceReferenceDate
        guard age >= 0, age < 0.7 else { return }
        let bell = dsin(min(age / 0.7, 1) * .pi)

        var rng = SplitMix64(seed: knockSeed)
        let u = Double.random(in: 0.30...0.70, using: &rng)
        let v = Double.random(in: 0.25...0.75, using: &rng)
        var current = nearestHexVertex(SIMD2(u * latticeColumns, v * 1.5 * latticeColumns))
        var previous = current
        var path = Path()
        if let start = wrapPoint(current, geo: geo) { path.move(to: start) }
        for _ in 0..<3 {
            let options = hexNeighbors(of: current).filter { dist2($0, previous) > 0.01 }
            guard let next = options.shuffled(using: &rng).first,
                  let pt = wrapPoint(next, geo: geo) else { break }
            path.addLine(to: pt)
            previous = current
            current = next
        }

        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: geo.frontQuad[0], endPoint: geo.frontQuad[2])
        var glow = ctx
        glow.opacity = 0.40 * bell
        glow.addFilter(.blur(radius: 5))
        glow.stroke(path, with: spectrum, lineWidth: 3.5)
        var crisp = ctx
        crisp.opacity = 0.5 * bell
        crisp.stroke(path, with: spectrum, lineWidth: 1.0)
    }

    /// Cracks rendered in face space: each tear's branch polylines live in UV,
    /// mapped through the CURRENT projected quad every frame — the crack rides
    /// the case through float and tilt. The strike is an EVENT, not a decal:
    /// branches PROPAGATE outward from the finger (~0.22s), flash white-hot on
    /// impact with an expanding shock ring, and taper from a wide wound at the
    /// strike to hairline tips. Light-bleed escalates per tear and floods
    /// during the shatter.
    /// One strike's authored fracture set — the SAME geometry consumed by the
    /// shell pass (drawTears) and the interior card pass (drawInterior), so the
    /// wound reads as going all the way through (Segment 5). Fully deterministic
    /// (seeded), so both passes computing it independently stay aligned.
    private struct TearNetwork {
        let k: Int
        let tear: CaseTear
        let lines: [[CGPoint]]
        let ripAngle: Double
    }

    /// Build every tear's crack network for the current frame geometry.
    /// CHOREO — the cracks + rip aim toward the CENTRE: corner strikes spray a
    /// DIRECTED fan toward the middle (the composition converges there); the
    /// central kill radiates full. This is what makes the 1-2-3 read as one
    /// composed failure instead of three scattered hits. The central kill also
    /// reaches cracks to BOTH previous strikes (connecting the whole network
    /// before the shatter); corner strikes don't link — their directed fan
    /// already converges on the centre.
    private func tearNetworks(geo: CaseGeometry) -> [TearNetwork] {
        var occupied = Set<Int64>()
        var nets: [TearNetwork] = []
        for (k, tear) in tears.enumerated() {
            let toC = SIMD2(0.5 - Double(tear.faceUV.x), 0.5 - Double(tear.faceUV.y))
            let centered = (toC.x * toC.x + toC.y * toC.y).squareRoot() < 0.12
            let anchorAngle = centered ? tear.angleDeg * .pi / 180 : atan2(toC.y, toC.x)
            let spread = centered ? 2 * Double.pi : 1.8   // tighter = cracks aim AT centre, not the borders
            let ripAngle = centered ? tear.angleDeg : anchorAngle * 180 / .pi
            let links: [CGPoint] = centered ? Array(tears.prefix(k)).map { $0.faceUV } : []
            // count + reach AUTHORED by severity (the designed 1-2-3 escalation)
            let cracks = radiatingCracks(tear, geo: geo, count: 4 + k,
                                         reach: 18 + 5 * k, links: links,
                                         anchorAngle: anchorAngle, spread: spread,
                                         occupied: &occupied)
            nets.append(TearNetwork(k: k, tear: tear, lines: cracks, ripAngle: ripAngle))
        }
        return nets
    }

    private func drawTears(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           overload: Double, t: Double, motion: Bool) {
        guard !tears.isEmpty else { return }
        let quad = geo.frontQuad
        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: quad[0], endPoint: quad[2])
        // sizing is relative to the FACE WIDTH so the damage uses the case's real
        // estate (Opal-scale), not a few fixed pixels.
        let faceW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)

        for net in tearNetworks(geo: geo) {
            let k = net.k, tear = net.tear
            // DESIGNED 1-2-3 sequence: severity is AUTHORED by strike index, not
            // random — each strike is a heavier impact than the last.
            let sev   = k + 1                                  // 1, 2, 3
            let age   = motion ? max(0, t - tear.struck.timeIntervalSinceReferenceDate) : 10
            let grow  = min(1.0, age / 0.30)
            let growE = 1 - (1 - grow) * (1 - grow)
            let flash = max(0.0, 1.0 - age / 0.28)
            let phase = Double(tear.seed % 628) / 100.0
            let pulse = motion ? 0.5 + 0.5 * dsin(t * (2 * .pi / 1.6) + phase) : 1.0
            let bleed = min(1.7, (0.5 + 0.22 * Double(k)) * (0.7 + 0.5 * pulse) + 1.0 * overload)
            let widen = 1.0 + 0.25 * Double(k) + 0.5 * overload
            let ripAngle = net.ripAngle

            for line in net.lines {
                drawCrackLine(&ctx, line, growE: growE, widen: widen, bleed: bleed,
                              flash: flash, overload: overload, t: t, motion: motion,
                              spectrum: spectrum)
            }

            // THE WOUND — a big tear at the composed strike point, its rip pointing
            // toward centre; sized off the face (Opal-scale), bigger each strike.
            let woundR = faceW * (0.135 + 0.04 * Double(sev)) * growE * (0.9 + 0.25 * coreGlow)
            drawWound(&ctx, at: tear.faceUV, geo: geo, radius: woundR, angleDeg: ripAngle,
                      seed: tear.seed, bleed: bleed, flash: flash, overload: overload,
                      spectrum: spectrum)

            // shock ring — expands from the impact, dies as the crack lands
            if flash > 0, motion {
                let origin = bilerp(quad, Double(tear.faceUV.x), Double(tear.faceUV.y))
                let ringP = min(1.0, age / 0.35)
                let radius = 5 + 26 * (1 - (1 - ringP) * (1 - ringP))
                var ring = ctx
                ring.opacity = (1 - ringP) * 0.5
                ring.stroke(Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                                   width: radius * 2, height: radius * 2)),
                            with: spectrum, lineWidth: 1.5)
            }
        }
    }

    /// One radiating crack line — reveal-animated from the impact, soft glow + a
    /// crisp tapered core, then LIVELY accents (the released energy alive in the
    /// fracture): flickering glints crackling along it + a bright pulse coursing out.
    private func drawCrackLine(_ ctx: inout GraphicsContext, _ branch: [CGPoint],
                               growE: Double, widen: Double, bleed: Double,
                               flash: Double, overload: Double, t: Double, motion: Bool,
                               spectrum: GraphicsContext.Shading) {
        let n = branch.count - 1
        guard n > 0 else { return }
        let reveal = growE * Double(n)
        var revealed = Path()
        revealed.move(to: branch[0])
        var revealedPts: [CGPoint] = [branch[0]]
        var segments: [(Path, Double)] = []
        for i in 0..<n {
            let segP = min(max(reveal - Double(i), 0), 1)
            guard segP > 0 else { break }
            let a = branch[i], b = branch[i + 1]
            let end = segP >= 1 ? b
                : CGPoint(x: a.x + (b.x - a.x) * segP, y: a.y + (b.y - a.y) * segP)
            revealed.addLine(to: end)
            revealedPts.append(end)
            var seg = Path(); seg.move(to: a); seg.addLine(to: end)
            let width = 2.2 - 1.7 * Double(i) / Double(max(n - 1, 1))
            segments.append((seg, width))
        }
        var glow = ctx
        glow.opacity = min(1.0, 0.45 * bleed)
        glow.addFilter(.blur(radius: 4.0))
        glow.stroke(revealed, with: spectrum, lineWidth: 4.0 * widen)
        for (seg, width) in segments {
            var crisp = ctx
            crisp.opacity = min(1.0, 0.6 + 0.4 * bleed)
            crisp.stroke(seg, with: spectrum, lineWidth: width * widen)
            var core = ctx
            core.opacity = min(1.0, 0.30 * bleed + 0.6 * flash + overload)
            core.stroke(seg, with: .color(.white), lineWidth: width * widen * 0.45)
        }

        // LIVELY accents — per-crack phase so they don't pulse in lockstep
        guard motion, revealedPts.count > 1 else { return }
        let ph = Double(branch[0].x) * 0.013 + Double(branch[0].y) * 0.017
        // flickering glints crackling along the crack's length (electric/alive)
        for (j, vp) in revealedPts.enumerated() {
            let tw = dsin(t * 6 + ph + Double(j) * 1.9)
            guard tw > 0.74 else { continue }
            var gl = ctx
            gl.opacity = (tw - 0.74) / 0.26 * 0.45
            gl.addFilter(.blur(radius: 1.2))
            gl.fill(Path(ellipseIn: CGRect(x: vp.x - 1.4, y: vp.y - 1.4, width: 2.8, height: 2.8)),
                    with: .color(.white))
        }
        // a bright energy pulse coursing OUTWARD along the crack, fading at the tip
        let pf = CGFloat(((t * 0.8 + ph).truncatingRemainder(dividingBy: 1.0) + 1)
                            .truncatingRemainder(dividingBy: 1.0))
        let pp = pointAlong(revealedPts, pf)
        var pulse = ctx
        pulse.opacity = 0.5 * (1 - Double(pf)) * min(1, 0.4 + 0.6 * bleed)
        pulse.addFilter(.blur(radius: 3))
        pulse.fill(Path(ellipseIn: CGRect(x: pp.x - 3, y: pp.y - 3, width: 6, height: 6)),
                   with: .color(.white))
    }

    /// Point at arc-length fraction `f` (0…1) along a polyline.
    private func pointAlong(_ pts: [CGPoint], _ f: CGFloat) -> CGPoint {
        guard pts.count > 1 else { return pts.first ?? .zero }
        var lens: [CGFloat] = [], total: CGFloat = 0
        for i in 0..<pts.count - 1 {
            let d = hypot(pts[i + 1].x - pts[i].x, pts[i + 1].y - pts[i].y)
            lens.append(d); total += d
        }
        guard total > 0 else { return pts[0] }
        var target = max(0, min(1, f)) * total
        for i in 0..<lens.count {
            if target <= lens[i] {
                let u = lens[i] > 0 ? target / lens[i] : 0
                return CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * u,
                               y: pts[i].y + (pts[i + 1].y - pts[i].y) * u)
            }
            target -= lens[i]
        }
        return pts[pts.count - 1]
    }

    /// The WOUND at an impact — an elongated jagged RIP centred on the strike and
    /// oriented along the crack axis (a torn slit, not a round splat). Dark gap
    /// (depth) + glowing card-light inset behind a shadow rim + bright jagged lip.
    /// Screen-space (small enough that tilt foreshortening doesn't matter).
    private func drawWound(_ ctx: inout GraphicsContext, at uv: CGPoint, geo: CaseGeometry,
                           radius: Double, angleDeg: Double, seed: UInt64,
                           bleed: Double, flash: Double, overload: Double,
                           spectrum: GraphicsContext.Shading) {
        guard radius > 0.6 else { return }
        let center = bilerp(geo.frontQuad, Double(uv.x), Double(uv.y))
        let ang = angleDeg * .pi / 180, ca = dcos(ang), sa = dsin(ang)
        let L = radius * 2.7, W = radius * 0.95          // elongated along the crack axis
        var rng = SplitMix64(seed: seed ^ 0x770F)
        let steps = 7
        let topJit = (0...steps).map { _ in 0.65 + 0.6 * Double.random(in: 0...1, using: &rng) }
        let botJit = (0...steps).map { _ in 0.65 + 0.6 * Double.random(in: 0...1, using: &rng) }
        // a jagged lens (pointed ends, bulged middle) rotated to the crack axis — a rip
        func lens(_ scale: Double) -> Path {
            var p = Path()
            let hl = L * 0.5 * scale, hw = W * 0.5 * scale
            func map(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: center.x + x * ca - y * sa, y: center.y + x * sa + y * ca)
            }
            for i in 0...steps {                          // top edge: left → right, bulging up
                let s = Double(i) / Double(steps)
                let pt = map(-hl + 2 * hl * s, -hw * dsin(.pi * s) * topJit[i])
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            for i in 0...steps {                          // bottom edge: right → left, bulging down
                let s = Double(i) / Double(steps)
                p.addLine(to: map(hl - 2 * hl * s, hw * dsin(.pi * s) * botJit[steps - i]))
            }
            p.closeSubpath(); return p
        }
        let outer = lens(1.0)

        // 1. PUNCH THROUGH — erase the shell so the glowing interior (drawn BEHIND
        //    in the ZStack) shows as true NEGATIVE SPACE. The hex shader passes
        //    transparent pixels straight through (`if a < 0.01 return currentColor`),
        //    so no grooves fill the hole.
        var cut = ctx
        cut.blendMode = .destinationOut
        cut.fill(outer, with: .color(.black))

        // 2. THICKNESS — a dark inner WALL just inside the broken edge (the case's
        //    depth in shadow), so the hole reads as an extrusion, not a flat cut.
        var wall = ctx
        wall.opacity = min(1.0, 0.55 + 0.2 * flash)
        wall.stroke(lens(0.82), with: .color(AppColors.void), lineWidth: max(2, radius * 0.2))

        // 3. DIRECTIONAL RIM — bright broken metal ONLY on the light-facing edge,
        //    fading to nothing on the shadow side (never a 360° neon outline).
        let lightTL = CGPoint(x: center.x - L, y: center.y - L)
        let lightBR = CGPoint(x: center.x + L, y: center.y + L)
        var rim = ctx
        rim.opacity = min(1.0, 0.8 + 0.4 * flash)
        rim.stroke(outer, with: .linearGradient(
            Gradient(stops: [
                .init(color: .white,                         location: 0.0),
                .init(color: theme.colorway.c1.opacity(0.6), location: 0.4),
                .init(color: .clear,                         location: 0.62),
            ]),
            startPoint: lightTL, endPoint: lightBR), lineWidth: 2.0)
    }

    /// smoothstep — 0 below `a`, 1 above `b`, eased between.
    private func sstep(_ x: Double, _ a: Double, _ b: Double) -> Double {
        let u = min(1, max(0, (x - a) / (b - a)))
        return u * u * (3 - 2 * u)
    }

    /// The glowing INTERIOR revealed through the erased wounds — a generic lit panel
    /// (spectrum, brightest at centre) clipped to the case silhouette so it only
    /// shows through real negative space. Lives BEHIND the shell Canvas in the
    /// ZStack. Kept generic so the module stays content-agnostic.
    ///
    /// Segment 5 — the wound goes ALL THE WAY THROUGH: the same fracture network
    /// as the shell (identical seeds → identical geometry via tearNetworks) is
    /// rendered on this card body as a dark fissure with a hot edge, so a wound
    /// shows the crack continuing beneath the shell. TRANSIENT by design: the
    /// fissures cool and seal as the energy drains through the un-knit — the
    /// actual reveal content the consumer mounts behind is never touched.
    ///
    /// During the un-knit the whole layer DRAINS (the escaping essence), handing
    /// the uncovered holes to the consumer's content behind the module.
    private func drawInterior(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                              t: Double, motion: Bool, flood: Double) {
        let drain = sstep(flood, 0.10, 0.75)
        guard drain < 0.999 else { return }
        let hull = roundedFacePath(convexHull(geo.proj), softness: cornerSoftness)
        let q = geo.frontQuad
        let center = CGPoint(x: (q[0].x + q[2].x) / 2, y: (q[0].y + q[2].y) / 2)
        let r = hypot(q[2].x - q[0].x, q[2].y - q[0].y) * 0.62
        var g = ctx
        g.clip(to: hull)
        g.opacity = 1 - drain
        g.fill(hull, with: .radialGradient(
            Gradient(stops: [
                .init(color: .white.opacity(0.92),            location: 0.0),
                .init(color: theme.colorway.c1.opacity(0.85), location: 0.4),
                .init(color: theme.colorway.c2.opacity(0.7),  location: 0.8),
                .init(color: theme.colorway.c0.opacity(0.6),  location: 1.0),
            ]),
            center: center, startRadius: 0, endRadius: r))

        // the through-cracks — grow in sync with the shell's (same 0.30s reveal),
        // cool + seal as the un-knit settles (a slightly earlier fade than the
        // glow, so the damage heals before the light finishes leaving)
        let cool = 1 - sstep(flood, 0.20, 0.70)
        guard cool > 0.01 else { return }
        for net in tearNetworks(geo: geo) {
            let age   = motion ? max(0, t - net.tear.struck.timeIntervalSinceReferenceDate) : 10
            let grow  = min(1.0, age / 0.30)
            let growE = 1 - (1 - grow) * (1 - grow)
            guard growE > 0.01 else { continue }
            for line in net.lines {
                let path = revealedPath(line, growE: growE)
                // hot edge first (the card's energy pressed into the fissure)…
                var hot = g
                hot.blendMode = .plusLighter
                hot.opacity = 0.35 * growE * cool
                hot.addFilter(.blur(radius: 2.0))
                hot.stroke(path, with: .color(theme.colorway.c2), lineWidth: 3.2)
                // …then the dark split itself — damage on a glowing body
                var fissure = g
                fissure.opacity = 0.6 * growE * cool
                fissure.stroke(path, with: .color(AppColors.void), lineWidth: 1.8)
            }
        }
    }

    /// The revealed prefix of a crack polyline at growth `growE` (0…1) — the
    /// propagation animation as a single Path. Shared by the shell's crack pass
    /// (per-segment styling lives in drawCrackLine) and the interior card pass,
    /// so the two stay frame-locked.
    private func revealedPath(_ branch: [CGPoint], growE: Double) -> Path {
        var path = Path()
        let n = branch.count - 1
        guard n > 0 else { return path }
        let reveal = growE * Double(n)
        path.move(to: branch[0])
        for i in 0..<n {
            let segP = min(max(reveal - Double(i), 0), 1)
            guard segP > 0 else { break }
            let a = branch[i], b = branch[i + 1]
            path.addLine(to: segP >= 1 ? b
                : CGPoint(x: a.x + (b.x - a.x) * segP, y: a.y + (b.y - a.y) * segP))
        }
        return path
    }

    // MARK: - Un-knit (Segment 3): the shell disassembles along its own lattice

    /// One honeycomb cell of the shell during the un-knit wave.
    ///   lead < 0  — still knitted, but the wave front is near (seam pre-glow)
    ///   0…1       — departing: erased from the shell, drawn as a freed piece
    ///   ≥ 1       — gone
    private struct UnknitCell {
        let center: SIMD2<Double>   // lattice space
        let lead: Double
        let jitter: Double          // per-cell 0…1 (seeded) — organic front + flight variance
        var q: Double { min(1, max(0, lead)) }
    }

    /// Enumerate the honeycomb cell centers covering the face + fold overhang
    /// (the same two offset grids as hexFoilSurface / nearestHexVertex) and
    /// compute each cell's departure under the wave. The wave radiates from the
    /// KILL strike (dead centre in the Pincer); a small seeded jitter keeps the
    /// front organic without breaking the formation-in-reverse read.
    /// Only cells the front has reached (or is about to) are returned.
    private func unknitCells(flood: Double) -> [UnknitCell] {
        guard flood > 0.001 else { return [] }
        let r3 = 1.7320508
        let cols = latticeColumns
        let over = Double(depthFrac) * cols               // fold overhang, lattice units
        let xLo = -over, xHi = cols + over
        let yLo = -over, yHi = 1.5 * cols + over
        // wave origin = the kill strike
        let o = tears.last.map {
            SIMD2(Double($0.faceUV.x) * cols, Double($0.faceUV.y) * 1.5 * cols)
        } ?? SIMD2(0.5 * cols, 0.75 * cols)
        // the wave must reach the farthest corner
        let maxD = [SIMD2(xLo, yLo), SIMD2(xHi, yLo), SIMD2(xLo, yHi), SIMD2(xHi, yHi)]
            .map { c -> Double in
                let v = c - o
                return (v.x * v.x + v.y * v.y).squareRoot()
            }
            .max() ?? 1
        let waveD = flood * (maxD + unknitBand)
        let waveSeed = tears.last?.seed ?? 0x0BAD_CE11

        var cells: [UnknitCell] = []
        func visit(_ c: SIMD2<Double>) {
            let v = c - o
            let d = (v.x * v.x + v.y * v.y).squareRoot()
            var rng = SplitMix64(seed: UInt64(bitPattern: vertexKey(c)) ^ waveSeed)
            let jitter = Double.random(in: 0...1, using: &rng)
            let lead = (waveD - (d + (jitter - 0.5) * 1.6)) / unknitBand
            guard lead > -0.5 else { return }
            cells.append(UnknitCell(center: c, lead: lead, jitter: jitter))
        }
        let jLo = Int((yLo / r3).rounded(.down)), jHi = Int((yHi / r3).rounded(.up))
        let iLo = Int(xLo.rounded(.down)), iHi = Int(xHi.rounded(.up))
        for j in jLo...jHi {
            let rowY = Double(j) * r3
            for i in iLo...iHi {
                visit(SIMD2(Double(i), rowY))                       // grid A
                visit(SIMD2(Double(i) + 0.5, rowY + r3 * 0.5))      // grid B
            }
        }
        return cells
    }

    /// A cell's hexagon in screen space, corners scaled about the center
    /// (`scale` > 1 swallows the groove seam). Nil if any corner falls past a
    /// fold the camera can't see — that cell has no drawable piece.
    private func hexCellPath(center: SIMD2<Double>, geo: CaseGeometry,
                             scale: Double) -> Path? {
        let R = Self.hexR
        let offs: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0.5,  R / 2), SIMD2(0.5, -R / 2),
            SIMD2(0, -R), SIMD2(-0.5, -R / 2), SIMD2(-0.5, R / 2),
        ]
        var pts: [CGPoint] = []
        for off in offs {
            guard let p = wrapPoint(center + off * scale, geo: geo) else { return nil }
            pts.append(p)
        }
        var path = Path()
        path.move(to: pts[0])
        for p in pts.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }

    /// Erase departed cells from the shell — the un-knit's NEGATIVE SPACE. Runs
    /// inside the shell Canvas (destinationOut) so the hex shader passes the
    /// holes straight through: whatever the consumer mounted behind the module
    /// is genuinely UNCOVERED, never cross-faded to. The 1.18 inflation swallows
    /// the groove seams — the lattice's joints give way with the cell.
    private func eraseUnknit(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        guard flood > 0.001 else { return }
        var cut = ctx
        cut.blendMode = .destinationOut
        for cell in unknitCells(flood: flood) where cell.lead > 0 {
            guard let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.18) else { continue }
            cut.fill(hex, with: .color(.black))
        }
    }

    /// The wave front, drawn OVER the shell in a plain (un-shadered) Canvas:
    ///   · seam pre-glow — cells the front is about to take flare along their
    ///     hex outline (the lattice visibly giving way ahead of the wave)
    ///   · freed pieces — each departing cell lifts a short way OUTWARD from the
    ///     wave origin, tips slightly, cools and fades. Formation-in-reverse:
    ///     ordered, light, no gravity, no tumble. (Segment 6 holds heavier
    ///     per-cell flight physics in reserve pending the device feel pass.)
    private func drawUnknitPieces(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        let cells = unknitCells(flood: flood)
        guard !cells.isEmpty else { return }
        let quad = geo.frontQuad
        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: quad[0], endPoint: quad[2])
        let originUV = tears.last?.faceUV ?? CGPoint(x: 0.5, y: 0.5)
        let origin = bilerp(quad, Double(originUV.x), Double(originUV.y))
        let metal = color(mix(Self.components(theme.colorway.c1), SIMD3(0, 0, 0), 0.5))
        let backMetal = color(mix(Self.components(theme.colorway.c1), SIMD3(0, 0, 0), 0.78))

        for cell in cells {
            // seam pre-glow just ahead of the front
            if cell.lead <= 0 {
                guard let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0) else { continue }
                var pre = ctx
                pre.blendMode = .plusLighter
                pre.opacity = (0.5 + cell.lead) / 0.5 * 0.35
                pre.addFilter(.blur(radius: 1.5))
                pre.stroke(hex, with: spectrum, lineWidth: 1.2)
                continue
            }
            let q = cell.q
            guard q < 1,
                  let pc = wrapPoint(cell.center, geo: geo),
                  let hex = hexCellPath(center: cell.center, geo: geo, scale: 1.0)
            else { continue }

            // freed piece: short outward lift, slight tip, cool + fade
            let dx = pc.x - origin.x, dy = pc.y - origin.y
            let len = max(1, hypot(dx, dy))
            let qe = 1 - (1 - q) * (1 - q)                     // easeOut departure
            let travel = (10 + 14 * cell.jitter) * qe
            let ox = dx / len * travel, oy = dy / len * travel
            let ang = (cell.jitter - 0.5) * 0.8 * q
            let ca = dcos(ang), sa = dsin(ang)
            let sc = 1 - 0.30 * q
            var piece = Path()
            hex.forEach { el in
                func moved(_ p: CGPoint) -> CGPoint {
                    let rx = (p.x - pc.x) * sc, ry = (p.y - pc.y) * sc
                    return CGPoint(x: pc.x + (rx * ca - ry * sa) + ox,
                                   y: pc.y + (rx * sa + ry * ca) + oy)
                }
                switch el {
                case .move(let p):        piece.move(to: moved(p))
                case .line(let p):        piece.addLine(to: moved(p))
                case .closeSubpath:       piece.closeSubpath()
                default:                  break
                }
            }
            let alpha = 1 - q
            // thin dark back-offset → the piece reads as solid metal, not paper
            var back = ctx
            back.opacity = alpha
            back.fill(piece.applying(CGAffineTransform(translationX: 1.5 * sc, y: 1.5 * sc)),
                      with: .color(backMetal))
            var front = ctx
            front.opacity = alpha
            front.fill(piece, with: .color(metal))
            front.stroke(piece, with: spectrum, lineWidth: 0.8)
            // detach flare — the seam light releasing as the cell lets go
            if q < 0.35 {
                var flare = ctx
                flare.blendMode = .plusLighter
                flare.opacity = (0.35 - q) / 0.35 * 0.8
                flare.addFilter(.blur(radius: 2))
                flare.stroke(piece, with: spectrum, lineWidth: 1.4)
            }
        }
    }

    /// Cracks RADIATE from the impact — `count` clean lines fanning out in evenly
    /// spread directions (a stone-through-glass impact), each propagating `reach`
    /// hex steps along the lattice (the seams give way) with the occasional straight
    /// chord across a cell for natural long runs. count/reach are AUTHORED by the
    /// caller per strike severity (the designed 1-2-3 escalation), so the only
    /// randomness is natural direction jitter. Deterministic per tear (seeded).
    /// `occupied` blocks cracks from crossing/merging across strikes.
    private func radiatingCracks(_ tear: CaseTear, geo: CaseGeometry,
                                 count: Int, reach: Int, links: [CGPoint],
                                 anchorAngle: Double, spread: Double,
                                 occupied: inout Set<Int64>) -> [[CGPoint]] {
        var rng = SplitMix64(seed: tear.seed)
        let strike = nearestHexVertex(SIMD2(Double(tear.faceUV.x) * latticeColumns,
                                            Double(tear.faceUV.y) * 1.5 * latticeColumns))
        occupied.insert(vertexKey(strike))

        // directions toward each LINKED (previous) strike — these cracks reach for
        // them so the central kill connects the whole network (they stop at the
        // earlier cracks they run into, reading as a join).
        let linkDirs: [SIMD2<Double>] = links.compactMap { l in
            let target = SIMD2(Double(l.x) * latticeColumns, Double(l.y) * 1.5 * latticeColumns)
            let d = target - strike
            let len = (d.x * d.x + d.y * d.y).squareRoot()
            return len > 0.01 ? SIMD2(d.x / len, d.y / len) : nil
        }
        let total = max(count, linkDirs.count)
        let fanCount = max(1, total - linkDirs.count)

        var lines: [[CGPoint]] = []
        for i in 0..<total {
            // the first cracks reach the linked strikes; the rest fan within `spread`
            // (toward centre for corner strikes, full circle for the central kill)
            let isLink = i < linkDirs.count
            let dir: SIMD2<Double>
            if isLink {
                dir = linkDirs[i]
            } else {
                let fi = i - linkDirs.count
                let ang = fanCount > 1
                    ? anchorAngle + spread * (Double(fi) / Double(fanCount - 1) - 0.5)
                        + Double.random(in: -0.2...0.2, using: &rng)
                    : anchorAngle
                dir = SIMD2(dcos(ang), dsin(ang))
            }
            let armReach = isLink ? reach + 10 : reach   // link spans toward the corner
            let (mainScreen, mainLat) = walkFracture(from: strike, dir: dir, reach: armReach,
                                                     geo: geo, occupied: &occupied, rng: &rng)
            if mainScreen.count > 1 { lines.append(mainScreen) }

            // OFFSHOOTS — short sub-cracks forking off the main run, so the fracture
            // SPREADS and covers area (a tree, not a single scratch).
            guard mainLat.count > 4 else { continue }
            for _ in 0..<2 {
                let idx = Int.random(in: 2..<mainLat.count, using: &rng)
                let side: Double = Bool.random(using: &rng) ? 1 : -1
                let offAng = atan2(dir.y, dir.x) + side * Double.random(in: 0.6...1.1, using: &rng)
                let offDir = SIMD2(dcos(offAng), dsin(offAng))
                let (offScreen, _) = walkFracture(from: mainLat[idx], dir: offDir,
                                                  reach: max(3, armReach / 2),
                                                  geo: geo, occupied: &occupied, rng: &rng)
                if offScreen.count > 1 { lines.append(offScreen) }
            }
        }
        return lines
    }

    /// Walk one fracture run along the hex lattice from `start` heading `dir`, up to
    /// `reach` steps (with the occasional straight chord across a cell). Returns the
    /// screen polyline + the lattice vertices visited (so offshoots can fork off it).
    private func walkFracture(from start: SIMD2<Double>, dir: SIMD2<Double>, reach: Int,
                              geo: CaseGeometry, occupied: inout Set<Int64>,
                              rng: inout SplitMix64) -> ([CGPoint], [SIMD2<Double>]) {
        let openings = hexNeighbors(of: start).filter { !occupied.contains(vertexKey($0)) }
        guard let first = openings.max(by: { align($0 - start, dir) < align($1 - start, dir) }),
              let p0 = wrapPoint(start, geo: geo),
              let p1 = wrapPoint(first, geo: geo) else { return ([], []) }
        occupied.insert(vertexKey(first))
        var screen = [p0, p1]
        var lat = [start, first]
        var previous = start, current = first
        for _ in 0..<reach {
            let options = hexNeighbors(of: current).filter {
                dist2($0, previous) > 0.01 && !occupied.contains(vertexKey($0))
            }
            guard !options.isEmpty else { break }
            var next = options.max(by: {
                align($0 - current, dir) + Double.random(in: 0...0.3, using: &rng)
              < align($1 - current, dir) + Double.random(in: 0...0.3, using: &rng)
            })!
            if Double.random(in: 0...1, using: &rng) < 0.3 {
                let heading = next - current
                let beyond = hexNeighbors(of: next).filter {
                    dist2($0, current) > 0.01 && !occupied.contains(vertexKey($0))
                }
                if let through = beyond.max(by: {
                    align($0 - next, heading) < align($1 - next, heading)
                }) { next = through }
            }
            previous = current; current = next
            guard let pt = wrapPoint(current, geo: geo) else { break }
            occupied.insert(vertexKey(current))
            screen.append(pt); lat.append(current)
        }
        return (screen, lat)
    }

    /// Normalized alignment of a step with a direction (−1…1).
    private func align(_ step: SIMD2<Double>, _ dir: SIMD2<Double>) -> Double {
        let len = (step.x * step.x + step.y * step.y).squareRoot()
        guard len > 1e-9 else { return -1 }
        return (step.x * dir.x + step.y * dir.y) / len
    }

    /// Quantized lattice-vertex key: x lives on multiples of 0.5, y on
    /// multiples of 1/(2√3) — exact integer grid once scaled.
    private func vertexKey(_ v: SIMD2<Double>) -> Int64 {
        let xi = Int64((v.x * 2).rounded())
        let yi = Int64((v.y * 2 * 1.7320508).rounded())
        return (xi << 32) ^ (yi & 0xFFFF_FFFF)
    }

    // MARK: Lattice-space helpers — these mirror hexFoilSurface's grid EXACTLY
    // (pointy-top hexes tiled on r = (1, √3), centers on two offset grids).
    // If the shader's layout changes, these must change with it.

    /// Hex circumradius for apothem 0.5 — also the honeycomb edge length.
    private static let hexR = 1.0 / 1.7320508

    private func uvFromLattice(_ p: SIMD2<Double>) -> CGPoint {
        CGPoint(x: p.x / latticeColumns, y: p.y / (1.5 * latticeColumns))
    }

    /// Face UV → screen, WRAPPING OVER THE BOX FOLDS: u/v beyond [0,1] continue
    /// onto the side/top/bottom faces (the shell fails all around, not just the
    /// front plate). Overhang is mapped across the box depth toward the back
    /// edge; returns nil past the fold of a face the camera can't see, or past
    /// 90% of the depth — the branch dies there.
    private func wrapPoint(_ p: SIMD2<Double>, geo: CaseGeometry) -> CGPoint? {
        let uv = uvFromLattice(p)
        let u = Double(uv.x), v = Double(uv.y)
        let depthU = Double(depthFrac)            // side-face depth in u units
        let depthV = Double(depthFrac) / 1.5      // top/bottom depth in v units
        let proj = geo.proj
        func mixP(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        func facing(_ n: SIMD3<Double>) -> Bool {
            rotate(n, rx: geo.rx, ry: geo.ry).z > 0.04
        }
        switch ((0.0...1.0).contains(u), (0.0...1.0).contains(v)) {
        case (true, true):
            return bilerp(geo.frontQuad, u, v)
        case (false, true):                       // left / right face
            let left = u < 0
            let s = (left ? -u : u - 1) / depthU
            guard s <= 0.9, facing(SIMD3(left ? -1 : 1, 0, 0)) else { return nil }
            return left
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[3], proj[7], s), v)
                : mixP(mixP(proj[1], proj[5], s), mixP(proj[2], proj[6], s), v)
        case (true, false):                       // top / bottom face
            let top = v < 0
            let s = (top ? -v : v - 1) / depthV
            guard s <= 0.9, facing(SIMD3(0, top ? -1 : 1, 0)) else { return nil }
            return top
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[1], proj[5], s), u)
                : mixP(mixP(proj[3], proj[7], s), mixP(proj[2], proj[6], s), u)
        default:                                  // past a box corner — stop
            return nil
        }
    }

    private func dist2(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let d = a - b
        return d.x * d.x + d.y * d.y
    }

    /// Nearest honeycomb VERTEX (cell corner) to a lattice-space point.
    private func nearestHexVertex(_ p: SIMD2<Double>) -> SIMD2<Double> {
        let r = SIMD2(1.0, 1.7320508)
        func wrap(_ x: SIMD2<Double>) -> SIMD2<Double> {
            SIMD2(x.x - r.x * (x.x / r.x).rounded(.down),
                  x.y - r.y * (x.y / r.y).rounded(.down)) - r * 0.5
        }
        let ga = wrap(p)
        let gb = wrap(p - r * 0.5)
        let gv = (ga.x * ga.x + ga.y * ga.y) < (gb.x * gb.x + gb.y * gb.y) ? ga : gb
        let center = p - gv                      // owning cell center
        let R = Self.hexR
        let corners: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0.5,  R / 2), SIMD2(0.5, -R / 2),
            SIMD2(0, -R), SIMD2(-0.5, -R / 2), SIMD2(-0.5, R / 2),
        ]
        return corners
            .map { center + $0 }
            .min(by: { dist2($0, p) < dist2($1, p) })!
    }

    /// A honeycomb vertex's 3 neighbors: probe all 6 edge directions and keep
    /// the ones that land on a real vertex — no parity bookkeeping to drift.
    private func hexNeighbors(of v: SIMD2<Double>) -> [SIMD2<Double>] {
        let R = Self.hexR
        let dirs: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0, -R),
            SIMD2( 0.5,  R / 2), SIMD2( 0.5, -R / 2),
            SIMD2(-0.5,  R / 2), SIMD2(-0.5, -R / 2),
        ]
        return dirs.compactMap { d in
            let candidate = v + d
            let snapped = nearestHexVertex(candidate)
            return dist2(snapped, candidate) < (R * 0.05) * (R * 0.05) ? snapped : nil
        }
    }

    /// UV → screen through the projected front quad (TL, TR, BR, BL).
    private func bilerp(_ q: [CGPoint], _ u: Double, _ v: Double) -> CGPoint {
        let top = CGPoint(x: q[0].x + (q[1].x - q[0].x) * u, y: q[0].y + (q[1].y - q[0].y) * u)
        let bot = CGPoint(x: q[3].x + (q[2].x - q[3].x) * u, y: q[3].y + (q[2].y - q[3].y) * u)
        return CGPoint(x: top.x + (bot.x - top.x) * v, y: top.y + (bot.y - top.y) * v)
    }

    /// Screen → UV: analytic inverse-bilinear over the projected front quad
    /// (TL, TR, BR, BL) — the same machinery the foil shader uses, so a tap
    /// lands exactly where the crack will render.
    private func invBilinear(_ p: CGPoint, quad q: [CGPoint]) -> CGPoint? {
        guard q.count == 4 else { return nil }
        let a = SIMD2(Double(q[0].x), Double(q[0].y))
        let b = SIMD2(Double(q[1].x), Double(q[1].y))
        let c = SIMD2(Double(q[2].x), Double(q[2].y))
        let d = SIMD2(Double(q[3].x), Double(q[3].y))
        let pt = SIMD2(Double(p.x), Double(p.y))

        let e = b - a, f = d - a, g = a - b + c - d, h = pt - a
        func cross2(_ x: SIMD2<Double>, _ y: SIMD2<Double>) -> Double { x.x * y.y - x.y * y.x }
        let k2 = cross2(g, f)
        let k1 = cross2(e, f) + cross2(h, g)
        let k0 = cross2(h, e)

        var v: Double
        if abs(k2) < 1e-7 {
            guard abs(k1) > 1e-9 else { return nil }
            v = -k0 / k1
        } else {
            let disc = k1 * k1 - 4 * k2 * k0
            guard disc >= 0 else { return nil }
            let sq = disc.squareRoot()
            let v1 = (-k1 + sq) / (2 * k2)
            let v2 = (-k1 - sq) / (2 * k2)
            // the quad is convex — pick the root nearest the unit interval
            func unitDistance(_ x: Double) -> Double { x < 0 ? -x : (x > 1 ? x - 1 : 0) }
            v = unitDistance(v1) <= unitDistance(v2) ? v1 : v2
        }
        let denX = e.x + g.x * v
        let denY = e.y + g.y * v
        guard max(abs(denX), abs(denY)) > 1e-9 else { return nil }
        let u = abs(denX) > abs(denY) ? (h.x - f.x * v) / denX
                                      : (h.y - f.y * v) / denY
        return CGPoint(x: u, y: v)
    }

    /// Seeded deterministic RNG for crack geometry — same pattern every frame.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    // MARK: - 3D math

    private func rotate(_ p: SIMD3<Double>, rx: Double, ry: Double) -> SIMD3<Double> {
        // rotate around X then Y
        let y1 = p.y * dcos(rx) - p.z * dsin(rx)
        let z1 = p.y * dsin(rx) + p.z * dcos(rx)
        let x2 = p.x * dcos(ry) + z1 * dsin(ry)
        let z2 = -p.x * dsin(ry) + z1 * dcos(ry)
        return SIMD3(x2, y1, z2)
    }

    private func project(_ p: SIMD3<Double>, center: CGPoint) -> CGPoint {
        let s = perspective / (perspective - p.z)
        return CGPoint(x: center.x + CGFloat(p.x * s), y: center.y + CGFloat(p.y * s))
    }

    // Disambiguate cos/sin: CoreGraphics' cos(CGFloat) + implicit CGFloat↔Double
    // conversion makes the bare calls ambiguous. Darwin has only the Double overload.
    private func dcos(_ x: Double) -> Double { Darwin.cos(x) }
    private func dsin(_ x: Double) -> Double { Darwin.sin(x) }

    // MARK: - Surface (foil)

    /// A face path with rounded corners — softens the machined-plate read toward foil.
    private func roundedFacePath(_ pts: [CGPoint], softness: Double) -> Path {
        var path = Path()
        guard pts.count >= 3 else { return path }
        if softness <= 0 {
            path.move(to: pts[0]); for p in pts.dropFirst() { path.addLine(to: p) }
            path.closeSubpath(); return path
        }
        let n = pts.count
        // UNIFORM corner radius: base it on the silhouette's overall size, not on
        // each corner's adjacent edge lengths. With the old per-edge radius, a
        // corner between two LONG edges (the perspective-compressed bottom, where
        // the long side edges converge) got a far bigger round than the rest and
        // read as a melted/warped corner — which ALSO clipped the brand frame
        // there (the frame is drawn inside this same clip), so both symptoms shared
        // one cause. Cap per-corner so a short edge still can't be over-rounded.
        let xs = pts.map(\.x), ys = pts.map(\.y)
        let span = min((xs.max() ?? 0) - (xs.min() ?? 0), (ys.max() ?? 0) - (ys.min() ?? 0))
        let maxR = CGFloat(softness) * 0.5 * span
        for i in 0..<n {
            let cur = pts[i], prev = pts[(i + n - 1) % n], next = pts[(i + 1) % n]
            let r = min(maxR, 0.5 * min(dist(cur, prev), dist(cur, next)))
            let a = lerpPoint(cur, prev, r)
            let b = lerpPoint(cur, next, r)
            if i == 0 { path.move(to: a) } else { path.addLine(to: a) }
            path.addQuadCurve(to: b, control: cur)
        }
        path.closeSubpath()
        return path
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
    private func lerpPoint(_ from: CGPoint, _ to: CGPoint, _ d: CGFloat) -> CGPoint {
        let len = max(0.0001, dist(from, to))
        let f = min(1, d / len)
        return CGPoint(x: from.x + (to.x - from.x) * f, y: from.y + (to.y - from.y) * f)
    }

    // MARK: - Colour helpers

    private func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
        a + (b - a) * t
    }
    private func color(_ v: SIMD3<Double>) -> Color {
        Color(red: min(1, max(0, v.x)), green: min(1, max(0, v.y)), blue: min(1, max(0, v.z)))
    }

    /// Cyclic interpolation cyan → purple → magenta → cyan, p in 0...1.
    private static func metalHue(_ p: Double) -> SIMD3<Double> {
        let x = ((p.truncatingRemainder(dividingBy: 1)) + 1).truncatingRemainder(dividingBy: 1)
        let anchors = [anchorCyan, anchorPurple, anchorMagenta, anchorCyan]
        let seg = min(2, Int(x * 3))
        let lt = x * 3 - Double(seg)
        return anchors[seg] + (anchors[seg + 1] - anchors[seg]) * lt
    }

    // spectrum tokens resolved to RGB once, for the metallic math (no raw colour literals)
    private static func components(_ c: Color) -> SIMD3<Double> {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        _ = ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3(Double(r), Double(g), Double(b))
    }
    private static let anchorCyan    = components(AppColors.spectrumCyan)
    private static let anchorPurple  = components(AppColors.spectrumPurple)
    private static let anchorMagenta = components(AppColors.spectrumMagenta)
    private static let anchorDark    = components(AppColors.void)
}

// MARK: - Preview

#Preview("Metallic case") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView()
    }
    .preferredColorScheme(.dark)
}

// Reuse-contract proof: a different colorway + deck name with ZERO code changes.
// Ramp deliberately reuses existing tokens in a different order — the real
// category legend (sex, jealousy, …) is defined later.
#Preview("Alt deck theme") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView(theme: FoilDeckTheme(
            colorway: FoilColorway(
                c0: AppColors.spectrumMagenta,
                c1: AppColors.spectrumPurple,
                c2: AppColors.spectrumCyan
            ),
            deckName: "JEALOUSY"
        ))
    }
    .preferredColorScheme(.dark)
}

// Temporary verification harness — judge every foil segment against the card
// back it must complement. Same footprint for both so value range, spectrum
// order, and texture family compare directly.
#Preview("Case vs card back") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.md) {
            let cardW = AppLayout.obCardWidth(in: 240)
            let cardH = AppLayout.obCardHeight(in: 240)
            MetallicCaseView()
                .frame(width: cardW, height: cardH)
            VaylCardBack()
                .frame(width: cardW, height: cardH)
        }
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Vayl/Features/Onboarding/Components/DeckWrapView.swift` {#file-vayl-features-onboarding-components-deckwrapview-swift}

```swift
//
//  DeckWrapView.swift
//  Vayl
//
//  BuildDeck "Forge" beat. Spectrum ribbons spiral AROUND the rising deck (a helix) —
//  the foil being woven onto it as it lifts off the felt. Front strands draw bright,
//  back strands dim (as if behind the deck), and the whole helix spins. Driven by a
//  TimelineView clock so it actually animates.
//

import SwiftUI
import Darwin

struct DeckWrapView: View {
    var center:    CGPoint   // the (rising) deck centre
    var deckSize:  CGSize
    var startDate: Date
    var intensity: Double    // 0 → 1 (fades in / tightens as the deck builds)

    private let palette: [Color] = [AppColors.spectrumCyan,
                                    AppColors.spectrumPurple,
                                    AppColors.spectrumMagenta]

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(startDate)
            Canvas { ctx, _ in draw(&ctx, t: t) }
                .allowsHitTesting(false)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, t: Double) {
        guard intensity > 0.001 else { return }
        let hw = deckSize.width  * 0.50          // wrap radius ≈ deck half-width (hugs the deck)
        let hh = deckSize.height * 0.52
        let turns = 1.1 + 0.4 * intensity        // a few loose ribbons, not a tight coil
        let rot = t * 1.0                         // the helix spins
        let steps = 80

        for r in 0..<palette.count {
            let phaseOff = Double(r) / Double(palette.count) * 2 * .pi
            let color = palette[r]
            var prev: CGPoint? = nil
            for s in 0...steps {
                let u = Double(s) / Double(steps)            // 0 = top, 1 = bottom
                let ang = u * turns * 2 * .pi + rot + phaseOff
                let pt = CGPoint(x: center.x + CGFloat(Darwin.cos(ang)) * hw,
                                 y: center.y - hh + CGFloat(u) * 2 * hh)
                let front = Darwin.sin(ang) > 0              // toward the viewer?
                if let p = prev {
                    var seg = Path(); seg.move(to: p); seg.addLine(to: pt)
                    let op = (front ? 0.85 : 0.22) * intensity
                    let lw: CGFloat = front ? 2.2 : 1.3
                    var glow = ctx
                    glow.addFilter(.blur(radius: front ? 4 : 2))
                    glow.stroke(seg, with: .color(color.opacity(op * 0.55)),
                                style: StrokeStyle(lineWidth: lw + 2, lineCap: .round))
                    ctx.stroke(seg, with: .color(color.opacity(op)),
                               style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
                prev = pt
            }
        }
    }
}

```

---

## File: `Vayl/Design/Components/Cards/VaylDeckStack.swift` {#file-vayl-design-components-cards-vayldeckstack-swift}

```swift
// Design/Components/Cards/VaylDeckStack.swift

import SwiftUI

/// The squared deck — six real card backs whose per-layer offsets mirror
/// ConfirmationPhase's exit positions card-for-card. One source of truth for
/// "a deck of Vayl cards at rest":
///   • CuriosityPhase exit — the kept cards compress into this deck before it
///     flies to the corner (the credential travels as the same object the
///     user is about to see forged).
///   • BuildDeckPhase — the deck on the felt before the melt (its private
///     DeckStack predates this component; unify when next in that file).
struct VaylDeckStack: View {
    var size: CGSize
    /// Number of stacked backs. Default 6 (BuildDeck). Curiosity passes fewer for a
    /// slimmer symbolic deck.
    var count: Int = 6
    /// When true the stack recedes straight UP behind the front card, so the front
    /// card is anchored to the bottom and both sides. An overlaid LiftHalo then sits
    /// flush there (the deck thickness shows only above the top edge). Default false
    /// keeps BuildDeck's down-right bleed.
    var bleedUp: Bool = false
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                VaylCardBack()
                    .frame(width: size.width, height: size.height)
                    .offset(
                        x: bleedUp ? 0 : CGFloat(count - 1 - i) * 1.2,
                        y: CGFloat(count - 1 - i) * (bleedUp ? -1.6 : 1.6)
                    )
            }
        }
    }
}

```

---

## File: `Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift` {#file-vayl-features-onboarding-canvas-tablesurfaceview-swift}

```swift
//
//  TableSurfaceView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// Features/Onboarding/Canvas/TableSurfaceView.swift

import SwiftUI

// MARK: — TableSurfaceView
/// Layer 3 in OnboardingCanvasView.
/// Draws the full Vayl card table:
///   0. Upper void atmosphere — blobs in the card travel zone above the arc
///   1. Felt fill
///   2. Vignette — corner and top darkening
///   3. Topo contour lines
///   4. Compass star
///   5. Amber overhead pool
///   6. Spectrum rim arc + inner glow
///
/// Visibility is controlled entirely by fade — never by conditional rendering.
/// VaylDirector writes fade. SwiftUI animates it. This view never animates itself.
/// This view never responds to gestures and never holds state.
///
/// STRUCTURE — three stacked Canvases, split by what actually animates:
///   • TableBaseCanvas  (atmosphere + felt + vignette) — static; drawn once per size.
///   • TableTopoCanvas  (contour lines) — Animatable over warp/flowOut/forgeEnergy;
///     redraws per frame ONLY during the gender dissolution and the forge ceremony,
///     from precomputed TopoField samples (no per-frame noise evaluation).
///   • TableRimCanvas   (compass + amber pool + rim arc) — Animatable over rimBurst;
///     redraws per frame only while a rim burst decays.
///   `fade` is a plain `.opacity` on the stack — SwiftUI animates the composited
///   texture natively, so a table fade re-renders NOTHING.
/// The previous single-Canvas version made ALL of body's inputs animatable, which
/// re-evaluated the entire surface (62 noise-driven contour lines included) on
/// every frame of every fade and every card-landing rim burst — the main source
/// of dropped frames across the whole OB.
struct TableSurfaceView: View {

    // ── Parameters ────────────────────────────────────────────────────────────

    /// 0.0 = invisible, 1.0 = fully present.
    /// Never animated by this view — caller drives the value.
    /// VaylDirector is the only thing that writes this.
    var fade: Double
    /// 0.0 = resting spectrum rim. 1.0 = full impact flare.
    /// Caller drives — VaylDirector does not own this value.
    var rimBurst: Double = 0

    /// 0.0–0.52 — topo lines pulled inward toward card footprint (early dissolution).
    /// Driven by VaylDirector.dissolutionWarp. Zero when no card is crystallising.
    var dissolutionWarp: Double = 0

    /// 0.0–1.0 — topo lines deflect around card rounded-rect boundary (later dissolution).
    /// Driven by VaylDirector.dissolutionFlowOut. Zero when no card is crystallising.
    var dissolutionFlowOut: Double = 0

    /// 0.0–1.0 — the table "works": topo lines sway laterally with a per-line
    /// phase (forge ceremony). BuildDeckPhase oscillates this while the deck
    /// is being forged under the felt. Zero everywhere else.
    var forgeEnergy: Double = 0

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            TableBaseCanvas()
            TableTopoCanvas(
                dissolutionWarp:    dissolutionWarp,
                dissolutionFlowOut: dissolutionFlowOut,
                forgeEnergy:        forgeEnergy
            )
            TableRimCanvas(rimBurst: rimBurst)
        }
        .opacity(fade)
        // No .animation(value: fade) here — the caller's withAnimation drives the
        // opacity natively. A view-level animation would retarget every caller
        // curve and low-pass all table fades to one duration regardless of intent.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: — Preview
#Preview("Table Surface — Dark") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        TableSurfaceView(fade: 1.0)
    }
    .preferredColorScheme(.dark)
}

// MARK: — Shared geometry

/// The primary table geometry every layer derives from. All constants come from
/// AppLayout tokens — nothing hardcoded inside any sub-layer function.
private struct TableGeometry {
    let W:      CGFloat
    let H:      CGFloat
    let TY:     CGFloat   // arc peak Y on screen
    let tableR: CGFloat   // large radius — top cap only
    let cx:     CGFloat   // horizontal center
    let cy:     CGFloat   // circle center below screen
    let dpX:    CGFloat   // deal point x — arc centerline
    let dpY:    CGFloat   // deal point y — sits on arc

    init(size: CGSize) {
        W      = size.width
        H      = size.height
        TY     = H * AppLayout.tableArcPeakYFrac
        tableR = H * AppLayout.tableArcRadiusFrac
        cx     = W * 0.50
        cy     = TY + tableR
        dpX    = cx
        dpY    = TY + 1
    }
}

// MARK: — Base canvas (static: atmosphere + felt + vignette)

private struct TableBaseCanvas: View {

    var body: some View {
        Canvas { context, size in
            let g = TableGeometry(size: size)
            drawUpperAtmosphere(context: context, size: size, W: g.W, H: g.H, TY: g.TY)
            drawFeltFill(context: context, size: size, cx: g.cx, cy: g.cy, tableR: g.tableR)
            drawVignette(context: context, size: size, W: g.W, H: g.H)
        }
    }

    private func drawUpperAtmosphere(
        context: GraphicsContext,
        size:    CGSize,
        W:       CGFloat,
        H:       CGFloat,
        TY:      CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)

        struct Blob {
            let cx:     CGFloat
            let cy:     CGFloat
            let radius: CGFloat
            let color:  Color
        }

        let blobs: [Blob] = [
            // Large purple blob — upper left. Primary atmospheric anchor.
            // 0.058 — highest blob opacity, sets the atmospheric ceiling.
            Blob(cx: W * 0.18, cy: H * 0.10, radius: W * 0.60,
                 color: AppColors.spectrumPurple.opacity(0.058)),

            // Smaller purple blob — upper right. Secondary anchor.
            // 0.032 — half of primary, standard atmospheric falloff.
            Blob(cx: W * 0.82, cy: H * 0.08, radius: W * 0.46,
                 color: AppColors.spectrumPurple.opacity(0.032)),

            // Center purple bloom — sits at the deal point horizon.
            // 0.024 — tertiary, fills the center void without competing.
            Blob(cx: W * 0.50, cy: H * 0.22, radius: W * 0.52,
                 color: AppColors.spectrumPurple.opacity(0.024)),

            // Left cyan accent — adds spectral width to the atmosphere.
            // 0.016 — minimal, chromatic accent only.
            Blob(cx: W * 0.10, cy: H * 0.38, radius: W * 0.36,
                 color: AppColors.spectrumCyan.opacity(0.016)),

            // Right magenta accent — mirrors cyan for chromatic balance.
            // 0.014 — slightly lower than cyan so cyan leads.
            Blob(cx: W * 0.90, cy: H * 0.35, radius: W * 0.34,
                 color: AppColors.spectrumMagenta.opacity(0.014)),
        ]

        for blob in blobs {
            context.fill(
                Path(rect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: blob.color,            location: 0),
                        .init(color: blob.color.opacity(0), location: 1),
                    ]),
                    center:      CGPoint(x: blob.cx, y: blob.cy),
                    startRadius: 0,
                    endRadius:   blob.radius
                )
            )
        }
    }

    private func drawFeltFill(
        context: GraphicsContext,
        size:    CGSize,
        cx:      CGFloat,
        cy:      CGFloat,
        tableR:  CGFloat
    ) {
        let gradient = Gradient(stops: [
            .init(color: AppColors.tableFeltCore,  location: 0.00),
            .init(color: AppColors.tableFeltMid,   location: 0.25),
            .init(color: AppColors.tableFeltOuter, location: 0.60),
            .init(color: AppColors.tableFeltEdge,  location: 1.00),
        ])

        var path = Path()
        path.addEllipse(in: CGRect(
            x: cx - tableR, y: cy - tableR,
            width: tableR * 2, height: tableR * 2
        ))

        context.fill(
            path,
            with: .radialGradient(
                gradient,
                center:      CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius:   tableR
            )
        )
    }

    private func drawVignette(
        context: GraphicsContext,
        size:    CGSize,
        W:       CGFloat,
        H:       CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)

        // Four corner radial gradients — darken edges so the felt reads
        // as lit from the center overhead source. Edges fall into shadow.
        // AppColors.void is the darkest OB canvas surface — correct for vignette.
        // 0.82 — corner opacity. Strong enough to feel like physical shadow,
        // not so strong that it clips the topo lines near the card boundary.
        let cornerRadius  = W * 0.76
        let cornerOpacity = 0.82

        let corners: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: W, y: 0),
            CGPoint(x: W, y: H),
            CGPoint(x: 0, y: H),
        ]

        for corner in corners {
            context.fill(
                Path(rect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: AppColors.void.opacity(cornerOpacity), location: 0),
                        .init(color: AppColors.void.opacity(0),             location: 1),
                    ]),
                    center:      corner,
                    startRadius: 0,
                    endRadius:   cornerRadius
                )
            )
        }

        // Top linear gradient — darkens the top 20% of the screen.
        // Directs the eye toward the arc and deal point.
        // 0.45 — present enough to read as void depth, low enough
        // not to crush the atmosphere blobs beneath it.
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: AppColors.void.opacity(0.45), location: 0.00),
                    .init(color: AppColors.void.opacity(0),    location: 1.00),
                ]),
                startPoint: CGPoint(x: W / 2, y: 0),
                endPoint:   CGPoint(x: W / 2, y: H * 0.20)
            )
        )
    }
}

// MARK: — Topo canvas (animatable: dissolution warp/flow + forge sway)

private struct TableTopoCanvas: View, Animatable {

    var dissolutionWarp:    Double
    var dissolutionFlowOut: Double
    var forgeEnergy:        Double

    // Without Animatable conformance a Canvas view receives only the FINAL
    // value of a withAnimation change — the dissolution and forge oscillation
    // would freeze. Conforming makes these genuinely interpolate per frame.
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get {
            AnimatablePair(forgeEnergy, AnimatablePair(dissolutionWarp, dissolutionFlowOut))
        }
        set {
            forgeEnergy        = newValue.first
            dissolutionWarp    = newValue.second.first
            dissolutionFlowOut = newValue.second.second
        }
    }

    var body: some View {
        Canvas { context, size in
            drawTopoLines(context: context, size: size)
        }
    }

    private func drawTopoLines(context: GraphicsContext, size: CGSize) {
        let field = TopoField.shared.field(for: size)

        let activeWarp  = dissolutionWarp > 0.001 || dissolutionFlowOut > 0.001
        let activeForge = forgeEnergy > 0.001

        // ── Resting fast path ──────────────────────────────────────────────────
        // No displacement active (the whole OB outside the gender dissolution and
        // the forge ceremony): stroke the precomputed paths and return.
        guard activeWarp || activeForge else {
            for line in field.restingPaths {
                context.stroke(
                    line.path,
                    with: .color(AppColors.tableTopoLine.opacity(line.alpha)),
                    lineWidth: line.width
                )
            }
            return
        }

        // ── Animated path — displace cached base samples per frame ────────────
        let g = TableGeometry(size: size)
        let tableRSqInner = (g.tableR - 2) * (g.tableR - 2)

        // ── Card geometry for dissolution warp + flow-around ──────────────────
        // Derived entirely from AppLayout tokens — no raw geometry values.
        let cardW:      CGFloat = AppLayout.obTableCardWidth(in: g.W) * AppLayout.obTableCardCinematicScale
        let cardH:      CGFloat = cardW * 1.5   // 3:2 portrait ratio — matches obTableCardHeight derivation
        let cardCX:     CGFloat = g.W * 0.50
        let cardCY:     CGFloat = g.H * AppLayout.obGenderCardRestYFrac
        let cardRadius: CGFloat = AppRadius.obCard

        // Tuning constants — calibrated against the HTML prototype.
        let warpPullStrength:    CGFloat = 0.55  // inward pull magnitude at influence edge
        let flowInsidePush:      CGFloat = 0.92  // push-to-boundary strength inside card
        let flowOutsideBend:     CGFloat = 0.70  // tangential bend strength outside card
        let flowInfluenceRadius: CGFloat = 0.38  // influence zone as fraction of cardW

        let netWarp = CGFloat(dissolutionWarp) * (1 - CGFloat(dissolutionFlowOut))
        let netFlow = CGFloat(dissolutionFlowOut) * 0.68
        let fe      = CGFloat(forgeEnergy)

        for line in field.lines {
            var path      = Path()
            var wasInside = false

            for sample in line.samples {
                var px = sample.x
                let py = sample.y

                // ── Forge sway — the table works (BuildDeck ceremony) ─────────
                // Each line breathes laterally with its own phase; amplitude
                // scales with forgeEnergy so the felt is dead-still at 0.
                // 4.5 — max sway amplitude (pt). Rendering constant.
                if activeForge {
                    px += sin(sample.depthT * 5.2 + line.seed * 4.7 + fe * .pi * 2) * 4.5 * fe
                }

                // ── Dissolution warp + flow-around ────────────────────────────
                // Only runs when the gender card is crystallising.
                if activeWarp {
                    // — Phase 1: WARP — topo lines pulled inward toward card centre.
                    // Decays as flowOut rises — warp gives way to flow-around.
                    if netWarp > 0.001 {
                        let wdx = px - cardCX
                        let wdy = py - cardCY
                        let wd  = sqrt(wdx*wdx + wdy*wdy)
                        // 0.85 — warp influence radius as fraction of cardW.
                        let wr = cardW * 0.85
                        if wd < wr && wd > 0.001 {
                            let wf = pow(1 - wd/wr, 2.2)
                            px -= wdx * netWarp * wf * warpPullStrength
                        }
                    }

                    // — Phase 2: FLOW-AROUND — deflect lines at card rounded-rect boundary.
                    // SDF gives the signed distance to the card outline:
                    //   < 0 = inside card   → push point to nearest boundary
                    //   > 0 = outside, near → bend tangentially along boundary
                    if netFlow > 0.001 {
                        let sdf        = rrSDF(px: px, py: py,
                                               cx: cardCX, cy: cardCY,
                                               w: cardW,   h: cardH, r: cardRadius)
                        let influenceR = cardW * flowInfluenceRadius

                        if sdf < influenceR {
                            let rawProx  = 1 - max(0, min(1, sdf / influenceR))
                            // Smoothstep — prevents hard edge at influence boundary.
                            let smoothP  = rawProx * rawProx * (3 - 2 * rawProx)
                            let bx = nearestOnRRx(px: px, py: py,
                                                  cx: cardCX, cy: cardCY,
                                                  w: cardW,   h: cardH, r: cardRadius)
                            if sdf < 0 {
                                // Inside card: push all the way to the boundary.
                                px += (bx - px) * netFlow * smoothP * flowInsidePush
                            } else {
                                // Outside but close: gentle tangential bend.
                                px += (bx - px) * netFlow * smoothP * flowOutsideBend
                            }
                        }
                    }
                }

                let dx     = px - g.cx
                let dyCir  = py - g.cy
                let distSq = dx * dx + dyCir * dyCir
                let inside = distSq < tableRSqInner && py >= g.TY - 2

                if inside {
                    if !wasInside { path.move(to: CGPoint(x: px, y: py)) }
                    else          { path.addLine(to: CGPoint(x: px, y: py)) }
                }
                wasInside = inside
            }

            if !path.isEmpty {
                context.stroke(
                    path,
                    with: .color(AppColors.tableTopoLine.opacity(line.alpha)),
                    lineWidth: line.width
                )
            }
        }
    }

    // MARK: - Dissolution SDF Helpers

    /// Signed distance field for a rounded rectangle.
    /// Returns < 0 if `(px, py)` is inside, > 0 if outside.
    /// Used by drawTopoLines to determine which flow-around force to apply.
    private func rrSDF(px: CGFloat, py: CGFloat,
                       cx: CGFloat, cy: CGFloat,
                       w:  CGFloat, h:  CGFloat,
                       r:  CGFloat) -> CGFloat {
        let qx = abs(px - cx) - w / 2 + r
        let qy = abs(py - cy) - h / 2 + r
        return sqrt(max(qx, 0) * max(qx, 0) + max(qy, 0) * max(qy, 0))
             + min(max(qx, qy), 0) - r
    }

    /// X coordinate of the nearest point on the rounded-rect boundary to `(px, py)`.
    /// For inside points: returns the x of the nearest face centre.
    /// For outside points: returns the x of the nearest corner arc tangent point.
    private func nearestOnRRx(px: CGFloat, py: CGFloat,
                              cx: CGFloat, cy: CGFloat,
                              w:  CGFloat, h:  CGFloat,
                              r:  CGFloat) -> CGFloat {
        let hw = w / 2
        let hh = h / 2
        let dx = px - cx
        let dy = py - cy
        let qx = abs(dx) - hw + r
        let qy = abs(dy) - hh + r

        if qx <= 0 && qy <= 0 {
            // Inside: push to nearest vertical face (left/right wall).
            // If the horizontal distance to the face is smaller, push there;
            // otherwise leave x unchanged (point will push to top/bottom face via y).
            let toFace = hw - abs(dx)
            let toTop  = hh - abs(dy)
            if toFace < toTop {
                return cx + (dx >= 0 ? hw : -hw)
            } else {
                return px
            }
        } else {
            // Outside: project from the nearest corner circle centre.
            let cornerCX = cx + (dx >= 0 ? (hw - r) : -(hw - r))
            let cornerCY = cy + (dy >= 0 ? (hh - r) : -(hh - r))
            let dcx = px - cornerCX
            let dcy = py - cornerCY
            let dl  = sqrt(dcx * dcx + dcy * dcy)
            guard dl > 0.001 else { return cornerCX + r }
            return cornerCX + dcx / dl * r
        }
    }
}

// MARK: — Rim canvas (compass + amber pool + rim arc; animatable: rimBurst)

private struct TableRimCanvas: View, Animatable {

    var rimBurst: Double

    var animatableData: Double {
        get { rimBurst }
        set { rimBurst = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let g = TableGeometry(size: size)
            drawCompassStar(context: context, dpX: g.dpX, dpY: g.dpY, starSize: 20)
            drawAmberPool(context: context, size: size, dpX: g.dpX, dpY: g.dpY, W: g.W)
            drawSpectrumRim(
                context: context, size: size,
                cx: g.cx, cy: g.cy, tableR: g.tableR,
                TY: g.TY, W: g.W, dpX: g.dpX, dpY: g.dpY,
                rimBurst: rimBurst
            )
        }
    }

    private func drawCompassStar(
        context:  GraphicsContext,
        dpX:      CGFloat,
        dpY:      CGFloat,
        starSize: CGFloat
    ) {
        let center = CGPoint(x: dpX, y: dpY)

        // ── Soft glow behind star ──────────────────────────────────────────────
        // Drawn first so all star geometry renders on top.
        // AppGlows.compassStarGlow.color is tuned to 0.07 opacity — whisper presence.
        let glowRadius   = starSize * AppGlows.compassStarGlow.radiusMultiplier
        let glowGradient = Gradient(stops: [
            .init(color: AppGlows.compassStarGlow.color,            location: 0),
            .init(color: AppGlows.compassStarGlow.color.opacity(0), location: 1),
        ])

        var glowPath = Path()
        glowPath.addEllipse(in: CGRect(
            x: dpX - glowRadius, y: dpY - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        ))
        context.fill(
            glowPath,
            with: .radialGradient(
                glowGradient,
                center:      center,
                startRadius: 0,
                endRadius:   glowRadius
            )
        )

        // ── Outer halo ring ────────────────────────────────────────────────────
        // 1.18 — halo radius multiplier. Rendering constant — outer decorative ring
        // proportional to star size.
        let haloRadius = starSize * 1.18
        var haloPath   = Path()
        haloPath.addEllipse(in: CGRect(
            x: dpX - haloRadius, y: dpY - haloRadius,
            width: haloRadius * 2, height: haloRadius * 2
        ))
        context.stroke(
            haloPath,
            with: .color(AppColors.tableCompassStar.opacity(0.06)),
            lineWidth: 0.30
        )

        // ── Inner ring ─────────────────────────────────────────────────────────
        // 0.22 — inner ring radius multiplier. Rendering constant.
        let innerRingRadius = starSize * 0.22
        var innerRingPath   = Path()
        innerRingPath.addEllipse(in: CGRect(
            x: dpX - innerRingRadius, y: dpY - innerRingRadius,
            width: innerRingRadius * 2, height: innerRingRadius * 2
        ))
        context.stroke(
            innerRingPath,
            with: .color(AppColors.tableCompassStar.opacity(0.18)),
            lineWidth: 0.35
        )

        // ── 8 spikes ───────────────────────────────────────────────────────────
        // 4 cardinal (even index) + 4 intercardinal (odd index).
        // Each spike: light face + shadow face + thin outline.
        for i in 0 ..< 8 {
            let angle      = (CGFloat(i) / 8.0) * 2 * .pi - (.pi / 2)
            let isCardinal = (i % 2 == 0)

            // 0.46 — intercardinal length ratio. Rendering constant.
            // 0.072 / 0.048 — cardinal and intercardinal base widths. Rendering constants.
            let length:   CGFloat = isCardinal ? starSize         : starSize * 0.46
            let halfBase: CGFloat = isCardinal ? starSize * 0.072 : starSize * 0.048

            let perpAngle = angle + (.pi / 2)

            let tip = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            let baseLeft = CGPoint(
                x: center.x + cos(perpAngle) * halfBase,
                y: center.y + sin(perpAngle) * halfBase
            )
            let baseRight = CGPoint(
                x: center.x - cos(perpAngle) * halfBase,
                y: center.y - sin(perpAngle) * halfBase
            )

            // 0.62 / 0.40 — light face opacities. Rendering constants —
            // simulate overhead light catching the spike face.
            // 0.36 / 0.22 — shadow face opacities. Rendering constants —
            // simulate self-shadow on the opposite spike face.
            let lightOpacity:  Double = isCardinal ? 0.62 : 0.40
            let shadowOpacity: Double = isCardinal ? 0.36 : 0.22

            var lightFace = Path()
            lightFace.move(to: tip)
            lightFace.addLine(to: baseLeft)
            lightFace.addLine(to: center)
            lightFace.closeSubpath()
            context.fill(lightFace,
                         with: .color(AppColors.tableCompassStar.opacity(lightOpacity)))

            var shadowFace = Path()
            shadowFace.move(to: tip)
            shadowFace.addLine(to: baseRight)
            shadowFace.addLine(to: center)
            shadowFace.closeSubpath()
            context.fill(shadowFace,
                         with: .color(AppColors.tableCompassStar.opacity(shadowOpacity)))

            var outline = Path()
            outline.move(to: tip)
            outline.addLine(to: baseLeft)
            outline.addLine(to: center)
            outline.addLine(to: baseRight)
            outline.addLine(to: tip)
            context.stroke(
                outline,
                with: .color(AppColors.tableCompassStar.opacity(0.25)),
                lineWidth: 0.30
            )
        }

        // ── Center octagon ─────────────────────────────────────────────────────
        // 0.075 — octagon radius multiplier. Rendering constant.
        let octRadius = starSize * 0.075
        var octPath   = Path()
        for i in 0 ..< 8 {
            let a     = (CGFloat(i) / 8.0) * 2 * .pi
            let point = CGPoint(
                x: center.x + cos(a) * octRadius,
                y: center.y + sin(a) * octRadius
            )
            if i == 0 { octPath.move(to: point) }
            else       { octPath.addLine(to: point) }
        }
        octPath.closeSubpath()
        context.fill(octPath,
                     with: .color(AppColors.tableCompassStar.opacity(0.72)))
    }

    private func drawAmberPool(
        context: GraphicsContext,
        size:    CGSize,
        dpX:     CGFloat,
        dpY:     CGFloat,
        W:       CGFloat
    ) {
        // 35 — pool center vertical offset below deal point. Rendering constant —
        // pool sits on the near felt surface, not at the arc itself.
        // 0.42 — pool radius as fraction of screen width. Rendering constant.
        let poolCenter = CGPoint(x: dpX, y: dpY + 35)
        let poolRadius = W * 0.42

        let gradient = Gradient(stops: [
            .init(color: AppColors.tableAmberPool,            location: 0),
            .init(color: AppColors.tableAmberPool.opacity(0), location: 1),
        ])

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                gradient,
                center:      poolCenter,
                startRadius: 0,
                endRadius:   poolRadius
            )
        )
    }

    private func drawSpectrumRim(
        context:  GraphicsContext,
        size:     CGSize,
        cx:       CGFloat,
        cy:       CGFloat,
        tableR:   CGFloat,
        TY:       CGFloat,
        W:        CGFloat,
        dpX:      CGFloat,
        dpY:      CGFloat,
        rimBurst: Double
    ) {
        // ── Rim inner glow ─────────────────────────────────────────────────────
        // AppGlows.tableRimInnerGlow.color is tuned to 0.05 opacity — accent only.
        let innerR = tableR - AppGlows.tableRimInnerGlow.innerInset
        let outerR = tableR + AppGlows.tableRimInnerGlow.outerInset
        let peak   = AppGlows.tableRimInnerGlow.peakPosition

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppGlows.tableRimInnerGlow.color.opacity(0), location: 0),
                    .init(color: AppGlows.tableRimInnerGlow.color,            location: peak),
                    .init(color: AppGlows.tableRimInnerGlow.color.opacity(0), location: 1),
                ]),
                center:      CGPoint(x: cx, y: cy),
                startRadius: innerR,
                endRadius:   outerR
            )
        )

        // ── Star emission glow along arc ───────────────────────────────────────
        // The compass star sits at arc center (3π/2). A radial gradient from the
        // star position outward makes the arc read as powered by the star.
        // 0.18 — star emit radius multiplier. Rendering constant — tight halo
        // immediately around the star position only.
        // 0.03 — star emit opacity. Rendering constant — atmosphere, not glow.
        let starEmitRadius = tableR * 0.18
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.tableCompassStar.opacity(0.03), location: 0),
                    .init(color: AppColors.tableCompassStar.opacity(0),    location: 1),
                ]),
                center:      CGPoint(x: dpX, y: dpY),
                startRadius: 0,
                endRadius:   starEmitRadius
            )
        )

        // ── Tapered spectrum rim arc ───────────────────────────────────────────
        // Arc runs from π (left) to 2π (right) — top arc only.
        // The compass star sits at 3π/2 (top center — the arc midpoint).
        //
        // Taper uses a squared distance curve — holds thick longer at the ends
        // and drops off faster near center so the star feels deliberately spotlit.
        //
        // Crisp stroke:  0.9pt center → 2.7pt edges
        // Base stroke:   crisp × 2.5 (bloom hugs the crisp line exactly)
        // Base pass composited at 0.12 opacity via drawLayer — reads as a glow
        // embedded in the felt surface rather than a fat duplicate stroke.

        // 120 — segment count. Rendering constant — smooth taper at any screen size.
        let segmentCount = 120
        let arcStart:    CGFloat = .pi
        let arcEnd:      CGFloat = 2 * .pi
        let arcMid:      CGFloat = 3 * .pi / 2
        let arcSpan:     CGFloat = arcEnd - arcStart

        // Rendering constants — crisp stroke range.
        let crispThin:   CGFloat = 0.9
        let crispThick:  CGFloat = 2.7
        // 2.5 — base bloom multiplier. Rendering constant — bloom hugs crisp line exactly.
        let baseMultiplier: CGFloat = 2.5
        // rimBurst spikes to 1.0 on card impact, decays to 0.0.
        // Multiplies base pass opacity and rim gradient stops for the flare.
        let burstMult   = 1.0 + rimBurst * 4.0
        let baseOpacity = 0.12 * burstMult

        let bo = min(rimBurst * 2.5, 1.0)  // burst opacity additive, capped
        let rimGradient = Gradient(stops: [
            .init(color: AppColors.spectrumCyan.opacity(0.28 + bo * 0.50),    location: 0.00),
            .init(color: AppColors.spectrumCyan.opacity(0.55 + bo * 0.40),    location: 0.06),
            .init(color: AppColors.spectrumCyan.opacity(0.70 + bo * 0.30),    location: 0.26),
            .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.44),
            .init(color: AppColors.spectrumPurple.opacity(0.94 + bo * 0.06),  location: 0.50),
            .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.56),
            .init(color: AppColors.spectrumMagenta.opacity(0.70 + bo * 0.30), location: 0.74),
            .init(color: AppColors.spectrumMagenta.opacity(0.55 + bo * 0.40), location: 0.94),
            .init(color: AppColors.spectrumMagenta.opacity(0.28 + bo * 0.50), location: 1.00),
        ])

        let gradStart = CGPoint(x: 0, y: TY)
        let gradEnd   = CGPoint(x: W, y: TY)

        for i in 0 ..< segmentCount {
            let t0 = CGFloat(i)     / CGFloat(segmentCount)
            let t1 = CGFloat(i + 1) / CGFloat(segmentCount)

            let angle0   = arcStart + t0 * arcSpan
            let angle1   = arcStart + t1 * arcSpan
            let angleMid = (angle0 + angle1) / 2

            // Normalised angular distance from arc center (0=star, 1=edge).
            let distFromCenter = abs(angleMid - arcMid) / (arcSpan / 2)

            // Squared taper — holds thick at edges, drops fast near center.
            let taper = distFromCenter * distFromCenter

            let crispWidth = crispThin + (crispThick - crispThin) * taper
            let baseWidth  = crispWidth * baseMultiplier

            var segPath = Path()
            segPath.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     tableR,
                startAngle: .radians(angle0),
                endAngle:   .radians(angle1),
                clockwise:  false
            )

            // Base pass — composited at reduced opacity so it reads as a
            // glow embedded in the felt surface, not a fat duplicate stroke.
            context.drawLayer { layerContext in
                layerContext.opacity = baseOpacity
                layerContext.stroke(
                    segPath,
                    with: .linearGradient(rimGradient,
                                          startPoint: gradStart,
                                          endPoint:   gradEnd),
                    lineWidth: baseWidth
                )
            }

            // Crisp top pass — the visible spectrum line.
            context.stroke(
                segPath,
                with: .linearGradient(rimGradient,
                                      startPoint: gradStart,
                                      endPoint:   gradEnd),
                lineWidth: crispWidth
            )
        }
    }
}

```

---

## File: `Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift` {#file-vayl-features-onboarding-canvas-onboardingcanvasview-swift}

```swift
//
//  OnboardingCanvasView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

// Features/Onboarding/Canvas/OnboardingCanvasView.swift

import SwiftData
import SwiftUI
import SpriteKit

/// The single persistent canvas for the entire OB flow.
/// Layer order: void → atmosphere → table → dealpoint → cardFlight(SpriteKit, 4b) →
///              tableCards → inFlightCards → projectedText → phaseOverlay → cornerDeck → marks
/// No NavigationStack. No .sheet(isPresented:) within this boundary.
struct OnboardingCanvasView: View {

    @State var director: VaylDirector
    @State private var tableRimBurst: Double = 0
    @State private var tableForgeEnergy: Double = 0

    @MainActor init() {
        self._director = State(initialValue: VaylDirector())
    }

    init(director: VaylDirector) {
        self._director = State(initialValue: director)
    }

    /// True only inside the Xcode Preview canvas. SpriteKit's `SpriteView` fails to
    /// composite there and blanks the whole preview to a gray backdrop, hiding the
    /// void + atmosphere. It has nothing to render while walking phases anyway (no
    /// card flights), so we skip mounting it in previews. No effect on device/sim.
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var atmosphereConfig: AtmosphereConfig {
        switch director.phase {
        case .stat:         return .stat
        case .name:         return .name
        case .gender:       return .name        // no distinct gender config — name atmosphere
        case .modeSelect:   return .modeSelect
        case .curiosity:    return .curiosityPicker
        default:            return .name         // all remaining phases use name atmosphere
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // ── Layer 1: Void ─────────────────────────────────
                AppColors.void
                    .ignoresSafeArea()

                // ── Layer 2: Atmosphere ───────────────────────────
                OnboardingAtmosphere(config: atmosphereConfig)
                    .opacity(0.68)
                    // Config crossfade is owned by OnboardingAtmosphere's internal
                    // atmosphereShift — no second animation here (was double-driving it).
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layer 3: Table surface ────────────────────────
                TableSurfaceView(
                    fade:               director.tableFade,
                    rimBurst:           tableRimBurst,
                    dissolutionWarp:    director.gender.dissolutionWarp,
                    dissolutionFlowOut: director.gender.dissolutionFlowOut,
                    forgeEnergy:        tableForgeEnergy
                )
                .ignoresSafeArea()

                // ── Layer 4: Deal point ───────────────────────────
                DealPointView(
                    intensity:  director.dealPointIntensity,
                    screenSize: size
                )

                // ── Layer 4b: SpriteKit card flight ───────────────
                // Persistent physics scene — clear background so the
                // table surface shows through between card flights.
                // allowsHitTesting false — gestures pass through to
                // phase overlays beneath and above this layer.
                // Scene is sized in .onAppear because size is zero
                // at CardFlightScene() init time.
                //
                // shouldRender — the scene gates its own frames (renders only
                // while cards exist + a short grace to flush removals), so the
                // idle SpriteView costs no GPU behind the rest of the OB.
                // 120fps — deals render at ProMotion rate instead of the SKView
                // default 60, matching the SwiftUI animations around them
                // (CADisableMinimumFrameDurationOnPhone is set in Vayl.plist;
                // non-ProMotion displays clamp to 60 automatically).
                // Skipped in the Xcode Preview canvas — SpriteView blanks the whole
                // preview to gray there (see `isPreview`). Rendered normally on device/sim.
                if !isPreview {
                    let flightScene = director.cardFlightScene
                    SpriteView(
                        scene:   flightScene,
                        preferredFramesPerSecond: 120,
                        options: [.allowsTransparency],
                        shouldRender: { flightScene.shouldRender(at: $0) }
                    )
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .onAppear {
                        director.cardFlightScene.size = size
                    }
                }

                // ── Layer 5: Table cards ──────────────────────────
                ForEach(director.tableCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                        .zIndex(Double(card.zIndex))
                }

                // ── Layer 6: In-flight cards ──────────────────────
                ForEach(director.inFlightCards) { card in
                    VaylCardRenderer(card: card, screenSize: size)
                        .zIndex(Double(card.zIndex))
                }

                // ── Layer 7: Projected dealer text ────────────────
                // Suppressed during .context — ContextPhase renders its OWN copy
                // above its card stack (this canvas layer sits below the phase
                // overlay), so rendering both double-composites the dealer line.
                // Mirrors the corner-deck phase guard below.
                if director.projector.projectedTextVisible,
                   let text = director.projector.projectedText,
                   director.phase != .context {
                    ProjectedTextView(text: text, screenSize: size,
                                      anchorYFrac: director.projector.projectedTextAnchorYFrac)
                        .transition(.opacity)
                }

                // ── Layer 8: Corner deck ─────────────────────────
                // Sits below the phase overlay so form screens naturally
                // cover it — deck is only visible during canvas/table moments.
                // Corner deck follows the table world — visible when tableFade > 0 and a card has been collected.
                // Never independently toggled; visibility is purely derived from state.
                // Hidden during .confirmation — the credential cards deal out of the
                // corner into the review fan (ConfirmationPhase), so the source deck
                // would otherwise double up with them.
                // Also hidden during .buildDeck — those same six credentials have
                // collapsed into the centre deck that the forge melts; a corner deck
                // fading back in top-right would double them and contradict "yours alone".
                if director.tableFade > 0.01 && !director.cornerDeckCards.isEmpty
                    && director.phase != .confirmation
                    && director.phase != .buildDeck {
                    CornerDeckView(
                        cards:      director.cornerDeckCards,
                        screenSize: size,
                        deckPulse:  director.deckPulse
                    )
                    .opacity(director.tableFade)
                    .transition(.opacity)
                }

                // ── Layer 9: Phase overlays ───────────────────────
                PhaseOverlayView(director: director, screenSize: size,
                                 tableRimBurst: $tableRimBurst,
                                 tableForgeEnergy: $tableForgeEnergy)
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()

                // ── Layer 10: Corner marks ────────────────────────
            

                
            }
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            director.start()
        }
    }
}

// MARK: - OnboardingCanvasWrapper
//
// Use this at every call site (AppRootView) instead of OnboardingCanvasView directly.
// This wrapper's GeometryReader sits *outside* the .ignoresSafeArea() chain, so
// geo.safeAreaInsets correctly reports the real device safe area (top:59, bottom:34
// on Face ID phones). Those values are injected into the environment before the
// canvas's own .ignoresSafeArea() gets to consume them.
struct OnboardingCanvasWrapper: View {
    @State private var director = VaylDirector()

    var body: some View {
        @Bindable var director = director
        return GeometryReader { geo in
            ZStack {
                OnboardingCanvasView(director: director)
                    .environment(\.realSafeArea, geo.safeAreaInsets)
                    .ignoresSafeArea()

                // ConfirmationPhase edit sheet. Hosted HERE — outside the canvas
                // boundary — and driven by director.editingCredential. A CUSTOM
                // full-bleed, medium-detent bottom sheet (not native .sheet):
                // iOS 26 native sheets inset to floating cards, so this is the
                // only way to get edge-to-edge full width. Medium detent keeps
                // the review fan visible above it.
                if let credential = director.editingCredential {
                    CredentialEditorOverlay(director: director, credential: credential)
                }

                // Single-user couples-first greeting (ContextPhase) — hosted here, outside
                // the canvas, same as the edit overlay above.
                if director.showSingleGreeting {
                    SingleGreetingOverlay(director: director)
                }
            }
            .animation(AppAnimation.standard.reduceMotionSafe, value: director.editingCredential)
            .animation(AppAnimation.standard.reduceMotionSafe, value: director.showSingleGreeting)
        }
    }
}

// MARK: - Phase Router
// Switch on director.phase. VaylDirector is the only thing that changes director.phase.
// Phases hand over with a continuous depth cross-fade (see `phaseHandoff`): the arriving
// phase settles in from slightly forward, the departing phase recedes back — so the canvas
// reads as one space with z-depth, not a slideshow. Reduce Motion → pure opacity.

private struct PhaseOverlayView: View {
    let director:   VaylDirector
    let screenSize: CGSize
    @Binding var tableRimBurst: Double
    @Binding var tableForgeEnergy: Double

    var body: some View {
        ZStack {
            phaseContent
                .transition(phaseHandoff)
        }
        // Pin the ZStack to screen dimensions.
        // Card transforms during NamePhase (offset to deal origin,
        // scaleEffect during lift) exceed the ZStack's natural content
        // size. Without this frame SwiftUI clips anything that renders
        // outside the smaller collapsed boundary.
        .frame(width: screenSize.width, height: screenSize.height)
        .ignoresSafeArea()
        // `slow` (0.5s) over `standard` (0.3s) — slow's own token doc names it the
        // onboarding step-transition animation. reduceMotionSafe → fast opacity confirm.
        .animation(AppAnimation.slow.reduceMotionSafe, value: director.phase)
    }

    /// The active phase view. Each case is a distinct type, so changing `director.phase`
    /// changes identity → `phaseHandoff` plays on the outgoing + incoming phase.
    @ViewBuilder
    private var phaseContent: some View {
        switch director.phase {
        case .stat:
            StatPhase(director: director)

        case .demo:
            DemoPhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .name:
            NamePhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .gender:
            GenderPhase(director: director, screenSize: screenSize, tableRimBurst: $tableRimBurst)

        case .modeSelect:
            ModeSelectPhase(director: director, screenSize: screenSize)

        case .experienceLevel:
            ExperienceLevelPhase(director: director, screenSize: screenSize)

        case .context:
            ContextPhase(director: director, screenSize: screenSize)

        case .curiosity:
            CuriosityPhase(director: director, screenSize: screenSize)

        case .confirmation:
            ConfirmationPhase(director: director)

        case .buildDeck:
            BuildDeckPhase(director: director, screenSize: screenSize,
                           tableRimBurst: $tableRimBurst,
                           tableForgeEnergy: $tableForgeEnergy)

        case .founderLetter:
            FounderLetterPhase(director: director)
        }
    }

    /// Continuous phase-to-phase depth handoff. FEEL-GATE — the scale magnitudes are
    /// starting points; verify on device and dial to taste. Incoming settles in from
    /// slightly forward (1.02 → 1.0); outgoing recedes back (1.0 → 0.97). Under Reduce
    /// Motion this collapses to a pure opacity cross-fade — scale is motion.
    private var phaseHandoff: AnyTransition {
        // Confirmation → BuildDeck is a pixel-identical deck handoff (the collapsed
        // credential fan and BuildDeck's VaylDeckStack share point/size/face). A depth
        // scale would counter-scale the two near-identical decks about screen-centre and
        // double-image the swap. Both the leaving Confirmation and the arriving BuildDeck
        // evaluate this against the POST-advance phase, so keying on .buildDeck drops the
        // scale on BOTH sides of this one seam only — every other handoff keeps its depth.
        if director.phase == .buildDeck { return .opacity }
        // Staple 1, Loud register — the OB IS the loud register's reference implementation.
        // vaylDepth handles the Reduce Motion collapse to .opacity internally.
        return .vaylDepth(.loud)
    }
}

#if DEBUG
#Preview("Full OB Flow") {
    let appState = AppState()
    let store = OnboardingStore(
        modelContainer: ModelContainer.previewContainer,  // in-memory — never hits disk in previews
        appState: appState
    )

    struct DevWrapper: View {
        @State private var director = VaylDirector()
        @State private var menuVisible = true

        var body: some View {
            @Bindable var director = director
            return GeometryReader { geo in
            ZStack(alignment: .bottom) {
                OnboardingCanvasView(director: director)
                    .environment(\.realSafeArea, geo.safeAreaInsets)
                    .ignoresSafeArea()

                if menuVisible {
                    VStack(spacing: 0) {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(OBPhase.allCases, id: \.self) { phase in
                                    Button {
                                        // Jump through the real navigation path so the target
                                        // phase's entry routine runs (advance → handlePhaseEntry).
                                        // Setting director.phase directly skips entry — e.g.
                                        // Curiosity never arms curiosityDemoActive, so its deal
                                        // bails on the guard and the phase looks stuck until you
                                        // reach it through a real transition. The canvas already
                                        // cross-fades on director.phase, so no withAnimation here.
                                        director.advance(to: phase)
                                    } label: {
                                        Text(String(describing: phase))
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                director.phase == phase
                                                    ? AppColors.accentPrimary
                                                    : Color.black.opacity(0.55)
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(AppAnimation.standard) {
                                menuVisible.toggle()
                            }
                        } label: {
                            Image(systemName: menuVisible ? "hammer.fill" : "hammer")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                    }
                    Spacer()
                }

                // Mirror OnboardingCanvasWrapper's custom editor overlay so the
                // ConfirmationPhase edit sheet works in the preview too.
                if let credential = director.editingCredential {
                    CredentialEditorOverlay(director: director, credential: credential)
                }

                if director.showSingleGreeting {
                    SingleGreetingOverlay(director: director)
                }
            }
            } // GeometryReader
            .animation(AppAnimation.standard, value: director.editingCredential)
            .animation(AppAnimation.standard, value: director.showSingleGreeting)
        }
    }

    return DevWrapper()
        .environment(store)
        .preferredColorScheme(.dark)
}
#endif

```

---

## File: `Vayl/Features/Onboarding/Models/WelcomeDeck.swift` {#file-vayl-features-onboarding-models-welcomedeck-swift}

```swift
// Vayl/Features/Onboarding/Models/WelcomeDeck.swift
import SwiftUI

/// The forged starter deck revealed at the end of BuildDeck. Identity derives
/// from `OpenerDeckType` (set by `VaylDirector.evaluateOpenerDeckType()` at the
/// end of Curiosity). Card CONTENT is placeholder pending the content pass;
/// name + purpose + colorway are real so the reveal feels personalised.
struct WelcomeDeck: Equatable {
    let name: String        // the genuine name reveal
    let purpose: String     // one line above the carousel
    let colorway: FoilColorway

    /// Placeholder prompt cards — shared set; the content pass replaces these.
    /// Tuple shape mirrors `VaylCardFace.context(number:title:subtitle:detail:)`.
    static let placeholderCards: [(number: String, title: String, subtitle: String, detail: String)] = [
        ("01", "Name it",    "What pulled you toward this", "A first card to open the conversation."),
        ("02", "Out loud",   "Say one true thing",          "Practice putting words to the want."),
        ("03", "The edge",   "Where it gets tender",        "The place you usually go quiet."),
        ("04", "Their side", "What you'd want to hear",     "Imagine it from across the table."),
        ("05", "Small step", "One thing this week",         "Low stakes, real movement."),
        ("06", "Check in",   "How it actually felt",        "Come back and tell the truth about it."),
    ]

    // provisional working titles — map to OpenerDeckType semantics; content pass renames
    static func of(_ type: OpenerDeckType) -> WelcomeDeck {
        switch type {
        case .anxious:        return .init(name: "STEADY",  purpose: "Start slow. Find your footing.",      colorway: .solo)
        case .excited:        return .init(name: "OPENING", purpose: "Lean into the momentum.",             colorway: .solo)
        case .reflectiveCalm: return .init(name: "RETURN",  purpose: "Revisit what you already know.",      colorway: .solo)
        case .reflectiveOpen: return .init(name: "WIDER",   purpose: "Build on the ground you've covered.", colorway: .solo)
        }
    }
}

```

---

## File: `Vayl/Features/Onboarding/Models/FoilTear.swift` {#file-vayl-features-onboarding-models-foiltear-swift}

```swift
//
//  FoilTear.swift
//  Vayl
//

// Features/Onboarding/Models/FoilTear.swift

import CoreGraphics
import Foundation

/// A single crack in the sealed case during BuildDeckPhase.
/// Created by VaylDirector when the user taps the case (Beat 5, crack ceremony).
/// Three tears → the foil integrity collapses and the case shatters.
struct FoilTear: Identifiable {

    // MARK: - Identity

    let id: UUID = UUID()

    // MARK: - Geometry

    /// The tap point in FACE-LOCAL UV (u across the case front, v down it).
    /// Stored in face space — never screen space — so the crack sticks to the
    /// case while it floats and tilts (ceremony spec: tears convert to
    /// face-local UV at tap time).
    let faceUV: CGPoint

    /// Authored dominant orientation of this crack's main fracture, in degrees
    /// (0 = horizontal across the face, 90 = vertical down it). Each sequence
    /// gives its three strikes deliberately different orientations.
    let angleDeg: Double

    /// Stable seed for the tear's generated branch geometry — the crack
    /// pattern is procedural but identical frame to frame.
    let seed: UInt64 = .random(in: .min ... .max)

    /// When the strike landed — drives the crack's propagation animation
    /// (cracks travel outward from the finger; they don't appear formed).
    let struck: Date = .now
}

```

---

## File: `Vayl/App/Theme/AppAnimation.swift` {#file-vayl-app-theme-appanimation-swift}

```swift
//
//  AppAnimation.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// App/Theme/AppAnimation.swift

import SwiftUI
import UIKit

/// Tier 2 — Semantic animation tokens.
/// Every animation in the codebase must reference one of these tokens.
/// Ad hoc values like .easeOut(duration: 0.3) anywhere outside this file are a violation.
///
/// Two animation classes exist and must never be confused:
///   Reactive  — responds directly to a user action (tap, swipe, drag release).
///               Always takes priority. Never cancel or defer a reactive animation.
///   Ambient   — runs continuously without user input (pulse, glow, orbit).
///               Always yields to reactive animations. Never block user feedback.
///
/// Reduce Motion rules:
///   Every token has a documented reduce-motion fallback.
///   Reactive animations: replace movement with an instant opacity cross-fade.
///   Ambient animations: disable entirely — remove the animation, not just slow it down.
///   Never use .default or .linear as a reduce-motion fallback — they still move.
///   The correct fallback for movement is no movement. Opacity change is permitted.
internal enum AppAnimation {

    // MARK: — Reactive Animations
    // These respond to user actions. They must feel immediate and confirm input.
    // Reduce motion fallback for all reactive tokens: .easeOut(duration: 0.15)
    // This preserves the state change confirmation while eliminating spatial movement.

    /// 0.15s ease-out — Immediate micro-responses to user input.
    /// Use for button press states, toggle flips, selection highlights, and icon state changes.
    /// The speed communicates that the app registered the tap instantly.
    /// Reduce motion: use as-is — at 0.15s this is already at the threshold of perception.
    static let fast: Animation = .easeOut(duration: 0.15)

    /// 0.3s ease-out — Standard state transitions driven by user action.
    /// Use for screen element rearrangement after a selection, card state changes,
    /// and any layout shift that results directly from a tap or swipe.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm the change, skip the travel.
    static let standard: Animation = .easeOut(duration: 0.3)

    /// 0.5s ease-out — Deliberate, weighty transitions for significant state changes.
    /// Use for onboarding step transitions, modal presentations driven by user action,
    /// and reveal animations where the user has explicitly requested new content.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — the reveal happens, the travel does not.
    static let slow: Animation = .easeOut(duration: 0.5)

    // MARK: — Cinematic Duration
    // Not an Animation value — a raw duration for use with .easeOut(duration: AppAnimation.cinematic).
    // Reserved for screen-level content reveals requiring ceremony beyond slow (0.5s).
    // Ambient animations must be disabled entirely when reduce motion is active.

    /// 1.2s — Cinematic reveal duration.
    /// Use for name reveals, tagline entrances, and LivingText fade-in arrivals that
    /// require ceremony beyond slow (0.5s). Not an Animation instance — pass as a
    /// duration parameter: .easeOut(duration: AppAnimation.cinematic).
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    /// Do not use for UI response animations — those use slow or enter.
    static let cinematic: Double = 1.2

    /// Cinematic ease-out — TableSurfaceView fade in/out.
    /// Use this instead of constructing .easeOut(duration: AppAnimation.cinematic) inline.
    static let cinematicFade: Animation = .easeOut(duration: AppAnimation.cinematic)

    // MARK: — StatPhase Arrival Ignition
    // The "1 in 5" hero fires a one-time light-catch as it seats: a bright specular
    // sweep crosses the numeral, the glow blooms past its resting level then settles,
    // and a soft haptic lands. Tuned in docs/prototypes/statphase-arrival.html.
    // Reduce motion: skip the sweep + bloom entirely (visual only); the soft land
    // haptic still fires (haptics are not motion).

    /// 0.76s — Delay from the stat's cascade entrance to the ignition firing, so the
    /// light catches the numeral as it *seats* rather than on first appearance.
    static let statIgnitionDelay: Double = 0.76

    /// 0.68s ease-out — The one bright specular sweep travelling across the numeral on land.
    static let statIgnitionSweep: Animation = .easeOut(duration: 0.68)

    /// 0.14s ease-out — Glow blooming up to its ignition peak as the numeral seats.
    static let statGlowBloomIn: Animation = .easeOut(duration: 0.14)

    /// 0.16s — Hold at the bloom peak before it settles back to the resting glow.
    /// Must exceed statGlowBloomIn (0.14s) or the settle retargets the bloom mid-flight.
    static let statGlowBloomHold: Double = 0.16

    /// 0.46s settle — Glow easing back down from the ignition peak to its resting level.
    /// timingCurve (0.22, 1, 0.36, 1): snappy ease-out, no overshoot.
    static let statGlowBloomSettle: Animation = .timingCurve(0.22, 1, 0.36, 1, duration: 0.46)

    /// 0.65s ease-out — StatPhase exit: the entire phase fades out after "Begin" is tapped.
    /// Long enough that the phase cross-fade (AppAnimation.slow) absorbs the remaining tail.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statExitFade: Animation = .easeOut(duration: 0.65)

    /// 0.32s ease-in-out — StatPhase citation panel toggle (open and close).
    /// Calm dim + fade — not snappy, not ceremonial. The panel is reference content.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let statCitationToggle: Animation = .easeInOut(duration: 0.32)

    /// 0.35s material expand — Citation panel expand and collapse.
    /// timingCurve (0.4, 0, 0.2, 1): standard deceleration curve — element
    /// enters fast and eases into its resting position. Used for the expandable
    /// citation card in StatPhase. Not a general-purpose animation token — do
    /// not use outside StatPhase without deliberate intent.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let materialExpand: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.35)

    /// Spring — Physical, elastic responses to direct manipulation.
    /// Use for card lifts, pill selections, drag release snapping, and any interaction
    /// where the element should feel like it has mass and momentum.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — confirm without the bounce.
    static let spring: Animation = .spring(response: 0.5, dampingFraction: 0.85)

    // MARK: — Directional Transition Animations
    // Use for elements entering or leaving the screen as a result of navigation.
    // Reduce motion fallback: replace directional movement with opacity only.

    /// 0.4s ease-out — Elements entering the screen or becoming visible.
    /// Use for views sliding or fading into position after navigation, and for
    /// content appearing after an async load completes.
    /// Reduce motion: replace movement with .opacity animation at 0.2s duration.
    static let enter: Animation = .easeOut(duration: 0.4)

    /// 0.2s ease-in — Elements leaving the screen or becoming hidden.
    /// Use for views dismissing after navigation away, and for
    /// content disappearing before a state replacement.
    /// Ease-in for exit makes the departure feel intentional, not interrupted.
    /// Reduce motion: replace movement with .opacity animation at 0.15s duration.
    static let exit: Animation = .easeIn(duration: 0.2)

    // MARK: — Ambient Animation Durations
    // These are not Animation values — they are raw durations for use with
    // TimelineView, withAnimation loops, or RepeatForever animations.
    // Ambient animations must be disabled entirely when reduce motion is active.
    // Never use these durations inside a withAnimation block that responds to user input.

    /// 2.0s — Slow, continuous ambient pulse.
    /// Use for background glow breathe cycles, aura scale oscillation,
    /// and any effect that communicates the app is alive and listening.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientPulse: Double = 2.0

    /// 4.0s — Very slow ambient drift.
    /// Use for aurora blob position shifts, background gradient rotation,
    /// and effects that should feel geological — barely perceptible movement.
    /// Reduce motion: remove the animation entirely. The static state must be visually complete.
    static let ambientDrift: Double = 4.0

    /// 1.2s — Medium ambient shimmer cycle.
    /// Use for specular highlight sweeps across card surfaces, shimmer loading states,
    /// and light-catch effects on premium surfaces.
    /// Reduce motion: remove the animation entirely — shimmer is purely decorative.
    static let ambientShimmer: Double = 1.2

    /// 2.2s — Duration of one direction of a candle's breath (in OR out). Build the
    /// animation at the call site with `.easeInOut(duration: AppAnimation.candleBreathDuration)`
    /// and sleep the same span between toggles so each inhale/exhale fully completes.
    /// The candle breathes in, then out, then RESTS (see candleBreathHold) rather than
    /// oscillating continuously — keeps the hand calm with occasional, subtle motion.
    /// Pair the amplitude small (~1.5–2%) so the breath reads as life, not a pulse.
    /// Reduce motion: no breathing; the candle holds its static frame.
    static let candleBreathDuration: Double = 2.2

    /// 3.0s — Intermittent rest between candle breaths. After a full in/out breath the
    /// candle holds still for this long before the next, so the motion is occasional.
    static let candleBreathHold: Double = 3.0

    // MARK: — Border Effect
        // Used by VaylBorderEffect. Applied to the spectrum stroke fill and glow pop
        // on VaylButton, SelectablePill, sheets, and any bordered surface.
        //
        // Spring timing note:
        // borderFill uses a spring, not a cubic-bezier. Spring animations do not
        // have a fixed wall-clock duration — response: 0.36 is the spring's natural
        // period, not its settle time. The actual visual settle is longer (~0.52s
        // at dampingFraction: 0.9). borderFillDuration accounts for this by using
        // the observed settle time rather than the spring response value.
        // If borderFill's spring parameters change, re-measure and update
        // borderFillDuration to match the new observed settle time.
        //
        // Reduce motion fallback: borderFill → instant state change, no animation.
        // Hairline tokens are opacity-only — safe under reduce motion as-is.

        /// Observed settle duration of borderFill — used in onPressUp() to calculate
        /// how long to wait before firing the glow so it lands exactly when the arcs meet.
        /// This is NOT the spring response value. It is the wall-clock time at which
        /// the spring animation is perceptually complete (within 1pt of target).
        /// Re-measure if borderFill spring parameters change.
        static let borderFillDuration: Double = 0.30

        /// Spring — Spectrum border filling around a pill on press.
        /// Two arcs sweep from top-center down to meet at bottom-center simultaneously.
        /// response: 0.36, dampingFraction: 0.9 — snappy initial velocity, no visible
        /// bounce. The circuit-completing feel comes from the arcs arriving with
        /// confidence rather than coasting in.
        /// Reduce motion: skip animation entirely — border jumps to filled state.
        static let borderFill: Animation = .spring(response: 0.36, dampingFraction: 0.9)

        /// 0.12s ease-out — Glow bursting on the moment arcs meet at bottom-center.
        /// Short and fast — this should feel like a flash of energy completing the
        /// circuit, not a bloom or fade-in. The intensity peak is immediate.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowIn: Animation = .easeOut(duration: 0.12)

        /// 0.28s ease-in — Glow dissipating after the hold period.
        /// Ease-in communicates energy draining — the glow accelerates away from
        /// the peak rather than fading linearly. Faster than the previous 0.38s
        /// so the button feels resolved rather than lingering.
        /// Reduce motion: skip — no glow fires under reduce motion.
        static let borderGlowOut: Animation = .easeIn(duration: 0.28)

        /// How long the glow holds at full intensity before borderGlowOut begins.
        /// Not an Animation — a raw TimeInterval consumed by Task.sleep in VaylButton.
        /// 0.12s is short enough to clear before a rapid second tap, long enough
        /// to register as a deliberate energy burst rather than a flicker.
        /// Reduce motion: unused — glow sequence is skipped entirely.
        static let borderGlowHoldDuration: TimeInterval = 0.12

        /// 0.12s ease-in — Hairline retracting as border fill begins.
        /// Fast ease-in so the hairline clears before the arc strokes are visible.
        /// No visual overlap between hairline and arcs at any point in the transition.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineRetract: Animation = .easeIn(duration: 0.12)

        /// 0.35s ease-out — Hairline returning after border resets on cancel.
        /// Slower than retract — eases back in gently rather than snapping.
        /// Reduce motion: use as-is — opacity only, no spatial movement.
        static let hairlineReturn: Animation = .easeOut(duration: 0.35)

        /// 0.16s ease-in — Border retreating after a cancelled press.
        /// Ease-in signals a decisive abort — the border accelerates away from
        /// the pressed state rather than drifting back.
        /// Reduce motion: instant borderProgress = 0, no animation.
        static let borderRetract: Animation = .easeIn(duration: 0.16)
    // MARK: — Splash Screen
    // These tokens are exclusive to VaylSplashScreen.
    // They must never appear in any other screen — the cold launch ceremony
    // does not repeat as a UI pattern anywhere in the main app.
    //
    // Sequence timing (absolute offsets from cold launch):
    //   0.000s  void       — black screen, destination renders silently underneath
    //   0.250s  slit       — spectrum line aperture opens at constant velocity
    //   0.280s  bloom creep — line bloom builds from 0.35 → 0.58 over 300ms
    //   0.600s  ignition   — wordmark reveal begins, bloom spikes to 1.0
    //   0.640s  pulse      — linePulse fires 40ms after ignition (reveal leads)
    //   0.900s  hold       — bloom settles to 0.65, ambient oscillation begins
    //   1.660s  anticipate — zoom container micro-squeezes to 0.97× (40ms)
    //   1.700s  zoom       — camera crashes into line at 3.5×
    //   1.950s  tear       — panels snap apart, destination revealed
    //   2.200s  home fade  — destination opacity confirms (no animation — instant)
    //   2.400s  dismiss    — splash container removed from hierarchy
    //
    // Reduce motion fallback for all splash tokens:
    //   Skip the sequence entirely. Crossfade from void to destination at
    //   AppAnimation.standard duration. The destination must be visually
    //   complete at rest — no motion required to read it.

    /// 0.08s linear — Spectrum line aperture opening.
    /// Constant velocity communicates mechanical precision — an iris or shutter
    /// opening, not a fade. Linear is intentional and correct here.
    /// Reduce motion: skip — line appears instantly at full opacity.
    static let splashLineAppear: Animation = .linear(duration: 0.08)

    /// 0.58s easeOutExpo approximation — Wordmark reveal from light source.
    /// timingCurve (0.16, 1.0, 0.3, 1.0): high initial velocity decelerating
    /// sharply — communicates the letterforms arriving with mass from the energy
    /// of the line. Do NOT substitute .easeOut — it will feel lighter and faster.
    /// Reduce motion: skip — wordmark appears at full reveal instantly.
    static let splashReveal: Animation = .timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.58)

    /// 0.18s overshoot — Bloom energy spike at ignition.
    /// timingCurve (0.0, 0.8, 0.2, 1.2): y2 of 1.2 produces a genuine mathematical
    /// overshoot beyond the target bloom value before settling. This makes the
    /// ignition feel like a physical energy punch, not a fade-up.
    /// Reduce motion: skip — bloom appears at hold level instantly.
    static let splashBloomIgnite: Animation = .timingCurve(0.0, 0.8, 0.2, 1.2, duration: 0.18)

    /// 0.35s settle — Bloom returning to hold level after ignition overshoot.
    /// timingCurve (0.22, 1.0, 0.36, 1.0): snappy ease-out, no overshoot.
    /// Fired after splashBloomIgnite completes — bloom coasts down to resting glow.
    /// Reduce motion: not reached — reduce motion skips the ignition entirely.
    static let splashBloomSettle: Animation = .timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.35)

    /// 0.04s ease — Zoom container micro-squeeze anticipation.
    /// timingCurve (0.4, 0.0, 0.6, 1.0): scales the container to 0.97× in 40ms
    /// immediately before the zoom fires. The brief compression makes the zoom
    /// feel launched rather than switched on — physical cause before effect.
    /// Reduce motion: skip — zoom is suppressed entirely under reduce motion.
    static let splashZoomAnticipate: Animation = .timingCurve(0.4, 0.0, 0.6, 1.0, duration: 0.04)

    /// 0.38s crash — Camera zoom into the spectrum line.
    /// timingCurve (0.12, 0.9, 0.2, 1.0): acceleration-dominant curve that
    /// commits to the zoom early and arrives with confidence. The transform origin
    /// is locked to LINE_Y — the line stays fixed while everything else expands.
    /// Reduce motion: skip — zoom does not fire, sequence jumps straight to tear.
    static let splashZoom: Animation = .timingCurve(0.12, 0.9, 0.2, 1.0, duration: 0.38)

    /// 0.28s snap — Panels separating on tear.
    /// timingCurve (0.2, 0.9, 0.2, 1.0): near-instant initial velocity communicates
    /// a physical snap rather than a slide. The 20ms ramp at the start (x1=0.2)
    /// provides a one-frame buffer against dropped first frames on older hardware.
    /// Pairs with a keyframe overshoot: panels travel to H*0.74 then settle at H*0.70.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity only —
    /// panels do not move, destination crossfades in.
    static let splashTear: Animation = .timingCurve(0.2, 0.9, 0.2, 1.0, duration: 0.28)

    /// Tear overshoot distance as a ratio of panel travel distance.
    /// Panels snap to (tearDistance * splashTearOvershoot) then settle back to tearDistance.
    /// 1.056 = ~5.6% overshoot — enough to read as physical momentum, not noticeable as error.
    /// Used by the KeyframeAnimator driving panel translation. Not an Animation value.
    static let splashTearOvershoot: CGFloat = 1.056

    // MARK: — OB Card Physics
    // These tokens are exclusive to the Onboarding canvas. They must never appear
    // in main-app screens — the table metaphor does not leave the OB boundary.
    // Reduce motion fallback for all card physics tokens: .easeOut(duration: 0.15)
    // on opacity only. Card travel stops. State changes are still confirmed.

    /// 0.85s custom ease — Card travelling from deal point to table position.
    /// Cubic bezier (0, 0, 0.2, 1): accelerates instantly off the deal point,
    /// decelerates sharply into the landing position. Communicates weight and arrival.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card appears in place.
    static let cardSlide: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.85)

    /// Spring — Card settling after it lands on the table.
    /// High damping (0.92) gives a single, confident settle with no secondary bounce.
    /// Fired immediately after cardSlide completes at the destination.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — skip the physical settle.
    static let cardSettle: Animation = .spring(response: 0.55, dampingFraction: 0.92)

    /// Spring — Card sliding from table scatter position to center-screen.
    /// response: 0.72, dampingFraction: 1.0 — critically damped, zero wobble per spec.
    /// Communicates the card arriving with impossible smoothness — no physical bounce.
    /// Fired after the landing breath pause in NamePhase.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — centers without travel.
    // critically damped — zero wobble per spec. was response:0.6, dampingFraction:0.75
    static let cardCenter: Animation = .spring(response: 0.72, dampingFraction: 1.0)

    /// 0.52s custom ease — Card pocketing to the corner deck.
    /// Cubic bezier (0.4, 0, 1, 1): eases into motion then accelerates off-screen.
    /// The asymmetric exit communicates the card is being filed away, not dismissed.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — card disappears in place.
    static let cardPocket: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.52)

    /// 0.2s ease-in, delayed 0.32s — Card alpha fading out at the END of a pocket flight.
    /// Companion to cardPocket: the card stays visible for ~90% of the travel and dissolves
    /// INTO the corner deck rather than fading at launch (fading across the whole flight made
    /// it vanish in ~0.15s, so the handoff never visibly arrived). Used at every pocket site —
    /// NamePhase, DemoPhase, GenderPhase, CuriosityPhase handoff, and ThreeCardFanController.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15); the delay is dropped.
    static let pocketAlphaFade: Animation = .easeIn(duration: 0.2).delay(0.32)

    /// Spring — the ContextPhase carousel assembling up off the receding felt. A touch of
    /// overshoot (lower damping than the general `spring` 0.5/0.85) so the cards ARRIVE
    /// rather than fade in. FEEL-GATE — tuned on device.
    /// Reduce motion: guarded at the call site (only fires on the non-RM entrance path).
    static let carouselAssemble: Animation = .spring(response: 0.6, dampingFraction: 0.74)

    /// Spring — ConfirmationPhase fan dealing out of the corner deck onto the felt.
    /// Applied per-card with a staggered .delay() at the call site (rightmost deals first).
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmDeal: Animation = .spring(response: 0.46, dampingFraction: 0.84)   // FEEL-GATE: snappier, livelier deal (was 0.55 / 0.86)

    /// Spring — ConfirmationPhase fan GATHERING into the deck on confirm (the keystone
    /// "six credentials become THE deck" moment). 0.8 response so the collapse reads as a
    /// deliberate gather, not a snap. Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmGather: Animation = .spring(response: 0.8, dampingFraction: 0.85)

    /// Spring — ConfirmationPhase cards turning face-down as they gather (their truths go
    /// private on the way to the deck). Applied per-card with a staggered .delay() at the call site.
    /// Reduce motion: call site returns AppAnimation.fast instead.
    static let confirmFlip: Animation = .spring(response: 0.5, dampingFraction: 0.9)

    /// 0.36s custom ease — Curiosity sort card flung off-screen on a keep/pass commit.
    /// Cubic bezier (0.4, 0, 0.5, 1): eases off the release point then accelerates
    /// away — the card is thrown clear of the pile, not filed. Value is the locked
    /// feel reference (docs/prototypes/curiosity-swipe-prototype.html, --throw-ms).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card exits without travel.
    static let curiosityThrow: Animation = .timingCurve(0.4, 0, 0.5, 1, duration: 0.36)

    /// 0.22s custom ease — Next curiosity card rising into the top slot after a commit.
    /// Cubic bezier (0.2, 0.8, 0.2, 1): high initial velocity decelerating into place —
    /// the card snaps up crisply rather than settling with spring overshoot. Matches the
    /// locked feel reference (docs/prototypes/curiosity-swipe-prototype.html, commit()).
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card appears in place.
    static let curiosityRise: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)

    /// 0.58s custom ease — Card flipping face-up or face-down.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease creates the sense of rotation
    /// through space. Applied to scaleX: 1 → 0 (first half) then -1 → 0 (second half).
    /// The renderer swaps VaylCardBack ↔ VaylCardFace at the scaleX = 0 moment.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card face changes without rotating.
    static let cardFlip: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.58)

    /// 0.95s custom ease — Card lifting off the table toward the user.
    /// Cubic bezier (0.4, 0, 0.2, 1): gradual initial lift that carries through to the
    /// extended hold position. Elevation value drives shadow deepening simultaneously.
    /// Used for raise-and-confirm mechanic and full-bleed card expansion.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card confirms raised state instantly.
    static let cardLift: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.95)

    /// Spring — Fan of cards spreading from a deck.
    /// Lower damping (0.88) than cardSettle allows a soft overshoot as cards fan apart,
    /// reinforcing the sense of physical playing cards spreading under slight tension.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — fan state appears without travel.
    static let deckFan: Animation = .spring(response: 0.70, dampingFraction: 0.88)

    /// 0.72s ease — Deck weave shuffle (interleaving two halves).
    /// Standard ease (0.25, 0.46, 0.45, 0.94) used here because the weave is a
    /// composed sequence — each card's motion looks hand-applied, not mechanical.
    /// Applied per-card with staggered delays, not to the deck as a whole.
    /// Reduce motion: skip the shuffle sequence entirely — deck goes directly to squared state.
    static let deckWeave: Animation = .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.72)

    /// 0.65s ease-in — Foil surface dissolving after sufficient tears.
    /// Ease-in curve communicates the foil burning outward from tear edges —
    /// starts slow at the breach, accelerates as integrity collapses.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — foil disappears instantly.
    static let foilDissolve: Animation = .easeIn(duration: 0.65)

    /// 0.70s custom ease — Table surface receding during hand-raise and full-bleed phases.
    /// Cubic bezier (0.4, 0, 0.6, 1): symmetric ease so the table feels like it is
    /// physically pulling back rather than fading. Applied to tableFade in VaylDirector.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — table dims instantly.
    static let tableRecede: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.70)

    /// 0.70s ease-out — The felt blooming UP onto the table (the inverse of tableRecede).
    /// One characteristic weight for every felt fade-IN after the first arrival, so the
    /// table reads as one physical surface: ModeSelect entry, Confirmation entry, and the
    /// Context felt re-emerging after the carousel. (The very first felt arrival in Demo
    /// stays on the heavier cinematicFade — the world's debut.) FEEL-GATE.
    /// Reduce motion: via .reduceMotionSafe → .easeOut(duration: 0.15) — felt appears.
    static let tableBloom: Animation = .easeOut(duration: 0.70)

    /// 1.0s ease-in-out — OB atmosphere crossfade between phases (OnboardingAtmosphere).
    /// Slow + geological so the background shifts beneath attention, never snappy. Single
    /// owner of the config crossfade — the canvas no longer double-animates it.
    /// Reduce motion: ambient background; acceptable as-is (opacity-only crossfade).
    static let atmosphereShift: Animation = .easeInOut(duration: 1.0)

    /// Spring — Corner deck receiving a newly pocketed card.
    /// Fast response (0.40) makes the receive feel reactive to the arriving card.
    /// The glow pulse uses this same token and fades after 600ms.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — card count increments without bounce.
    static let deckReceive: Animation = .spring(response: 0.40, dampingFraction: 0.85)

    /// 0.50s ease-out — Dealer line projecting onto the felt surface.
    /// Matched to the scaleY (0.94 → 1.0) and opacity entrance of ProjectedTextView.
    /// Text must be fully legible before the phase interaction begins — do not rush this token.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — text appears without scaling.
    static let textProject: Animation = .easeOut(duration: 0.50)

    /// 3.2s ease-in-out repeating — Subtle card surface breathe on the table.
    /// Applied to the elevation/glow of a stationary card while it awaits user input.
    /// Communicates that the card is alive and waiting, not frozen.
    /// This is an ambient animation — remove entirely under reduce motion.
    /// Use .ambientAnimation(AppAnimation.cardBreathe, value:) at every call site.
    static let cardBreathe: Animation = .easeInOut(duration: 3.2).repeatForever(autoreverses: true)

    /// 0.29s per half — One half of a card flip (scaleX 1→0 or 0→-1).
    /// Two halves compose the full 0.58s cardFlip total.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let cardFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.29)

    /// 0.42s per half — Demo card 3D flip. Same cubic as cardFlipHalf (0.4,0,0.6,1)
    /// but slower — DemoPhase is the user's first flip encounter; extra weight adds ceremony.
    /// Two halves compose a full 0.84s Demo flip. Not interchangeable with cardFlipHalf.
    /// Reduce motion: skip flip entirely — face swaps without rotation.
    static let demoFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.42)

    /// 0.52s cubic — 3D edge-turn on ExperienceLevelPhase card flip.
    /// timingCurve (0.45, 0.05, 0.55, 0.95): slight ease-in gathering momentum,
    /// then easing out as the card faces the user. Not a general flip token.
    /// Reduce motion: skip the turn — face swaps instantly.
    static let cardTurn3D: Animation = .timingCurve(0.45, 0.05, 0.55, 0.95, duration: 0.52)

    // MARK: — DemoPhase Sequence
    // Tokens for the Demo "I want ___" card: sentence melt → verb cycle → seal → dissolve.
    // These are ceremony-level animations that ONLY belong in DemoPhase — do not reuse.

    /// 1.05s ease-out — "I want" sentence dissolving / melting onto the card face.
    /// Deliberately slow — the melt is the first "magic" moment the user sees.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let demoSentenceMelt: Animation = .easeOut(duration: 1.05)

    /// 0.24s ease-in-out — Verb slot-machine crossfade during the intro cycle.
    /// Short enough that the cycle feels quick and mechanical.
    /// Reduce motion: cycle is skipped entirely at call site.
    static let demoVerbCrossfade: Animation = .easeInOut(duration: 0.24)

    /// Spring — Demo card gliding to stage centre. response: 0.95, dampingFraction: 1.0 —
    /// critically damped (no oscillation), deliberately slower than cardCenter (0.72s).
    /// The demo card should feel weighty arriving at its presentation spot.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let demoCenterDeliberate: Animation = .spring(response: 0.95, dampingFraction: 1.0)

    /// 0.35s ease-in-out — Sentence fusing into the seal line (chevron + prompt resolve).
    /// Runs before the dissolve — traces the line, THEN breaks it into motes.
    /// Reduce motion: replace with AppAnimation.fast at call site.
    static let sealTrace: Animation = .easeInOut(duration: 0.35)

    /// 1.0s ease-out — Card dissolving into spectrum motes after seal.
    /// Runs concurrently with the pocket animation — motes lift off before card flies.
    /// sealBloom (0.5s) uses AppAnimation.slow (exact match) — no separate token.
    /// Reduce motion: dissolve is skipped entirely at call site.
    static let sealDissolve: Animation = .easeOut(duration: 1.0)

    /// 0.60s custom ease — Table rim burst decaying after card lands.
    /// Cubic bezier (0.2, 0.8, 0.4, 1.0). was 0.50s — corrected to spec.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let rimBurstDecay: Animation = .timingCurve(0.2, 0.8, 0.4, 1.0, duration: 0.60)

    /// 0.55s ease-in — Blur ramping in as card lifts toward the camera.
    /// Also used for tableFade during the same lift sequence.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftBlurRamp: Animation = .easeIn(duration: 0.55)

    /// 0.40s ease-in — Card screen alpha fading out at peak of lift sequence.
    /// Ease-in communicates the card accelerating away from the user's plane.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let liftCardFade: Animation = .easeIn(duration: 0.40)

    /// 0.55s ease-in — Table surface fading during the lift sequence.
    static let tableFadeOut: Animation = .easeIn(duration: 0.55)

    /// 0.45s ease-out — Card surface properties restoring after name is submitted.
    /// Scale and angle are reset instantly before this fires — only opacity
    /// and blur animate, producing a cross-fade rather than a zoom-in.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let cardRestore: Animation = .easeOut(duration: 0.45)

    /// 0.52s ease-out — Name input UI fading in after card lift sequence.
    /// Reduce motion: replaced with .linear(duration: 0.1) at call site.
    static let uiFadeIn: Animation = .easeOut(duration: 0.52)

    /// Spring — Greeting "Hi [name]" row settling into view after typing pause.
    /// response: 1.1, dampingFraction: 0.88 — slow deliberate arrival with
    /// minimal overshoot. The greeting should feel earned, not snappy.
    /// Reduce motion: replace with AppAnimation.standard at call site.
    static let greetingSettle: Animation = .spring(response: 1.1, dampingFraction: 0.88)

    /// 0.35s ease-in-out — Header text fading out/in during the crossfade
    /// sequence after the name is confirmed. Applied per-line.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let headerFade: Animation = .easeInOut(duration: 0.35)

    /// Spring — Keystroke micro-bounce on underline. High stiffness, low damping —
    /// snappy downward kick that reads as the line reacting to each character arriving.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounce: Animation = .interpolatingSpring(stiffness: 600, damping: 12)

    /// Spring — Underline returning to baseline after keystroke bounce.
    /// Lower stiffness than keystrokeBounce — the return is softer than the kick.
    /// Reduce motion: skip entirely — no bounce fires under reduce motion.
    static let keystrokeBounceReturn: Animation = .interpolatingSpring(stiffness: 400, damping: 18)

    /// 0.40s ease-out — Impact ring expanding outward after card lands on table.
    static let impactRingDecay: Animation = .easeOut(duration: 0.40)

    /// 0.35s ease-out — Radial burst fading after card flip completes.
    static let flipBurstDecay: Animation = .easeOut(duration: 0.35)

    /// 0.45s ease-out — Spectrum underline sweeping in on first field focus.
    static let lineReveal: Animation = .easeOut(duration: 0.45)

    /// 0.30s ease-in — Coach mark or hint element fading into view.
    static let coachMarkIn: Animation = .easeIn(duration: 0.30)

    /// 0.55s ease-in-out — Coach mark travelling downward during the hint sequence.
    static let coachMarkTravel: Animation = .easeInOut(duration: 0.55)

    /// 0.35s ease-out — Coach mark or hint element fading out of view.
    static let coachMarkOut: Animation = .easeOut(duration: 0.35)

    /// Spring — Screen nudging downward to hint at the swipe affordance.
    /// response: 0.45, dampingFraction: 0.62 — perceptible overshoot that
    /// communicates the screen is moveable.
    static let screenNudge: Animation = .spring(response: 0.45, dampingFraction: 0.62)

    /// Spring — Screen returning to baseline after the nudge hint.
    /// Higher damping than screenNudge — the return is settled, not bouncy.
    static let screenNudgeReturn: Animation = .spring(response: 0.55, dampingFraction: 0.78)

    /// 0.25s ease-in — Hint arrow chevron fading into view.
    static let hintArrowIn: Animation = .easeIn(duration: 0.25)

    /// 0.45s ease-out — Hint arrow chevron fading out of view.
    static let hintArrowOut: Animation = .easeOut(duration: 0.45)

    /// 0.55s ease-in-out — Name glow pulse expanding on the greeting.
    /// Applied in both directions: scale up and scale back to 1.0.
    static let glowPulse: Animation = .easeInOut(duration: 0.55)

    /// 4.0s ease-in-out — VaylFlourishView ambient breathing pulse.
    /// Apply .repeatForever(autoreverses: true) at the call site.
    /// This is an ambient animation — remove entirely under reduce motion.
    static let flourishBreath: Animation = .easeInOut(duration: 4.0)

    // MARK: — Gender Phase: Swipe Hint
    // An intermittent "swipe right" demo that runs only after the user has settled the
    // gender drum — i.e. has actively made a choice and earned the prompt. The card
    // flicks right then springs home, pauses, and repeats, modeled on how dating apps
    // demonstrate a right-swipe. No rotation: pure directional translation so it reads
    // as the swipe gesture itself, not a tilt. Stops the instant the user grabs the card
    // or re-scrolls the drum.
    // Ambient: suppressed entirely under reduce motion (guarded at the call site by
    // the View's accessibilityReduceMotion value). Settle to rest with the spring /
    // AppAnimation.standard when the hint stops.

    /// 0.26s ease-out — Card throwing right during one swipe-hint flick.
    /// Fast departure that reads as the start of a real right-swipe; paired with
    /// AppAnimation.spring for the settle back home, then a still pause before repeating.
    /// Reduce motion: never fires — the start branch is guarded by reduceMotion.
    static let swipeHintFlick: Animation = .easeOut(duration: 0.26)

    // MARK: — FounderLetterPhase
    /// 0.45s ease-in-out — The OB's final swipe-down descent ("curtain falls").
    /// Heavier than exit (0.2s easeIn) — the last gesture deserves weight.
    /// Half of the letter's own 0.4s arrival, so it mirrors rather than outdoes it.
    /// Apply .reduceMotionSafe at the call site.
    static let curtainFall: Animation = .easeInOut(duration: 0.45)

    // MARK: — Desire Map
    // Tokens for the ten-screen Desire Map flow (rater + reveal + paywall).
    // Two classes, same rules as the rest of this file:
    //   Reactive  — screen transitions, star ignitions, sheet rises, depth-push.
    //               Reduce motion fallback: .easeOut(duration: 0.15).
    //   Ambient   — sparkle cadence, hesitant line sketch, charted hold.
    //               Disable entirely under reduce motion — skip the .task / loop,
    //               hold the static state.
    //
    // Starting values tuned from the storyboard prototypes. Bryan dials final feel
    // on device — do not lock these before the device pass.

    // Reveal reactive
    /// 0.80s ease-out — Spectrum-bloom entrance wash as the rater opens.
    /// The one ceremonial entrance: the start screen recedes and Q1 emerges from depth.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireRevealBloom: Animation = .easeOut(duration: 0.80)

    /// 0.72s ease-out — Free star glow blooming in on reveal open.
    /// Fires on .onAppear of the free star; the star ignites to full then sparkles.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears lit, no bloom.
    static let desireStarIgnite: Animation = .easeOut(duration: 0.72)

    /// 0.56s overshoot — a matched star blooming from two seeds into one bright star (the merge
    /// settle). The timingCurve's y2 > 1 produces a soft overshoot past full size before it settles.
    /// Feel reference: docs/prototypes/desire-map-match-ceremony.html
    /// Reduce motion: the two-seed entrance is skipped entirely; the star renders lit.
    static let desireStarMergeSettle: Animation = .timingCurve(0.34, 1.3, 0.5, 1, duration: 0.56)

    /// 0.56s — the two seeds (your purple, their magenta) drifting together as the star ignites.
    /// Slightly less overshoot than the bloom so the points arrive cleanly into one.
    /// Reduce motion: the entrance is skipped.
    static let desireStarSeedDrift: Animation = .timingCurve(0.34, 1.2, 0.5, 1, duration: 0.56)

    /// 0.18s — the bloom starts this long after the seeds begin converging, so the star brightens
    /// as the seeds arrive rather than before. Consumed as a `.delay`. Reduce motion: unused.
    static let desireStarMergeBloomDelay: Double = 0.18

    /// 0.76s ease-out — Constellation lines drawing on at the reveal.
    /// Applied to a trimFraction (0 → 1) on the confident-mode path in ConstellationField.
    /// Reduce motion: lines appear at full opacity, no draw-on travel.
    static let desireLineDraw: Animation = .easeOut(duration: 0.76)

    /// 0.50s ease-out — Detail / full-map / paywall sheet rising from the bottom.
    /// Applied to the .move(edge: .bottom) transition inside the cover's sheet host.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — sheet appears in place.
    static let desireSheetRise: Animation = .easeOut(duration: 0.50)

    // Rater depth-push reactive
    /// 0.20s ease-in — Current question receding on answer: scale .93 + translateY 7 + fade.
    /// Fast exit clears the stage for the incoming question without lingering.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question disappears.
    static let desireDepthExit: Animation = .easeIn(duration: 0.20)

    /// 0.34s ease-out — Next question emerging from depth: scale 1.07 → 1 + fade-in.
    /// Slightly longer than exit — the arrival has more presence than the departure.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — question appears.
    static let desireDepthEnter: Animation = .easeOut(duration: 0.34)

    /// 0.56s ease-out — Answer star rising into the personal sky above.
    /// Synced to fire alongside desireDepthExit so the star lifts as the question recedes.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — star appears in sky position.
    static let desireStarRise: Animation = .easeOut(duration: 0.56)

    // Finish-beat reactive
    /// 0.35s ease-out — Last question and answer rows fading out at completion.
    /// Clears the stage for the finish-flair star rise.
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireFinishFade: Animation = .easeOut(duration: 0.35)

    /// 0.80s ease-out — Last star rising with extra ignite + sparkle burst on completion.
    /// Brighter and slower than a normal desireStarRise — the climactic beat of rating.
    /// Reduce motion: replace with .easeOut(duration: 0.15) — final star appears lit.
    static let desireFinishFlair: Animation = .easeOut(duration: 0.80)

    /// 0.60s ease-out — "Your map is charted." copy + hesitant constellation lines fading in.
    /// Fired after the finish-flair star settles, not immediately after the last rate().
    /// Reduce motion: replace with .easeOut(duration: 0.15).
    static let desireChartedFadeIn: Animation = .easeOut(duration: 0.60)

    // Desire Map ambient (raw Double — not Animation instances)
    // All three: disable the .task / loop entirely when reduce motion is active.
    // The static state (a resting cross + glow, faint partial lines) must read without motion.

    /// 0.95s — Total duration of one sparkle keyframe (scale 0→1→0.55, opacity 0→1→0, slight rotation).
    /// Not an Animation — consumed by KeyframeAnimator total. Divide across CubicKeyframe tracks at the call site.
    /// Reduce motion: skip the .task trigger entirely; sparkle never fires.
    static let desireSparkleDuration: Double = 0.95

    /// 3.5s — Mean cadence for free/active star sparkle.
    /// Randomize ±55–160% at the call site (.task sleeps desireSparkleFreeRate * factor)
    /// so stars twinkle out of phase rather than in sync.
    /// Reduce motion: .task is never started.
    static let desireSparkleFreeRate: Double = 3.5

    /// 7.0s — Mean cadence for locked/dim star sparkle.
    /// Same randomize recipe as desireSparkleFreeRate; locked stars twinkle rarely.
    /// Reduce motion: .task is never started.
    static let desireSparkleLockedRate: Double = 7.0

    /// 2.0s — Hold at the charted screen before auto-advancing (tap-anywhere skips).
    /// Not an Animation — consumed by Task.sleep at the call site.
    /// Reduce motion: use as-is; the hold is timing, not motion.
    static let desireChartedHold: Double = 2.0

    /// 4.2s — One full pass of the hesitant constellation line sketch loop.
    /// Lines draw partway, pull back, fade, and restart — never locking.
    /// Not an Animation — consumed by a repeating loop at the call site.
    /// Reduce motion: loop never starts; lines hold at a faint partial-draw static state.
    static let desireHesitantSketch: Double = 4.2

    // Reveal 3-beat ceremony holds (raw Double — consumed by Task.sleep in DesireRevealStore).
    // Reduce motion: collapse both holds to ~0 so the reveal resolves instantly (no timed ceremony).

    /// 1.5s — Beat 1 → Beat 2: the free star settles before the locked gap appears.
    static let desireBeatHold1: Double = 1.5

    /// 1.2s — Beat 2 → Beat 3: the gap holds before the paywall rises.
    static let desireBeatHold2: Double = 1.2

    /// 0.08s — Per-locked-row stagger step (added per locked match before the Beat-2 hold begins).
    static let desireBeatStaggerStep: Double = 0.08

    /// 0.14s — Base offset before the locked-row stagger (the first row's lead-in).
    static let desireBeatStaggerBase: Double = 0.14

    /// 0.36s — A single locked teaser row fading/staggering into the gap (Beat 2).
    /// Reduce motion: falls back via `.reduceMotionSafe` to a fast opacity confirm.
    static let desireLockedRowEnter: Animation = .easeOut(duration: 0.36)

    // Reveal ceremony — the telegraphed constellation assembly (DesireConstellationView).
    // Stars light in the variant's order with a budgeted stagger; lines draw when both ends are
    // lit; a telegraph wind-up precedes. Reduce motion: skip to the static lit sky (no assembly).

    /// 1.4s — total budget to light all non-hero stars; per-star stagger = budget / count (clamped),
    /// so many stars do not drag.
    static let desireCeremonyBudget: Double = 1.4
    /// 0.5s — gap after the hero ignites before the rest begin (Gather).
    static let desireCeremonyHeroLead: Double = 0.5
    /// Per-star stagger clamps during the assembly.
    static let desireCeremonyStaggerMin: Double = 0.09
    static let desireCeremonyStaggerMax: Double = 0.30
    /// 1.7s — the Sweep band's full pass across the field; stars light as it reaches them.
    static let desireSweepDuration: Double = 1.7
    /// Linear sweep of the telegraph band across the field.
    static let desireSweepBand: Animation = .linear(duration: desireSweepDuration)
    /// 0.64s ease-in — the Gather telegraph contracting a point of light to center before the hero.
    static let desireGatherPulse: Animation = .easeIn(duration: 0.64)
    /// 0.5s — how long the Gather wind-up holds before the hero forms. Consumed by Task.sleep.
    static let desireGatherLead: Double = 0.5

    // Vayl mark ceremony — the one-shot "map charted" moment (MapChartedMoment).
    // Reduce motion: skip both; the mark is shown fully drawn and the copy is shown at once.

    /// 1.0s — The aperture draws/assembles on: rings trim in, glow blooms, core ignites.
    static let markDraw: Animation = .easeOut(duration: 1.0)

    /// 0.5s — The copy fades up after the mark has mostly assembled.
    static let markCopyRise: Animation = .easeOut(duration: 0.5)

    /// 0.9s — How long the copy waits for the mark to draw before rising (a `.delay`).
    static let markCopyDelay: Double = 0.9

    /// 2.8s — Hold after the copy resolves before the moment auto-advances back to Home.
    /// Reduce motion: measured from appear (no draw lead). Consumed by Task.sleep.
    static let markHold: Double = 2.8

    // MARK: — Pulse Aura
    // Ambient durations for PulseAura (raw Doubles — construct with .easeInOut at call site).
    // All three are ambient: guard with `!reduceMotion` in PulseAura; never fire under reduce motion.
    // FEEL: all values tuned on device against docs/prototypes/pulse-aura-glass.html.

    /// 5.4s — Aura body breathe (scale 1 ↔ 1.045, autoreverses). FEEL: tune on device.
    static let auraBreathe: Double = 5.4

    /// 7.0s — Caustic drift, one leg (offsets alternate, autoreverses). FEEL: tune on device.
    static let auraCausticDrift: Double = 7.0

    /// 8.5s — Glass sweep full non-reversing cycle. Mockup parity: the glint crosses the
    /// circle about every 8.5s (map-pulse-final.html @keyframes sweep / .od note).
    /// Was 17.0s; halved to match the mockup cadence. FEEL: confirm on device.
    static let auraGlassSweep: Double = 8.5

    /// The check-in ball's position-change shift (Q1-Q5 drift). Plain eased interpolation,
    /// NOT a spring — even a critically-damped spring still has a fast-snap-then-settle
    /// character; this reads as a smooth, even slide to the new point instead.
    /// 🎚️ FEEL: confirm on device.
    static let pulseBallDrift: Animation = .easeInOut(duration: 0.32)

    /// Uncharted resolution — the field (zone blobs, ghost labels, axis labels) fades to
    /// opacity 0 when the variance check fires after the final answer. 🎚️ FEEL: tune on device.
    static let pulseUnchartedFieldFade: Animation = .easeInOut(duration: 1.2)

    /// Uncharted resolution — the orb colour dissolves from its bilinear colour to Sage Deep,
    /// slightly slower than the field fade so colour lands last. 🎚️ FEEL: tune on device.
    static let pulseUnchartedColorDissolve: Animation = .easeInOut(duration: 1.5)

    /// Uncharted orb drift — slow, non-repeating-pattern wander around centre; replaces the
    /// bloom ring as the "landed" signal. Raw duration: construct .easeInOut(duration:).repeatForever
    /// at the call site. 🎚️ FEEL: amplitude + timing tuned on device.
    static let pulseUnchartedDrift: Double = 6.0

    /// History-grid border-state dots — one shared TimelineView drives all border dots'
    /// gentle two-colour LEAN at this cadence (per-dot phase offset by index). Slow on purpose:
    /// a border dot is a blend that drifts, never a flash. Raw seconds used in the sin() phase
    /// term, not an Animation. 🎚️ FEEL: tune on device.
    static let pulseHistoryBorderCadence: Double = 4.5

    // MARK: — Tab Navigation
    // Tokens for the tab bar orb snap-and-halo and tab content gravity drift.
    // Both are reactive (user-initiated tap). Reduce motion: easeOut(0.15), suppress offsets at call site.

    /// Spring — Tab bar orb snapping to new selection. response: 0.40, dampingFraction: 0.62
    /// overshoots ~15% past target then springs back, communicating physical momentum.
    /// Also drives the halo burst scale at the landing icon.
    /// Reduce motion: replace with AppAnimation.fast — orb jumps to position without travel.
    /// DEPRECATED by the motion system: `orbGlide` replaces this (the overshoot read as
    /// disconnected from the staple grammar — feel-rejected 2026-07-03). Delete this token
    /// when RacetrackTabBar migrates (motion spec §7 step 2); do not adopt in new code.
    static let orbSnap: Animation = .spring(response: 0.40, dampingFraction: 0.62)

    /// 0.25s ease-out — Tab content gravitational drift on tab switch.
    /// Incoming view drifts 14pt in from the direction of navigation, decelerating to rest.
    /// Outgoing view fades in place (no counter-drift — avoids direction-mismatch on removal).
    /// Reduce motion: call site should suppress the offset and cross-fade only.
    static let tabSwitch: Animation = .easeOut(duration: 0.25)

    // MARK: — Motion System (Staples & Registers)
    // The app-wide motion grammar. Spec: docs/superpowers/specs/2026-07-03-motion-system-design.md
    // Feel reference: docs/prototypes/motion-system-staples.html (all values tuned there;
    // device-feel-gated — starting points until Bryan's device pass confirms).
    //
    // Three staples × two registers:
    //   Staple 1 — Depth Handoff   (screen-level change: settle from depth, recede into it)
    //   Staple 2 — Weighted Arrival (objects entering: sheets, covers, cards)
    //   Staple 3 — Charged Tap      (input: the borderFill grammar — shared register, see
    //                                VaylBorderEffect; its tokens live in the Border Effect
    //                                section above)
    //   Loud  = OB + protected covers. Quiet = everything else.
    //
    // Appliers (transitions/modifiers with Reduce Motion built in) live in AppMotion.swift —
    // the AppGlows pattern: values here, thin stateless applications there.
    //
    // QUIET-TIER CEILINGS (hard caps, cite in review): scale delta ≤ quietMaxScaleDelta,
    // travel ≤ quietMaxTravel, duration ≤ 0.55s. Ceremony-class motion (multi-second builds,
    // dealer motifs) is BANNED outside the OB canvas and .vaylCover contents.

    /// 0.26s ease-out — Staple 1, Quiet register: main-app screen/content swaps.
    /// Incoming settles 1.01 → 1, outgoing recedes 1 → 0.985, opacity cross-fade. Never a slide.
    /// Reduce motion: AppMotion's applier collapses to pure opacity.
    static let depthQuiet: Animation = .easeOut(duration: 0.26)

    /// Staple 1 scale amplitudes. Quiet pair obeys quietMaxScaleDelta; Loud pair is the OB
    /// phaseHandoff (promoted from OnboardingCanvasView literals — same values, now tokens).
    /// Loud duration = AppAnimation.slow (the OB step-transition token), unchanged.
    static let depthQuietScaleIn:  CGFloat = 1.01
    static let depthQuietScaleOut: CGFloat = 0.985
    static let depthLoudScaleIn:   CGFloat = 1.02
    static let depthLoudScaleOut:  CGFloat = 0.97

    /// 0.50s ease-out — Staple 2, Quiet: a .vaylSheet rising, settling, and dismissing.
    /// One confident glide home, zero bounce. Device-feel-gated to easeOut/0.50 (Bryan's
    /// pass 2026-07-04, preferred over the earlier 0.42 deal-curve for the workhorse sheet);
    /// now wired into `.vaylSheet` (VaylPresentation). Shares its curve with desireSheetRise.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity — sheet appears in place.
    static let arrive: Animation = .easeOut(duration: 0.50)

    /// 0.55s deal-curve — Staple 2, Loud: a .vaylCover entering the table world. Same curve as
    /// `arrive`, heavier. The register shift IS the threshold cue into a protected mode.
    /// Reduce motion: replace with .easeOut(duration: 0.15) on opacity.
    static let arriveCover: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.55)

    /// 0.18s — Cover CONTENT settles from depth (Staple 1 nested in Staple 2) this long after
    /// the cover container starts rising. Consumed as a .delay on the content's settle.
    /// Reduce motion: unused — content appears with the cover.
    static let arriveCoverContentLag: Double = 0.18

    /// 0.38s glide — Tab bar orb drifting to the new selection: soft gather, long decelerating
    /// tail, ZERO overshoot — cubic (0.3, 0, 0.15, 1), the arrival-curve family, so the orb
    /// speaks the same physics as the sheets and the depth handoff. Replaces orbSnap (the
    /// spring overshoot was feel-rejected as disconnected). The halo burst re-times to this
    /// glide's landing, not a spring peak.
    /// Reduce motion: replace with AppAnimation.fast — orb jumps without travel.
    static let orbGlide: Animation = .timingCurve(0.3, 0, 0.15, 1, duration: 0.38)

    /// 0.52s long-tail drift — One row of a FIRST-ARRIVAL cascade: cubic (0.25, 0.1, 0.15, 1),
    /// soft start, slow bleed into rest. Rows overlap ~85% via cascadeStagger so the list reads
    /// as ONE wave travelling down, not per-row pops. Deliberately slower than `enter`: the
    /// cascade is the entrance for the whole list, not per-element decoration.
    /// LAW: only the first data arrival cascades — refreshes fade, never cascade.
    /// Reduce motion: all rows appear together with a single 0.2s fade (AppMotion applier).
    static let cascadeRow: Animation = .timingCurve(0.25, 0.1, 0.15, 1, duration: 0.52)

    /// 75ms — Per-row cascade stagger. The overlap ratio is what sells the wave: tighten the
    /// stagger for a quicker wave, lengthen cascadeRow for a dreamier one — duration alone
    /// does not fix abruptness.
    static let cascadeStagger: Double = 0.075

    /// 6 — Cascade row cap. Rows past the cap arrive together WITH the last capped row, so a
    /// long list never turns the entrance into a parade.
    static let cascadeCap: Int = 6

    /// 14pt — Cascade row rise distance (obeys quietMaxTravel).
    static let cascadeRise: CGFloat = 14

    /// 0.28s / ±3pt — Staple 3's "no": a refused (disabled/invalid) commit shivers laterally;
    /// the border arcs never fill. Pair with .sensoryFeedback(.impact(.medium)) at the call
    /// site — the haptic is half the refusal.
    /// Reduce motion: no shiver; the haptic still fires (haptics are not motion).
    static let refusalDuration:  Double  = 0.28
    static let refusalAmplitude: CGFloat = 3

    /// 0.10s — Commit dismissal: a task-completing sheet's exit launches this long after the
    /// commit glow's PEAK (glow peaks at borderGlowIn 0.12s → exit begins 0.22s after release,
    /// riding the glow's decay out). Cancels (grabber, scrim, Cancel) exit plain on `exit` —
    /// no charge ever built. Feel-locked at 100ms in the reference (60 buried the glow,
    /// 160 read as the app admiring its own button).
    static let commitDismissLag: Double = 0.10

    /// Quiet-register amplitude ceilings — hard caps, not guidelines. A quiet-tier animation
    /// scaling by more than this delta or travelling further than this is a violation; reach
    /// for a Loud token only inside the OB canvas or .vaylCover contents.
    static let quietMaxScaleDelta: Double  = 0.02
    static let quietMaxTravel:     CGFloat = 16

    // MARK: — OB Ceremony Tokens (tokenized from raw call-site values, 2026-07-03)
    // Values moved VERBATIM from OB files during the motion-token migration — the token
    // contract ("zero raw values") now holds inside the OB too. All are Loud-register,
    // OB-only. Do not re-tune here without a device feel pass; do not reuse in main-app code.

    /// Spring — the name-entry write line kicking down as a character lands (NamePhase).
    /// Softer than keystrokeBounce (600/12): the line reacts, the key does the snapping.
    /// Reduce motion: skip — no bounce fires under reduce motion.
    static let writeLineBounce: Animation = .interpolatingSpring(stiffness: 320, damping: 16)

    /// Spring — the Demo noun field pulsing back after input is cleaned/capped (DemoPhase).
    /// Reduce motion: acceptable as-is — a 6pt settle, confirmation not travel.
    static let demoFieldPulse: Animation = .interpolatingSpring(stiffness: 320, damping: 14)

    /// 0.7s ease-out — the Name card being SET DOWN by the dealer (fades in a hair high +
    /// large, settles to rest). Not a deal: no flight, no slide. FEEL-GATE origin value.
    /// Reduce motion: skipped at call site — card appears at rest.
    static let cardSetDown: Animation = .easeOut(duration: 0.7)

    /// 0.22s ease-in — the Curiosity DEMO card gliding partway off during the dealer's
    /// keep/pass demonstration (not the user's own throw — that's curiosityThrow).
    /// Reduce motion: the demo sequence is skipped entirely at the call site.
    static let curiosityDemoSwipe: Animation = .easeIn(duration: 0.22)

    /// 0.42s ease-out — the monte fan OPENING into a ribbon spread before the turnover
    /// (ExperienceLevelPhase). FEEL-GATE origin value.
    /// Reduce motion: the spread sequence never runs (reveal() path).
    static let fanSpreadOpen: Animation = .easeOut(duration: 0.42)

    /// 0.42s ease-in-out — the spread RE-COLLECTING to the resting fan after the turnover.
    /// Symmetric ease: the close mirrors the open. Reduce motion: never runs.
    static let fanRecollect: Animation = .easeInOut(duration: 0.42)

    /// 0.88s deal-curve — the ModeSelect mirror deal: both cards travelling simultaneously
    /// from opposite screen edges, weighted deceleration (cubic 0,0,0.2,1 — the arrival
    /// family at its heaviest travel).
    /// Reduce motion: call path is guarded upstream by the phase's RM branch.
    static let mirrorDealTravel: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.88)

    /// 0.22s per half — the REJECTED mirror card turning face-down on confirm. Same cubic
    /// as cardFlipHalf (0.4, 0, 0.6, 1) but faster (0.22 vs 0.29): the discard turn is an
    /// aside, not a reveal. Two halves compose the 0.44s reject flip.
    static let mirrorRejectFlipHalf: Animation = .timingCurve(0.4, 0, 0.6, 1, duration: 0.22)

    /// 0.42s — the rejected card sliding back toward its origin and fading. Same
    /// ease-into-motion-then-accelerate-away cubic as cardPocket (0.4, 0, 1, 1), shorter:
    /// the discard leaves, it is not filed.
    static let mirrorRejectExit: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.42)

    // — BuildDeck forge ceremony (Beats 1–7). All Loud-register, ceremony-class:
    //   these tokens must NEVER appear outside BuildDeckPhase / the OB canvas.

    /// Spring pair — the stage JOLT on a case strike: hard kick in (0.12/0.5), settle (0.32/0.7).
    static let strikeJolt:       Animation = .spring(response: 0.12, dampingFraction: 0.5)
    static let strikeJoltSettle: Animation = .spring(response: 0.32, dampingFraction: 0.7)

    /// Spring — the case yawing back to rest after a directional strike recoil.
    static let strikeRecoilReturn: Animation = .spring(response: 0.3, dampingFraction: 0.55)

    /// Spring — the case settling after an autonomous knock twitch (the deck wants out).
    /// Lower damping than strikeRecoilReturn: the knock wobbles, the strike is commanded.
    static let knockReturn: Animation = .spring(response: 0.35, dampingFraction: 0.5)

    /// Spring pair — the stage jolt on the SHATTER (third strike): heavier than a strike
    /// (0.18/0.6 in, 0.4/0.7 settle) — the climax lands harder than its wind-up.
    static let shatterJolt:       Animation = .spring(response: 0.18, dampingFraction: 0.6)
    static let shatterJoltSettle: Animation = .spring(response: 0.4, dampingFraction: 0.7)

    /// 0.5s ease-out — the white flash decaying after the case bursts.
    static let burstFlashDecay: Animation = .easeOut(duration: 0.5)

    /// 0.34s ease-in — the revealed deck (cards + title + CTA) sinking away on hand-off
    /// to the founder letter. FEEL-GATE origin value.
    static let deckExitSink: Animation = .easeIn(duration: 0.34)

    /// 0.5s ease-in-out — the founder letter sheet rising bottom → full. FEEL-GATE origin.
    static let letterRise: Animation = .easeInOut(duration: 0.5)

    /// 2.6s ease-in — the credential deck MELTING down through the felt (Beat 1).
    /// Ceremony-class duration: the forge's slowest, heaviest move.
    static let deckMeltDown: Animation = .easeIn(duration: 2.6)

    /// 1.0s ease-out — the forged case fading in on the felt (Beat 3a).
    static let caseFadeIn: Animation = .easeOut(duration: 1.0)

    /// 2.0s ease-in-out — the standing case taking the air and scaling up (Beat 3c dolly).
    static let caseFloatLift: Animation = .easeInOut(duration: 2.0)

    /// 1.4s ease-out — the table's rim + sway settling to rest as the felt lets the case go.
    static let forgeSettle: Animation = .easeOut(duration: 1.4)

    /// 1.2s ease-in-out — the case core lighting up once armed (contained energy).
    static let coreCharge: Animation = .easeInOut(duration: 1.2)

    /// 0.9s / 1.3s — one leg of the forge's rim-glow and topo-sway oscillations (Beat 1–2,
    /// "the table works"). Raw Doubles per the ambient-duration convention: build at the
    /// call site with .easeInOut(duration:) + .repeatForever(autoreverses: true).
    /// Reduce motion: the oscillation never starts (steady mid glow, still lines).
    static let forgeRimOscillation:  Double = 0.9
    static let forgeSwayOscillation: Double = 1.3
}

// MARK: — Ambient Motion Gate (Reduce Motion + Low Power Mode)

extension AppAnimation {

    /// True while the device is in Low Power Mode. Decorative ambient loops are exactly
    /// the discretionary GPU/CPU cost Low Power Mode exists to cut, so ambient motion
    /// treats it the same way it treats Reduce Motion: the loop is removed, the static
    /// state must read complete. Reactive animations are NOT gated on this — user
    /// feedback always plays.
    static var lowPower: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// The one question every ambient loop asks before starting: Reduce Motion
    /// (accessibility) OR Low Power Mode (battery). Read at body-evaluation time,
    /// same semantics as the Reduce Motion check — a mid-session toggle takes
    /// effect the next time the view re-evaluates or re-appears.
    /// Call sites that already hold `@Environment(\.accessibilityReduceMotion)`
    /// should guard with `reduceMotion || AppAnimation.lowPower` so the RM half
    /// keeps its live environment reactivity.
    static var ambientMotionDisabled: Bool {
        UIAccessibility.isReduceMotionEnabled || lowPower
    }
}

// MARK: — Reduce Motion Helpers

extension Animation {

    /// Returns the reduce-motion safe version of a reactive animation.
    /// Replaces spatial movement with a fast opacity confirmation.
    /// Uses UIAccessibility directly — safe to call outside of a View context.
    /// Use at every call site where the animation drives positional change.
    ///
    /// Example:
    ///   withAnimation(.standard.reduceMotionSafe) { ... }
    var reduceMotionSafe: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .easeOut(duration: 0.15)
        }
        return self
    }
}

extension View {

    /// Conditionally applies an ambient animation only when reduce motion is not active.
    /// Gated on `value` via the standard `.animation(_:value:)` modifier — this ONLY
    /// (re-)triggers when `value` itself changes (e.g. the one-time false→true flip an
    /// `.onAppear` typically does to kick off a `.repeatForever()` loop). Once running,
    /// an unrelated re-render elsewhere in the app does not restart it.
    ///
    /// The previous implementation used `.transaction { transaction.animation = animation }`,
    /// which is unconditional — it reapplies the ambient animation to EVERY transaction that
    /// flows through the view, for ANY reason, regardless of whether `value` changed. On a
    /// screen with frequent nearby `withAnimation(...)` calls (e.g. the Pulse check-in firing
    /// one on every pill tap), that repeatedly forced the aura's already-looping
    /// breathe/caustic/sweep layers to reset mid-cycle — visible as the orb "not staying
    /// static between answer selections" even when its position genuinely hadn't changed.
    ///
    /// Example:
    ///   myGlowView
    ///       .ambientAnimation(.easeInOut(duration: AppAnimation.ambientPulse).repeatForever(),
    ///                         value: isAnimating)
    func ambientAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(AppAnimation.ambientMotionDisabled ? nil : animation, value: value)
    }
}

```

---

## File: `Vayl/App/Theme/AppLayout.swift` {#file-vayl-app-theme-applayout-swift}

```swift
//
//  AppLayout.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


//
//  AppLayout.swift
//  Vayl
//
//  Design System — Phase 2.1
//
//  AppLayout resolves real screen geometry from a GeometryProxy and exposes
//  derived layout values used throughout the app. This is the single source
//  of truth for screen dimensions, device-class breakpoints, and safe area insets.
//
//  Usage — at the root of any screen-level view:
//
//      GeometryReader { geo in
//          let layout = AppLayout.from(geo)
//          YourView(layout: layout)
//      }
//
//  Rules:
//  - UIScreen.main.bounds is banned. Always use AppLayout.from(geometry).
//  - Never hardcode width, height, or safe-area offsets for layout purposes.
//  - Never hardcode .padding(.top, 60) or .padding(.bottom, 34) to clear
//    hardware elements — use layout.safeAreaInsets.top / .bottom instead.
//  - cardWidth, fullWidth, and contentMaxWidth are the only permitted width
//    values in layout code. Never derive your own from screenWidth directly.
//  - isSmallDevice and isLargeDevice drive conditional layout — never branch
//    on hardcoded point values in views.

import SwiftUI

struct AppLayout {

    // MARK: - Screen Dimensions

    /// Full screen width resolved from GeometryProxy. Never hardcode this value.
    let screenWidth: CGFloat

    /// Full screen height resolved from GeometryProxy. Never hardcode this value.
    let screenHeight: CGFloat

    // MARK: - Safe Area Insets

    /// Safe area insets resolved from GeometryProxy.
    /// Accounts for the Dynamic Island, notch, status bar, and home indicator
    /// on every device without hardcoding any pixel values.
    ///
    /// - `safeAreaInsets.top`    — clears the Dynamic Island, notch, or status bar.
    /// - `safeAreaInsets.bottom` — clears the home indicator on notchless devices.
    ///
    /// Use these wherever the violation catalogue shows .top, 60 or .bottom, 100
    /// or .bottom, 34 used as hardware-clearance proxies.
    let safeAreaInsets: EdgeInsets

    // MARK: - Device Class

    /// True for iPhone SE and iPhone mini form factors — screen width at or below 375pt.
    /// Use to apply compact layout adjustments, never to gate features.
    let isSmallDevice: Bool

    /// True for iPhone Pro Max and Plus form factors — screen width at or above 428pt.
    /// Use to apply expanded layout where additional breathing room is available.
    let isLargeDevice: Bool

    // MARK: - Derived Layout Values

    /// Standard content width with symmetric horizontal margins.
    /// Equal to screenWidth minus two AppSpacing.lg margins (24pt each side).
    /// Use for cards, form fields, and single-column content blocks.
    var cardWidth: CGFloat {
        screenWidth - (AppSpacing.lg * 2)
    }

    /// Full bleed width — equal to screenWidth.
    /// Use only for backgrounds, hero imagery, and tab bars that span edge to edge.
    /// All interactive content must remain within cardWidth or contentMaxWidth.
    var fullWidth: CGFloat {
        screenWidth
    }

    /// Maximum content width for readability on large screens.
    /// Clamps at 460pt so that text and form content never becomes uncomfortably
    /// wide on Pro Max devices. Use for body text containers and form layouts.
    var contentMaxWidth: CGFloat {
        min(screenWidth - (AppSpacing.lg * 2), 460)
    }

    // MARK: - Tab Bar

    /// Height of the visible UITabBar, read from the key window at call time.
    /// Returns 0 when no tab bar is present (onboarding, sheets, modals).
    /// Use with .bottomClearance(_:includesTabBar:) — do not read this value directly in views.
    var tabBarHeight: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.rootViewController?
            .view.subviews
            .first(where: { $0 is UITabBar })?
            .frame.height ?? 0
    }

    // MARK: - Factory

    /// Resolves an AppLayout from a GeometryProxy.
    /// Call this once at the root of a screen-level view and pass the result down.
    /// Never call UIScreen.main.bounds — this is the only permitted resolution path.
    static func from(_ geometry: GeometryProxy) -> AppLayout {
        let width = geometry.size.width
        return AppLayout(
            screenWidth:    width,
            screenHeight:   geometry.size.height,
            safeAreaInsets: geometry.safeAreaInsets,
            isSmallDevice:  width <= 375,
            isLargeDevice:  width >= 428
        )
    }

    // MARK: - Standard Screen Spacing
    // Referenced by the Screen Building Protocol and used across all main-app screens.
    // Do not override these values per-screen — if a screen needs more breathing room,
    // the layout design should be revisited, not the tokens.

    /// 18pt — Horizontal padding from screen edge to content.
    /// Applied to the outer ScrollView or VStack container of every screen.
    static let screenHPad: CGFloat = 18

    /// 24pt — Horizontal margin applied to the OB canvas content column.
    /// Wider than screenHPad (18pt) — the OB canvas uses a more spacious
    /// margin appropriate for cinematic phase layouts.
    static let screenMargin: CGFloat = 24

    /// 32pt — Horizontal inset for the primary CTA on OB screens.
    /// Intentionally wider than screenMargin so the CTA button sits visually
    /// inside the content column rather than spanning edge-to-edge.
    static let ctaHorizontalMargin: CGFloat = 32

    /// 20pt — Vertical padding at the top of every screen's scroll content.
    /// Provides breathing room below the header before the first card.
    static let screenVPad: CGFloat = 20

    /// 16pt — Horizontal padding inside a card, from card edge to card content.
    static let cardHPad: CGFloat = 16

    /// 14pt — Vertical padding inside a card, from card edge to card content.
    static let cardVPad: CGFloat = 14

    /// 10pt — Vertical gap between adjacent cards in a list or stack.
    static let cardGap: CGFloat = 10

    /// 24pt — Vertical gap between distinct sections on a screen.
    static let sectionGap: CGFloat = 24

    /// 13pt — Horizontal gap between an icon and its accompanying label in a row.
    static let rowGap: CGFloat = 13

    // MARK: - Standard Component Sizing

    /// 52pt — Height of a primary CTA button.
    static let ctaHeight: CGFloat = 52

    /// 32pt — Height of a filter pill or selection pill.
    static let pillHeight: CGFloat = 32

    /// 14pt — Horizontal padding inside a pill, from pill edge to label.
    static let pillHPad: CGFloat = 14

    /// 30pt — Tap area size for a ghost icon button (icon-only, no label).
    /// The visible icon may be smaller — this is the minimum hit target.
    static let iconBtnSize: CGFloat = 30

    /// 36pt — Width of the drag handle on a bottom sheet.
    static let dragHandleW: CGFloat = 36

    /// 4pt — Height of the drag handle on a bottom sheet.
    static let dragHandleH: CGFloat = 4

    /// 300pt — Maximum width of the expandable citation panel in StatPhase.
    /// Constrains the dense citation copy to a readable measure regardless of
    /// screen width. Matches the visual design at standard iPhone widths.
    static let citationPanelMaxWidth: CGFloat = 300

    // MARK: - OB Card Geometry
    // These values are exclusive to the Onboarding canvas.
    // They must never appear in main-app screens — the table metaphor
    // does not leave the OB boundary.
    //
    // All functions take screenWidth as a parameter because OB card geometry
    // is a function of screen width, not a fixed constant. Pass geo.size.width
    // from the GeometryReader in OnboardingCanvasView.

    /// Width of a full-size OB vertical card.
    /// Clamps at 320pt to preserve card proportions on Pro Max devices.
    /// Vertical cards are OB/personal only. Horizontal cards are session/shared.
    static func obCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.72, 320)
    }

    /// Height of a full-size OB vertical card.
    /// Derived from obCardWidth at a fixed 3:2 portrait aspect ratio (×1.5).
    static func obCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obCardWidth(in: screenWidth) * 1.5
    }
    /// Width of a card sitting on the OB table during the deal sequence.
    /// ~30% of screen width — small enough to read as a physical card on a surface.
    /// Distinct from obCardWidth (72%) which is used for the full-bleed expanded state.
    /// Never use obTableCardWidth for any state other than the on-table resting position.
    static func obTableCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.30, 195)
    }

    /// Height of the on-table card. Derived from obTableCardWidth at 3:2 portrait ratio.
    static func obTableCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obTableCardWidth(in: screenWidth) * 1.5
    }

    /// Width of a card in the ExperienceLevel fanned hand. Larger than the on-table
    /// row card because the fan cards overlap — the overlap absorbs the extra width.
    static func obFanCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.42, 280)
    }

    /// Height of a fan card. Derived at the 3:2 portrait ratio.
    static func obFanCardHeight(in screenWidth: CGFloat) -> CGFloat {
        obFanCardWidth(in: screenWidth) * 1.5
    }

    /// Per-slot (offset-from-center, angle-degrees) for the three fanned-hand cards.
    /// Slot 0 = left, 1 = center (upright, on top), 2 = right. Offsets are relative to
    /// screen center; the caller adds the fan center Y (`obTableCardCenterY`).
    static func monteFanLayout(in containerWidth: CGFloat) -> [(offset: CGSize, angle: Double)] {
        let fanW = obFanCardWidth(in: containerWidth)
        let fanH = obFanCardHeight(in: containerWidth)
        let dx   = fanW * 0.58     // horizontal spread — wider so the outer cards peek out more
        let rise = fanH * 0.05     // outer cards lift slightly (held-hand arc)
        let tilt = 17.0            // outer-card fan angle (deg) — steeper = more spread
        return [
            (CGSize(width: -dx, height: -rise), -tilt),
            (CGSize(width:   0, height:     0),    0),
            (CGSize(width:  dx, height: -rise),  tilt),
        ]
    }

    /// Cinematic zoom applied to the on-table card during the NamePhase deal sequence.
    /// Scales `obTableCardWidth` from 30% to ~45% of screen width, matching the HTML
    /// prototype's visual proportion (195px card in a 430px max-width container).
    /// Only NamePhase applies this. Do not use in other table card contexts.
    static let obTableCardCinematicScale: CGFloat = 1.5

    /// Width of a session card (horizontal orientation).
    /// Clamps at 480pt. Used in the main app session flow, never in OB.
    static func sessionCardWidth(in screenWidth: CGFloat) -> CGFloat {
        min(screenWidth * 0.88, 480)
    }

    /// Height of a session card (horizontal orientation).
    /// Derived from sessionCardWidth at a fixed aspect ratio (×0.708).
    static func sessionCardHeight(in screenWidth: CGFloat) -> CGFloat {
        sessionCardWidth(in: screenWidth) * 0.708
    }

    // MARK: - OB Corner Deck Geometry
    // The corner deck occupies the top-right corner of OnboardingCanvasView
    // from NamePhase onward. These constants define its frame and position.
    // The top-right ✦ mark is replaced by the corner deck — never overlap them.

    /// 48pt — Width of the corner deck mini-card stack.
    static let cornerDeckWidth:  CGFloat = 48

    /// 72pt — Height of the corner deck mini-card stack.
    static let cornerDeckHeight: CGFloat = 72

    /// 56pt — Distance from the top safe-area edge to the top of the corner deck.
    /// Sits just below the Dynamic Island with breathing room.
    /// Bump to 64 or 72 if it still reads too high on device.
    static let cornerDeckTop:    CGFloat = 56

    /// 24pt — Distance from the right screen edge to the right of the corner deck.
    static let cornerDeckRight:  CGFloat = 24

    // MARK: - OB Gender Card Rest Position

    /// 0.52 — Vertical position of the gender card's rest state as a fraction of screen height.
    /// Card is placed HERE from frame 0 during the dissolution sequence — it never moves.
    /// Used by VaylDirector (restY calculation) and GenderPhase (bloom layer center Y).
    static let obGenderCardRestYFrac: CGFloat = 0.52

    // MARK: - OB Deal Point Geometry
    // The deal point is the origin from which all OB cards are launched.
    // Its position is derived from screen dimensions at render time —
    // these are the constants that define its appearance and vertical anchor.

    /// 22pt — Radius of the deal point glow ring.
    /// The center dot and outer haze scale from this value in DealPointView.
    static let dealPointRadius:  CGFloat = 22

    /// 0.32 — Vertical position of the deal point as a fraction of screen height.
    /// The deal point sits at the horizon where the felt meets the void.
    /// This fraction is shared with tableHorizonYFrac — they are the same anchor.
    static let dealPointYFrac:   CGFloat = 0.32

    // MARK: - OB Table Geometry

    /// 0.32 — Vertical position of the table horizon line as a fraction of screen height.
    /// The felt trapezoid's top edge, the deal point, and the projected text anchor
    /// all derive from this single fraction. Change this value to reposition the
    /// entire table world simultaneously.
    static let tableHorizonYFrac: CGFloat = 0.32

    /// 0.13 — Dealer-line anchor while the forged case floats (BuildDeck Beat 4).
    /// At 2× zoom the case occupies the horizon band where projected text normally
    /// lives — a line at tableHorizonYFrac would type invisibly behind it. This
    /// anchor projects the line into the clear air above the case.
    static let forgeFloatTextYFrac: CGFloat = 0.13

    /// 0.34 — Arc peak Y fraction for the circular table surface.
    /// Matches the HTML reference prototype where the table edge sits at H*0.34,
    /// giving the "zoomed in on the table" perspective the user wants.
    /// Distinct from tableHorizonYFrac (0.32) which is the trapezoid horizon.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcPeakYFrac: CGFloat = 0.34

    /// 1.05 — Table circle radius as a fraction of screen height.
    /// Large radius ensures only the top cap of the circle is visible.
    /// Used by TableSurfaceView arc geometry only.
    static let tableArcRadiusFrac: CGFloat = 1.05

    // MARK: - OB Card Landing Slots
    // Five predefined landing configurations for the OB deal sequence.
    // Cards pick from the available pool so no two cards in the same round
    // share a landing zone. Slots are defined in screen-fraction space so
    // they adapt to any device size.

    static let obCardLandingSlots: [CardLandingSlot] = [

        // Slot 0 — Center settle: classic deal, card rests just right of center
        CardLandingSlot(
            id: 0,
            xFrac: 0.50, yFrac: 0.535,
            angleDeg:  1.8,
            jitterX: 12, jitterY: 8, jitterAngle: 1.0
        ),

        // Slot 1 — Left lean: card drifts wide left, slight CCW tilt
        CardLandingSlot(
            id: 1,
            xFrac: 0.30, yFrac: 0.61,
            angleDeg: -6.0,
            jitterX: 12, jitterY: 8, jitterAngle: 1.5
        ),

        // Slot 2 — Deep slide: card overshoots toward the player, steep CW,
        // bottom third of card clips off-screen
        CardLandingSlot(
            id: 2,
            xFrac: 0.52, yFrac: 0.74,
            angleDeg:  13.0,
            jitterX: 14, jitterY: 10, jitterAngle: 2.0
        ),

        // Slot 3 — Hard right: card cuts right, steep CCW, right edge off-screen
        CardLandingSlot(
            id: 3,
            xFrac: 0.80, yFrac: 0.64,
            angleDeg: -19.0,
            jitterX: 12, jitterY: 8, jitterAngle: 2.0
        ),

        // Slot 4 — Bottom-left diagonal: card curves lower-left, partially off-screen
        CardLandingSlot(
            id: 4,
            xFrac: 0.24, yFrac: 0.70,
            angleDeg: -11.0,
            jitterX: 12, jitterY: 10, jitterAngle: 2.5
        ),
    ]

    /// Returns the Y coordinate of the optical center of the felt table surface.
    /// Derived from tableArcPeakYFrac — the fraction where the spectrum rim arc peaks.
    /// The table surface runs from that point to the bottom of the screen.
    /// Card center is the midpoint of that zone.
    /// Use this for every card resting position in the OB sequence.
    /// Never hardcode 0.55 or any raw Y fraction for card positioning.
    static func obTableCardCenterY(in screenHeight: CGFloat) -> CGFloat {
        let arcPeakY    = screenHeight * tableArcPeakYFrac
        let tableHeight = screenHeight - arcPeakY
        return arcPeakY + (tableHeight * 0.50)
    }

    // MARK: - OB NamePhase Layout Tokens
    // Exclusive to NamePhase. Never use in main-app screens.

    /// 80pt — Height of the swipe-to-submit zone above the name input field.
    static let swipeZoneHeight: CGFloat = 80

    /// 80pt — Translation threshold for a swipe-down to register as a submit gesture.
    static let swipeSubmitThreshold: CGFloat = 80

    /// 1.2 — Multiplier applied to screen height for the dragY exit translation on submit.
    /// Ensures the UI travels well past the screen bottom before disappearing.
    static let dragExitMultiplier: CGFloat = 1.2

    /// 30 — Maximum character count for a user-entered display name.
    static let maxNameLength: Int = 30

    /// 28pt — Blur radius applied to the card during the lift-toward-camera sequence.
    static let cardLiftBlurRadius: CGFloat = 28.0

    /// 4.5 — Scale multiplier for the card diving toward the camera during performLift.
    /// At 4.5× the card exceeds the screen width — the lens is inside the surface.
    static let cardLiftDiveMultiplier: CGFloat = 4.5

    /// 0.5pt — Letter-spacing applied to the user's name in the greeting display.
    static let nameLetterSpacing: CGFloat = 0.5

    // MARK: - StatPhase Hero Numeral
    // Exclusive to the StatPhase "1 in 5" hero. Never use elsewhere.

    /// Responsive point size for the holographic stat hero numeral.
    /// Lives here (not as inline literals in StatPhase) so the hero scales by the
    /// same geometry rules as every other OB element. Three steps, by usable height
    /// and width: short devices (SE) shrink to 100pt to clear the cascade; tall wide
    /// devices (Pro Max) grow to 164pt; the common case sits at 140pt. Dynamic Type
    /// still scales the result via AppFonts.statHero's relativeTo: .largeTitle anchor.
    static func statHeroSize(usableHeight: CGFloat, screenWidth: CGFloat) -> CGFloat {
        if usableHeight <= 700 { return 100 }
        return screenWidth > 390 ? 164 : 140
    }

    // MARK: - OB Flourish Geometry
    // Exclusive to VaylFlourishView. Never use in main-app screens.

    /// 280pt — Width of the VaylFlourishView decorative component.
    static let flourishWidth: CGFloat = 280

    /// 72pt — Height of the VaylFlourishView decorative component.
    static let flourishHeight: CGFloat = 72

    /// 1.015 — Scale factor for the ambient breathing pulse on VaylFlourishView.
    static let flourishPulseScale: CGFloat = 1.015

    /// Visible position offset for the greeting row. Negative = moves up.
    /// Proportional to screen height for correct positioning across device sizes.
    static func greetingOffsetVisible(in screenHeight: CGFloat) -> CGFloat {
        -(screenHeight * 0.07)
    }

    /// Hidden/resting position offset for the greeting row.
    static func greetingOffsetHidden(in screenHeight: CGFloat) -> CGFloat {
        screenHeight * 0.017
    }
}

```

---

## File: `Vayl/App/Theme/AppRadius.swift` {#file-vayl-app-theme-appradius-swift}

```swift
//
//  AppRadius.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//


// App/Theme/AppRadius.swift

import CoreGraphics

/// Tier 2 — Semantic corner radius tokens.
/// Every `.cornerRadius()`, `.clipShape()`, or `RoundedRectangle(cornerRadius:)` call
/// in the codebase must reference one of these tokens.
/// Hardcoded numeric values in any corner radius context are a violation.
/// Nothing in this file may reference VaylPrimitives — radius has no primitive tier.
///
/// Grid note: Radius tokens use a 4pt grid. This is intentional and independent
/// of the 8pt spacing grid — radius granularity requirements are finer than spacing
/// requirements. The two grids do not need to be unified.
internal enum AppRadius {

    /// 2pt — Drag handle pills and fine decorative dividers.
    /// Use for drag handle capsules, hairline divider end-caps, and sub-pixel decorative rounding.
    /// Never use for interactive elements, cards, or any tappable surface.
    static let micro: CGFloat = 2

    /// 8pt — Small interactive chips, tags, and badge labels.
    /// Use for pills that display metadata (counts, status tags) and small category chips.
    /// Never use for primary buttons, cards, or any surface larger than a label container.
    static let sm: CGFloat = 8

    /// 12pt — Input fields and secondary buttons.
    /// Use for text input containers, secondary action buttons, and segmented control backgrounds.
    /// Never use for primary CTAs, cards, or modal surfaces.
    static let md: CGFloat = 12

    /// 16pt — Cards and primary action buttons.
    /// Use for all content cards regardless of elevation level, and for the HoloCTAButton.
    /// Never use for modals, sheets, or surfaces larger than a card.
    static let lg: CGFloat = 16

    /// 24pt — Modals, sheets, and large overlay surfaces.
    /// Use for bottom sheets, full-screen overlays presented over content, and large surface containers.
    /// Never use for cards or buttons — this radius is reserved for surfaces that sit above cards.
    static let xl: CGFloat = 24

    /// 20pt — Onboarding cards, home widgets, and pairing surfaces.
    /// Use for the dominant off-grid card radius seen across onboarding and home feature surfaces.
    /// Distinct from lg (16pt cards) and xl (24pt modals) — sits between them for hero containers.
    static let container: CGFloat = 20

    /// Infinity — Fully rounded capsule shape.
    /// Use for selectable pills, toggle tracks, and any element that must render as a perfect capsule.
    /// SwiftUI mathematically clamps .infinity to perfectly round the shortest edge.
    /// Never use for cards, buttons, inputs, or any rectangular surface.
    static let pill: CGFloat = .infinity

    /// 57pt — Native-style presented sheet corners for Dynamic Island devices.
    /// Apple's native bottom sheets on modern Pro devices (iPhone 14/15 Pro) use
    /// a much larger continuous corner radius of ~55pt to match the hardware corners.
    /// Because VaylSheetChrome applies a 2pt bleed (pushing the shape off-screen),
    /// we increase this to 57pt. This ensures exactly 55pt of the curve is
    /// visible on-screen.
    static let sheet: CGFloat = 57

    // MARK: - OB Card Radii
    // These tokens are exclusive to the Onboarding canvas and its card components.
    // They must never appear in main-app screens — the table metaphor does not
    // leave the OB boundary.

    /// 14pt — Full-size OB vertical card.
    /// Applied to VaylCardBack, VaylCardFace, and VaylCardRenderer frame clips.
    /// Distinct from lg (16pt) — the slightly tighter radius reads as a playing card,
    /// not a UI card. Do not substitute lg here.
    /// Vertical cards are OB/personal only. This token never appears on session cards.
    static let obCard: CGFloat = 14

    /// 4pt — Corner deck mini-card stack.
    /// Applied to the scaled-down card representations in CornerDeckView.
    /// At the rendered scale of the corner deck (~22% of full card size), 4pt
    /// produces the correct visual proportion of the obCard radius.
    /// Never use for full-size cards.
    static let cornerCard: CGFloat = 4

    /// 16pt — Foil wrapper overlay in BuildDeckPhase.
    /// Applied to FoilRenderer as it wraps the assembled deck.
    /// Matches lg intentionally — the foil sits over the deck surface and its
    /// edge radius must align with the card stack beneath it.
    static let foilEdge: CGFloat = 16
}

```

---


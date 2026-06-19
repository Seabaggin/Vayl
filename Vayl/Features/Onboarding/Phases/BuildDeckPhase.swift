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
///   Beat 5 · crack ceremony — three strikes, escalating light + haptics,
///            third → bloom-flood shatter (taps forward to director.addFoilTear)
///   Beat 7 · founder letter sheet-peek exit (interim: after the shatter, or as
///            an idle fallback — replaced by the reveal carousel in segment 7)
///
/// Timing values below are raw on purpose — feel-tuning per the Build Protocol;
/// they become AppAnimation tokens once verified on device.
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

    // crack ceremony (Beat 5) — taps forward to director.addFoilTear
    @State private var caseArmed:    Bool = false   // invitation landed; taps live
    @State private var caseDissolve: Date = .distantFuture  // third crack → shatter
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

            // Beat 3 — the cased deck: lies flat and lifeless where the cards
            // went under, lifts to vertical, then the camera dollies in; the
            // hex material wakes only after the zoom lands.
            // Beat 5 — once the invitation arms it, taps crack the foil:
            // the view forwards face-UV strikes to the director (sole owner of
            // crack state); the dealer's words are the affordance.
            if caseShown {
                MetallicCaseView(
                    riseStart: caseRiseStart,
                    latticeWakeStart: latticeWake,
                    tears: director.foilTears.map {
                        CaseTear(id: $0.id, faceUV: $0.faceUV, seed: $0.seed,
                                 struck: $0.struck, angleDeg: $0.angleDeg)
                    },
                    dissolveStart: caseDissolve,
                    onFaceTap: caseArmed && caseDissolve == .distantFuture
                        ? { uv in director.addFoilTear(atFaceUV: uv) }
                        : nil,
                    knockStart: knockStart,
                    knockSeed: knockSeed
                )
                    .frame(width: deckSize.width, height: deckSize.height)
                    .rotation3DEffect(.degrees(kickDeg),
                                      axis: (x: kickAxis.x, y: kickAxis.y, z: 0),
                                      perspective: 0.5)
                    .scaleEffect(caseFloat ? floatZoom : 1.0)
                    .position(caseFloat ? floatCenter : feltCenter)
                    .opacity(caseOpacity)
                    .accessibilityLabel("Your sealed deck")
                    .accessibilityHint(caseArmed ? "Tap three times to break it open" : "")
                    .accessibilityAddTraits(caseArmed ? .isButton : [])
            }

            // Beat 6 — out of the bloom, the forged deck. Browse freely.
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
        .scaleEffect(stagePunch ? 1.03 : 1.0)   // the whole stage jolts at the burst
        .sensoryFeedback(.impact(weight: .medium), trigger: meltDone)   // the deck goes under
        .sensoryFeedback(.impact(weight: .heavy),  trigger: caseFloat)  // the case takes the air
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: knockCount)
        // crack ceremony — strikes escalate light, medium, heavy (the ritual arc)
        .sensoryFeedback(trigger: director.foilTears.count) { old, new in
            guard new > old else { return nil }
            switch new {
            case 1:  return .impact(weight: .light,  intensity: 0.8)
            case 2:  return .impact(weight: .medium, intensity: 0.9)
            default: return .impact(weight: .heavy,  intensity: 1.0)
            }
        }
        .onChange(of: director.foilTears.count) { _, count in
            guard count > 0, let strike = director.foilTears.last?.faceUV else { return }
            // If the idle peek already rose and the user then commits to the
            // ritual, retract it — the knock-cued strike wins. Two exit
            // affordances must not coexist (and the peek's low edge could
            // otherwise intercept a strike tap near the bottom of the case).
            if count == 1, peekShown, caseDissolve == .distantFuture {
                withAnimation(AppAnimation.fast.reduceMotionSafe) { peekShown = false }
            }
            // every strike hits harder — the ritual escalates
            recoil(from: strike, degrees: 2.6 + 0.9 * Double(count - 1))
            spawnSparks(at: strike, count: 12 + 8 * (count - 1))
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).reduceMotionSafe) {
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
                  director.foilTears.isEmpty,
                  caseDissolve == .distantFuture {
                try? await Task.sleep(for: .seconds(3.5))
                guard director.foilTears.isEmpty, caseDissolve == .distantFuture else { break }
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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).reduceMotionSafe) {
                kickDeg = 0
            }
        }
    }

    /// Third crack — the case view runs OVERLOAD (0.45s: every crack flares
    /// white, the drift freezes, the held breath) then the FLOOD: the room
    /// shakes (screen flash + stage punch) and celebration sparks ride the
    /// light out. The letter peek is the interim landing until the reveal
    /// (segment 7).
    private func beginShatter() {
        guard caseDissolve == .distantFuture else { return }
        caseDissolve = .now
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.45))   // overload holds
            if !reduceMotion {
                burstFlashOpacity = 0.65
                withAnimation(.easeOut(duration: 0.5)) { burstFlashOpacity = 0 }
                withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { stagePunch = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(160))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { stagePunch = false }
                }
            }
            spawnSparks(at: CGPoint(x: 0.5, y: 0.5), count: 34, style: .burst)
            // Retire the spark field once the celebration motes age out, so its
            // TimelineView(.animation) stops redrawing through the user-paced reveal.
            sparksClearTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(SparkBurst.lifespan))
                sparkBursts = []
            }
            // The flood resolves INTO the deck — object continuity, no void.
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 1.3))   // FEEL-GATE: tune on device
            withAnimation(AppAnimation.enter.reduceMotionSafe) { revealShown = true }
            // the deck lands first; the exit CTA fades in a beat later
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.2))   // FEEL-GATE: tune on device
            withAnimation(AppAnimation.enter.reduceMotionSafe) { ctaShown = true }
        }
    }

    /// CTA exit — the deck is the user's to keep, so a TAP (not a swipe) hands
    /// off. The founder letter auto-rises from the bottom to full, then advances
    /// behind the covering sheet (the curtain). User-paced: only fires on tap.
    private func presentLetter() {
        guard !revealExiting, !sheetExpanded else { return }
        // Beat 1 — the deck exits: cards + title + CTA fade out and sink.
        withAnimation(.easeIn(duration: 0.34).reduceMotionSafe) { revealExiting = true }   // FEEL-GATE
        Task { @MainActor in
            // Beat 2 — tightly behind it, the founder letter rises from the
            // bottom to full. The gap is short (slight overlap with Beat 1's
            // fade) so the two beats read as one smooth handoff, not a stutter.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 220))   // FEEL-GATE: the 1→2 gap
            peekShown = true
            try? await Task.sleep(for: .milliseconds(20))   // one frame at the bottom edge so the rise has a "from"
            withAnimation(.easeInOut(duration: 0.5).reduceMotionSafe) {          // FEEL-GATE: the rise
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
            // settle — the deck just arrived from confirmation; let it sit
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.8))
            // Holds are computed from type time (the `…` now costs a real beat
            // since the ellipsis cadence fix — a fixed hideAfter clipped the
            // hold to ~0.4s). Line holds ~0.6s, then is GONE ~0.4s before the
            // melt — the deck's exit gets full attention, no text competing.
            let line1 = "From everything you've shown me…"
            let t1 = Double(AppDealerTyping.typeDuration(line1)) / 1000.0
            director.showDealerLine(line1, hideAfter: t1 + 0.6)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : t1 + 1.0))

            // Beat 1 — the deck melts down through the felt; the table's rim
            // begins its working oscillation (the table is the performer)
            withAnimation(.easeIn(duration: 2.6).reduceMotionSafe) { deckMelt = 1 }
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
            director.showDealerLine(line2, hideAfter: t2 + 0.6)
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : t2 + 1.0))

            // Beat 3a — the cased deck lies flat where the cards went under —
            // no animation, no life yet (rise pending, lattice asleep)
            caseShown = true
            withAnimation(.easeOut(duration: 1.0).reduceMotionSafe) { caseOpacity = 1 }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.8))

            // Beat 3b — the lift: face-on flat → the standing ¾ box (pose
            // driver in the case view). The table stays put for the whole rise —
            // flat → pause → stand → THEN the felt lets go (user-confirmed order).
            caseRiseStart = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.0))

            // Beat 3c — the rise has landed: the camera dollies in, the case
            // takes the air and scales up WHILE the felt recedes beneath it
            // (zoom, not growth); the rim settles as the table lets it go
            withAnimation(.easeInOut(duration: 2.0).reduceMotionSafe) { caseFloat = true }
            director.recedeTableForForge()
            withAnimation(.easeOut(duration: 1.4).reduceMotionSafe) {
                tableRimBurst = 0
                tableForgeEnergy = 0
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 1.0))

            // …and the hex material wakes upon zoom-in. Hold past the 1.2s wake
            // so the lattice finishes powering on before the invitation types.
            latticeWake = .now
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.3))

            // Beat 4 — stillness already passed; the invitation. Projected ABOVE
            // the floating case — at 2× zoom the case covers the horizon anchor
            // and the line would type invisibly behind it.
            let invite = "This one's yours. Break it open."
            let inviteMs = AppDealerTyping.typeDuration(invite)
            director.showDealerLine(invite, hideAfter: Double(inviteMs) / 1000.0 + 2.0,
                                    anchorYFrac: AppLayout.forgeFloatTextYFrac)

            // Arm WITH the words landing, not as they start — a fast tap mustn't
            // strike the case mid-sentence (the motion peak shouldn't preempt the
            // line that summons it).
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : inviteMs + 250))
            caseArmed = true
            startKnocking()   // the deck inside wants out
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
        if reduceMotion {
            tableRimBurst = 0.3
        } else {
            // 0.8 ceiling — the work has to survive phone scale; at 0.55 the
            // oscillation read as dead air in the recording, not a performance
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                tableRimBurst = 0.8
            }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
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

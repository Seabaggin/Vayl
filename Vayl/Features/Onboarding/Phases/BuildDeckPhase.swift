//
//  BuildDeckPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Build Deck (renders OBPhase.buildDeck).
/// The forge ceremony, per the 2026-06-10 ceremony spec + the Living Case
/// rework (2026-07-04):
///   Beat 1 · the confirmed deck MELTS down through the felt (their truths go
///            under the table)
///   Beat 2 · the TABLE performs — its spectrum rim oscillates while it works
///   Beat 3 · the cased deck lies FLAT and lifeless, lifts to vertical, the
///            camera dollies in, and the hex material wakes on arrival
///   Beat 4 · stillness, dealer invitation — the case ARMS
///   Beat 5 · the LIVING CASE tap ceremony — the case is actively holding the
///            deck in, and the three taps are a negotiation:
///            tap 1 RECOGNITION — the case flinches, a card tears up through
///                  the lattice, the seams strain, then it reseals (case wins)
///            tap 2 RESISTANCE — bigger recoil, two cards, slower reseal
///            tap 3 RELEASE — maximum shudder, the seams stay open, the HELD
///                  BREATH (~380ms, everything freezes, the case brightens),
///                  then the FLOWER PEEL: the lattice peels centre-out like
///                  petals opening, uncovering the deck already standing behind
///   Beat 6 · the reveal sequence on a FIXED STAGE (nothing reflows):
///            breath (the freed deck inhales/exhales once, no UI) → name rises
///            → the fan blooms face-down → flip wave left-to-right → carousel
///            + the exit CTA
///   Beat 7 · founder letter sheet-peek exit
///
/// Timing values are AppAnimation tokens (OB Ceremony Tokens section). Re-tune
/// the tokens directly after a device feel pass — never by re-introducing raw
/// values here.
struct BuildDeckPhase: View {

    let director: VaylDirector
    let screenSize: CGSize
    /// The table's spectrum rim — phases drive it (NamePhase/GenderPhase
    /// pattern). During the forge it oscillates: the TABLE is the performer.
    @Binding var tableRimBurst: Double
    /// Topo-line sway — the felt's contour lines breathe while the table works.
    @Binding var tableForgeEnergy: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // sequence state
    @State private var started: Bool = false
    // Long-lived task handles — cancelled on disappear so the knock loop, the beat
    // sequences, and the spark-field retirement never outlive the phase.
    @State private var sequenceTask: Task<Void, Never>?
    @State private var knockTask: Task<Void, Never>?
    @State private var sparksClearTask: Task<Void, Never>?
    @State private var deckShown: Bool = true
    @State private var deckMelt: Double = 0       // 0 intact → 1 fully under the felt
    @State private var meltDone: Bool = false     // haptic trigger
    @State private var caseShown: Bool = false
    @State private var caseOpacity: Double = 0      // dissolve-up reveal
    // .distantFuture = mounted lying FLAT, lifeless — the lift is assigned later.
    // (nil would mean "full float pose" and causes the double-rise bug.)
    @State private var caseRiseStart: Date? = .distantFuture
    @State private var latticeWake: Date = .distantFuture  // hex wakes AFTER the zoom
    @State private var caseFloat: Bool = false     // felt → float position

    // Living Case tap ceremony (Beat 5) — state lives in director.ceremony
    // (tapCount / eruptStart / holdBreath); the view owns only the physical read.
    @State private var caseArmed: Bool = false   // invitation landed; taps live
    @State private var caseDissolve: Date = .distantFuture  // third tap → flower peel
    // Segment 2 — the charged core: the deck's energy contained inside the shell.
    @State private var coreEnergy: Double = 0
    // damped-oscillation shake — the case recoiling with MASS (per-frame task)
    @State private var shakeOffset: CGSize = .zero
    @State private var shakeTask: Task<Void, Never>?
    // directional micro-yaw — the knock twitch + a small kick riding each shake
    @State private var kickDeg: Double = 0
    @State private var kickAxis: (x: CGFloat, y: CGFloat) = (0, 1)
    // reseal haptics — the lattice closing over the card after taps 1–2
    @State private var resealCount: Int = 0
    @State private var resealTask: Task<Void, Never>?
    // the held breath — the case brightens, nothing moves (third tap). The date
    // also feeds MetallicCaseView so the float drift damps to dead-still.
    @State private var holdBreathVisual: Bool = false
    @State private var breathHoldStart: Date = .distantFuture
    @State private var peelStarted: Bool = false   // .success haptic trigger
    // spectrum motes venting as the peel opens
    @State private var sparkBursts: [SparkBurst] = []
    // the knock from inside — anticipation while armed and untouched
    @State private var knockStart: Date = .distantFuture
    @State private var knockSeed: UInt64 = 0
    @State private var knockCount: Int = 0

    // founder letter sheet-peek (Beat 7)
    @State private var peekShown: Bool = false
    @State private var sheetExpanded: Bool = false
    @State private var peekPressed: Bool = false
    @State private var sheetDrag: CGFloat = 0
    private let peekHeight: CGFloat = 100   // shows the grabber + "A note from the founder" with presence

    // Beat 6 — the reveal sequence, on a FIXED STAGE anchored to floatCenter:
    // the case and the reveal occupy the same position, nothing reflows.
    // breath → name → fan → flip wave → carousel → CTA. User-paced exit.
    @State private var revealTask: Task<Void, Never>?
    @State private var deckStanding: Bool = false           // fan cards mounted behind the shell
    @State private var deckOpacity: Double = 0             // uncovered through the opening centre
    @State private var deckRise: CGFloat = 8            // small settle-down as it's freed
    @State private var glowPulse: Double = 0             // released energy → the breath
    @State private var nameShown: Bool = false           // Beat 6b — named AFTER it stands alone
    @State private var fanned: Bool = false           // Beat 6c — the bloom
    @State private var flipDegrees: [Double] = Array(repeating: 180, count: 6)
    @State private var faceUp: [Bool]   = Array(repeating: false, count: 6)
    @State private var flipIndex: Int = -1               // .selection haptic trigger
    @State private var inCarousel: Bool = false           // Beat 6e
    @State private var revealExiting: Bool = false          // the deck sinks on hand-off
    @State private var ctaShown: Bool = false           // "Take your deck"
    @State private var revealPhysics = CarouselPhysics(count: 6)   // every opener deck (Resources/Decks/opener-*.json) has 6 cards
    /// The real catalog deck for this user's assigned opener type — no more
    /// placeholder copy. Falls back to opener-steady (always bundled), then to
    /// an empty-but-valid literal if even that somehow fails to decode.
    private var welcomeDeck: Deck {
        if let real = try? ContentLoader.loadDeck(id: director.openerDeckType.welcomeDeckId) {
            return real
        }
        if let fallback = try? ContentLoader.loadDeck(id: "opener-steady") {
            return fallback
        }
        return Deck(id: "opener-steady", title: "Steady", subtitle: "Start slow. Find your footing.",
                    category: .foundationEntry, act: 1, intensity: .void, isLocked: false,
                    requiredEntitlement: nil, tags: [], sortOrder: 0, schemaVersion: 2, cards: [])
    }

    // Mirrors ConfirmationPhase.cardWidth(in:) — the deck arrives at FAN-card
    // scale (the collapse never grows the cards). The size change to the hero
    // case happens as a camera zoom during the float, not object growth.
    private var deckW: CGFloat { min(screenSize.width * 0.32, 230) }
    private var deckSize: CGSize { CGSize(width: deckW, height: deckW * 1.5) }

    /// Camera dolly-in during Beat 3c: the case scales up WHILE the felt
    /// recedes beneath it — object-up + background-away reads as the camera
    /// moving closer, never as the object inflating. Feel-tunable.
    private let floatZoom: CGFloat = 2.0
    private var feltCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: AppLayout.obTableCardCenterY(in: screenSize.height)) }
    private var floatCenter: CGPoint { CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.42) }

    // Beat 6c fan geometry — mockup values scaled to card width (mockup card 88pt).
    private let fanAngles: [Double]  = [-22, -13, -4, 4, 13, 22]
    private let fanOffsetFracs: [CGFloat] = [-0.91, -0.55, -0.18, 0.18, 0.55, 0.91]

    var body: some View {
        ZStack {
            // No background — the persistent canvas (void + atmosphere + FELT) shows through.

            // Beat 1 — the confirmed deck, melting down through the felt.
            if deckShown {
                VaylDeckStack(size: deckSize)
                    .modifier(MeltThroughFelt(progress: deckMelt, size: deckSize))
                    .position(feltCenter)
            }

            // Beat 6 — the reveal stage. Mounted BEHIND the shell (earlier in
            // this ZStack) the moment the peel starts, so the case peels away
            // FROM the deck — object continuity, no cross-fade, no void.
            if deckStanding {
                revealStage
                    // Beat 7 hand-off — the deck exits: fade out + a small sink.
                    .opacity(revealExiting ? 0 : 1)
                    .offset(y: revealExiting ? AppSpacing.xl : 0)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Your \(welcomeDeck.title) deck")
                    .accessibilityHint("Swipe left or right to browse your cards.")

                // The exit — a bottom CTA. The deck is the user's to keep, so a
                // TAP (not a hand-it-back swipe) presents the founder letter.
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

            // Beat 3 — the cased deck. Beat 5 — the Living Case: once armed,
            // taps land ANYWHERE on it (the sequence is fixed, no authored
            // strike zones); the ceremony store escalates eruption + stress +
            // wake rings, and the view reads them straight through.
            if caseShown {
                MetallicCaseView(
                    riseStart: caseRiseStart,
                    latticeWakeStart: latticeWake,
                    dissolveStart: caseDissolve,
                    onFaceTap: caseArmed && caseDissolve == .distantFuture
                        ? { uv in strike(at: uv) }
                        : nil,
                    knockStart: knockStart,
                    knockSeed: knockSeed,
                    coreGlow: coreEnergy,
                    peelMode: true,
                    // No card-punch-through-the-shell visual on taps — the reveal
                    // stays inside the case (wake rings + seam stress + breathing)
                    // until the peel; a card popping out mid-tap read as a separate,
                    // competing gesture rather than the shell itself coming alive.
                    // director.ceremony.eruptStart is still tracked (gates the
                    // knock-anticipation pause window below) — only the view's
                    // erupting-card draw is disabled here.
                    eruptStart: .distantFuture,
                    eruptTapIndex: 0,
                    seamStress: director.ceremony.stressLevel,
                    seamStressFloor: director.ceremony.stressFloor,
                    strainPulse: director.ceremony.strainPulse,
                    breathHoldStart: breathHoldStart,
                    wakeRings: director.ceremony.tapCount
                )
                    .frame(width: deckSize.width, height: deckSize.height)
                    .rotation3DEffect(.degrees(kickDeg),
                                      axis: (x: kickAxis.x, y: kickAxis.y, z: 0),
                                      perspective: 0.5)
                    .offset(shakeOffset)
                    // the held breath — the case brightens + saturates, nothing moves
                    .brightness(holdBreathVisual ? 0.12 : 0)
                    .saturation(holdBreathVisual ? 1.5 : 1)
                    .scaleEffect(caseFloat ? floatZoom : 1.0)
                    .position(caseFloat ? floatCenter : feltCenter)
                    .opacity(caseOpacity)
                    .accessibilityLabel("Your sealed deck")
                    .accessibilityHint(caseArmed ? "Tap three times to let it out" : "")
                    .accessibilityAddTraits(caseArmed ? .isButton : [])
            }

            // motes venting as the peel opens — float free in screen space
            if !sparkBursts.isEmpty {
                SpectrumSparkField(bursts: sparkBursts)
                    .frame(width: screenSize.width, height: screenSize.height)
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
        .sensoryFeedback(.impact(weight: .medium), trigger: meltDone)   // the deck goes under
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: caseFloat)  // the case takes the air — a seal, not the safe-word tier
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: knockCount)
        // the three strikes — light 0.8, medium 0.9, rigid 1.0 (the negotiation arc).
        // `.heavy` is reserved app-wide for the safe-word only — a tap-to-open
        // release must never carry that same weight.
        .sensoryFeedback(trigger: director.ceremony.tapCount) { old, new in
            guard new > old else { return nil }
            switch new {
            case 1:  return .impact(weight: .light, intensity: 0.8)
            case 2:  return .impact(weight: .medium, intensity: 0.9)
            default: return .impact(flexibility: .rigid, intensity: 1.0)
            }
        }
        // the reseal — a softer confirmation as the lattice closes over the card
        .sensoryFeedback(trigger: resealCount) { old, new in
            guard new > old else { return nil }
            return .impact(weight: .light, intensity: new == 1 ? 0.4 : 0.5)
        }
        .sensoryFeedback(.success, trigger: peelStarted)   // the release
        .sensoryFeedback(.selection, trigger: flipIndex)   // the flip wave, card by card
        .accessibilityLabel("Build deck phase")
        .onAppear {
            guard !started else { return }
            started = true
            runSequence()
        }
        .onDisappear {
            sequenceTask?.cancel()
            knockTask?.cancel()
            shakeTask?.cancel()
            resealTask?.cancel()
            revealTask?.cancel()
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

    // MARK: - Beat 6: the reveal stage (fixed — nothing reflows)

    /// The freed deck + name + fan + carousel, all absolutely positioned at
    /// floatCenter — the same anchor the case occupied. No layout shift, no
    /// camera-pan feeling, when the shell unmounts and the reveal takes over.
    @ViewBuilder
    private var revealStage: some View {
        ZStack {
            // the released energy — glows behind the deck, then breathes (Beat 6a)
            Ellipse()
                .fill(RadialGradient(
                    colors: [AppColors.spectrumPurple.opacity(0.55),
                             AppColors.spectrumCyan.opacity(0.18),
                             .clear],
                    center: .center, startRadius: 0, endRadius: deckSize.width))
                .frame(width: deckSize.width * 2.2, height: deckSize.height * 1.4)
                .opacity(glowPulse * 0.7)   // glow breathes 0 → 0.7, never to full white-out
                .allowsHitTesting(false)

            // the cards — stacked → fan → flip wave; crossfades to the carousel
            if inCarousel {
                VaylCardCarousel(
                    count: welcomeDeck.cards.count,
                    cardSize: deckSize,
                    physics: revealPhysics,
                    content: { index, isFront in
                        let c = welcomeDeck.cards[index]
                        VaylCardFace(
                            // ContextCardFace only renders number + title (subtitle/detail
                            // are retained-but-unused props) — see its file header.
                            content: .context(number: String(format: "%02d", c.sortOrder),
                                              title: c.text, subtitle: "", detail: c.backCopy ?? ""),
                            isFront: isFront, confirmed: false
                        )
                    }
                )
                .frame(height: deckSize.height * 1.3)
                .transition(.opacity)
            } else {
                ForEach(0..<6, id: \.self) { i in
                    fanCard(i)
                }
                .transition(.opacity)
            }

            // Beat 6b — the name, risen ABOVE the cards. The deck is named
            // AFTER it stands alone: the object earns its name by existing first.
            VStack(spacing: AppSpacing.xxs) {
                Text("Your Deck")
                    .font(AppFonts.caption)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.spectrumCyan.opacity(0.65))
                Text(welcomeDeck.title.uppercased())
                    .font(AppFonts.screenTitle)
                    .foregroundStyle(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing))
            }
            .offset(y: -(deckSize.height * 0.82) + (nameShown ? 0 : 6))
            .opacity(nameShown ? 1 : 0)
        }
        .offset(y: deckRise)
        .opacity(deckOpacity)
        .position(floatCenter)
    }

    /// One card of the reveal fan. Face-down (VaylCardBack) until its flip-wave
    /// moment; the content swaps edge-on at ~90° so neither face ever shows
    /// mirrored. At rest (pre-fan) the six cards sit in the VaylDeckStack pose,
    /// so the deck the peel uncovers and the fan are the SAME object.
    @ViewBuilder
    private func fanCard(_ i: Int) -> some View {
        let off   = fanOffsetFracs[i] * deckW
        let yLift = abs(off) * 0.09
        ZStack {
            if faceUp[i] {
                let c = welcomeDeck.cards[i]
                VaylCardFace(
                    content: .context(number: String(format: "%02d", c.sortOrder),
                                      title: c.text, subtitle: "", detail: c.backCopy ?? ""),
                    isFront: true, confirmed: false
                )
            } else {
                VaylCardBack()
                    // counter-rotated so the back reads UN-mirrored at 180°
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(width: deckSize.width, height: deckSize.height)
        .rotation3DEffect(.degrees(flipDegrees[i]),
                          axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotationEffect(.degrees(fanned ? fanAngles[i] : 0))
        .offset(x: fanned ? off : CGFloat(5 - i) * 1.2,
                y: fanned ? -yLift : CGFloat(5 - i) * 1.6)
        .zIndex(fanned ? (3 - abs(2.5 - Double(i))) : Double(i))
    }

    // MARK: - Living Case tap ceremony (Beat 5)

    /// A strike lands. The SEQUENCE is fixed (no authored zones), but the
    /// physics honours the finger: the case recoils AWAY from where it was
    /// struck. The ceremony store escalates; the view runs the physical read
    /// (shake, dealer line, core charge) and fires the release on the third.
    private func strike(at uv: CGPoint) {
        guard let idx = director.ceremony.registerTap() else { return }
        // If the idle peek somehow rose, retract it — two exit affordances
        // must not coexist, and its low edge could intercept a strike tap.
        if idx == 0, peekShown, caseDissolve == .distantFuture {
            withAnimation(AppAnimation.fast.reduceMotionSafe) { peekShown = false }
        }
        runShake(idx, from: uv)
        // the contained charge climbs — recognition, resistance, release
        withAnimation(AppAnimation.standard.reduceMotionSafe) {
            coreEnergy = [0.32, 0.68, 1.0][idx]
        }
        switch idx {
        case 0:
            showStatusLine("It fights back. Tap again.")
            scheduleReseal(afterMilliseconds: 520)   // erupt 300 + hold 220
        case 1:
            showStatusLine("It's losing. One more.")
            scheduleReseal(afterMilliseconds: 660)   // erupt 360 + hold 300
        default:
            beginRelease()
        }
    }

    private func showStatusLine(_ line: String) {
        let t = Double(AppDealerTyping.typeDuration(line)) / 1000.0
        director.projector.showDealerLine(line, hideAfter: t + 0.8,
                                          anchorYFrac: AppLayout.forgeFloatTextYFrac)
    }

    /// The reseal haptic — fires as the lattice closes back over the card
    /// (taps 1–2 only). Cancelled if the next strike lands first.
    private func scheduleReseal(afterMilliseconds ms: Int) {
        resealTask?.cancel()
        resealTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(ms))
            guard !Task.isCancelled else { return }
            resealCount += 1
        }
    }

    /// Damped-oscillation shake — a per-frame mathematical spring
    /// (amplitude * exp(-p*5) * sin(p*freq*2π)) so the case reads as an object
    /// with MASS recoiling, not a UI element transitioning. Escalates per tap;
    /// tap 3 adds a stronger vertical component (the whole case shudders).
    /// DIRECTIONAL: the recoil axis points AWAY from the strike (Opal recoil
    /// is away from your thumb) — a centre tap defaults to a lateral kick.
    private func runShake(_ tapIdx: Int, from uv: CGPoint) {
        shakeTask?.cancel()
        guard !reduceMotion else { return }
        let amp: [Double] = [5, 9, 14]
        let decay: [Double] = [AppAnimation.caseShake1, AppAnimation.caseShake2, AppAnimation.caseShake3]
        let freq: [Double] = [3, 2.5, 2]
        // away-from-the-finger direction; near-centre strikes fall back to lateral
        var dx = Double(0.5 - uv.x), dy = Double(0.5 - uv.y)
        let len = (dx * dx + dy * dy).squareRoot()
        if len < 0.08 { dx = 1; dy = 0.25 } else { dx /= len; dy /= len }
        let yGain = tapIdx == 2 ? 0.6 : 0.35   // the third shudders vertically too
        // torque axis perpendicular to the push (the old recoil's physics)
        kickAxis = (x: CGFloat(-dy), y: CGFloat(dx))
        shakeTask = Task { @MainActor in
            let start = Date.now
            while !Task.isCancelled {
                let p = Date.now.timeIntervalSince(start) / decay[tapIdx]
                guard p < 1 else { break }
                let envelope = exp(-p * 5)
                let osc = sin(p * freq[tapIdx] * 2 * .pi)
                let kick = osc * amp[tapIdx] * envelope
                shakeOffset = CGSize(width: kick * dx,
                                     height: kick * dy * yGain)
                kickDeg = kick * 0.35
                try? await Task.sleep(for: .milliseconds(16))
            }
            shakeOffset = .zero
            kickDeg = 0
        }
    }

    /// Third tap — RELEASE. The seams stay open, then the HELD BREATH: ~380ms
    /// where everything freezes and the case brightens (the moment before the
    /// break). Then the flower peel begins and the deck is already there.
    private func beginRelease() {
        guard caseDissolve == .distantFuture else { return }
        withAnimation(AppAnimation.fast.reduceMotionSafe) { holdBreathVisual = true }
        breathHoldStart = .now   // the float drift damps to dead-still in the case view
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 380))
            director.ceremony.releaseBreath()
            withAnimation(AppAnimation.exit.reduceMotionSafe) { holdBreathVisual = false }
            peelStarted = true          // .notification(.success) — the release
            caseDissolve = .now         // the flower peel begins
            beginPeelReveal()
        }
    }

    /// The peel + Beat 6. The deck mounts BEHIND the shell the moment the peel
    /// begins — the user watches the case peel away FROM the deck. Then, on the
    /// fixed stage: the breath (silence, no UI) → the name → the fan bloom →
    /// the flip wave → the carousel + CTA.
    private func beginPeelReveal() {
        deckStanding = true
        deckOpacity = 0; deckRise = 8; glowPulse = 0
        revealTask = Task { @MainActor in
            let rm = reduceMotion

            // — Beat 5b: the deck uncovered through the opening centre —
            try? await Task.sleep(for: .milliseconds(rm ? 0 : 70))
            withAnimation(AppAnimation.peelDeckFade.reduceMotionSafe) { deckOpacity = 1 }
            withAnimation(AppAnimation.peelDeckRise.reduceMotionSafe) { deckRise = 0 }
            // it glows with the energy that was just released
            withAnimation(AppAnimation.flowerPeel.reduceMotionSafe) { glowPulse = 0.6 }
            // essence venting — it STREAMS out through the peel, not detonates
            if !rm {
                spawnSparks(at: CGPoint(x: 0.5, y: 0.5), count: 18, style: .burst)
                sparksClearTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(SparkBurst.lifespan))
                    sparkBursts = []
                }
            }
            // the shell unmounts once the peel has consumed it
            try? await Task.sleep(for: .seconds(rm ? 0.1 : AppAnimation.flowerPeelSpan + 0.05))
            guard !Task.isCancelled else { return }
            caseShown = false
            caseOpacity = 0

            // — Beat 6a: the breath. No UI, no haptics — the silence beat. —
            // Trimmed from 0.68/0.52 — a solitary slow glow ramp reads as dead
            // air even though it's technically animating; still a real pause,
            // just not a stall.
            withAnimation(AppAnimation.deckBreathIn.reduceMotionSafe) { glowPulse = 1.0 }
            try? await Task.sleep(for: .seconds(rm ? 0 : 0.45))
            withAnimation(AppAnimation.deckBreathOut.reduceMotionSafe) { glowPulse = 0 }
            try? await Task.sleep(for: .seconds(rm ? 0 : 0.35))

            // — Beat 6b: the name rises (the object earned it by existing first) —
            try? await Task.sleep(for: .milliseconds(rm ? 0 : 100))
            withAnimation(AppAnimation.deckNameRise.reduceMotionSafe) { nameShown = true }
            try? await Task.sleep(for: .seconds(rm ? 0.1 : 0.58))

            // — Beat 6c: the fan blooms (face-down — the object before the content) —
            try? await Task.sleep(for: .milliseconds(rm ? 0 : 100))
            withAnimation(AppAnimation.deckFanBloom.reduceMotionSafe) { fanned = true }
            try? await Task.sleep(for: .seconds(rm ? 0 : 0.70))

            // — Beat 6d: the flip wave, left to right —
            try? await Task.sleep(for: .milliseconds(rm ? 0 : 80))
            guard !Task.isCancelled else { return }
            if rm {
                for i in 0..<6 { flipDegrees[i] = 0; faceUp[i] = true }
            } else {
                for i in 0..<6 {
                    try? await Task.sleep(for: .seconds(AppAnimation.deckFlipStagger))
                    guard !Task.isCancelled else { return }
                    withAnimation(AppAnimation.deckFlipWave) { flipDegrees[i] = 0 }
                    flipIndex = i   // .selection — the haptic wave rides the visual one
                    Task { @MainActor in
                        // content swaps edge-on at the flip's midpoint (~90°)
                        try? await Task.sleep(for: .milliseconds(160))
                        faceUp[i] = true
                    }
                }
                try? await Task.sleep(for: .milliseconds(320))   // the last flip lands
            }

            // — Beat 6e: the fan collapses to the carousel; the deck is theirs —
            // Trimmed from 520 — enough to register the full fanned deck, not
            // enough to stall before the payoff.
            try? await Task.sleep(for: .milliseconds(rm ? 0 : 350))
            guard !Task.isCancelled else { return }
            withAnimation(AppAnimation.standard.reduceMotionSafe) { inCarousel = true }
            withAnimation(AppAnimation.deckCtaFade.reduceMotionSafe) { ctaShown = true }
        }
    }

    /// Spectrum motes venting into the air. Origin is a face-UV point mapped
    /// through the case's frame (tilt ignored — airborne particles don't need
    /// surgical registration).
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

    /// While the case is armed, the deck inside KNOCKS: a physical twitch +
    /// soft haptic + a seam glimmer in the case view — anticipation that
    /// doubles as the tap cue. It does NOT stop at the first strike: each
    /// strike makes the thing inside more desperate — the cadence accelerates
    /// (3.5s → 1.8s → 0.9s) and the twitch grows. Only the release ends it.
    private func startKnocking() {
        guard !reduceMotion else { return }
        knockTask = Task { @MainActor in
            let cadence: [Double] = [3.5, 1.8, 0.9]
            while knockCount < 40,
                  director.ceremony.tapCount < 3,
                  caseDissolve == .distantFuture {
                try? await Task.sleep(for: .seconds(cadence[min(director.ceremony.tapCount, 2)]))
                guard director.ceremony.tapCount < 3, caseDissolve == .distantFuture else { break }
                // the strike beat owns the case while a card is erupting/resealing
                if director.ceremony.eruptStart != .distantFuture,
                   Date.now.timeIntervalSince(director.ceremony.eruptStart) < 1.1 { continue }
                knock(intensity: 1.0 + 0.6 * Double(director.ceremony.tapCount))
            }
        }
    }

    private func knock(intensity: Double = 1.0) {
        knockCount += 1           // haptic trigger
        knockSeed = .random(in: .min ... .max)
        knockStart = .now         // seam glimmer in the case view
        // the twitch — a small kick about a random axis, then settle
        let angle = Double.random(in: 0...(2 * .pi))
        kickAxis = (x: CGFloat(cos(angle)), y: CGFloat(sin(angle)))
        withAnimation(AppAnimation.fast.reduceMotionSafe) { kickDeg = intensity }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(AppAnimation.knockReturn.reduceMotionSafe) {
                kickDeg = 0
            }
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
                        .init(color: progress > 0.001 ? .clear : .black, location: 1.00)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}

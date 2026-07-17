//
//  SessionCloseView.swift
//  Vayl
//
//  Screen 7 of the couple session cover: the close.
//  One calm acknowledgment — the afterglow recap ("You went N cards deep") —
//  with the reflection riding up as a peeking sheet over it. The peek is the
//  invitation: drag it up to reflect (a floating field of words + one optional
//  private note), or swipe it away to land back home. Reflection never shoves
//  itself up; the sheet only peeks, and declining it is a single swipe. The
//  words feed your Map as trends, never grades — the only place communication
//  gets coached is after, by your own noticing.
//
//  Design direction: docs/prototypes couple-session-close V6, then collapsed
//  from two sequential pages to acknowledgment + peeking sheet (2026-07-12).
//  The reflection dropped the two "carried it / felt heard" sliders — words +
//  note only. (Those fields stay on SessionReflection at a neutral centre; see
//  CoupleSessionStore.)
//

import SwiftUI

struct SessionCloseView: View {

    @Bindable var store: CoupleSessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The reflection sheet peeks up over the acknowledgment on arrival — present
    /// but optional. Dragging it up reflects; swiping it away is the honest skip.
    /// `store.phase` stays `.close` until Save or a dismiss moves it to `.done`.
    @State private var reflectionUp = false
    /// Drives the backdrop afterglow's slow breath (living surface, auraBreathe).
    @State private var breathe = false

    /// The sheet's resting peek height, shared with the backdrop so the recap
    /// centres in the band ABOVE the sheet (not the full screen). FEEL-GATE.
    private let peekFraction: CGFloat = 0.40

    @State private var showNote = false
    @FocusState private var noteFocused: Bool

    /// Word bank — spans warm → neutral → harder, so honest words are there too.
    /// Order matters: it maps 1:1 onto `wordAnchors` (the constellation layout).
    private let bankWords = [
        "close", "seen", "warm", "light", "honest",
        "steady", "quiet", "full", "surface",
        "tender", "raw", "heavy", "distant"
    ]

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            backdrop(layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .vaylSheet(
                    isPresented: $reflectionUp,
                    // Peek (invitation) → large (the full field). The peek is set
                    // to tease the top row of words above the fold so "there's
                    // more up here" reads without a grabber alone carrying it.
                    // FEEL-GATE: tune peekFraction on device until a word peeks.
                    detents: [.fraction(peekFraction), .large],
                    // The recap behind the scrim is meant to be read — don't let a
                    // tap on it become a silent exit (the swipe / "not tonight" are
                    // the deliberate ways out).
                    scrimTapDismisses: false,
                    // Once a word or note is entered, a stray downward drag settles
                    // back to peek instead of discarding it — content is intent.
                    // Leaving then stays explicit: "not tonight" (discard) or Done
                    // (keep). An empty sheet still swipes away as the honest skip.
                    interactiveDismissDisabled: store.reflectionHasContent
                ) {
                    reflection(layout)
                }
        }
        // Peek up on arrival — the recap stays behind it; the reflection invites
        // without shoving itself up. The afterglow starts its slow breath.
        .onAppear {
            reflectionUp = true
            breathe = true
        }
        // Swiping an EMPTY sheet away is the honest skip: finish the close and let
        // the cover land the user back home. Once there's content the sheet guards
        // against a stray dismiss (settles to peek), so this only fires on a real,
        // content-free dismiss. Save/skip have already moved the phase to `.done`.
        .onChange(of: reflectionUp) { _, up in
            if !up && store.phase == .close {
                store.skipReflection()
            }
        }
        // The swipe-down skip isn't reachable with VoiceOver on a custom sheet,
        // so the standard escape gesture (two-finger scrub) completes the close
        // the same way — the exit the removed skip button used to provide.
        .accessibilityAction(.escape) {
            if store.phase == .close { store.skipReflection() }
        }
    }

    // MARK: - Time context

    /// "this morning" · "today" · "tonight" — the copy leans into the hour so
    /// the close feels addressed to now, not a generic post-session screen.
    private var timeContext: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "this morning"
        case 12..<17: return "today"
        default:      return "tonight"
        }
    }

    // MARK: - Backdrop (the afterglow)

    /// The acknowledgment the couple lands on: the recap, resting in a soft
    /// afterglow, centred in the band above the peeking sheet. No action lives
    /// here — the sheet is the invite, and swiping it away is the way out.
    private func backdrop(_ layout: AppLayout) -> some View {
        ZStack {
            // The afterglow — a slow-breathing spectrum bloom filling the void
            // the recap sits in, so the space reads as radiant deep, not empty
            // black. Reserved to the visible band above the sheet.
            afterglowBloom
                .padding(.bottom, layout.screenHeight * peekFraction)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppSpacing.sm) {
                    Text("✦")
                        .font(AppFonts.bodyMedium)
                        // Below 24pt the full gradient muddies — the Earned Spectrum
                        // Rule keeps it to strokes/hero; a small glyph takes the
                        // single cyan accent instead.
                        .foregroundStyle(AppColors.textAccent)
                    Text("the afterglow")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.bottom, AppSpacing.lg)

                recapTitle

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: AppIcons.clockOutline)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(store.sessionDurationLabel)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.top, AppSpacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(store.sessionDurationLabel) long")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
            // Centre the recap in the band above the sheet, not the full screen —
            // reserving the peek keeps it out of the sheet's zone.
            .padding(.bottom, layout.screenHeight * peekFraction)
        }
    }

    /// The afterglow bloom — three spectrum orbs (the paywall's headerBloom
    /// vocabulary, calmer) breathing slowly. Living surface → auraBreathe; gated
    /// off under Reduce Motion / Low Power by `.ambientAnimation`.
    private var afterglowBloom: some View {
        ZStack {
            GlowOrb(color: AppColors.spectrumCyan, size: 240)
                .offset(x: -90, y: -30)
            GlowOrb(color: AppColors.spectrumMagenta, size: 240)
                .offset(x: 90, y: 40)
            GlowOrb(color: AppColors.spectrumPurple, size: 340)   // dominant core
        }
        .scaleEffect(breathe ? 1.04 : 0.96)
        .ambientAnimation(
            .easeInOut(duration: AppAnimation.auraBreathe).repeatForever(autoreverses: true),
            value: breathe
        )
        .allowsHitTesting(false)
    }

    private var recapTitle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("You went")
            Text("\(store.closeCardsDeep) \(store.closeCardsDeep == 1 ? "card" : "cards")")
                .foregroundStyle(AppColors.spectrumText)
            Text("deep \(timeContext).")
        }
        .font(AppFonts.closeHero)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Reflection

    /// The reflection is one scrolling column inside the sheet: at the peek
    /// detent only the header shows (the invitation); dragging the sheet up
    /// reveals the word field, the note, and Save at the end. No pinned footer —
    /// declining is a swipe-down, so Save lives where you arrive after engaging.
    /// The honest exit, pinned top-trailing over the reflection. Content-sized (not
    /// full-width) so it reads as a corner affordance, with horizontal padding
    /// keeping the tap target comfortable and off the edge.
    private var offRampButton: some View {
        Button {
            store.skipReflection()
        } label: {
            Text("not tonight")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.sm)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.vaylPressable(scale: 0.97))
        .accessibilityLabel("Not tonight, close without reflecting")
    }

    private func reflection(_ layout: AppLayout) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // The invitation greets first at peek. The off-ramp is pinned
                // top-trailing (the overlay below) so leaving stays one tap and
                // always visible, without the exit being the first thing read.
                reflectionHeader(layout)

                // The words carry no verb on their own — a picked word just settles
                // forward, and at rest the scatter can read as decoration, not a
                // pick-list. One quiet line names the interaction, hugged close to
                // the field (tight spacing) so it reads as the field's own label.
                VStack(spacing: AppSpacing.sm) {
                    Text("pick any that fit, or none")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        // The visible cue already teaches this; keep it out of the
                        // VoiceOver tree so the words' own hint isn't said twice.
                        .accessibilityHidden(true)

                    wordField(layout)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Reflection words")
                        .accessibilityValue(
                            store.reflectionWords.isEmpty
                                ? "none picked"
                                : "\(store.reflectionWords.count) picked"
                        )
                        .accessibilityHint("Pick any that fit, or none")
                }
                .padding(.horizontal, AppSpacing.lg)

                noteSection
                    .padding(.horizontal, AppSpacing.lg)

                // A picked word in the scatter is easy to lose track of, so a quiet
                // count sits with Done — confirmation the taps registered, without
                // re-scanning the field. Hidden below one pick (an eager "0 picked"
                // would nag). VoiceOver already hears the count on the word field.
                VStack(spacing: AppSpacing.sm) {
                    if store.reflectionWords.count > 0 {
                        Text("\(store.reflectionWords.count) picked")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                            .accessibilityHidden(true)
                    }

                    // "Done", not "Save" — an empty commit (no words, no note) is an
                    // honest close, not a saved thing, so the label mustn't promise
                    // one. saveReflection() persists only when there's content.
                    VaylButton(label: "Done") {
                        store.saveReflection()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .animation(AppAnimation.standard, value: store.reflectionWords.count)
            }
            // Clear the pinned off-ramp band so the header greeting doesn't tuck
            // under it at peek. FEEL-GATE: tune with peekFraction on device.
            .padding(.top, AppSpacing.xxl)
            .bottomClearance(layout)
        }
        // A soft spectrum bloom at the sheet's top (the paywall's headerBloom
        // vocabulary) so the surface reads as lit, not a flat muted-purple panel.
        // Behind the scroll, fixed, so it stays at the top as words scroll past.
        .background(alignment: .top) { reflectionBloom }
        .scrollDismissesKeyboard(.interactively)
        // Pinned to the sheet's top-trailing corner — fixed, never scrolls, so the
        // honest exit is always one tap while the reading path stays the invitation.
        .overlay(alignment: .topTrailing) {
            offRampButton
                .padding(.trailing, AppSpacing.lg)
                .padding(.top, AppSpacing.xs)
        }
    }

    private var reflectionBloom: some View {
        ZStack {
            GlowOrb(color: AppColors.spectrumCyan, size: 200)
                .offset(x: -70, y: -20)
            GlowOrb(color: AppColors.spectrumMagenta, size: 200)
                .offset(x: 70, y: -20)
            GlowOrb(color: AppColors.spectrumPurple, size: 260)   // dominant core
                .offset(y: -20)
        }
        .opacity(0.7)   // calmer than the paywall's full-strength conversion bloom
        .allowsHitTesting(false)
    }

    /// The word field adapts to text size: the loose constellation at normal
    /// sizes, and a wrapping flow of chips once type reaches accessibility sizes
    /// (where the scatter's absolute positions would collide and clip).
    @ViewBuilder
    private func wordField(_ layout: AppLayout) -> some View {
        if dynamicTypeSize >= .accessibility1 {
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(bankWords, id: \.self) { word in
                    reflectionWordChip(word)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            WordConstellation(
                words: bankWords,
                selected: store.reflectionWords,
                reduceMotion: reduceMotion
            ) { store.toggleWord($0) }
            .frame(height: layout.screenWidth * 0.70)
        }
    }

    /// A single word as a wrapping chip — the accessibility-size counterpart to
    /// a constellation word, with a guaranteed 44pt target and the same
    /// weight + colour selection language.
    private func reflectionWordChip(_ word: String) -> some View {
        let on = store.reflectionWords.contains(word)
        return Button {
            store.toggleWord(word)
        } label: {
            Text(word)
                .font(AppFonts.bodyMedium)
                // Matches the constellation's weight-on-pick, minus the scale —
                // chips sit in a flow row where a size jump would reflow.
                .fontWeight(on ? .semibold : .regular)
                .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.vertical, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(on ? AppColors.whisperFill : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
                        .opacity(on ? AppOpacity.stroke : AppOpacity.hairline)
                )
                .contentShape(Capsule())
                .animation(AppAnimation.standard, value: on)
        }
        .buttonStyle(.vaylPressable(scale: 0.96))
        .accessibilityLabel(word)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func reflectionHeader(_ layout: AppLayout) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text("How was it \(timeContext), for you?")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Capsule()
                .fill(AppColors.spectrumBorder)
                .frame(width: layout.screenWidth * 0.42, height: 1)
                .opacity(AppOpacity.stroke)

            // The quiet reassurance: on a two-device app about a shared talk,
            // "is my partner seeing this?" is the unspoken question. Answer it
            // before they wonder — this field is theirs alone.
            Text("only you'll see this")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
        // No self top padding — the scroll's top inset clears the pinned off-ramp,
        // and the VStack spacing owns the rest, keeping this a peek-tight header so
        // the cue and top words can tease above the fold.
    }

    // MARK: - Note

    private var noteSection: some View {
        Group {
            if showNote {
                noteField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button {
                    withAnimation(AppAnimation.standard) { showNote = true }
                    noteFocused = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        // Single accent below 24pt (Earned Spectrum Rule), not the
                        // full gradient — matches the "✦" afterglow glyph.
                        Text("+").foregroundStyle(AppColors.textAccent)
                        Text("add a note")
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    // Centered to match the sheet's other controls (the cue, the
                    // "N picked" readout, the "not tonight" row) — a lone leading
                    // "+" read as a mis-indent among centered siblings.
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.vaylPressable(scale: 0.98))
            }
        }
    }

    private var noteField: some View {
        TextField(
            "a line for future-you about \(timeContext)…",
            text: $store.reflectionNote,
            axis: .vertical
        )
        .font(AppFonts.bodyText)
        .foregroundStyle(AppColors.textBody)
        .lineSpacing(AppSpacing.xs)
        .lineLimit(4, reservesSpace: true)
        .focused($noteFocused)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColors.inputBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.5)
                // Quiet at rest, present on focus — the border reads while the
                // glow below carries the actual focus bloom.
                .opacity(noteFocused ? AppOpacity.stroke : AppOpacity.dim)
        )
        .spectrumBorderGlow(intensity: noteFocused ? 0.5 : 0)
        .animation(AppAnimation.standard, value: noteFocused)
    }

}

// MARK: - WordConstellation

/// The reflection word field: a loose scatter of the bank words, not a grid or
/// wrapping chip row. Picking a word settles it forward — heavier weight, full
/// contrast, and a spectrum underline that draws in from the left. No size jump
/// on selection, so neighbours never nudge (weight + colour + underline carry it
/// instead), which keeps the whole field still while one word lights up.
private struct WordConstellation: View {

    let words: [String]
    let selected: Set<String>
    let reduceMotion: Bool
    let onTap: (String) -> Void

    /// Normalised offsets from centre (dx·usableWidth, dy·usableHeight) plus a
    /// weight tier. Tuned in the V6 prototype; index maps 1:1 onto `words`.
    private struct Anchor { let dx: CGFloat; let dy: CGFloat; let big: Bool }
    private let anchors: [Anchor] = [
        .init(dx: -0.30, dy: -0.42, big: true),   // close
        .init(dx: 0.05, dy: -0.46, big: false),   // seen
        .init(dx: 0.34, dy: -0.38, big: false),   // warm
        .init(dx: -0.38, dy: -0.18, big: false),  // light
        .init(dx: 0.00, dy: -0.20, big: true),    // honest
        .init(dx: 0.36, dy: -0.14, big: false),   // steady
        .init(dx: -0.28, dy: 0.06, big: false),   // quiet
        .init(dx: 0.14, dy: 0.04, big: false),    // full
        .init(dx: 0.38, dy: 0.12, big: false),    // surface
        .init(dx: -0.36, dy: 0.28, big: true),    // tender
        .init(dx: -0.04, dy: 0.30, big: false),   // raw
        .init(dx: 0.30, dy: 0.34, big: false),    // heavy
        .init(dx: -0.20, dy: 0.46, big: false)    // distant
    ]

    var body: some View {
        // Words map 1:1 onto anchors — assert so a future edit to the bank trips
        // here in debug instead of a modulo silently stacking word 14 on anchor 0.
        assert(words.count == anchors.count, "WordConstellation: words and anchors must be 1:1")
        return GeometryReader { geo in
            // Inset the spread so the widest words stay clear of the edges on
            // narrow devices — the anchors describe position within this field,
            // not the full bounds.
            let usableW = geo.size.width - AppSpacing.xxl
            let usableH = geo.size.height - AppSpacing.xl
            // zip caps at the shorter of the two, so a mismatch degrades to fewer
            // placed words rather than overlapping — no word lands on a wrong anchor.
            ForEach(Array(zip(words, anchors).enumerated()), id: \.element.0) { _, pair in
                let (word, anchor) = pair
                wordButton(word, big: anchor.big)
                    .position(
                        x: geo.size.width / 2 + anchor.dx * usableW,
                        y: geo.size.height / 2 + anchor.dy * usableH
                    )
            }
        }
    }

    private func wordButton(_ word: String, big: Bool) -> some View {
        let on = selected.contains(word)
        return Button {
            onTap(word)
        } label: {
            Text(word)
                .font(big ? AppFonts.bodyMedium : AppFonts.caption)
                // A picked word settles forward with weight — semibold, brighter,
                // and grown ~+2pt (the V6 mockup's scale). The scatter is
                // absolutely positioned (.position), so scaling one word never
                // nudges its neighbours; the field stays still while it lifts.
                .fontWeight(on ? .semibold : .regular)
                .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(AppColors.spectrumText)
                        .frame(height: 1)
                        // Under Reduce Motion the underline cross-fades in place
                        // rather than drawing across — scale is motion.
                        .scaleEffect(x: (on || reduceMotion) ? 1 : 0, anchor: .leading)
                        .opacity(on ? 1 : 0)
                        .offset(y: AppSpacing.xxs)
                }
                .fixedSize()
                // ~+2pt of growth on the 13–15pt words; only when motion is
                // allowed — under Reduce Motion the weight + colour carry it.
                .scaleEffect((on && !reduceMotion) ? 1.14 : 1.0)
                // The tap region clears 44pt without changing the visual
                // scatter — padding is transparent and .position centres it.
                .padding(.vertical, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.xs)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .animation(AppAnimation.standard, value: on)
        }
        .buttonStyle(.vaylPressable(scale: 0.92))
        // A lit, scaled word sits above its neighbours so the bloom isn't
        // clipped by a later-drawn word in the scatter.
        .zIndex(on ? 1 : 0)
        .accessibilityLabel(word)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Session Close") {
    ZStack {
        OnboardingAtmosphere(config: .stat)
        SessionCloseView(store: {
            let s = CoupleSessionStore(
                hand: Array(Card.samples.prefix(8)),
                modelContainer: .previewContainer,
                appState: AppState()
            )
            return s
        }())
    }
    .preferredColorScheme(.dark)
}

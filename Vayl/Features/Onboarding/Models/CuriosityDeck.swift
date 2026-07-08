// Features/Onboarding/Models/CuriosityDeck.swift

import Foundation

/// The CuriosityPhase sort deck, selected by the user's mode + register.
///
/// The OB flow deals ROUND 2 ONLY since 2026-07-04 ("What are you curious to
/// try?" / "What do you want more of?"): a fixed, escalating set of milestone
/// acts (a date, then a threesome, a play party, swinging or open dating, then
/// polyamory), adjusted for solo vs couple and stage. Round 1 ("What's drawing
/// you here?" = inner feelings, register-weighted) was cut from the flow —
/// Context already carries the present-state signal — but its data is retained
/// here for potential future use (do NOT re-add it to OB without a new decision).
///
/// Selection is DETERMINISTIC for a given (mode, register), so the ConfirmationPhase
/// credential editor rebuilds the exact 10 cards the user sorted.
///
/// Card valence and the R2 tiers are grounded in relationship/sex research
/// (responsive desire, Dual Control, CNM-parity, jealousy-as-signal, the
/// fantasy-to-enactment gap) from the 2026-06-20 OB curiosity research pass.
/// Pure data + pure selection (Model layer): no state, no I/O. No em dashes in copy.
enum CuriosityDeck {

    /// The cards for one round of a given user's deck.
    static func cards(round: Int, mode: AppMode, register: SituationalRegister, stage: NMStage) -> [CuriositySortCard] {
        let ids = round == 1 ? round1Ids(mode: mode, register: register) : round2Ids(mode: mode, stage: stage)
        return ids.map { CuriositySortCard(id: $0, text: catalog[$0] ?? $0, round: round) }
    }

    // MARK: - Round 1 hands (mode × register)
    // Each hand is 5 cards in sort order: index 0 deals on top / is sorted first
    // (the register-appropriate lead); the rest span the valence range so the
    // keep/pass sort still discriminates.

    private static func round1Ids(mode: AppMode, register: SituationalRegister) -> [String] {
        switch (mode, register) {
        case (.solo, .excited):
            return ["r1_ready", "r1_turned_on", "r1_pleasure", "r1_curious_into", "r1_jealousy"]
        case (.solo, .flexible):
            return ["r1_curious_into", "r1_want_never", "r1_desired", "r1_version", "r1_getting_clear"]
        case (.solo, .anxious):
            return ["r1_pace", "r1_jealousy", "r1_curious_into", "r1_desired", "r1_pleasure"]
        case (.together, .excited):
            return ["r1_ready", "r1_bring_new", "r1_turned_on", "r1_curious_into", "r1_bring_up"]
        case (.together, .flexible):
            return ["r1_curious_into", "r1_want_never", "r1_desired", "r1_bring_new", "r1_holding_back"]
        case (.together, .anxious):
            return ["r1_bring_up", "r1_close", "r1_curious_into", "r1_desired", "r1_pleasure"]
        }
    }

    // MARK: - Round 2 (mode-adjusted; stage-gated)
    // Curious users get the entry first-times, dealt gentle to bold (a date
    // through polyamory), mode-split. In-it users (exploring/experienced) get a
    // shared, mode-neutral "what do you want more of" set: most experienced
    // non-monogamists are refining a lane they like (better chemistry, a regular
    // connection, a bigger event), not escalating toward poly or a live-in third,
    // so the deck reflects depth and more-of-what-works, not new milestones.

    private static func round2Ids(mode: AppMode, stage: NMStage) -> [String] {
        switch stage {
        case .curious:
            switch mode {
            case .solo:
                return ["r2_date", "r2_threesome", "r2_party", "r2_open_dating", "r2_solo_poly"]
            case .together:
                return ["r2_date", "r2_threesome_couple", "r2_party", "r2_swinging", "r2_full_poly"]
            }
        case .exploring, .experienced:
            return ["r2_grows", "r2_kink_deeper", "r2_chemistry", "r2_regular", "r2_bigger_event"]
        }
    }

    // MARK: - Catalog (stable id -> user-facing text)
    // Stable ids persist into curiositySelections. NEVER reuse an
    // id for different text. No em dashes (Vayl copy rule).

    private static let catalog: [String: String] = [
        // Round 1 — feelings
        "r1_ready": "I'm ready to explore, not just wonder",
        "r1_turned_on": "I'm more turned on by this than I expected",
        "r1_pleasure": "I want more pleasure in my life",
        "r1_curious_into": "I'm curious what I'm actually into",
        "r1_jealousy": "I want to understand my jealousy, not fear it",
        "r1_want_never": "I want things I've never let myself want",
        "r1_desired": "I want to feel desired again",
        "r1_version": "There's a version of me I haven't let out",
        "r1_getting_clear": "I'm still getting clear on what I want",
        "r1_pace": "I want to go at a pace that feels right",
        "r1_bring_new": "I want to bring something new to my sex life",
        "r1_bring_up": "I want to bring this up but don't know how",
        "r1_holding_back": "I keep holding back what I want",
        "r1_close": "I want to feel close again",

        // Round 2 — milestones
        "r2_date": "A date with someone new",
        "r2_threesome": "A threesome or moresome",
        "r2_threesome_couple": "A threesome, foursome, or moresome",
        "r2_party": "A play party",
        "r2_open_dating": "Seeing more than one person",
        "r2_swinging": "Swinging with another couple",
        "r2_solo_poly": "Solo polyamory",
        "r2_full_poly": "Full polyamory",

        // Round 2 — in it ("what do you want more of?")
        "r2_grows": "A connection that grows into something more",
        "r2_kink_deeper": "A kink I want to explore more deeply",
        "r2_chemistry": "Better chemistry, not just more people",
        "r2_regular": "A regular couple or person I actually click with",
        "r2_bigger_event": "A bigger lifestyle event or takeover"
    ]
}

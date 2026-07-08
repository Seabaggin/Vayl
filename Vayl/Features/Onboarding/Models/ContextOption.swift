// Features/Onboarding/Models/ContextOption.swift
//
// Pure data model for the ContextPhase options. Reason-based, collapsed to 4 sets:
// solo/couple × {curious, in-it} — exploring + experienced merged (the experienced cohort
// treats NM as lower-stakes, "not as big a deal"). Every card is first-person "I": the OB is
// two-device, each partner onboards alone and speaks only for themselves — never "we" / "you
// both". See spec docs/superpowers/specs/2026-06-20-contextphase-redesign-design.md.
//
// `context` is the persisted routing tag; `derivedRegister` (anxious/excited/flexible) is the
// behavioural driver — it feeds the dealer's exit line and opener-deck selection. Nothing
// downstream branches on the specific context. `accent` is decorative ONLY — never branch on it.

import Foundation

/// Purely decorative card flair. No semantic meaning. Do not branch on this.
enum CardAccent {
    case ember, spark, flame, inferno, nova
}

struct ContextOption: Identifiable {
    let id: String
    let context: RelationshipContext
    let accent: CardAccent
    let title: String
    let subtitle: String
    let detail: String

    /// Derived from `context`. The behavioural contract — downstream keys on the register,
    /// never on the specific context. Curious cohorts carry the anxiety (the leap); the
    /// in-it cohorts skew flexible (comfortable, lower-stakes).
    var derivedRegister: SituationalRegister {
        switch context {
        case .soloUndisclosed,
             .coupleNervous,
             .coupleInitiator,
             .coupleRecalibrating:
            return .anxious
        case .single,
             .soloIntentional,
             .coupleExcited,
             .coupleGoDeeper:
            return .excited
        case .soloLearning,
             .soloSeekingClarity,
             .soloExpandKnowledge,
             .soloCheckingOut,
             .coupleFiguringOut,
             .coupleGetBetter,
             .coupleKeepItFun:
            return .flexible
        }
    }
}

extension ContextOption {

    /// Total resolver. Exploring + experienced share the "in it" set per mode.
    static func options(appMode: AppMode, stage: NMStage) -> [ContextOption] {
        switch (appMode, stage) {
        case (.solo, .curious):                                   return soloCurious
        case (.solo, .exploring), (.solo, .experienced):         return soloInIt
        case (.together, .curious):                              return coupleCurious
        case (.together, .exploring), (.together, .experienced): return coupleInIt
        }
    }

    // MARK: Solo · Curious — why you're exploring alone, new to NM
    static let soloCurious: [ContextOption] = [
        .init(id: "solo_learning", context: .soloLearning, accent: .spark,
              title: "I'm here to learn", subtitle: "Curious about NM — maybe just that",
              detail: "Maybe you'll explore it for real one day, maybe you're just curious. Either way — understand it first, no pressure to go further."),
        .init(id: "solo_undisclosed", context: .soloUndisclosed, accent: .flame,
              title: "I don't know how to bring it up", subtitle: "I want to, but the conversation feels hard",
              detail: "You're into the idea; raising it with your partner is the hard part. Get clear on what you want, then find language that lowers the temperature instead of raising it."),
        .init(id: "solo_seeking_clarity", context: .soloSeekingClarity, accent: .inferno,
              title: "I want to gain clarity", subtitle: "Getting clear on what I want, on my own",
              detail: "Before anyone else is involved, understand your own desires and limits. Map what you actually want, on your own terms."),
        .init(id: "single_curious", context: .single, accent: .nova,
              title: "I'm single", subtitle: "Exploring on my own",
              detail: "No relationship to navigate — just you and your curiosity. Start with the fundamentals, at your own pace.")
    ]

    // MARK: Solo · In it — why you're exploring alone, already practicing
    static let soloInIt: [ContextOption] = [
        .init(id: "solo_intentional", context: .soloIntentional, accent: .spark,
              title: "I want to explore more intentionally", subtitle: "On my own terms, more deliberately",
              detail: "You're already practicing — now you want to bring intention to it. Be more deliberate about what you're already doing."),
        .init(id: "solo_expand_knowledge", context: .soloExpandKnowledge, accent: .flame,
              title: "I want to expand my knowledge", subtitle: "Going past the basics",
              detail: "You know the fundamentals — now go deeper. There's always another layer to understand."),
        .init(id: "solo_checking_out", context: .soloCheckingOut, accent: .inferno,
              title: "I'm just checking it out", subtitle: "Seeing what's here, no agenda",
              detail: "No particular plan — just seeing what the app offers. A fine place to start; poke around and find what's useful."),
        .init(id: "single_in_it", context: .single, accent: .nova,
              title: "I'm single", subtitle: "Exploring on my own",
              detail: "No relationship to navigate — just you and your own practice, at your own pace.")
    ]

    // MARK: Couple · Curious — first-person, new to it (higher-stakes)
    static let coupleCurious: [ContextOption] = [
        .init(id: "couple_excited", context: .coupleExcited, accent: .spark,
              title: "I'm excited to explore this with my partner", subtitle: "Ready to dive in",
              detail: "That energy is a real advantage. Build the shared language and the room to think out loud before any decisions get made."),
        .init(id: "couple_nervous", context: .coupleNervous, accent: .flame,
              title: "I want this, but I'm nervous", subtitle: "Into the idea, finding my footing",
              detail: "You want this, and the nerves are normal. Go at a pace that keeps you honest about what you're feeling as you figure it out."),
        .init(id: "couple_initiator", context: .coupleInitiator, accent: .inferno,
              title: "I brought this to my partner", subtitle: "I raised it — they're catching up",
              detail: "You opened the door. Say what you want without pressure — and leave your partner room to arrive at their own pace."),
        .init(id: "couple_figuring_out", context: .coupleFiguringOut, accent: .ember,
              title: "I'm still figuring out what I want", subtitle: "Open, but not sure yet",
              detail: "You don't need it mapped out to begin. Start here and figure out what you want as you go.")
    ]

    // MARK: Couple · In it — first-person, already in it (comfortable, lower-stakes)
    static let coupleInIt: [ContextOption] = [
        .init(id: "couple_go_deeper", context: .coupleGoDeeper, accent: .spark,
              title: "I want to go deeper with my partner", subtitle: "Past the basics, into the real thing",
              detail: "Past curiosity, into depth. Name what's working, what isn't, and where you want to go."),
        .init(id: "couple_get_better", context: .coupleGetBetter, accent: .flame,
              title: "I want to get better at the hard parts", subtitle: "The conversations, conflict, repair",
              detail: "You're good at the structure — now the craft underneath it: the conversations, the repairs, the emotional fluency."),
        .init(id: "couple_recalibrating", context: .coupleRecalibrating, accent: .inferno,
              title: "Something's shifted — I want to work through it", subtitle: "A change I want to navigate",
              detail: "Something's changed — a new connection, a boundary that isn't working, or a feeling that things are off. Time to recalibrate."),
        .init(id: "couple_keep_it_fun", context: .coupleKeepItFun, accent: .ember,
              title: "I want to keep it fun", subtitle: "Keeping the spark, no heavy agenda",
              detail: "Things are good — you just don't want them running on autopilot. Stay playful and curious about your partner.")
    ]
}

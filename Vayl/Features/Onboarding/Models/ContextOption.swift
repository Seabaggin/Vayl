// Features/Onboarding/Models/ContextOption.swift
//
// Pure data model for the ContextPhase 2×3 matrix.
// Content keyed on (AppMode, NMStage). 24 contexts across 6 cells, each cell
// holding 3 concrete situations + 1 first-class "undecided" card.
//
// `context` is the routing value — all downstream branches on it.
// `accent` is decorative ONLY — never branch on it.
// `derivedRegister` keeps SituationalRegister alive so VaylDirector's exit line,
// deck weighting, and Compass "heavy context" check work unchanged.

import Foundation

/// Purely decorative card flair. No semantic meaning. Do not branch on this.
enum CardAccent {
    case ember, spark, flame, inferno, nova
}

struct ContextOption: Identifiable {
    let id:       String
    let context:  RelationshipContext
    let accent:   CardAccent
    let title:    String
    let subtitle: String
    let detail:   String

    /// Derived from `context`. Undecided → flexible (lowest-stakes routing).
    var derivedRegister: SituationalRegister {
        switch context {
        case .partneredUndisclosed,
             .coupleAsymmetricCurious,
             .coupleStalledConversation,
             .coupleReorienting,
             .coupleEvolving:
            return .anxious
        case .singleExploring,
             .singleExperienced,
             .soloPolyIndependent,
             .coupleSolidifying,
             .coupleFreshIntentional,
             .coupleSkillBuilding:
            return .excited
        default:
            return .flexible
        }
    }
}

extension ContextOption {

    /// Total resolver. `.browsing` falls back to the solo set.
    static func options(appMode: AppMode, stage: NMStage) -> [ContextOption] {
        switch (appMode, stage) {
        case (.together, .curious):     return coupleCurious
        case (.together, .exploring):   return coupleExploring
        case (.together, .experienced): return coupleExperienced
        case (.solo, .curious),    (.browsing, .curious):     return soloCurious
        case (.solo, .exploring),  (.browsing, .exploring):   return soloExploring
        case (.solo, .experienced),(.browsing, .experienced): return soloExperienced
        }
    }

    // MARK: Solo × Curious
    static let soloCurious: [ContextOption] = [
        .init(id: "single_curious", context: .singleCurious, accent: .spark,
              title: "I'm single", subtitle: "NM is new territory for me",
              detail: "No relationship to navigate — just you and your curiosity. We'll start with the fundamentals and let you explore at your own pace."),
        .init(id: "partnered_supportive_curious", context: .partneredSupportiveCurious, accent: .flame,
              title: "My partner's on board", subtitle: "They're supportive of me looking into this",
              detail: "You've opened the door — we'll help you figure out what you actually want before the bigger conversations begin."),
        .init(id: "partnered_undisclosed", context: .partneredUndisclosed, accent: .inferno,
              title: "I haven't brought it up", subtitle: "I have a partner, but the conversation hasn't happened",
              detail: "You're still figuring out what this means to you. We'll help you get clarity before you decide whether or how to start the conversation."),
        .init(id: "solo_curious_undecided", context: .soloCuriousUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "My situation doesn't quite fit any of these",
              detail: "That's okay — most people's lives are messier than a list of options. Start here and we'll help you figure out the rest as you go."),
    ]

    // MARK: Solo × Exploring
    static let soloExploring: [ContextOption] = [
        .init(id: "single_exploring", context: .singleExploring, accent: .spark,
              title: "I'm single", subtitle: "Dating and still figuring out who I am in NM",
              detail: "You've moved past curiosity — now it's about building a real sense of your identity, boundaries, and what you want from connections."),
        .init(id: "partnered_hands_off", context: .partneredHandsOff, accent: .flame,
              title: "Partnered, but here on my own", subtitle: "I have a partner — exploring the app on my own",
              detail: "Your partner is on board but this is your journey. We'll focus on your individual growth while keeping the relationship in view."),
        .init(id: "multiple_undefined", context: .multipleUndefined, accent: .inferno,
              title: "I have multiple partners", subtitle: "Here to navigate it on my own",
              detail: "You're holding more than one connection and steering it yourself. We'll help you navigate the balance — communication, time, and what you actually want from each."),
        .init(id: "solo_exploring_undecided", context: .soloExploringUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "My situation is hard to pin down right now",
              detail: "You know you're exploring — you're just not sure which box fits. That's fine. We'll meet you where you are and let the label catch up later."),
    ]

    // MARK: Solo × Experienced
    static let soloExperienced: [ContextOption] = [
        .init(id: "single_experienced", context: .singleExperienced, accent: .spark,
              title: "I'm single", subtitle: "Solo, and clear on who I am in NM",
              detail: "You've done the work. This is about staying intentional, continuing to grow, and finding the connections that fit the life you've built."),
        .init(id: "partnered_aware", context: .partneredAware, accent: .flame,
              title: "I have an established partner", subtitle: "We're solid — this is my own space to manage it",
              detail: "Your partner is aware and supportive, but your NM journey is yours to navigate. We'll focus on depth, skill, and continued self-awareness."),
        .init(id: "solo_poly_independent", context: .soloPolyIndependent, accent: .inferno,
              title: "I have multiple partners", subtitle: "Solo poly — multiple relationships, no hierarchy",
              detail: "You move through connections on your own terms. We'll support the craft of that — communication, transitions, autonomy, and care without hierarchy."),
        .init(id: "solo_experienced_undecided", context: .soloExperiencedUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "My structure shifts and none of these fully capture it",
              detail: "Experienced doesn't always mean settled. If your situation is genuinely fluid, start here — we'll build around what's true right now."),
    ]

    // MARK: Couple × Curious
    static let coupleCurious: [ContextOption] = [
        .init(id: "couple_symmetric_curious", context: .coupleSymmetricCurious, accent: .spark,
              title: "We're both curious", subtitle: "Neither of us has done this before",
              detail: "You're starting from the same place, which is a real advantage. We'll build shared language and give you both room to think out loud before any decisions get made."),
        .init(id: "couple_asymmetric_curious", context: .coupleAsymmetricCurious, accent: .flame,
              title: "One of us brought this up", subtitle: "The other is open, but still processing",
              detail: "The interest isn't equal yet — and that's okay. We'll help both of you find your footing without pushing anyone faster than they're ready to go."),
        .init(id: "couple_stalled_conversation", context: .coupleStalledConversation, accent: .inferno,
              title: "We talked, but it stalled", subtitle: "But the conversation never really went anywhere",
              detail: "Something got in the way — timing, fear, uncertainty. We'll help you pick up the thread and figure out why it stalled before trying again."),
        .init(id: "couple_curious_undecided", context: .coupleCuriousUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "Our situation is a little bit of all of these",
              detail: "That's more common than you'd think. Start here — you don't need to have it figured out to begin figuring it out together."),
    ]

    // MARK: Couple × Exploring
    static let coupleExploring: [ContextOption] = [
        .init(id: "couple_solidifying", context: .coupleSolidifying, accent: .spark,
              title: "We're ready to go deeper", subtitle: "Now we want to go deeper with intention",
              detail: "You've moved past curiosity — now it's about building a shared identity in NM. We'll help you name what's working, what isn't, and where you want to go."),
        .init(id: "couple_reorienting", context: .coupleReorienting, accent: .flame,
              title: "Something has shifted", subtitle: "We're figuring out our footing again",
              detail: "Your dynamic has changed — a new connection, a boundary that isn't working, or just a feeling that things are off. We'll help you recalibrate together."),
        .init(id: "couple_parallel_exploring", context: .coupleParallelExploring, accent: .inferno,
              title: "We explore in parallel", subtitle: "Together, but each on our own path",
              detail: "You're a couple but your NM journeys run in parallel. We'll support both your individual growth and the connection that holds it all together."),
        .init(id: "couple_exploring_undecided", context: .coupleExploringUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "We're somewhere between all of these right now",
              detail: "Exploring rarely looks like one clean thing. If your dynamic is layered or shifting, start here — we'll help you make sense of it as you go."),
    ]

    // MARK: Couple × Experienced
    static let coupleExperienced: [ContextOption] = [
        .init(id: "couple_fresh_intentional", context: .coupleFreshIntentional, accent: .spark,
              title: "We know what we're doing", subtitle: "We want to stay intentional and keep it alive",
              detail: "Experience doesn't make things automatic. We'll help you stay curious about each other and your dynamic without letting it run on autopilot."),
        .init(id: "couple_skill_building", context: .coupleSkillBuilding, accent: .flame,
              title: "Better at the hard stuff", subtitle: "Communication, conflict, care — the meta-skills",
              detail: "You're good at NM. Now you want to be excellent at the relationship craft underneath it — the conversations, the repairs, the emotional fluency."),
        .init(id: "couple_evolving", context: .coupleEvolving, accent: .inferno,
              title: "We're rethinking our structure", subtitle: "Expanding, reorienting, or rebuilding our dynamic",
              detail: "Something about how you've set this up needs to evolve. We'll help you think through what that means and how to move through it without losing what matters."),
        .init(id: "couple_experienced_undecided", context: .coupleExperiencedUndecided, accent: .ember,
              title: "None of these quite fit", subtitle: "We just want to keep growing in whatever way fits",
              detail: "That's a legitimate place to be. You don't need a category — we'll focus on what's useful and let you steer."),
    ]
}

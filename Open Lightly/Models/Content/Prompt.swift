import Foundation

// MARK: - Prompt Model
// Represents a single prompt card in Open Lightly

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let highlightWords: [String]
    let category: PromptCategory
    let difficulty: PromptDifficulty
    let meta: String
    let isSensitive: Bool
    let canSkip: Bool
    let whoStarts: WhoStarts
    
    init(
        id: UUID = UUID(),
        text: String,
        highlightWords: [String] = [],
        category: PromptCategory = .prompt,
        difficulty: PromptDifficulty = .easy,
        meta: String = "",
        isSensitive: Bool = false,
        canSkip: Bool = true,
        whoStarts: WhoStarts = .partnerA
    ) {
        self.id = id
        self.text = text
        self.highlightWords = highlightWords
        self.category = category
        self.difficulty = difficulty
        self.meta = meta.isEmpty ? whoStarts.displayText : meta
        self.isSensitive = isSensitive
        self.canSkip = canSkip
        self.whoStarts = whoStarts
    }
    
    /// Auto-derive CardIntensity from difficulty
    var intensity: CardIntensity {
        CardIntensity.from(difficulty: difficulty.rawValue)
    }
}

// MARK: - Enums

enum PromptCategory: String, Codable, CaseIterable, Hashable {
    case prompt     = "Prompt"
    case reflect    = "Reflect"
    case deepDive   = "Deep Dive"
    case explore    = "Explore"
    case fantasy    = "Fantasy"
    case desireMap  = "Desire Map"
    case ultimate   = "Ultimate"
    
    var displayName: String { rawValue }
}

enum PromptDifficulty: String, Codable, CaseIterable, Hashable {
    case easy       = "Easy"
    case light      = "Light"
    case medium     = "Medium"
    case deep       = "Deep"
    case sensitive  = "Sensitive"
    case ultimate   = "Ultimate"
    
    var displayName: String { rawValue }
    
    /// Sort order for filtering
    var sortOrder: Int {
        switch self {
        case .easy:      return 0
        case .light:     return 1
        case .medium:    return 2
        case .deep:      return 3
        case .sensitive: return 4
        case .ultimate:  return 5
        }
    }
}

enum WhoStarts: String, Codable, CaseIterable, Hashable {
    case partnerA  = "partnerA"
    case partnerB  = "partnerB"
    case either    = "either"
    case both      = "both"
    
    var displayText: String {
        switch self {
        case .partnerA: return "Partner A starts"
        case .partnerB: return "Partner B starts"
        case .either:   return "Either partner starts"
        case .both:     return "Both share"
        }
    }
}

// MARK: - Sample Data

extension Prompt {
    static let samples: [Prompt] = [
        Prompt(
            text: "What first attracted you to the idea of opening your relationship?",
            highlightWords: ["opening your relationship"],
            category: .prompt,
            difficulty: .easy,
            whoStarts: .partnerA
        ),
        Prompt(
            text: "What does emotional safety actually feel like to you?",
            highlightWords: ["emotional safety"],
            category: .prompt,
            difficulty: .easy,
            whoStarts: .partnerA
        ),
        Prompt(
            text: "How do you handle jealousy when it shows up unexpectedly?",
            highlightWords: ["jealousy"],
            category: .reflect,
            difficulty: .medium,
            isSensitive: true,
            whoStarts: .partnerB
        ),
        Prompt(
            text: "What's one boundary you've been afraid to say out loud?",
            highlightWords: ["boundary"],
            category: .deepDive,
            difficulty: .medium,
            whoStarts: .either
        ),
        Prompt(
            text: "Have you ever been curious about role play or power exchange?",
            highlightWords: ["role play", "power exchange"],
            category: .explore,
            difficulty: .deep,
            whoStarts: .both
        ),
        Prompt(
            text: "Describe a fantasy you haven't shared — your partner shares theirs too.",
            highlightWords: ["fantasy", "theirs too"],
            category: .fantasy,
            difficulty: .deep,
            isSensitive: true,
            whoStarts: .both
        ),
        Prompt(
            text: "What would change if you both said yes to everything for one night?",
            highlightWords: ["yes", "one night"],
            category: .reflect,
            difficulty: .sensitive,
            isSensitive: true,
            whoStarts: .both
        ),
        Prompt(
            text: "If there were no fear and no judgment — what would your ideal relationship actually look like?",
            highlightWords: ["no fear", "no judgment"],
            category: .ultimate,
            difficulty: .ultimate,
            isSensitive: true,
            canSkip: false,
            whoStarts: .both
        )
    ]
}

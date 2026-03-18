//
//  Card.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// Card.swift
// A single conversation prompt shown during a session.
//
// WHY STRUCT (not class)?
// Structs are value types — when you copy one, you get an
// independent copy. For simple data containers like this,
// structs are safer and faster. Apple recommends structs as
// your default choice.
//
// KEY FIELDS:
// - cardType determines how the session renders this card.
//   prompt = discussion only; educationPrompt = info then discuss;
//   education = info only; coolOff = grounding exercise.
// - isFree determines whether the card is accessible without
//   a purchase. Free tier gets 3-5 sample cards per session.
// - sortOrder is the intentional therapeutic sequence.
//   Cards are NEVER shuffled — order is clinically meaningful.
// - sensitivity (via Difficulty) signals how emotionally heavy
//   the card is. The session engine auto-inserts a coolOff card
//   every 3-4 deep cards.
// ============================================================

struct Card: Identifiable, Codable {

    // Unique identifier — auto-generated, never collides
    let id: UUID

    // Which therapeutic category this card belongs to
    let category: CategoryType

    // What kind of card — affects session rendering
    let cardType: CardType

    // The primary discussion prompt text
    let prompt: String

    // For educationPrompt cards: the informational block shown
    // above the prompt. nil for plain prompt cards.
    let educationText: String?

    // Optional short title shown above the prompt on the card
    let title: String?

    // Optional follow-up hint shown below the main prompt
    let followUp: String?

    // Who speaks first on this card
    let turnOrder: TurnOrder

    // How emotionally intense this card is
    let difficulty: Difficulty

    // Intentional therapeutic sequence (lower = earlier in session)
    // Cards are never shuffled — this order is clinically meaningful.
    let sortOrder: Int

    // Whether this card is accessible on the free tier
    let isFree: Bool

    // ── Initializer ──

    init(
        id: UUID = UUID(),
        category: CategoryType,
        cardType: CardType = .prompt,
        prompt: String,
        educationText: String? = nil,
        title: String? = nil,
        followUp: String? = nil,
        turnOrder: TurnOrder,
        difficulty: Difficulty,
        sortOrder: Int = 0,
        isFree: Bool = false
    ) {
        self.id = id
        self.category = category
        self.cardType = cardType
        self.prompt = prompt
        self.educationText = educationText
        self.title = title
        self.followUp = followUp
        self.turnOrder = turnOrder
        self.difficulty = difficulty
        self.sortOrder = sortOrder
        self.isFree = isFree
    }
}

// ============================================================
// MARK: - Placeholder Content
//
// 5 cards per category × 6 categories = 30 placeholder cards.
// These exist so screens have data to display during development.
// First 2 cards per category are marked isFree for the free tier.
//
// Cards follow therapeutic order: easy -> medium -> deep.
// Replace prompt strings with final clinically-informed copy.
// ============================================================

extension Card {

    static let allPlaceholders: [Card] = {
        CategoryType.allCases.flatMap { placeholders(for: $0) }
    }()

    static func placeholders(for type: CategoryType) -> [Card] {
        let turns: [TurnOrder] = [.partnerA, .partnerB, .together, .partnerA, .partnerB]
        let diffs: [Difficulty] = [.easy, .easy, .medium, .medium, .deep]

        return (0..<5).map { i in
            Card(
                category: type,
                cardType: i == 4 ? .educationPrompt : .prompt,
                prompt: placeholderPrompt(for: type, index: i),
                followUp: i == 4 ? "Take a breath before answering." : nil,
                turnOrder: turns[i],
                difficulty: diffs[i],
                sortOrder: i + 1,
                isFree: i < 2
            )
        }
    }

    private static func placeholderPrompt(for type: CategoryType, index: Int) -> String {
        switch type {

        case .relationshipHealth:
            return [
                "What's one thing your partner does that makes you feel truly heard?",
                "Describe a recent moment where you felt misunderstood. What happened?",
                "How do you prefer to receive difficult news — direct or softened?",
                "When you shut down during conflict, what's actually happening inside?",
                "What conversation have you been avoiding, and what makes it scary?"
            ][index]

        case .insecurities:
            return [
                "What does jealousy physically feel like in your body?",
                "Describe a time you felt jealous but didn't say anything. Why not?",
                "Your partner comes home glowing from a great date. Walk through your honest reaction.",
                "What makes you feel most emotionally secure in this relationship?",
                "What would your partner need to say or do to help you through a jealousy spiral?"
            ][index]

        case .sexualSatisfaction:
            return [
                "What does feeling sexually satisfied in this relationship look like to you?",
                "Is there a desire you've had but never voiced? What made it hard to say?",
                "How has your sexual connection changed over the course of this relationship?",
                "What's the difference between what you want sexually and what you ask for?",
                "If there were no judgment, what's one fantasy you'd want to explore together?"
            ][index]

        case .compatibility:
            return [
                "What style of non-monogamy, if any, feels most aligned with who you are?",
                "How do you imagine your relationship looking in five years if you pursue ENM?",
                "What does 'primary partner' mean to you — and do you want to be each other's?",
                "How much time per week feels right for you to spend with outside partners?",
                "What's the one thing you need your relationship structure to protect, no matter what?"
            ][index]

        case .boundaries:
            return [
                "Name one boundary you hold that you're completely confident about.",
                "Is there a limit you've never spoken out loud but have expected your partner to know?",
                "How do you want your partner to respond when you state a hard limit?",
                "Describe a time a boundary of yours was crossed. What happened after?",
                "What agreement would, if broken, make you question whether to continue?"
            ][index]

        case .nmLogistics:
            return [
                "Who in your life knows you're exploring non-monogamy — and who do you want to know?",
                "How would you handle running into your partner's date in public?",
                "What are your expectations about safer sex with outside partners — and are they negotiable?",
                "How do you want to handle social media — visible relationship, or private?",
                "Your partner wants to spend a holiday with their other partner. Walk through how you'd feel."
            ][index]
        }
    }
}

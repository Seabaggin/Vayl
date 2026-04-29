import Foundation

struct ContextOption: Identifiable {
    let id: String
    let emotionalRegister: EmotionalRegister  // what this selection sets on OnboardingData
    let intensity: ContextIntensity
    let title: String
    let subtitle: String
    let detail: String
}

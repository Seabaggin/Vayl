//
//  ExperienceLevel.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/12/26.
//


// ExperienceLevelView.swift
// Open Lightly
//
// Onboarding screen: binary experience level selection.
// Curious → foundational content, primers, slower pacing
// Experienced → skip basics, deeper content faster

import SwiftUI

// MARK: - Experience Level Enum
// Move this to your models file if you have one.
// Delete from here if it already exists elsewhere.
enum ExperienceLevel: String, Codable, CaseIterable {
    case curious
    case experienced
    
    var title: String {
        switch self {
        case .curious: return "Curious"
        case .experienced: return "Experienced"
        }
    }
    
    var icon: String {
        switch self {
        case .curious: return "🌱"
        case .experienced: return "🌳"
        }
    }
    
    var description: String {
        switch self {
        case .curious:
            return "I'm exploring what ethical non‑monogamy means for me."
        case .experienced:
            return "I've practiced ENM and want to go deeper."
        }
    }
}

// MARK: - View
struct ExperienceLevelView: View {
    
    // nil = nothing selected yet
    @State private var selectedLevel: ExperienceLevel? = nil
    
    // Parent view handles navigation when user taps Continue
    var onContinue: (ExperienceLevel) -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            
            // MARK: Header
            VStack(spacing: 12) {
                Text("Where are you on this journey?")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("No wrong answers. This shapes your starting content.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // MARK: Two Option Cards
            VStack(spacing: 16) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    // Card button for each option
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLevel = level
                        }
                    } label: {
                        HStack(spacing: 16) {
                            // Emoji
                            Text(level.icon)
                                .font(.largeTitle)
                            
                            // Title + description
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(level.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedLevel == level
                                        ? Color.purple
                                        : Color.white.opacity(0.06),
                                    lineWidth: selectedLevel == level ? 2.5 : 1.5
                                )
                        )
                        // Slight scale bump when selected
                        .scaleEffect(selectedLevel == level ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // MARK: Continue Button
            // Disabled until user picks one
            Button {
                if let level = selectedLevel {
                    onContinue(level)
                }
            } label: {
                Text("Continue")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedLevel != nil
                                  ? Color.purple
                                  : Color.white.opacity(0.06))
                    )
            }
            .disabled(selectedLevel == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.012, green: 0.012, blue: 0.02)) // #030305
    }
}

// MARK: - Preview
#Preview {
    ExperienceLevelView { level in
        print("Selected: \(level.rawValue)")
    }
    .preferredColorScheme(.dark)
}
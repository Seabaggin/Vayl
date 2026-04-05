// OnboardingNavBar.swift
// Open Lightly
//
// Reusable nav row: back chevron + centered progress bar.
// Used at the top of every onboarding screen that shows navigation.
import SwiftUI

// MARK: - Private Modifiers

private struct BackButtonModifier: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.0)
                        )
                        
                )
                .shadow(color: AppColors.magenta.opacity(0.12), radius: 8, y: 2)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 16, y: 2)
        } else {
            content
                .padding(13)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )
                       
                )
                .shadow(color: AppColors.purple.opacity(0.22), radius: 8)
                .shadow(color: AppColors.cyan.opacity(0.12), radius: 20)
                .shadow(color: AppColors.purple.opacity(0.08), radius: 28)
        }
    }
}

// MARK: - View

struct OnboardingNavBar: View {
    let currentStep: Int
    let totalSteps: Int
    var onBack: (() -> Void)?  // nil = no back button (ground rules, priming, arrival)
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .light
                                         ? AppColors.wineDark
                                         : Color.white.opacity(0.80))
                        .modifier(BackButtonModifier(colorScheme: colorScheme))
                }
                .accessibilityLabel("Go back")
            } else {
                // Match the 38pt rendered size of the back button
                Color.clear.frame(width: 38, height: 38)
                    .padding(.trailing, 0) 
            }
            
            Spacer()
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
            Spacer()
            
            // FIXED: was 18pt — must match back button total size (18 icon + 10 pad each side = 38)
            Color.clear.frame(width: 38, height: 38)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Dark
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity)

        // Light
        ZStack {
            AppColors.lightPageBg.ignoresSafeArea()
            VStack(spacing: 40) {
                OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: { })
                OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: nil)
            }
            .padding(24)
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity)
    }
}

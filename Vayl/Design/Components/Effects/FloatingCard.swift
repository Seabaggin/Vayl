//
//  FloatingCardSpec.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/1/26.
//


// Design/Components/Effects/FloatingCard.swift
// Open Lightly
//
// Individual floating glass card for OnboardingCuriosityPickerView.
// Used as the cardContent closure inside FloatingStack.
//
// Dark:  deep purple fill + AngularGradient hot border + shimmer sweep
// Light: frost fill + warm aurora border + shadow spread
//
// Float physics are driven by the parent via floatY, floatRot, gravity.
// This view owns only its press state and mounted entrance.

import SwiftUI

// MARK: - FloatingCardSpec

struct FloatingCardSpec: Identifiable {
    let id:         String
    let lead:       String   // 3-5 word hook
    let full:       String   // complete sentence
    let xFrac:      Double   // fractional x position in cluster frame
    let yFrac:      Double   // fractional y position in cluster frame
    let floatPhase: Double   // unique phase so cards never drift in sync
}

// MARK: - FloatingCard

struct FloatingCard: View {
    
    let spec:          FloatingCardSpec
    let isSelected:    Bool

    var floatY:        CGFloat = 0
    var floatRot:      Double  = 0
    var gravity:       CGSize  = .zero
    var hue:           Double  = 200
    var tick:          Double  = 0
    var targetOpacity: Double  = 1.0
    var cardWidth:     CGFloat = 168
    var tintColor:     Color   = .clear
    var onTap:         () -> Void

    @State private var mounted  = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var cardCornerRadius: CGFloat { AppRadius.container }

    private var shimmerOffset: CGFloat {
        // Oscillates ±18pt around card center — no sweep, no reset
        CGFloat(sin(tick * 0.028) * 4)
    }
    
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(spec.full)
                .font(AppFonts.body(16, weight: isSelected ? .semibold : .medium, relativeTo: .body))
                .foregroundStyle(isLight
                    ? AppColors.textBody
                    : Color.white.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .frame(width: cardWidth, alignment: .leading)
        .background(glassSurface)
        .frame(width: cardWidth)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .offset(
            x: gravity.width,
            y: floatY + gravity.height
        )
        .rotationEffect(.degrees(floatRot))
        .opacity(mounted ? targetOpacity : 0)
        .animation(AppAnimation.spring, value: isSelected)
        .animation(AppAnimation.enter, value: targetOpacity)
        .onAppear {
            // intentional exception: slower mount entrance (response:0.5) than AppAnimation.spring for a softer initial float-in
            withAnimation(AppAnimation.spring.delay(0.08)) {
                mounted = true
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .accessibilityLabel(spec.lead)
        .accessibilityHint(spec.full)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Glass surface

private var glassSurface: some View {
      ZStack {
          // Base fill
          ZStack {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .fill(surfaceFill)
              // Set-identity tint layer — baked under gloss
              if tintColor != .clear {
                  RoundedRectangle(cornerRadius: cardCornerRadius)
                      .fill(tintColor)
              }
          }

          // Gloss + shimmer — all clipped together to card bounds
          ZStack {
              // Top edge highlight
              LinearGradient(
                  colors: [
                      Color.white.opacity(isLight ? 0.55 : 0.08),
                      Color.white.opacity(isLight ? 0.15 : 0.02),
                      Color.clear,
                  ],
                  startPoint: .top,
                  endPoint:   .init(x: 0.5, y: 0.45)
              )

              // Diagonal gloss — top-left corner catch
              LinearGradient(
                  colors: [
                      Color.white.opacity(isLight ? 0.25 : 0.06),
                      Color.clear,
                  ],
                  startPoint: .topLeading,
                  endPoint:   .init(x: 0.6, y: 0.6)
              )

              // Shimmer oscillation — selected dark only
              if isSelected && !isLight {
                  LinearGradient(
                      colors: [
                          .clear,
                          Color.white.opacity(0.03),
                          Color.white.opacity(0.06 + sin(tick * 0.028) * 0.04),
                          Color.white.opacity(0.03),
                          .clear,
                      ],
                      startPoint: .leading,
                      endPoint:   .trailing
                  )
                  .frame(width: cardWidth * 0.28, height: 140)
                  .offset(x: shimmerOffset)
                  .blur(radius: 4)
              }
          }
          .frame(width: cardWidth)
          .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
          .allowsHitTesting(false)

          // Border — outside clip so stroke never gets cut
          if isSelected {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .strokeBorder(
                      LinearGradient(
                          colors: isLight
                              ? [AppColors.accentTertiary, AppColors.progressBarLeading, AppColors.safetyAccent]
                              : [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                          startPoint: .topLeading,
                          endPoint:   .bottomTrailing
                      ),
                      lineWidth: 2.0
                  )
          } else {
              RoundedRectangle(cornerRadius: cardCornerRadius)
                  .strokeBorder(
                      isLight
                          ? AppColors.borderSubtle
                          : Color.white.opacity(0.09),
                      lineWidth: 1
                  )
          }
      }
      .frame(width: cardWidth)
  }

    // MARK: - Surface fill

    private var surfaceFill: AnyShapeStyle {
        if isLight {
            return isSelected
                ? AnyShapeStyle(AppColors.glassFrostPillSelected)
                : AnyShapeStyle(AppColors.glassFrostPill)
        } else {
            if isSelected {
                return AnyShapeStyle(LinearGradient(
                    colors: [AppColors.modalBackground, AppColors.cardBackground],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                ))
            } else {
                // Blend tint over base surface
                return AnyShapeStyle(LinearGradient(
                    colors: [
                        AppColors.pillSurface.opacity(0.85),
                        AppColors.pillSurfaceBottom.opacity(0.85),
                    ],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                ))
            }
        }
    }
}

// MARK: - Previews

private let previewSpec1 = FloatingCardSpec(
    id: "want_harder",
    lead: "What I want is harder",
    full: "I know what I don't want. What I actually want is harder.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 0.0
)

private let previewSpec2 = FloatingCardSpec(
    id: "same_fight",
    lead: "The same fight, again",
    full: "I've had the same fight in more than one relationship.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 1.17
)

private let previewSpec3 = FloatingCardSpec(
    id: "blow_up",
    lead: "I blow up or shut down",
    full: "Sometimes I blow up or shut down and I don't know why.",
    xFrac: 0.0, yFrac: 0.0, floatPhase: 2.34
)

#Preview("Unselected — Dark") {
    VStack(spacing: AppSpacing.md) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: false,
            hue:        200,
            tick:       0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       0,
            onTap:      {}
        )
    }
    .padding(AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Selected — Dark") {
    VStack(spacing: AppSpacing.md) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       120,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: true,
            hue:        320,
            tick:       120,
            onTap:      {}
        )
    }
    .padding(AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

#Preview("Unselected — Light") {
    VStack(spacing: AppSpacing.md) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: false,
            hue:        200,
            tick:       0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       0,
            onTap:      {}
        )
    }
    .padding(AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Selected — Light") {
    VStack(spacing: AppSpacing.md) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       120,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: true,
            hue:        320,
            tick:       120,
            onTap:      {}
        )
    }
    .padding(AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Mixed — Dark") {
    VStack(spacing: AppSpacing.md) {
        FloatingCard(
            spec:       previewSpec1,
            isSelected: true,
            hue:        200,
            tick:       80,
            targetOpacity: 1.0,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec2,
            isSelected: false,
            hue:        280,
            tick:       80,
            targetOpacity: 0.15,
            onTap:      {}
        )
        FloatingCard(
            spec:       previewSpec3,
            isSelected: false,
            hue:        160,
            tick:       80,
            targetOpacity: 0.12,
            onTap:      {}
        )
    }
    .padding(AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.pageBackground)
    .preferredColorScheme(.dark)
}

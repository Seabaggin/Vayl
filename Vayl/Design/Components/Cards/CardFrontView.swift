//
//  CardFrontView.swift
//  Open Lightly
//

import SwiftUI

struct CardFrontView: View {
   let cardSize:           CGSize
   let cornerRadius:       CGFloat
   let isLight:            Bool
   let arrowTriggered:     Bool
   let sitWithThisVisible: Bool
   let onTap:              () -> Void
   let fuseProgress:       Double
   var questionVisible:    Bool = true
   var pillsVisible:       Bool = false
   var onPillSelected:     ((CardRevealPill) -> Void)? = nil

   var body: some View {
       PremiumCardShell(
           isLight: isLight,
           cornerRadius: cornerRadius,
           fuseProgress: fuseProgress
       ) {
           VStack(spacing: AppSpacing.md) {
               Text("YOUR FIRST CARD")
                   .font(AppFonts.overline)
                   .tracking(2.0)
                   .foregroundStyle(AppColors.textTertiary)
                   .padding(.top, AppSpacing.md)

               Spacer(minLength: 0)

               ZStack {
                   // Question — dissolves out when pillsVisible becomes true
                   questionTextView
                       .opacity(pillsVisible ? 0 : (questionVisible ? 1 : 0))
                       .offset(y: pillsVisible ? -12 : 0)
                       .animation(AppAnimation.enter, value: pillsVisible)

                   // Pills — dissolve in when pillsVisible becomes true
                   if pillsVisible {
                       pillsView
                           .opacity(pillsVisible ? 1 : 0)
                           .offset(y: pillsVisible ? 0 : 12)
                           .animation(AppAnimation.enter, value: pillsVisible)
                           .transition(.opacity.combined(with: .offset(y: 12)))
                   }
               }

               Spacer(minLength: 0)
               Spacer(minLength: AppSpacing.xl)
           }
           .frame(width: cardSize.width, height: cardSize.height)
       }
       .cardShadows(isLight: isLight)
       .contentShape(Rectangle())
       .onTapGesture { onTap() }
   }

   // MARK: - Question Text View

   private var questionTextView: some View {
       VStack(spacing: AppSpacing.sm) {
           Text("What would you desire if nobody")
               .font(AppFonts.body(19, weight: .semibold, relativeTo: .title3))
               .foregroundStyle(
                   isLight ? AppColors.textBody : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)

           LivingText(
               text: "not even you,",
               font: AppFonts.body(20, weight: .semibold, relativeTo: .title3)
           )

           Text("would judge the answer?")
               .font(AppFonts.body(19, weight: .semibold, relativeTo: .title3))
               .foregroundStyle(
                   isLight ? AppColors.textBody : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)
       }
       .padding(.horizontal, AppSpacing.xl)
   }

   // MARK: - Pills View

   private var pillsView: some View {
       VStack(spacing: AppSpacing.sm) {
           ForEach(CardRevealPill.allCases) { pill in
               Button(action: {
                   onPillSelected?(pill)
               }) {
                   Text(pill.rawValue)
                       .font(AppFonts.body(17, weight: .semibold, relativeTo: .body))
                       .foregroundStyle(AppColors.textPrimary)
                       .frame(maxWidth: .infinity)
                       .frame(height: 44)
                       .background(
                           RoundedRectangle(cornerRadius: AppRadius.md)
                               .fill(Color.white.opacity(0.08))
                       )
               }
           }
       }
       .padding(.horizontal, AppSpacing.xl)
   }


}

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
           VStack(spacing: 16) {
               Text("YOUR FIRST CARD")
                   .font(AppFonts.overline)
                   .tracking(2.0)
                   .foregroundStyle(
                       isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                   )
                   .padding(.top, 20)

               Spacer(minLength: 0)

               ZStack {
                   // Question — dissolves out when pillsVisible becomes true
                   questionTextView
                       .opacity(pillsVisible ? 0 : (questionVisible ? 1 : 0))
                       .offset(y: pillsVisible ? -12 : 0)
                       .animation(.easeInOut(duration: 0.45), value: pillsVisible)

                   // Pills — dissolve in when pillsVisible becomes true
                   if pillsVisible {
                       pillsView
                           .opacity(pillsVisible ? 1 : 0)
                           .offset(y: pillsVisible ? 0 : 12)
                           .animation(.easeOut(duration: 0.4), value: pillsVisible)
                           .transition(.opacity.combined(with: .offset(y: 12)))
                   }
               }

               Spacer(minLength: 0)
               Spacer(minLength: 28)
           }
           .frame(width: cardSize.width, height: cardSize.height)
       }
       .cardShadows(isLight: isLight)
       .contentShape(Rectangle())
       .onTapGesture { onTap() }
   }

   // MARK: - Question Text View

   private var questionTextView: some View {
       VStack(spacing: 8) {
           Text("What would you desire if nobody")
               .font(AppFonts.body(19, weight: .semibold))
               .foregroundStyle(
                   isLight ? AppColors.lightCardTitle : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)

           LivingText(
               text: "not even you,",
               font: AppFonts.body(20, weight: .semibold)
           )

           Text("would judge the answer?")
               .font(AppFonts.body(19, weight: .semibold))
               .foregroundStyle(
                   isLight ? AppColors.lightCardTitle : AppColors.textPrimary
               )
               .multilineTextAlignment(.center)
       }
       .padding(.horizontal, 28)
   }

   // MARK: - Pills View

   private var pillsView: some View {
       VStack(spacing: 12) {
           ForEach(CardRevealPill.allCases) { pill in
               Button(action: {
                   onPillSelected?(pill)
               }) {
                   Text(pill.rawValue)
                       .font(AppFonts.body(17, weight: .semibold))
                       .foregroundStyle(AppColors.textPrimary)
                       .frame(maxWidth: .infinity)
                       .frame(height: 44)
                       .background(
                           RoundedRectangle(cornerRadius: 12)
                               .fill(Color.white.opacity(0.08))
                       )
               }
           }
       }
       .padding(.horizontal, 28)
   }


}

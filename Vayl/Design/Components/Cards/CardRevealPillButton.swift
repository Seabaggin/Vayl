//
//  CardRevealPillButton.swift
//  Open Lightly
//

import SwiftUI

struct CardRevealPillButton: View {
   let pill:          CardRevealPill
   let index:         Int
   let selectedPill:  CardRevealPill?
   let selectedScale: CGFloat
   let borderWidth:   CGFloat
   let globalVisible: Bool
   let revealed:      Bool
   let isLight:       Bool
   let onTap:         () -> Void

   @State private var entranceVisible = false

   private var isSelected: Bool { selectedPill == pill }
   private var isOther:    Bool { selectedPill != nil && !isSelected }

   // Heading has a 120ms head-start; pills stagger at 70ms each
   private var entranceDelay: Double { Double(index) * 0.07 + 0.12 }

   var body: some View {
       Button {
           guard selectedPill == nil else { return }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
           onTap()
       } label: {
           Text(pill.rawValue)
               .font(AppFonts.bodyMedium)
               .foregroundStyle(
                   isSelected
                       ? (isLight ? AppColors.textBody : AppColors.textPrimary)
                       : (isLight ? AppColors.textSecondary : Color.white.opacity(0.75))
               )
               .frame(maxWidth: .infinity)
               .frame(height: 40)
               .background(pillBackground)
               .overlay(pillBorder)
               .clipShape(Capsule())
       }
       .buttonStyle(.plain)
       // Scale — driven by parent selectedPillScale during beat 1
       .scaleEffect(isSelected ? selectedScale : 1.0)
       .animation(
           AppAnimation.spring,
           value: selectedScale
       )
       // Entrance stagger — rise from y+10
       .opacity(entranceVisible ? (isOther && !globalVisible ? 0 : 1) : 0)
       .offset(y: entranceVisible ? (isOther && !globalVisible ? 4 : 0) : 10)
       .animation(
           AppAnimation.standard.delay(entranceDelay),
           value: entranceVisible
       )
       // Beat 3 sink — independent from entrance
       .animation(AppAnimation.standard, value: globalVisible)
       .disabled(isOther)
       .accessibilityLabel(pill.rawValue)
       .accessibilityAddTraits(isSelected ? .isSelected : [])
       .onChange(of: revealed) { _, newVal in
           if newVal { entranceVisible = true }
       }
       .onAppear {
           if revealed { entranceVisible = true }
       }
   }

   @ViewBuilder
   private var pillBackground: some View {
       Capsule()
           .fill(
               isSelected
                   ? (isLight
                       ? AnyShapeStyle(AppColors.glassFrostPillSelected)
                       : AnyShapeStyle(Color.white.opacity(0.10)))
                   : (isLight
                       ? AnyShapeStyle(AppColors.glassFrostPill)
                       : AnyShapeStyle(AppColors.cardBackground))
           )
   }

   @ViewBuilder
   private var pillBorder: some View {
       if isSelected {
           if isLight {
               Capsule()
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: borderWidth)
           } else {
               Capsule()
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: borderWidth)
           }
       } else {
           Capsule()
               .strokeBorder(
                   AppColors.borderSubtle,
                   lineWidth: 1.5
               )
       }
   }
}

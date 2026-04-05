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
                       ? (isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                       : (isLight ? AppColors.wineDark : Color.white.opacity(0.75))
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
           .spring(response: 0.35, dampingFraction: 0.7),
           value: selectedScale
       )
       // Entrance stagger — rise from y+10
       .opacity(entranceVisible ? (isOther && !globalVisible ? 0 : 1) : 0)
       .offset(y: entranceVisible ? (isOther && !globalVisible ? 4 : 0) : 10)
       .animation(
           .easeOut(duration: 0.35).delay(entranceDelay),
           value: entranceVisible
       )
       // Beat 3 sink — independent from entrance
       .animation(.easeIn(duration: 0.35), value: globalVisible)
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
                       ? AnyShapeStyle(AppColors.lightFrostPillSel)
                       : AnyShapeStyle(Color.white.opacity(0.10)))
                   : (isLight
                       ? AnyShapeStyle(AppColors.lightFrostPill)
                       : AnyShapeStyle(AppColors.cardBg))
           )
   }

   @ViewBuilder
   private var pillBorder: some View {
       if isSelected {
           if isLight {
               Capsule()
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: borderWidth)
           } else {
               Capsule()
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: borderWidth)
           }
       } else {
           Capsule()
               .strokeBorder(
                   isLight ? AppColors.lightBorder : AppColors.border,
                   lineWidth: 1.5
               )
       }
   }
}

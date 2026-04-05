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
       ZStack {
           // Base fill
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(cardFill)

           // Ambient wash — top-left corner
           RoundedRectangle(cornerRadius: cornerRadius)
               .fill(
                   RadialGradient(
                       colors: isLight
                           ? [AppColors.magenta.opacity(0.06), Color.clear]
                           : [AppColors.purple.opacity(0.15),  Color.clear],
                       center:      UnitPoint(x: 0.3, y: 0.2),
                       startRadius: 0,
                       endRadius:   180
                   )
               )

           // Border
           if isLight {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
           } else {
               RoundedRectangle(cornerRadius: cornerRadius)
                   .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
           }

           // Burn cover — occludes the gradient border with card background
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Consumed segment — paints over the gradient border with the
               // card's own background color, creating the burn illusion.
               // lineWidth is wider than the border (4.0 vs 2.5) so it
               // fully occludes the gradient with no fringing.
               let startOffset: Double = 0.75  // mid-right edge, burns clockwise to top-right almost immediately
               let end = startOffset + fuseProgress

               if end <= 1.0 {
                   // No wrap needed
                   let consumed = path.trimmedPath(from: startOffset, to: end)
                   ctx.stroke(consumed,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               } else {
                   // Wrap — draw two segments
                   let seg1 = path.trimmedPath(from: startOffset, to: 1.0)
                   let seg2 = path.trimmedPath(from: 0, to: end - 1.0)
                   ctx.stroke(seg1,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                   ctx.stroke(seg2,
                       with: .color(isLight
                           ? Color(red: 1.00, green: 0.99, blue: 1.00)
                           : Color(red: 0.051, green: 0.043, blue: 0.122)),
                       style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
               }
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

           // Spark head — glowing spark at the burn position
           Canvas { ctx, canvasSize in
               guard fuseProgress > 0, fuseProgress < 1.0 else { return }
               let rect = CGRect(
                   x: 1.25,
                   y: 1.25,
                   width:  canvasSize.width  - 2.5,
                   height: canvasSize.height - 2.5
               )
               let fullPath = RoundedRectangle(cornerRadius: cornerRadius - 1.25)
                   .path(in: rect)
               let path = fullPath

               // Get the point at the current burn position
               let startOffset: Double = 0.75
               let sparkPos = (startOffset + fuseProgress)
                   .truncatingRemainder(dividingBy: 1.0)
               let head = path.trimmedPath(
                   from: max(0, sparkPos - 0.001),
                   to:   sparkPos)
               guard let pt = head.currentPoint else { return }

               let r = CGFloat(3.5)
               let sparkRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

               // Map spark's actual XY position to diagonal gradient progress.
               // Gradient runs topLeading → bottomTrailing so we average
               // normalized X and Y to get a 0→1 diagonal progress value.
               let gradientT = (pt.x / canvasSize.width * 0.5)
                             + (pt.y / canvasSize.height * 0.5)

               let sparkColor: Color = {
                   let t = max(0, min(1, gradientT))
                   if isLight {
                       // purple(0.0) → magenta(0.5) → gold(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.magenta,
                               to:   AppColors.gold,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   } else {
                       // cyan(0.0) → purple(0.5) → magenta(1.0)
                       if t < 0.5 {
                           return interpolate(
                               from: AppColors.cyan,
                               to:   AppColors.purple,
                               t:    t / 0.5
                           )
                       } else {
                           return interpolate(
                               from: AppColors.purple,
                               to:   AppColors.magenta,
                               t:    (t - 0.5) / 0.5
                           )
                       }
                   }
               }()

               // Outer atmospheric glow
               var outerCtx = ctx
               outerCtx.addFilter(.blur(radius: 6))
               outerCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -4, dy: -4)),
                   with: .color(sparkColor.opacity(0.5))
               )

               // Mid glow
               var midCtx = ctx
               midCtx.addFilter(.blur(radius: 3))
               midCtx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: -1, dy: -1)),
                   with: .color(sparkColor.opacity(0.7))
               )

               // Core
               ctx.fill(
                   Circle().path(in: sparkRect),
                   with: .color(sparkColor)
               )

               // Hot white center
               ctx.fill(
                   Circle().path(in: sparkRect.insetBy(dx: r * 0.45, dy: r * 0.45)),
                   with: .color(.white.opacity(0.95))
               )
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
           .allowsHitTesting(false)

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
           // ↓ THIS IS THE FIX — VStack must claim the card's full frame
           // so Spacers have room to distribute. Without this, the ZStack
           // collapses the VStack to its content height and Spacers = 0.
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

   private var cardFill: some ShapeStyle {
       isLight
           ? AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 1.00, green: 0.99, blue: 1.00),
                   Color(red: 0.98, green: 0.97, blue: 0.99),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
           : AnyShapeStyle(LinearGradient(
               colors: [
                   Color(red: 0.051, green: 0.043, blue: 0.122),
                   Color(red: 0.031, green: 0.024, blue: 0.094),
               ],
               startPoint: .topLeading,
               endPoint:   .bottomTrailing))
   }

   private func interpolate(from: Color, to: Color, t: Double) -> Color {
       let t = max(0, min(1, t))
       let fromUI = UIColor(from)
       let toUI   = UIColor(to)
       var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
       var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
       fromUI.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
       toUI.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
       return Color(
           red:   Double(r1 + (r2 - r1) * t),
           green: Double(g1 + (g2 - g1) * t),
           blue:  Double(b1 + (b2 - b1) * t),
           opacity: Double(a1 + (a2 - a1) * t)
       )
   }
}

//
//  ProjectedTextView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/9/26.
//

//
//  ProjectedTextView.swift
//  Vayl
//

// Features/Onboarding/Renderers/ProjectedTextView.swift

import SwiftUI

/// Dealer text projected onto the felt surface.
/// Positioned above the table horizon. Never floating UI.
/// Driven by VaylDirector.projectedText and projectedTextVisible.
///
/// Visual spec (implemented):
///   - Shadow beneath: AppColors.shadowDeep, blur 10 offsetY 3 — the line sits ON the felt
///   - Entrance: scaleY 0.94→1.0 over AppAnimation.textProject (opacity fade is the
///     caller's `.transition(.opacity)` — one owner per property)
///   - Spectrum line beneath (2pt, 9% opacity) — projection glow on felt
///   - Font: single-sourced from AppDealerTyping.font (dealer voice decision superseded
///     the original italic-serif note — one dealer, one voice)
///   - Warm amber tint via AppColors.tableProjectedText (rgba 245,235,215,0.90)
///
/// This view never responds to gestures and never holds transient UI state.
struct ProjectedTextView: View {
    let text: String
    let screenSize: CGSize
    /// Vertical anchor as a fraction of screen height. Defaults to the felt table
    /// horizon (where the projected dealer line lives). Callers that anchor the dealer
    /// elsewhere pass their own fraction without forking the styling.
    var anchorYFrac: CGFloat = AppLayout.tableHorizonYFrac
    /// Optical offset above the anchor, in points.
    var yOffset: CGFloat = -28
    /// Single-line callers (e.g. the ContextPhase headline) set this to reveal the ACTUAL
    /// typed substring, which grows symmetrically from the centre instead of filling into a
    /// pre-laid-out, left-anchored full line. Only safe for text that stays on ONE line —
    /// multi-line text must keep the default (clear-tail) layout to avoid mid-type re-wrap.
    var centerGrow: Bool = false

    @State private var revealedCount: Int = 0
    /// Drives the projection entrance — scaleY 0.94→1.0 over textProject as the line
    /// lands on the felt (the documented "project onto the surface" feel). RM: instant.
    @State private var entered: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Projection surface spec — tuned reference values from the render TODO
    // (same idiom as the file's yOffset: documented literals pending layout tokens).
    /// Shadow blur beneath the line — the projection sits ON the felt, so the
    /// shadow is tight, not a floating-card drop (spec: blur 10).
    private let shadowBlur: CGFloat = 10
    /// Shadow vertical drop (spec: offsetY 3).
    private let shadowDropY: CGFloat = 3
    /// The spectrum line under the text is a glow caught on the felt, not a rule —
    /// atmospheric register (spec: 9%, in the aurora ≤~9% band).
    private let glowLineOpacity: Double = 0.09
    /// Optical gap between the text's last baseline and the projection glow line.
    private let glowLineGap: CGFloat = AppSpacing.xs

    var body: some View {
        Group {
            if centerGrow {
                // Real substring in a STATIC full-width, centre-aligned frame — the box
                // stops resizing per character, so .position no longer pins the leading
                // edge; the string expands left and right equally from centre.
                Text(String(text.prefix(revealedCount)))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(attributedReveal)
            }
        }
        // Dealer voice — single source (AppDealerTyping.font). Change the font once there.
        .font(AppDealerTyping.font)
        .foregroundStyle(AppColors.tableProjectedText)
        .multilineTextAlignment(.center)
        // Grounding shadow — the line is light cast ON the felt, so the shadow is
        // tight and directly beneath (never a floating-card elevation token).
        .shadow(color: AppColors.shadowDeep, radius: shadowBlur, y: shadowDropY)
        // Projection glow on the felt — a 2pt spectrum line under the text. Applied
        // AFTER the shadow so the glow itself casts nothing; strokes/lines are the
        // sanctioned home of the full spectrum gradient.
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.spectrumBorder)
                .frame(height: AppSpacing.xxs)
                .opacity(glowLineOpacity)
                .offset(y: glowLineGap + AppSpacing.xxs)
        }
        .padding(.horizontal, AppLayout.screenHPad)
        // Projection entrance — a slight vertical grow as the line lands on the felt,
        // co-timed with the caller's opacity fade (both AppAnimation.textProject).
        .scaleEffect(y: entered ? 1.0 : 0.94)
        .position(
            x: screenSize.width  * 0.50,
            y: screenSize.height * anchorYFrac + yOffset // optical offset — token pending AppLayout.projectedTextOffset
        )
        .allowsHitTesting(false)
        .task(id: text) { await typeOn(text) }
        .onAppear {
            guard !reduceMotion else { entered = true; return }
            withAnimation(AppAnimation.textProject) { entered = true }
        }
    }

    /// The FULL line laid out from the first frame — unrevealed characters are
    /// painted clear rather than absent, so the wrap geometry never changes
    /// mid-type (typing into a growing string re-wraps when a word crosses the
    /// line break, a visible layout flinch).
    private var attributedReveal: AttributedString {
        var line = AttributedString(text)
        let cut = line.index(line.startIndex, offsetByCharacters: min(revealedCount, text.count))
        line[cut...].foregroundColor = .clear
        return line
    }

    /// Reveal `target` character-by-character at the shared dealer cadence
    /// (AppDealerTyping.charDelay — the same rhythm NamePhase types at). Reduce Motion
    /// shows the full line immediately.
    private func typeOn(_ target: String) async {
        guard !reduceMotion else { revealedCount = target.count; return }
        revealedCount = 0
        var prev: Character?
        for char in target {
            let delay = AppDealerTyping.charDelay(char, prev: prev)
            try? await Task.sleep(for: .milliseconds(Int(delay)))
            if Task.isCancelled { revealedCount = target.count; return }
            revealedCount += 1
            prev = char
        }
    }
}

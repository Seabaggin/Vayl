// Design/Components/Navigation/MastheadCollapse.swift
// Vayl
//
// Couples a tab masthead to the scroll-linked hero recede: as the user scrolls,
// the masthead RESISTS leaving (parallax) while shrinking toward its leading
// edge — so the header and the hero read as one surface tilting into depth
// rather than two independent motions.
//
// "Shrink & leave", not "condense & pin": there is NO persistent chrome bar. The
// masthead still departs; it just doesn't depart eagerly.
//
// WHY PARALLAX IS LOad-BEARING (2026-07-19, after the first device pass):
// v1 had no parallax and shrank over 120pt. Bryan couldn't see it, and the
// reason is that THREE mechanisms remove this masthead at once:
//   1. it travels 1:1 with the scroll (1pt scrolled = 1pt gone),
//   2. `scrollTopEdgeFade` dissolves it — engaging over just 44pt, and the
//      masthead sits inside that top strip from the very start,
//   3. this shrink.
// The shrink is by far the weakest of the three: by the time it was ~40% done
// the mask had already eaten the wordmark and it was half off-screen. Shrinking
// harder does not fix that — the element is GONE, not too big.
//
// The fix is to buy the shrink a window to be perceived in. At `parallax` 0.45
// the masthead travels at 55% of scroll speed, so at full shrink it has moved
// 56pt instead of 96pt — roughly double the on-screen time, and the resistance
// itself reads as weight (the "gravitational" register the feel contract asks
// for). The shrink range also came down 120 → 90pt so it completes while the
// wordmark is still legible.
//
// The masthead's DISSOLVE stays owned by `scrollTopEdgeFade` (opacity), so this
// modifier deliberately touches scale + offset ONLY — never opacity — and the
// two can't double-dim each other.
//
// Reduce Motion: the transform is removed entirely (the header just scrolls,
// crisp). The applier gates this itself so a call site cannot forget it — the
// same discipline as AppMotion's staples.
//
// Apply to the masthead, INSIDE its horizontal padding so the leading-edge
// anchor tracks the padded text frame:
//   PlayMastheadView().mastheadCollapse(scrollY: scrollY)

import SwiftUI

extension View {
    /// Couples a tab masthead's shrink + parallax to the rest-zeroed scroll
    /// offset (pt) produced by `.mastheadScrollReader(_:)`. One input, two
    /// mappings (masthead + hero). See file header. Reduce-Motion-safe.
    func mastheadCollapse(scrollY: CGFloat) -> some View {
        modifier(MastheadCollapse(scrollY: scrollY))
    }

    /// Writes the REST-ZEROED vertical scroll offset into `offset` — 0 at rest,
    /// growing as the user scrolls down. Apply to a ScrollView; pair with
    /// `.mastheadCollapse(scrollY:)` on that scroll view's masthead.
    ///
    /// This is the ONE place the safe-area normalisation lives, and it exists
    /// precisely so no tab hand-rolls it wrong. `contentOffset.y` sits at
    /// ≈ −contentInsets.top at REST (the top inset the safe area adds), so a tab
    /// that reads it raw only starts responding after the inset's worth of
    /// scroll — which is how the Play masthead shrink ran entirely off-screen
    /// (2026-07-19). Adding the inset back makes 0 mean "at rest". Same
    /// normalisation `ScrollTopEdgeFade` already uses.
    ///
    /// iOS 18+ (onScrollGeometryChange). Below that the binding stays 0 — the
    /// masthead simply doesn't collapse, an acceptable degradation.
    func mastheadScrollReader(_ offset: Binding<CGFloat>) -> some View {
        modifier(MastheadScrollReader(offset: offset))
    }
}

private struct MastheadScrollReader: ViewModifier {
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, y in
                offset = y
            }
        } else {
            content
        }
    }
}

private struct MastheadCollapse: ViewModifier {
    /// Raw vertical scroll offset in points — the same value the hero's
    /// `collapse` is derived from. Taken raw (not pre-normalised) because
    /// parallax is a function of DISTANCE TRAVELLED, not of collapse progress.
    let scrollY: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // FEEL-GATE (Bryan, on device). Scrubbed transform magnitudes, not time
    // tokens — the same class of inline constant the hero recede uses.
    /// Points of scroll over which the shrink completes. Was 120 in v1, which
    /// finished long after the edge mask had eaten the wordmark.
    private let shrinkRange: CGFloat = 90
    /// The masthead settles to 66% of its resting size at full collapse.
    private let shrink: CGFloat = 0.34
    /// How hard the masthead resists leaving. 0 = travels 1:1 with the scroll
    /// (v1 — invisible); 0.45 = travels at 55% of scroll speed. See header.
    private let parallax: CGFloat = 0.45
    /// A small extra lift so the header reads as receding, not merely scrolling.
    private let lift: CGFloat = 6

    /// Downward scroll distance, floored at 0.
    ///
    /// MUST be clamped before anything else uses it. `contentOffset.y` is
    /// NEGATIVE at rest in a ScrollView with a top safe-area inset (it sits at
    /// roughly −contentInsets.top), and it goes further negative on rubber-band
    /// pull-down. An unclamped value drove `lag` negative, which offset the
    /// masthead UP into the Dynamic Island and clipped the wordmark at rest.
    private var y: CGFloat { max(0, scrollY) }

    /// 0 at rest → 1 once scrolled past the shrink range.
    private var progress: CGFloat {
        min(1, y / shrinkRange)
    }

    /// How far the masthead lags behind the content, in points. Grows only
    /// across the shrink window, then HOLDS — past that the masthead is already
    /// masked out, and letting the lag grow unbounded would drift it down onto
    /// the hero (offset doesn't affect layout, so it would overlap).
    /// Never negative: see `y`.
    private var lag: CGFloat {
        min(y, shrinkRange) * parallax
    }

    func body(content: Content) -> some View {
        content
            // Anchored to the leading edge: the wordmark shrinks toward its start,
            // staying left-aligned as it recedes (never drifting to center).
            .scaleEffect(reduceMotion ? 1 : 1 - progress * shrink, anchor: .topLeading)
            // +lag pushes DOWN against the content's upward travel (the resistance);
            // −lift is the small independent recede. Net on-screen motion is still
            // upward, just slower than the scroll.
            .offset(y: reduceMotion ? 0 : lag - progress * lift)
    }
}

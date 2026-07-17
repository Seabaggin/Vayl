// Features/Pulse/Components/PulseHistoryGrid.swift
//
// A 10-column grid of the user's last 30 check-ins — never "last 30 days."
//
// Each cell is a flat tinted-glass chip in its space's colour. Named spaces read as their
// tier core; Neutral is lavender silver, Uncharted is sage deep. A solo border-state dot
// crossfades between its two neighbouring space colours — all border dots share ONE
// TimelineView driver, each offset by its index so they don't pulse in sync.
//
// Me mode — one dot per cell in the space's colour.
// Us mode — split bead: your colour fills the top-left half, partner's the bottom-right,
//           seamed on the diagonal. Solid when you shared a space. Border states round to
//           their nearest named space in split view (no animation there).
//
// `collapsible` (2026-07-17) — the Map hero renders this as a 10-dot strip that expands to
// the full 30 in place, so history stops being a destination. Off by default: the Pulse
// pillar owns a screen and has nothing to hide. Collapsed and expanded are exclusive tap
// modes (whole-block vs per-dot), never nested.
//
// Visual reference: docs/mockups/map-pulse-hero-options.html — option A ("spoken invite").
// Predecessor: docs/prototypes/map-pulse-us.html — .grid / .sgd (upgraded).

import SwiftUI

struct PulseHistoryGrid: View {

    enum Mode {
        case me([(date: Date, space: PulseSpace)])
        case us([(date: Date, mine: PulseSpace, partner: PulseSpace?)], partnerName: String)
    }

    let mode: Mode

    /// When true the grid starts collapsed to a single `collapsedCount` row and the whole
    /// block taps to expand in place. Default false so the Pulse pillar (`PulseFullView`),
    /// which owns a screen and has no reason to hide anything, keeps rendering all 30.
    var collapsible: Bool = false
    /// How many of the most recent check-ins the collapsed strip shows.
    var collapsedCount: Int = 10

    /// Which cell (if any) is showing its date/space-name callout below the grid.
    @State private var selectedIndex: Int?
    /// Off-screen pause: border dots only run their timeline while the grid is visible.
    @State private var isVisible: Bool = false
    /// Collapsed/expanded state. Always true (and never toggled) when `collapsible` is false.
    @State private var isExpanded: Bool = false

    // MARK: - Layout

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 10)

    var body: some View {
        // Collapsed and expanded are EXCLUSIVE tap modes, never nested. Collapsed, the
        // whole block is one target that expands (dots inert). Expanded, the dots are the
        // targets and the header row collapses. A tap target inside a tap target is the
        // gesture conflict this shape exists to avoid.
        Group {
            if isCollapsed {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.standard) { isExpanded = true }
                } label: {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows all \(cells.count) check-ins")
            } else {
                content
            }
        }
        .animation(AppAnimation.fast, value: selectedIndex)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var content: some View {
        // Hoisted once per render — `cells` re-derives from `mode` on every read, and
        // the grid used to subscript it per row inside the ForEach (a full re-map of
        // the 30-entry history per dot). One local copy per body evaluation instead.
        let cells = self.visibleCells
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            header

            // The grid container is STATIC — only the individual border dots own a timeline, so
            // named / Neutral / Uncharted dots never re-render (no whole-grid flicker). Border
            // dots read the same absolute wall-clock, so they stay phase-coherent without a
            // shared parent driver (offset only by index).
            LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                ForEach(cells.indices, id: \.self) { i in
                    dot(cells, i)
                }
            }

            if !isCollapsed, let i = selectedIndex, i < cells.count {
                Text(calloutText(for: cells[i]))
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func dot(_ cells: [(date: Date, mine: PulseSpace, partner: PulseSpace?)], _ i: Int) -> some View {
        let d = AuraDot(space: cells[i].mine, partner: cells[i].partner, index: i, animate: isVisible)
        if isCollapsed {
            // Inert: the enclosing button owns the tap, and a11y reads the block, not 10 dots.
            d.accessibilityHidden(true)
        } else {
            d.contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedIndex = (selectedIndex == i) ? nil : i
                }
                // Colour-only meaning needs a text fallback for VoiceOver:
                // same date + space wording as the tap callout below.
                .accessibilityElement()
                .accessibilityLabel(accessibilityLabel(for: cells[i]))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows this check-in's details")
        }
    }

    // MARK: - Header (also the collapse affordance once expanded)

    @ViewBuilder
    private var header: some View {
        if collapsible {
            HStack(spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                Image(systemName: isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            // Expanded, the header is the way back. Collapsed, the whole block already
            // is the target, so this must not become a second one inside it.
            .contentShape(Rectangle())
            .modifier(CollapseTap(active: isExpanded) {
                withAnimation(AppAnimation.standard) {
                    isExpanded = false
                    selectedIndex = nil
                }
            })
        } else {
            Text(label)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Cell model

    /// Each cell: the date, your space, plus the partner's when it differs (nil = solid,
    /// i.e. same space or Me mode).
    private var cells: [(date: Date, mine: PulseSpace, partner: PulseSpace?)] {
        switch mode {
        case .me(let days):
            return days.map { (date: $0.date, mine: $0.space, partner: nil) }
        case .us(let pairs, _):
            return pairs.map { pair in
                guard let partner = pair.partner, partner != pair.mine else {
                    return (date: pair.date, mine: pair.mine, partner: nil)
                }
                return (date: pair.date, mine: pair.mine, partner: partner)
            }
        }
    }

    /// True only while a collapsible grid is showing its short strip.
    private var isCollapsed: Bool { collapsible && !isExpanded }

    /// The cells actually rendered. Collapsed shows the most recent `collapsedCount`;
    /// `suffix` because the history reads oldest to newest, so "recent" is the tail.
    private var visibleCells: [(date: Date, mine: PulseSpace, partner: PulseSpace?)] {
        let all = cells
        guard isCollapsed, all.count > collapsedCount else { return all }
        return Array(all.suffix(collapsedCount))
    }

    private func calloutText(for cell: (date: Date, mine: PulseSpace, partner: PulseSpace?)) -> String {
        let dateText = Self.dateFormatter.string(from: cell.date)
        // "·" not "—": no em dashes in copy (PRODUCT.md voice). The Us branch already
        // separated its two halves with "·", so the em dash was inconsistent with the
        // line's own punctuation as well as with the house rule.
        switch mode {
        case .me:
            return "\(dateText) · \(cell.mine.displayName)"
        case .us(_, let name):
            guard let partner = cell.partner else { return "\(dateText) · \(cell.mine.displayName)" }
            let displayName = name.isEmpty ? "partner" : name
            return "\(dateText) · you: \(cell.mine.displayName) · \(displayName): \(partner.displayName)"
        }
    }

    /// VoiceOver fallback for a colour-only cell — the same date + space wording
    /// as `calloutText`, without the visual separators.
    private func accessibilityLabel(for cell: (date: Date, mine: PulseSpace, partner: PulseSpace?)) -> String {
        let dateText = Self.dateFormatter.string(from: cell.date)
        var text = "\(dateText), \(cell.mine.displayName)"
        if case .us(_, let name) = mode, let partner = cell.partner {
            let displayName = name.isEmpty ? "partner" : name
            text += ", \(displayName): \(partner.displayName)"
        }
        return text
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    // MARK: - Label

    // Counts the actual cells so 4 entries never claim "30" (pre-TestFlight D12).
    private var label: String {
        let count = cells.count
        let base = count == 1 ? "Your first check-in" : "Your last \(count) check-ins"
        switch mode {
        case .me:
            return base
        case .us(_, let name):
            let displayName = name.isEmpty ? "partner" : name
            return "\(base) · you / \(displayName)"
        }
    }
}

// MARK: - Collapse tap

/// Attaches the collapse tap only while the grid is expanded. A concrete modifier rather
/// than an inline `if` in the @ViewBuilder: conditional view branches in a preview host
/// are what trip DebugReplaceableView's SIGABRT.
private struct CollapseTap: ViewModifier {
    let active: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if active {
            content
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Collapses the history")
        } else {
            content
        }
    }
}

// MARK: - Aura dot (static glossy orb, or an animated border crossfade)

private struct AuraDot: View {

    let space: PulseSpace
    var partner: PulseSpace?
    var index: Int  = 0
    /// Whether this dot may run its border-lean timeline (false while the grid is off-screen).
    var animate: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// sin() angular speed — one gentle lean cycle per cadence.
    private var speed: Double { 2 * .pi / AppAnimation.pulseHistoryBorderCadence }

    /// Only a SOLO border dot animates; everything else is a fixed view that never re-renders.
    private var isAnimatedBorder: Bool {
        partner == nil && space.borderCores != nil && animate && !reduceMotion && !AppAnimation.lowPower
    }

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            orb(d)
                .frame(width: d, height: d)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func orb(_ d: CGFloat) -> some View {
        ZStack {
            ZStack {
                fill
                // Glass sheen — soft reflected light across the upper half.
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.24), .white.opacity(0.04), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
            }
            .clipShape(Circle())

            // Glass edge — bright top rim fading to faint bottom.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: max(0.6, d * 0.035)
                )
        }
    }

    @ViewBuilder
    private var fill: some View {
        if let partner {
            // Split bead — border states round to their nearest named colour (dotCoreStatic),
            // no animation in split view.
            ZStack {
                Circle().fill(space.dotCoreStatic)
                    .clipShape(DiagonalHalf(topLeading: true))
                Circle().fill(partner.dotCoreStatic)
                    .clipShape(DiagonalHalf(topLeading: false))
                SeamLine()
                    .stroke(AppColors.borderActive, lineWidth: 0.6)
            }
        } else if let cores = space.borderCores, isAnimatedBorder {
            // A border dot lives BETWEEN two spaces, so it renders as a blend of both and only
            // LEANS gently toward each side — never a full crossfade (that reads as flashing).
            // Its own timeline reads the absolute clock so all border dots stay phase-coherent
            // without re-rendering their non-border neighbours. Lean = narrow band ±0.12 around
            // a 50/50 mix; index offset desyncs them. 🎚️ FEEL: amplitude + cadence on device.
            TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let lean = 0.5 + 0.12 * sin(t * speed + Double(index) * 0.4)
                borderBlend(cores, lean: lean)
            }
        } else if let cores = space.borderCores {
            // Border at rest (Reduce Motion / off-screen) — a fixed 50/50 blend, no timeline.
            borderBlend(cores, lean: 0.5)
        } else {
            // Solid — named tier, Neutral, or Uncharted.
            Circle().fill(space.dotCoreStatic)
        }
    }

    private func borderBlend(_ cores: (Color, Color), lean: Double) -> some View {
        ZStack {
            Circle().fill(cores.1)
            Circle().fill(cores.0).opacity(lean)
        }
    }
}

// The you/partner split runs along the anti-diagonal (top-right → bottom-left),
// matching the mockup's `linear-gradient(135deg, a 0 50%, b 50% 100%)`.
private struct DiagonalHalf: Shape {
    let topLeading: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if topLeading {
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        }
        p.closeSubpath()
        return p
    }
}

private struct SeamLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        return p
    }
}

// MARK: - Preview

#Preview("Me — glossy") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseHistoryGrid(mode: .me(previewMeDays))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

#Preview("Us — split") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        PulseHistoryGrid(mode: .us(previewUsPairs, partnerName: "Alex"))
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

private let previewMeSpaces: [PulseSpace] = [
    .expansive, .expansive, .receptive, .expansive, .expansive,
    .receptive, .expansive, .neutral, .reactive, .expansive,
    .receptive, .expansive, .borderExpansiveReceptive, .receptive, .expansive,
    .expansive, .receptive, .expansive, .uncharted, .expansive,
    .expansive, .receptive, .expansive, .expansive, .receptive,
    .expansive, .expansive, .protective, .expansive, .expansive
]

private let previewMeDays: [(date: Date, space: PulseSpace)] =
    previewMeSpaces.enumerated().map { offset, space in
        (date: Date.daysAgo(previewMeSpaces.count - 1 - offset), space: space)
    }

private let previewUsSpacePairs: [(PulseSpace, PulseSpace?)] = [
    (.expansive, .receptive), (.expansive, .expansive), (.receptive, .receptive),
    (.expansive, .protective), (.expansive, .expansive), (.receptive, .expansive),
    (.expansive, .expansive), (.expansive, .receptive), (.reactive, .protective),
    (.expansive, .expansive), (.receptive, .receptive), (.expansive, .receptive),
    (.expansive, .expansive), (.receptive, .reactive), (.expansive, .expansive),
    (.expansive, .receptive), (.receptive, .receptive), (.expansive, .expansive),
    (.expansive, .protective), (.expansive, .expansive), (.expansive, .expansive),
    (.receptive, .expansive), (.expansive, .expansive), (.expansive, .receptive),
    (.receptive, .receptive), (.expansive, .expansive), (.expansive, .protective),
    (.expansive, .expansive), (.expansive, .expansive), (.expansive, .expansive)
]

private let previewUsPairs: [(date: Date, mine: PulseSpace, partner: PulseSpace?)] =
    previewUsSpacePairs.enumerated().map { offset, pair in
        (date: Date.daysAgo(previewUsSpacePairs.count - 1 - offset), mine: pair.0, partner: pair.1)
    }

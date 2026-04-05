//
//  FloatingStackConfig.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/1/26.
//


// Design/Components/Cards/FloatingStack.swift
// Open Lightly
//
// Generic floating stack — works for CuriosityPicker bubbles
// and session card decks. Pass any view as content.
//
// Usage (bubbles):
//   FloatingStack(items: selectedSpecs, cornerRadius: 20) { spec in
//       FloatingCard(spec: spec, ...)
//   }
//
// Usage (deck):
//   FloatingStack(items: deck.cards, cornerRadius: 16) { card in
//       PromptCard(card: card, ...)
//   }

import SwiftUI

// MARK: - Anchor

enum FloatingStackAnchor {
    case topLeft
    case center
    case centerLeft
    case centerRight

    var staggerX: CGFloat {
        switch self {
        case .topLeft:     return  3
        case .center:      return  3
        case .centerLeft:  return  4
        case .centerRight: return -4
        }
    }

    var staggerY: CGFloat {
        switch self {
        case .topLeft:     return  3
        case .center:      return -3
        case .centerLeft:  return  3
        case .centerRight: return  3
        }
    }

    var expandDirection: FloatingStackConfig.ExpandDirection {
        switch self {
        case .topLeft:     return .down
        case .center:      return .up
        case .centerLeft:  return .right
        case .centerRight: return .left
        }
    }
}

// MARK: - Configuration

struct FloatingStackConfig {
    // Visual
    var cardWidth:        CGFloat = 168
    var cardHeight:       CGFloat = 82
    var cornerRadius:     CGFloat = 20
    var stackOffsetX:     CGFloat = 4     // horizontal stagger per layer
    var stackOffsetY:     CGFloat = 4     // vertical stagger per layer
    var stackRotation:    Double  = 2.5   // degrees per layer
    var maxVisibleLayers: Int     = 3     // how many cards peek behind top

    // Badge
    var showBadge:        Bool    = true
    var badgeFont:        Font    = AppFonts.overline

    // Expansion
    var expandDirection:  ExpandDirection = .up
    var expandSpacing:    CGFloat = 12
    var expandAnimation:  Animation = .spring(response: 0.45, dampingFraction: 0.82)
    var collapseAnimation:Animation = .spring(response: 0.38, dampingFraction: 0.88)

    // Float (when used in cluster context)
    var floatEnabled:     Bool    = true
    var floatAmplitude:   CGFloat = 4
    var floatSpeed:       Double  = 0.009

    // Collapsed state
    var collapsedScale:   CGFloat = 1.0

    enum ExpandDirection {
        case up, down, left, right
    }

    // Preset for curiosity picker corner stack
    static let curiosityStack = FloatingStackConfig(
        cardWidth:        168,
        cardHeight:       82,
        cornerRadius:     20,
        stackOffsetX:     4,
        stackOffsetY:     3,
        stackRotation:    2.0,
        maxVisibleLayers: 3,
        showBadge:        true,
        expandDirection:  .down,
        expandSpacing:    10,
        floatEnabled:     true,
        floatAmplitude:   4,
        floatSpeed:       0.009
    )

    // Preset for session deck
    static let sessionDeck = FloatingStackConfig(
        cardWidth:        UIScreen.main.bounds.width - 48,
        cardHeight:       260,
        cornerRadius:     24,
        stackOffsetX:     6,
        stackOffsetY:     6,
        stackRotation:    1.5,
        maxVisibleLayers: 3,
        showBadge:        true,
        expandDirection:  .up,
        expandSpacing:    16,
        floatEnabled:     false,
        floatAmplitude:   0,
        floatSpeed:       0
    )
}

// MARK: - FloatingStack

struct FloatingStack<Item: Identifiable, CardContent: View>: View {

    let items:       [Item]
    let config:      FloatingStackConfig
    var floatTick:   Double = 0
    var floatPhase:  Double = 0
    var label:       String? = nil   // optional title above stack
    var anchor:      FloatingStackAnchor = .center
    let cardContent: (Item) -> CardContent

    @State private var isExpanded:  Bool   = false
    @State private var mounted:     Bool   = false
    @State private var pressing:    Bool   = false

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Computed

    private var count: Int { items.count }

    private var floatY: CGFloat {
        guard config.floatEnabled else { return 0 }
        return CGFloat(sin(floatPhase + floatTick * config.floatSpeed) * config.floatAmplitude)
    }

    private var floatRot: Double {
        guard config.floatEnabled else { return 0 }
        return sin(floatPhase + floatTick * config.floatSpeed * 0.7) * 0.5
    }

    // Layers shown behind the top card in collapsed state
    private var visibleLayers: [Item] {
        guard count > 1 else { return [] }
        let behind = Array(items.dropFirst())
        return Array(behind.prefix(config.maxVisibleLayers))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let label {
                stackLabel(label)
                    .padding(.bottom, 8)
            }

            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .offset(y: floatY)
        .rotationEffect(.degrees(floatRot))
        .opacity(mounted ? 1 : 0)
        .scaleEffect(mounted ? 1 : 0.88)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.1)) {
                mounted = true
            }
        }
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        ZStack {
            // Ghost layers behind top card
            ForEach(Array(visibleLayers.enumerated()), id: \.offset) { i, item in
                cardContent(item)
                    .frame(width: config.cardWidth, height: config.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                    .scaleEffect(config.collapsedScale - CGFloat(i + 1) * 0.03)
                    .offset(
                        x: CGFloat(i + 1) * anchor.staggerX,
                        y: CGFloat(i + 1) * anchor.staggerY
                    )
                    .rotationEffect(.degrees(Double(i + 1) * config.stackRotation))
                    .opacity(0.55 - Double(i) * 0.12)
                    .allowsHitTesting(false)
                    .zIndex(Double(config.maxVisibleLayers - i))
            }

            // Top card — tappable
            Group {
                if let first = items.first {
                    cardContent(first)
                        .frame(width: config.cardWidth, height: config.cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                }
            }
            .overlay(alignment: .topTrailing) {
                if config.showBadge && count > 1 {
                    badge
                        .offset(x: 8, y: -8)
                }
            }
            .scaleEffect(pressing ? config.collapsedScale * 0.97 : config.collapsedScale)
            .zIndex(Double(config.maxVisibleLayers + 1))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(config.expandAnimation) {
                    isExpanded = true
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded   { _ in pressing = false }
            )
        }
        .frame(
            width: config.cardWidth * config.collapsedScale
                + CGFloat(config.maxVisibleLayers) * abs(anchor.staggerX),
            height: config.cardHeight * config.collapsedScale
                + CGFloat(config.maxVisibleLayers) * abs(anchor.staggerY)
        )
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: config.expandSpacing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(config.collapseAnimation) {
                    isExpanded = false
                }
            } label: {
                collapseHandle
            }
            .buttonStyle(.plain)

            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                cardContent(item)
                    .frame(width: config.cardWidth, height: config.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                    .transition(.opacity.combined(with: .offset(y: expandInsertionOffset(i))))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.82)
                        .delay(Double(i) * 0.04),
                        value: isExpanded
                    )
            }
        }
    }

    // MARK: - Supporting Views

    private var badge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? AnyShapeStyle(AppColors.magenta)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                          ))
                )
                .frame(width: 22, height: 22)
                .shadow(
                    color: isLight
                        ? AppColors.magenta.opacity(0.40)
                        : AppColors.cyan.opacity(0.55),
                    radius: 6
                )
            Text("\(count)")
                .font(AppFonts.overline)
                .foregroundStyle(.white)
        }
    }

    private var collapseHandle: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.up")
                .font(.system(size: 11, weight: .semibold))
            Text("Collapse")
                .font(AppFonts.caption)
        }
        .foregroundStyle(
            isLight
                ? AppColors.lightTextSecondary
                : AppColors.textSecondary
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(
                    isLight
                        ? AppColors.lightFrostPill
                        : AppColors.surfaceBg
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isLight ? AppColors.lightBorder : AppColors.border,
                            lineWidth: 1
                        )
                )
        )
    }

    private func stackLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .foregroundStyle(
                isLight
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary
            )
            .tracking(1.5)
    }

    private func expandInsertionOffset(_ index: Int) -> CGFloat {
        switch anchor.expandDirection {
        case .up:    return  20
        case .down:  return -20
        case .left:  return  20
        case .right: return -20
        }
    }
}

// MARK: - Safe subscript helper

extension Array {
    subscript(safe index: Int) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
    }
}

//
//  ConstellationNode.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/22/26.
//


//
//  ConstellationView.swift
//  Open Lightly
//
//  Research + Glossary constellation component.
//  Floating nodes · parallax stars · burst tap animation · bottom sheet.
//
//  Dark mode:  pageBg (#030305) · cyan → purple → magenta nodes · white stars
//  Light mode: lightPageBg (#F8F6EE) · purple → magenta → gold nodes · SparkField embers
//
//  Drop-in usage in HomeDashboardView.ambientZone:
//
//    sectionDivider(
//        label:  "THE CONSTELLATION",
//        colors: colorScheme == .dark
//            ? [AppColors.cyan, AppColors.purple]
//            : [AppColors.purple, AppColors.magenta]
//    )
//    ConstellationView()
//        .padding(.horizontal, 14)

import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Data model
// ─────────────────────────────────────────────────────────────────────────────

struct ConstellationNode: Identifiable {
    let id:         String
    let type:       ConstellationNodeType
    let label:      String          // stat number or term name
    let title:      String          // subtitle shown in sheet
    let body:       String          // main copy in sheet
    let source:     String          // citation / vocab note
    let xPct:       CGFloat         // 0–100 % of canvas width
    let yPct:       CGFloat         // 0–100 % of canvas height
    let size:       CGFloat         // diameter in pts
    let satellites: [ConstellationSatellite]
}

enum ConstellationNodeType {
    case stat, term
}

struct ConstellationSatellite {
    let label:  String
    let detail: String
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Content
// ─────────────────────────────────────────────────────────────────────────────

private let allNodes: [ConstellationNode] = [
    // ── Stats (interior data points — smaller) ──────────────────────────────
    .init(id:"s1", type:.stat, label:"1 in 5",        title:"Explored CNM",                 body:"Americans have engaged in consensual non-monogamy at some point in their lives.",                              source:"Haupert et al., 2017",              xPct:14, yPct:10, size:68,
          satellites:[.init(label:"Who?",                detail:"Across age, income, religion, race — the distribution is remarkably consistent."),
                      .init(label:"How measured?",        detail:"8,718 single adults across two nationally representative studies."),
                      .init(label:"Why it matters",       detail:"You are not alone. The curiosity you're feeling is widely shared.")]),
    .init(id:"s2", type:.stat, label:"70%",           title:"Higher satisfaction",           body:"of couples who name their agreements explicitly report higher relationship satisfaction.",                    source:"Moors et al., 2024",                xPct:64, yPct:6,  size:54,
          satellites:[.init(label:"The key word",         detail:"'Name' — not just have agreements, but articulate them out loud together."),
                      .init(label:"What changes",         detail:"Explicit agreements reduce ambiguity, the most common source of conflict."),
                      .init(label:"Starting point",       detail:"You don't need perfect agreements. You need a first conversation.")]),
    .init(id:"s3", type:.stat, label:"87%",           title:"Stable over time",             body:"of CNM practitioners report their relationships as stable or improving over time.",                          source:"Sheff, 2014",                       xPct:76, yPct:52, size:58,
          satellites:[.init(label:"Time frame",           detail:"Sheff's study tracked families over 10+ years — one of the longest CNM studies."),
                      .init(label:"The 13%",              detail:"Instability was tied to poor communication, not CNM itself."),
                      .init(label:"What this means",      detail:"The structure isn't the risk. Entering it without preparation is.")]),
    .init(id:"s4", type:.stat, label:"3×",            title:"Safer sex",                    body:"more likely to practice consistent safer sex when agreements are made explicit.",                           source:"Lehmiller, 2018",                   xPct:6,  yPct:60, size:52,
          satellites:[.init(label:"The mechanism",        detail:"Explicit agreements force a conversation about testing and disclosure."),
                      .init(label:"The assumption",       detail:"Partners who assume the other is 'handling it' have gaps in practice."),
                      .init(label:"Take-away",            detail:"The conversation feels awkward. The alternative is worse.")]),
    .init(id:"s5", type:.stat, label:"68%",           title:"Personal growth",              body:"of people who tried CNM report personal growth as a primary outcome.",                                      source:"Mitchell et al., 2022",             xPct:38, yPct:40, size:56,
          satellites:[.init(label:"What kind?",           detail:"Self-awareness, communication skills, emotional regulation."),
                      .init(label:"Even when it ended",   detail:"61% still reported net personal growth after CNM relationships ended."),
                      .init(label:"Why",                  detail:"CNM forces conversations most relationships never have.")]),
    // ── Terms (dominant concept nodes — larger) ──────────────────────────────
    .init(id:"g1", type:.term, label:"Compersion",    title:"Joy from a partner's joy",     body:"The feeling of happiness when seeing your partner happy with someone else.",                              source:"Coined in polyamory community, 1980s", xPct:44, yPct:12, size:78,
          satellites:[.init(label:"Origin",               detail:"Coined as a counterpart to jealousy — a feeling that existed but had no name."),
                      .init(label:"Misconception",        detail:"Compersion doesn't mean you won't feel jealousy. Both can coexist."),
                      .init(label:"How to find it",       detail:"Start small. Notice when your partner is happy — period.")]),
    .init(id:"g2", type:.term, label:"NRE",           title:"New Relationship Energy",      body:"The rush of intensity and excitement in the early stage of a new connection.",                            source:"Coined by Zhahai Stewart, 1980s",    xPct:80, yPct:26, size:70,
          satellites:[.init(label:"The chemistry",        detail:"NRE is neurochemical — dopamine, norepinephrine. Real, and temporary."),
                      .init(label:"The danger",           detail:"NRE can make new connections feel more important than established ones."),
                      .init(label:"Duration",             detail:"Typically fades after 6–24 months, varying by person and context.")]),
    .init(id:"g3", type:.term, label:"Metamour",      title:"Your partner's partner",       body:"Someone you're connected to through love, even without a direct relationship.",                           source:"Common polyamory vocabulary",         xPct:18, yPct:28, size:74,
          satellites:[.init(label:"The relationship",     detail:"You didn't choose them. Your partner did."),
                      .init(label:"Two styles",           detail:"Kitchen Table — warm and close. Parallel — not intertwined. Both valid."),
                      .init(label:"The influence",        detail:"Your metamour's emotional health directly affects your partner.")]),
    .init(id:"g4", type:.term, label:"Polycule",      title:"Your relationship network",    body:"The full network of people connected through non-monogamous relationships.",                              source:"Common polyamory vocabulary",         xPct:60, yPct:30, size:68,
          satellites:[.init(label:"The shape",            detail:"Polycules vary — V shapes, triads, quads. Your shape isn't better or worse."),
                      .init(label:"It evolves",           detail:"What matters is how the network handles change."),
                      .init(label:"Systemic thinking",    detail:"A disturbance in one relationship affects the whole network.")]),
    .init(id:"g5", type:.term, label:"Kitchen Table", title:"Everyone comfortable together", body:"A style where all partners are comfortable enough to share a meal.",                                     source:"Common polyamory vocabulary",         xPct:22, yPct:70, size:76,
          satellites:[.init(label:"The image",            detail:"Everyone sitting around a table — casual, warm, no tension."),
                      .init(label:"The alternative",      detail:"Parallel polyamory — partners who know of each other but don't interact — is equally valid."),
                      .init(label:"No pressure",          detail:"Kitchen table is a style, not a goal.")]),
    .init(id:"g6", type:.term, label:"Agreements",    title:"Your shared rules",            body:"The explicit, revisable understandings between partners about how the relationship works.",                source:"Relationship structure vocabulary",    xPct:56, yPct:66, size:72,
          satellites:[.init(label:"Rules vs Agreements",  detail:"Rules are imposed. Agreements are reached together."),
                      .init(label:"Revisable is key",     detail:"Agreements that can't be revisited become resentments."),
                      .init(label:"Start somewhere",      detail:"Agree to keep talking.")]),
]

// Pre-computed proximity connections (dist threshold 30%)
private struct NodeConnection {
    let a: Int
    let b: Int
    let opacity: Double
}

private let nodeConnections: [NodeConnection] = {
    var lines: [NodeConnection] = []
    for i in 0..<allNodes.count {
        for j in (i+1)..<allNodes.count {
            let dx = allNodes[i].xPct - allNodes[j].xPct
            let dy = allNodes[i].yPct - allNodes[j].yPct
            let dist = sqrt(dx*dx + dy*dy)
            if dist < 30 {
                lines.append(.init(a: i, b: j, opacity: 0.12 * (1 - Double(dist) / 30)))
            }
        }
    }
    return lines
}()

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Color palette helpers
// ─────────────────────────────────────────────────────────────────────────────

private func nodeColor(index: Int, colorScheme: ColorScheme) -> Color {
    // Dark:  cyan → purple → magenta
    // Light: purple → magenta → gold
    let dark:  [Color] = [AppColors.cyan, AppColors.purple, AppColors.magenta]
    let light: [Color] = [AppColors.purple, AppColors.magenta, AppColors.gold]
    let palette = colorScheme == .dark ? dark : light
    return palette[index % palette.count]
}

private func threadColor(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color.white.opacity(0.10)
        : Color(hex: "8B5E3C").opacity(0.22)
}

private func starFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color.white
        : Color(hex: "8B5E3C")
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Float animation helper
// Each node gets its own repeating offset animation via @State
// ─────────────────────────────────────────────────────────────────────────────

private struct FloatingOffset: ViewModifier {
    let index:    Int
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                let duration = 4.2 + Double(index % 4) * 0.7
                let delay    = Double(index) * 0.45
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                    ) {
                        offset = -7
                    }
                }
            }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Single node view
// ─────────────────────────────────────────────────────────────────────────────

private struct ConstellationNodeView: View {
    let node:        ConstellationNode
    let color:       Color
    let index:       Int
    let isBursting:  Bool
    let onTap:       () -> Void

    @State private var burstScale:   CGFloat = 1.0
    @State private var burstOpacity: Double  = 1.0
    @State private var ring1Opacity: Double  = 0.0
    @State private var ring2Opacity: Double  = 0.0
    @State private var ring3Opacity: Double  = 0.0
    @State private var ring1Scale:   CGFloat = 1.0
    @State private var ring2Scale:   CGFloat = 1.0
    @State private var ring3Scale:   CGFloat = 1.0
    @State private var shimmer:      Double  = 0.03

    var body: some View {
        ZStack {
            // ── Expanding burst rings ─────────────────────
            ForEach(0..<3, id: \.self) { ri in
                Circle()
                    .strokeBorder(color, lineWidth: 1.5)
                    .frame(width: node.size + CGFloat(ri * 12),
                           height: node.size + CGFloat(ri * 12))
                    .scaleEffect(ri == 0 ? ring1Scale : ri == 1 ? ring2Scale : ring3Scale)
                    .opacity(ri == 0 ? ring1Opacity : ri == 1 ? ring2Opacity : ring3Opacity)
            }

            // ── Ambient halo ──────────────────────────────
            Circle()
                .fill(color.opacity(shimmer))
                .frame(width: node.size + 44, height: node.size + 44)
                .blur(radius: 10)

            // ── Outer ring — dashed for terms ─────────────
            Circle()
                .strokeBorder(
                    color.opacity(0.55),
                    style: StrokeStyle(
                        lineWidth: 0.9,
                        dash: node.type == .term ? [4, 4] : []
                    )
                )
                .frame(width: node.size + 12, height: node.size + 12)

            // ── Core fill ────────────────────────────────
            Circle()
                .fill(Color(hex: "0A0814"))
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.25),
                                    color.opacity(0.0)
                                ],
                                center:      .init(x: 0.38, y: 0.32),
                                startRadius: 0,
                                endRadius:   node.size / 2
                            )
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(0.8), lineWidth: 1.5)
                )
                .frame(width: node.size, height: node.size)
                .scaleEffect(burstScale)
                .opacity(burstOpacity)

            // ── Label ─────────────────────────────────────
            Text(node.label)
                .font({
                    switch node.type {
                    case .term:
                        // Terms are largest — scale font to fill the bigger circles
                        let pt: CGFloat = node.size > 74 ? 11 : node.size > 70 ? 10 : 9
                        return AppFonts.body(pt, weight: .semibold)
                    case .stat:
                        // "1 in 5" has spaces — needs smaller font to fit
                        if node.label.contains(" ") {
                            return AppFonts.display(13, weight: .bold)
                        }
                        // Pure numbers — scale relative to circle size
                        let pt: CGFloat = node.size > 56 ? 16 : node.size > 52 ? 14 : 13
                        return AppFonts.display(pt, weight: .bold)
                    }
                }())
                .foregroundStyle(color)
                .shadow(color: Color(hex: "0A0814").opacity(0.9), radius: 2, x: 0, y: 0)
                .shadow(color: color.opacity(0.6), radius: 4, x: 0, y: 0)
                .opacity(burstOpacity)
        }
        .modifier(FloatingOffset(index: index))
        .onTapGesture { fireBurst() }
        .onAppear { startShimmer() }
    }

    private func startShimmer() {
        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
            shimmer = 0.10
        }
    }

    private func fireBurst() {
        guard !isBursting else { return }
        onTap()

        // Core scale-burst
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            burstScale   = 1.6
            burstOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            burstScale   = 1.0
            burstOpacity = 1.0
        }

        // Staggered rings
        let ringPairs: [(Binding<CGFloat>, Binding<Double>)] = [
            ($ring1Scale, $ring1Opacity),
            ($ring2Scale, $ring2Opacity),
            ($ring3Scale, $ring3Opacity),
        ]
        for (i, (scaleB, opacityB)) in ringPairs.enumerated() {
            let delay = Double(i) * 0.09
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                opacityB.wrappedValue = 0.9
                withAnimation(.easeOut(duration: 0.55)) {
                    scaleB.wrappedValue   = 3.5 + CGFloat(i) * 0.5
                    opacityB.wrappedValue = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    scaleB.wrappedValue = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

private struct ConstellationSheet: View {
    let node:    ConstellationNode
    let color:   Color
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Drag handle ───────────────────────────────
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.45))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Header ────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.label)
                        .font(node.type == .stat
                              ? AppFonts.display(46, weight: .bold)
                              : AppFonts.display(28, weight: .semibold))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.30), radius: 12, x: 0, y: 2)

                    Text(node.title)
                        .font(AppFonts.body(13, weight: .semibold))
                        .foregroundStyle(color.opacity(0.75))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark
                                         ? AppColors.textTertiary
                                         : AppColors.lightTextTertiary)
                        .frame(width: 30, height: 30)
                        .background(colorScheme == .dark
                                    ? AppColors.surfaceBg
                                    : AppColors.lightFrostPill)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(color.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Divider()
                .overlay(color.opacity(0.12))
                .padding(.horizontal, 20)

            // ── Scrollable body ───────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Body copy
                    Text(node.body)
                        .font(AppFonts.body(15, weight: .regular))
                        .foregroundStyle(colorScheme == .dark
                                         ? AppColors.textPrimary
                                         : AppColors.lightBodyPrimary)
                        .lineSpacing(4)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    // Source
                    Text("— \(node.source)")
                        .font(AppFonts.body(11, weight: .regular))
                        .italic()
                        .foregroundStyle(colorScheme == .dark
                                         ? AppColors.textTertiary
                                         : AppColors.lightTextTertiary)
                        .padding(.bottom, 22)

                    // Satellite cards
                    VStack(spacing: 8) {
                        ForEach(node.satellites.indices, id: \.self) { i in
                            let sat = node.satellites[i]
                            HStack(alignment: .top, spacing: 0) {
                                // Left accent bar
                                Rectangle()
                                    .fill(color.opacity(0.55))
                                    .frame(width: 3)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 1.5)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sat.label.uppercased())
                                        .font(AppFonts.label)
                                        .tracking(1)
                                        .foregroundStyle(color)

                                    Text(sat.detail)
                                        .font(AppFonts.body(13, weight: .regular))
                                        .foregroundStyle(colorScheme == .dark
                                                         ? AppColors.textSecondary
                                                         : AppColors.lightBodyAccent)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)

                                Spacer()
                            }
                            .background(
                                colorScheme == .dark
                                    ? color.opacity(0.05)
                                    : color.opacity(0.06)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(color.opacity(0.12), lineWidth: 1)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                        }
                    }
                    .padding(.bottom, 48)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            colorScheme == .dark
                ? AppColors.surfaceBg
                : AppColors.lightFrostCard
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.14), radius: 32, x: 0, y: -8)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Main ConstellationView
// ─────────────────────────────────────────────────────────────────────────────

struct ConstellationView: View {

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedNode:       ConstellationNode? = nil
    @State private var burstingId:         String?            = nil
    @State private var showSheet:          Bool               = false
    @State private var sheetOffset:        CGFloat            = 0
    @State private var dragStart:          CGFloat?           = nil

    // ── Haptic ───────────────────────────────────────
    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack(alignment: .bottom) {

                // ── Constellation canvas ─────────────────
                constellationCanvas(W: W, H: H)

                // ── Backdrop ─────────────────────────────
                if showSheet {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .blur(radius: 0)
                        .overlay(
                            colorScheme == .light
                                ? Color(hex: "B4A0DC").opacity(0.35)
                                : Color.clear
                        )
                        .onTapGesture { dismissSheet() }
                        .transition(.opacity)
                }

                // ── Bottom sheet ──────────────────────────
                if let node = selectedNode, showSheet {
                    let color = nodeColor(
                        index: allNodes.firstIndex(where: { $0.id == node.id }) ?? 0,
                        colorScheme: colorScheme
                    )

                    ConstellationSheet(node: node, color: color) {
                        dismissSheet()
                    }
                    .frame(maxHeight: geo.size.height * 0.82)
                    .offset(y: sheetOffset)
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { val in
                                if dragStart == nil { dragStart = 0 }
                                let dy = max(0, val.translation.height)
                                sheetOffset = dy
                            }
                            .onEnded { val in
                                dragStart = nil
                                if val.translation.height > 80 {
                                    dismissSheet()
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        sheetOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal:   .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
        }
        .frame(height: 380)
        .overlay(legendLabel, alignment: .bottomLeading)
        .overlay(tapLabel,    alignment: .bottomTrailing)
    }

    // ─────────────────────────────────────────────────
    // MARK: Constellation canvas
    // ─────────────────────────────────────────────────

    @ViewBuilder
    private func constellationCanvas(W: CGFloat, H: CGFloat) -> some View {
        ZStack {
            // ── Connection threads ────────────────────
            Canvas { ctx, size in
                for conn in nodeConnections {
                    let na = allNodes[conn.a]
                    let nb = allNodes[conn.b]
                    let x1 = (na.xPct + 4) / 100 * size.width
                    let y1 = (na.yPct + 6) / 100 * size.height
                    let x2 = (nb.xPct + 4) / 100 * size.width
                    let y2 = (nb.yPct + 6) / 100 * size.height

                    var path = Path()
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))

                    ctx.stroke(
                        path,
                        with: .color(
                            threadColor(colorScheme: colorScheme)
                                .opacity(conn.opacity)
                        ),
                        style: StrokeStyle(
                            lineWidth: 0.7,
                            dash: []
                        )
                    )
                }
            }
            .allowsHitTesting(false)

            // ── Nodes ─────────────────────────────────
            ForEach(allNodes.indices, id: \.self) { i in
                let node  = allNodes[i]
                let color = nodeColor(index: i, colorScheme: colorScheme)
                let cx    = (node.xPct + 4) / 100 * W
                let cy    = (node.yPct + 6) / 100 * H

                ConstellationNodeView(
                    node:       node,
                    color:      color,
                    index:      i,
                    isBursting: burstingId != nil,
                    onTap:      { handleTap(node) }
                )
                .position(x: cx, y: cy)
            }
        }
    }

    // ─────────────────────────────────────────────────
    // MARK: Corner labels
    // ─────────────────────────────────────────────────

    private var tapLabel: some View {
        Text("TAP ANY NODE")
            .font(AppFonts.meta)
            .tracking(2)
            .foregroundStyle(
                colorScheme == .dark
                    ? AppColors.textMuted
                    : Color(hex: "B08060").opacity(0.8)
            )
            .padding(.trailing, 16)
            .padding(.bottom, 12)
    }

    private var legendLabel: some View {
        HStack(spacing: 12) {
            legendItem(
                fill:   colorScheme == .dark ? AppColors.cyan.opacity(0.12) : AppColors.purple.opacity(0.12),
                stroke: colorScheme == .dark ? AppColors.cyan : AppColors.purple,
                dashed: false,
                label:  "Research"
            )
            legendItem(
                fill:   colorScheme == .dark ? AppColors.magentaDark.opacity(0.12) : AppColors.magenta.opacity(0.10),
                stroke: colorScheme == .dark ? AppColors.magentaDark : AppColors.magenta,
                dashed: true,
                label:  "Glossary"
            )
        }
        .padding(.leading, 18)
        .padding(.bottom, 12)
    }

    private func legendItem(
        fill: Color, stroke: Color,
        dashed: Bool, label: String
    ) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(fill)
                .overlay(
                    Circle().strokeBorder(
                        stroke,
                        style: StrokeStyle(lineWidth: 1, dash: dashed ? [3,2] : [])
                    )
                )
                .frame(width: 12, height: 12)
            Text(label)
                .font(AppFonts.meta)
                .foregroundStyle(
                    colorScheme == .dark
                        ? AppColors.textMuted
                        : Color(hex: "B08060")
                )
        }
    }

    // ─────────────────────────────────────────────────
    // MARK: Interaction
    // ─────────────────────────────────────────────────

    private func handleTap(_ node: ConstellationNode) {
        guard burstingId == nil else { return }
        impact.impactOccurred()

        burstingId   = node.id
        selectedNode = node
        sheetOffset  = 0

        // Sheet opens simultaneously with burst — zero latency
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showSheet = true
        }

        // Clear burst state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            burstingId = nil
        }
    }

    private func dismissSheet() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showSheet   = false
            sheetOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            selectedNode = nil
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HomeDashboardView integration helpers
//
// Add the following block inside HomeDashboardView.ambientZone,
// after the Prism section and before ResearchTicker():
//
//   // ── Constellation ─────────────────────────────────
//   Spacer(minLength: 20)
//
//   sectionDivider(
//       label:  "THE CONSTELLATION",
//       colors: colorScheme == .dark
//           ? [AppColors.cyan, AppColors.purple]
//           : [AppColors.purple, AppColors.magenta]
//   )
//   .opacity(elementOpacity(visible: prismVisible))
//   .animation(.easeOut(duration: 0.5), value: prismVisible)
//
//   Spacer(minLength: 12)
//
//   ConstellationView()
//       .padding(.horizontal, 14)
//       .opacity(elementOpacity(visible: prismVisible))
//       .offset(y: prismVisible ? 0 : 12)
//       .blur(radius: deckFocused ? 20 : 0)
//       .allowsHitTesting(!deckFocused)
//       .animation(.easeOut(duration: 0.5), value: prismVisible)
//       .animation(focusAnimation, value: deckFocused)
//
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Dark — Constellation") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        VStack(spacing: 0) {
            Spacer()
            ConstellationView()
                .padding(.horizontal, 14)
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Constellation") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        AuroraGlowField().ignoresSafeArea()
        VStack(spacing: 0) {
            Spacer()
            ConstellationView()
                .padding(.horizontal, 14)
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}

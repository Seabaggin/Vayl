//
//  OnboardingCuriosityPickerView.swift
//  Open Lightly
//

import SwiftUI

private enum ClusterPhase: Equatable {
    case set1Active
    case set2Active
    case exiting
}

// Scatter slots — 2-column organic layout with hand-tuned positions
private struct ScatterSlot {
    let xFrac:    CGFloat
    let yPt:      CGFloat
    let baseRot:  Double
    let scale:    CGFloat
}

private let set1Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  70,  baseRot: -1.2, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt:  55,  baseRot:  0.8, scale: 0.97),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot:  0.5, scale: 1.02),
    ScatterSlot(xFrac: 0.52,  yPt: 215,  baseRot: -0.7, scale: 0.98),
    ScatterSlot(xFrac: 0.28,  yPt: 375,  baseRot: -0.8, scale: 1.00),
]

private let set2Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  65,  baseRot:  1.1, scale: 0.98),
    ScatterSlot(xFrac: 0.52,  yPt:  48,  baseRot: -0.9, scale: 1.01),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot: -0.6, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt: 218,  baseRot:  1.3, scale: 0.97),
    ScatterSlot(xFrac: 0.28,  yPt: 385,  baseRot:  0.6, scale: 1.00),
]

struct OnboardingCuriosityPickerView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // MARK: - Selection
    @State private var selectedSet1: Set<String> = []
    @State private var selectedSet2: Set<String> = []
    @State private var clusterPhase: ClusterPhase = .set1Active
    @State private var hasAdvanced: Bool = false

    // MARK: - Scroll
    @State private var scrollOffset: CGFloat = 0
    @State private var seam:         CGFloat = 0

    // MARK: - UI
    @State private var headerVisible:    Bool    = false
    @State private var cardsVisible:     Bool    = false
    @State private var navHeaderHeight:  CGFloat = 230
    @State private var headerMeasured:   Bool    = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Atmosphere progress 0→1 as user scrolls set1→set2
    private var atmosphereProgress: CGFloat {
        guard seam > 0 else { return 0 }
        return max(0, min(1, scrollOffset / seam))
    }

    private var atmosphereCyanOpacity:    Double { Double(1 - atmosphereProgress) * (isLight ? 0.10 : 0.20) }
    private var atmosphereMagentaOpacity: Double { Double(atmosphereProgress)     * (isLight ? 0.10 : 0.20) }

    // MARK: - Flash intensity — bell curve peaking at crossfade midpoint
    // Essentially zero by progress=0.25 and progress=0.75
    private var flashIntensity: CGFloat {
        guard seam > 0 else { return 0 }
        let p = atmosphereProgress
        return exp(-18 * pow(p - 0.5, 2))
    }

    // MARK: - Responsive font sizes
    private var headerTitleSize: CGFloat { 22 }
    private var headerSubtitleSize: CGFloat { 14 }

    // MARK: - Helpers
    private var hasSelection: Bool  { !selectedSet1.isEmpty && !selectedSet2.isEmpty }
    private var totalSelected: Int  { selectedSet1.count + selectedSet2.count }
    
    private var config: CuriosityScreenConfig {
        switch data.appMode {
        case .together: return .coupleNotTalkedConfig
        case .solo:     return .soloSingleConfig
        case .browsing: return .browsingConfig
        case .none:     return .browsingConfig
        }
    }

    // MARK: - LivingText gradient stops — single source of truth
    private var livingGradientColors: [Color] {
        isLight
            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta]
    }

    // MARK: - Device-adaptive scaling
    private func scaledSlots(_ slots: [ScatterSlot], screenW: CGFloat) -> [ScatterSlot] {
        // Only scale DOWN for small screens — large screens don't need bigger gaps
        let yScale = min(max(screenW / 390, 0.85), 1.0)
        return slots.map { slot in
            ScatterSlot(
                xFrac:   slot.xFrac,
                yPt:     slot.yPt * yScale,
                baseRot: slot.baseRot,
                scale:   slot.scale
            )
        }
    }

    // MARK: - Card specs
    private enum CardSet { case set1, set2 }

    private struct CardSpec: Identifiable {
        let id:         String
        let lead:       String
        let full:       String
        let slot:       ScatterSlot
        let floatPhase: Double
        let set:        CardSet
    }

    private func cardSpecs(screenH: CGFloat, screenW: CGFloat) -> [CardSpec] {
        let s1slots = scaledSlots(set1Slots, screenW: screenW)
        let s2slots = scaledSlots(set2Slots, screenW: screenW)
        let s1 = Array(config.section1Options.prefix(5))
        let s2 = Array(config.section2Options.prefix(5))
        var out: [CardSpec] = []
        for (i, opt) in s1.enumerated() {
            out.append(CardSpec(
                id:         opt.id,
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s1slots[i % s1slots.count],
                floatPhase: Double(i) * 0.8,
                set:        .set1
            ))
        }
        for (i, opt) in s2.enumerated() {
            out.append(CardSpec(
                id:         opt.id + "_set2",
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s2slots[i % s2slots.count],
                floatPhase: Double(i) * 0.8 + 0.4,
                set:        .set2
            ))
        }
        return out
    }

    private func isSelected(_ spec: CardSpec) -> Bool {
        switch spec.set {
        case .set1: return selectedSet1.contains(spec.id)
        case .set2:
            let raw = spec.id.hasSuffix("_set2")
                ? String(spec.id.dropLast(5))
                : spec.id
            return selectedSet2.contains(raw)
        }
    }

    // MARK: - Selection Logic
    private let maxPerSection = 3

    private func toggle(_ spec: CardSpec) {
        guard clusterPhase != .exiting else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch spec.set {
        case .set1:
            if selectedSet1.contains(spec.id) {
                selectedSet1.remove(spec.id)
            } else if selectedSet1.count < maxPerSection {
                selectedSet1.insert(spec.id)
            } else {
                // Max reached — provide haptic warning, no change
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
            }
        case .set2:
            let raw = spec.id.hasSuffix("_set2")
                ? String(spec.id.dropLast(5))
                : spec.id
            if selectedSet2.contains(raw) {
                selectedSet2.remove(raw)
            } else if selectedSet2.count < maxPerSection {
                selectedSet2.insert(raw)
            } else {
                // Max reached — provide haptic warning, no change
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
            }
        }
    }

    // MARK: - Float
    // More amplitude (3→5pt Y, 0.2→0.35 rot)
    // Each card gets its own tick multiplier offset — never in sync
    private func floatY(_ spec: CardSpec, tick: Double) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let speedVariance = 0.009 + (spec.floatPhase.truncatingRemainder(dividingBy: 3)) * 0.002
        return CGFloat(sin(spec.floatPhase + tick * speedVariance) * 5)
    }

    private func floatRot(_ spec: CardSpec, tick: Double) -> Double {
        guard !reduceMotion else { return 0 }
        let speedVariance = 0.006 + (spec.floatPhase.truncatingRemainder(dividingBy: 2)) * 0.002
        return sin(spec.floatPhase + tick * speedVariance) * 0.35
    }

    private func gravity(_ spec: CardSpec) -> CGSize {
        guard isSelected(spec) else { return .zero }
        return CGSize(width: spec.slot.xFrac > 0.4 ? 10 : -10, height: 0)
    }

    // MARK: - Card width
    private func cardW(for spec: CardSpec, canvasW: CGFloat) -> CGFloat {
        canvasW * 0.44 * spec.slot.scale
    }

    // MARK: - Tint / border
    private func cardTint(_ spec: CardSpec) -> Color {
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.04 : 0.05)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.04 : 0.05)
        }
    }
    private func cardBorder(_ spec: CardSpec) -> Color {
        guard !isSelected(spec) else { return .clear }
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.18 : 0.14)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.18 : 0.14)
        }
    }

    // MARK: - Data / continue
    private func commitData() {
        data.communicationGoals = config.section1Options
            .filter { selectedSet1.contains($0.id) }.map(\.id).sorted()
        data.learningGoals = config.section2Options
            .filter { selectedSet2.contains($0.id) }.map(\.id).sorted()
        data.curiositySelections = data.communicationGoals + data.learningGoals
    }

    private func handleContinue() {
        guard !hasAdvanced else { return }
        hasAdvanced = true
        commitData()
        withAnimation(.easeInOut(duration: 0.3)) { clusterPhase = .exiting }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onContinue?() }
    }

    // MARK: - Dimensions
    private func sectionHeight(screenW: CGFloat) -> CGFloat {
        let scale = min(max(screenW / 390, 0.85), 1.0)
        return (385 + 90 + 95) * scale  // lastYPt + cardH + buffer for seam/margin
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let h   = geo.size.height
            let w   = geo.size.width
            let top = geo.safeAreaInsets.top
            let bot = geo.safeAreaInsets.bottom

            ZStack(alignment: .top) {

                // ── Atmosphere ────────────────────────────────────────
                ZStack {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.cyan.opacity(atmosphereCyanOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.25)
                        .blur(radius: 70)
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.magenta.opacity(atmosphereMagentaOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.78)
                        .blur(radius: 70)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // ── Scroll canvas ─────────────────────────────────────
                infiniteCanvas(w: w, h: h, top: top)
                    .frame(width: w, height: h)
                    .ignoresSafeArea()

                // ── Fixed nav + header ────────────────────────────────
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        OnboardingNavBar(
                            currentStep: 4,
                            totalSteps:  6,
                            onBack:      onBack
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, top + 8)
                        .padding(.bottom, OL.navBottom(h))

                        headerBlock
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                            .opacity(headerVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: headerVisible)
                    }
                    .background(
                        GeometryReader { navGeo in
                            Color.clear.onAppear {
                                guard !headerMeasured else { return }
                                headerMeasured  = true
                                navHeaderHeight = navGeo.size.height + 20
                            }
                        }
                    )

                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

                // ── Selection count pill — top right, below nav ───────────
                VStack {
                    HStack {
                        Spacer()
                        selectionPill
                            .padding(.top, top + 14)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .zIndex(20)

                // ── Fixed CTA ─────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    bottomZone
                        .padding(.horizontal, 24)
                        .padding(.bottom, bot + 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0),
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0.96),
                                ],
                                startPoint: .top,
                                endPoint:   .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { headerVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.30)) { cardsVisible  = true }
            }
            .onDisappear {
                // Preserve partial selections so back navigation
                // restores the user's progress.
                if !selectedSet1.isEmpty || !selectedSet2.isEmpty {
                    commitData()
                }
                hasAdvanced = false
            }
        }
    }

    // MARK: - Infinite canvas

    @ViewBuilder
    private func infiniteCanvas(w: CGFloat, h: CGFloat, top: CGFloat) -> some View {
        let secH     = sectionHeight(screenW: w)
        let seamGap: CGFloat = -90  // was 60
        let topPad:  CGFloat = navHeaderHeight
        let totalH   = topPad + secH + seamGap + secH + 10

        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {

                // ── Scroll tracker ────────────────────────────────────
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            Task { @MainActor in
                                // Seam position: scroll distance to the visual boundary between Set 1 and Set 2
                                // Calculated as the end of Set 1 panel plus half of seamGap to center at the visual seam
                                if seam == 0 { seam = secH + CGFloat(seamGap) / 2 }
                            }
                        }
                        .onChange(of: proxy.frame(in: .named("scroll")).minY) { _, currentY in
                            scrollOffset = max(0, -currentY)
                            // Keep clusterPhase in sync for card hit-testing
                            let inSet2 = scrollOffset >= seam
                            let target: ClusterPhase = inSet2 ? .set2Active : .set1Active
                            if clusterPhase != target && clusterPhase != .exiting {
                                clusterPhase = target
                            }
                        }
                }
                .frame(width: w, height: 0)

                // ── Animated cards ────────────────────────────────────
                TimelineView(.animation(minimumInterval: 1/30,
                                        paused: clusterPhase == .exiting || reduceMotion)) { tl in
                    let tick = tl.date.timeIntervalSinceReferenceDate * 60

                    ZStack(alignment: .topLeading) {
                        Color.clear.frame(width: w, height: totalH)

                        // Set 1
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set1 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = topPad + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }

                        // Set 2
                        let set2Origin = topPad + secH + seamGap
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set2 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = set2Origin + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }
                    }
                    .frame(width: w, height: totalH)
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .frame(width: w, height: h)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.15),
                    .init(color: .black, location: 1.00),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
        )
        .opacity(cardsVisible ? 1 : 0)
    }

    // MARK: - Individual card

    @ViewBuilder
    private func cardView(spec: CardSpec, tick: Double, cw: CGFloat) -> some View {
        let selected = isSelected(spec)
        let opacity: Double = clusterPhase == .exiting ? 0 : 1

        ZStack {
            FloatingCard(
                spec: FloatingCardSpec(
                    id:         spec.id,
                    lead:       spec.lead,
                    full:       spec.full,
                    xFrac:      Double(spec.slot.xFrac),
                    yFrac:      Double(spec.slot.yPt),
                    floatPhase: spec.floatPhase
                ),
                isSelected:    selected,
                floatY:        floatY(spec, tick: tick),
                floatRot:      floatRot(spec, tick: tick),
                gravity:       gravity(spec),
                tick:          tick,
                targetOpacity: opacity,
                cardWidth:     cw,
                tintColor:     cardTint(spec),
                onTap:         { toggle(spec) }
            )

            // ...existing code...
        }
        .allowsHitTesting(opacity > 0.3)
        .animation(.easeInOut(duration: 0.35), value: clusterPhase)
    }

    // MARK: - Fixed header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topLeading) {

                // Flash bloom — uses LivingText palette, direction-aware
                // cyan-weighted entering, magenta-weighted exiting
                LinearGradient(
                    colors: [
                        AppColors.cyan.opacity(flashIntensity * (1 - atmosphereProgress) * 0.25),
                        AppColors.purpleVivid.opacity(flashIntensity * 0.25),
                        AppColors.magenta.opacity(flashIntensity * atmosphereProgress * 0.25),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .blur(radius: 10 + flashIntensity * 14)
                .frame(height: 50)
                .padding(.horizontal, -16)
                .padding(.vertical, -12)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {

                    // Title crossfade with living gradient flash
                    ZStack(alignment: .topLeading) {
                        liveLabelTitle(
                            config.section1Label,
                            opacity: 1 - atmosphereProgress,
                            flash:   flashIntensity * (1 - atmosphereProgress)
                        )
                        liveLabelTitle(
                            config.section2Label,
                            opacity: atmosphereProgress,
                            flash:   flashIntensity * atmosphereProgress
                        )
                    }
                    .frame(height: 32)
                    .scaleEffect(1 + flashIntensity * 0.012, anchor: .leading)
                    .clipped()

                    // Subtitle crossfade — plain opacity, no gradient needed
                    ZStack(alignment: .topLeading) {
                        liveLabelSubtitle(config.section1Sublabel,
                                          opacity: 1 - atmosphereProgress)
                        liveLabelSubtitle(config.section2Sublabel,
                                          opacity: atmosphereProgress)
                    }
                    .frame(height: 22)
                    .padding(.top, 5)
                    .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Title label

    @ViewBuilder
    private func liveLabelTitle(_ text: String,
                                opacity: CGFloat,
                                flash: CGFloat) -> some View {
        ZStack {
            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(isLight
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .opacity(1 - flash)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 5)
                .opacity(flash * 0.40)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 2)
                .opacity(flash * 0.80)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .opacity(flash)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .modifier(GlowUnderline(isLight: isLight, flash: flash))
        .opacity(opacity)
    }

    // MARK: - Subtitle label

    @ViewBuilder
    private func liveLabelSubtitle(_ text: String, opacity: CGFloat) -> some View {
        Text(text)
            .font(AppFonts.body(headerSubtitleSize, weight: .regular))
            .foregroundStyle(isLight
                ? AppColors.lightTextSecondary
                : AppColors.textSecondary)
            .opacity(opacity)
    }

    // MARK: - Selection count pill
    private var selectionPill: some View {
        HStack(spacing: 6) {
            Text("\(totalSelected)")
                .font(AppFonts.body(16, weight: .semibold))
                .foregroundStyle(isLight ? AppColors.lightBodyWineDark : Color.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: totalSelected)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isLight ? AppColors.lightFrostPill : AppColors.surfaceBg)
        .overlay {
            if isLight {
                LightModeShimmer(duration: 4.0, usePillColors: true)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            } else {
                HolographicShimmer(duration: 4.0)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(Capsule())
        .overlay {
            if isLight {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: livingGradientColors.map { $0.opacity(0.78) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
            } else {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
            }
        }
        .shadow(color: isLight
            ? AppColors.magenta.opacity(0.18)
            : AppColors.purple.opacity(0.25),
                radius: 12, x: 0, y: 4)
        .opacity(totalSelected > 0 ? 1 : 0)
        .scaleEffect(totalSelected > 0 ? 1 : 0.85, anchor: .topTrailing)
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: totalSelected > 0)
    }

    // MARK: - Bottom zone

    private var bottomZone: some View {
        VStack(spacing: 8) {
            CuriosityPanelNudge(
                s1Empty: selectedSet1.isEmpty,
                s2Empty: selectedSet2.isEmpty,
                isLight: isLight
            )

            HoloCTAButton(
                title:     "Continue",
                isEnabled: hasSelection,
                action:    { handleContinue() }
            )
            .animation(.easeInOut(duration: 0.4), value: hasSelection)

            OnboardingFooter()
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Previews

#Preview("Dark — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        d.appMode     = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        d.appMode     = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — Couple") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        d.appMode     = .together
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

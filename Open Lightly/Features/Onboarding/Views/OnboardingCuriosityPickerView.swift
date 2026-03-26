//
//  OnboardingCuriosityPickerView.swift
//  Open Lightly
//
//  Screen 5 — Two-section interest & intent picker.
//  Config is fully derived from OnboardingData — no mode checks in the view.
//

import SwiftUI

// MARK: - Section Identity

private enum PickerSection {
    case one, two
}

// MARK: - Main View

struct OnboardingCuriosityPickerView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    // MARK: - State

    @State private var selectedCommunicationGoals: Set<String> = []
    @State private var selectedLearningGoals:      Set<String> = []
    @State private var headerVisible      = false
    @State private var section1Visible    = false
    @State private var section2Visible    = false
    @State private var reassuranceVisible = false

    @State private var section2HasAppeared = false
    @State private var ctaHasAppeared      = false
    @State private var ctaExpanding        = false
    @State private var isRestoringState    = false

    @Environment(\.colorScheme)    private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - Computed

    // FIXED: Extracted from body, sectionHeader, pillGrid, sectionDivider, and
    // CuriosityPill.body. Previously `let isLight = colorScheme == .light` was
    // declared inside each @ViewBuilder scope and captured across multiple nested
    // closures, exhausting the preview type-checker's per-expression time budget.
    private var isLight: Bool { colorScheme == .light }

    private var config: CuriosityScreenConfig {
        data.curiosityScreenConfig
    }

    private var hasSelection: Bool {
        !selectedCommunicationGoals.isEmpty || !selectedLearningGoals.isEmpty
    }

    private var pillColumns: [GridItem] {
        dynamicTypeSize >= .accessibility2
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10),
               GridItem(.flexible(), spacing: 10)]
    }

    // FIXED: Extracted from body — inline AnyShapeStyle ternary with LinearGradient
    // exceeded the preview type-checker's inference budget.
    private var reassuranceGradientStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.gold,    location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [
                    AppColors.cyan,
                    AppColors.purple,
                    AppColors.magenta,
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // LAYOUT-FIX: converted from var to func(size:) so atmosphere ellipse
    // receives proportional dimensions from the GeometryReader in body.
    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            if isLight {
                // ── Light background ──────────────────────────────
                AppColors.lightPageBg

                AuroraGlowField(config: .curiosityPickerView)

                // SparkField: fewest sparks — picker is dense,
                // sparks stay far peripheral
                // count:12, speed:0.18–0.28, opacity:0.14–0.24,
                // fade:0.65→0.52
                SparkField(config: .curiosityPickerView)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                // ── Dark background — unchanged ────────────────────
                AppColors.pageBg

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.3),
                                AppColors.deepBlue.opacity(0.15),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        )
                    )
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height)) // LAYOUT-FIX: was 600×500
                    .offset(y: -size.height * 0.09)                                       // LAYOUT-FIX: was -80
                    .blur(radius: 80)

                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in // LAYOUT-FIX: proportionally scale spacing
        let h = geo.size.height

        VStack(spacing: 0) {

            OnboardingNavBar(
                currentStep: 4,
                totalSteps: 5,
                onBack: onBack
            )
            .padding(.top, OL.navTop(h))        // LAYOUT-FIX: was 12 hardcoded
            .padding(.bottom, OL.navBottom(h))  // LAYOUT-FIX: was 20 hardcoded
            .padding(.horizontal, 24)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // LAYOUT-FIX: minHeight fills screen before scroll activates on SE

                        // MARK: Section 1 header
                        sectionHeader(
                            label:    config.section1Label,
                            sublabel: config.section1Sublabel
                        )
                        .padding(.horizontal, 24)
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 10)

                        Spacer(minLength: 14)

                        // MARK: Section 1 pills
                        pillGrid(
                            options:      config.section1Options,
                            selectedKeys: $selectedCommunicationGoals,
                            isVisible:    section1Visible,
                            section:      .one
                        )
                        .padding(.horizontal, 24)

                        // MARK: Gate 2 — Section 2 expands into layout
                        if config.showSection2 {
                            VStack(alignment: .leading, spacing: 0) {
                                if section2HasAppeared {
                                    sectionDivider
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 24)
                                        .opacity(section2Visible ? 1 : 0)

                                    sectionHeader(
                                        label:    config.section2Label,
                                        sublabel: config.section2Sublabel
                                    )
                                    .padding(.horizontal, 24)
                                    .opacity(section2Visible ? 1 : 0)
                                    .offset(y: section2Visible ? 0 : 10)
                                    .id("section2Top")

                                    Spacer(minLength: 14)

                                    pillGrid(
                                        options:      config.section2Options,
                                        selectedKeys: $selectedLearningGoals,
                                        isVisible:    section2Visible,
                                        section:      .two
                                    )
                                    .padding(.horizontal, 24)
                                }
                            }
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.82),
                                value: section2HasAppeared
                            )
                            .clipped()
                        }

                        Spacer(minLength: 16)

                        // MARK: Reassurance
                        // RULE B — magenta→gold in light; dark path unchanged
                        Text("No wrong answers. You can always explore more later.")
                            .font(AppFonts.caption)
                            .foregroundStyle(reassuranceGradientStyle) // FIXED: uses pre-resolved property
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .opacity(reassuranceVisible ? 1 : 0)
                            .offset(y: reassuranceVisible ? 0 : 8)

                        // MARK: Gate 3 — CTA inside scroll surface
                        if ctaHasAppeared {
                            HoloCTAButton(
                                title: "Show me my path",
                                isEnabled: hasSelection
                            ) {
                                handleContinue()
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .opacity(ctaExpanding ? 1 : 0)
                            .offset(y: ctaExpanding ? 0 : 12)
                            .id("ctaAnchor")
                        }

                        OnboardingFooter()
                            .opacity(0.5)
                            .padding(.top, 8)
                    }
                    .frame(minHeight: OL.scrollMinH(h)) // LAYOUT-FIX: fills screen before scroll activates
                }
                .onChange(of: section2HasAppeared) { _, appeared in
                    guard appeared, config.showSection2, !isRestoringState else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("section2Top", anchor: .top)
                        }
                    }
                }
                .onChange(of: ctaHasAppeared) { _, appeared in
                    guard appeared else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("ctaAnchor", anchor: .center)
                        }
                    }
                }
            }
        }
        .background { backgroundLayer(size: geo.size) } // LAYOUT-FIX: passes live size for proportional atmosphere
        // RULE D — .preferredColorScheme(.dark) removed;
        // screen now responds to system appearance.
        .onAppear {
            restoreSelectionsIfNeeded()
            runEntranceAnimations()
        }
        } // LAYOUT-FIX: end GeometryReader
    }

    // MARK: - Section Header

    private func sectionHeader(label: String, sublabel: String) -> some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.lightCardTitle)
                        : AnyShapeStyle(AppColors.textPrimary)
                )
                .fixedSize(horizontal: false, vertical: true)

            Text(sublabel)
                .font(AppFonts.caption)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
                        : AnyShapeStyle(AppColors.textSecondary)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pill Grid

    private func pillGrid(
        options: [CuriosityOption],
        selectedKeys: Binding<Set<String>>,
        isVisible: Bool,
        section: PickerSection
    ) -> some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        let isOdd = options.count % 2 != 0

        return VStack(alignment: .trailing, spacing: 6) {
            LazyVGrid(columns: pillColumns, spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let isLast = index == options.count - 1
                    CuriosityPill(
                        option:     option,
                        isSelected: selectedKeys.wrappedValue.contains(option.id),
                        onTap:      { toggleSelection(option.id, in: selectedKeys, section: section) }
                    )
                    .gridCellColumns(isOdd && isLast ? 2 : 1)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 12)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.04),
                        value: isVisible
                    )
                }
            }
            if !selectedKeys.wrappedValue.isEmpty {
                Text("Tap to deselect")
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight
                            // lightTextTertiary handles low-emphasis
                            // hint text on cream — no raw opacity needed
                            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.40))
                            : AnyShapeStyle(AppColors.textSecondary.opacity(0.45))
                    )
                    .transition(.opacity)
                    .accessibilityHidden(true) // visual affordance only
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedKeys.wrappedValue.isEmpty)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        HStack(spacing: 6) {
            ForEach(0..<12, id: \.self) { _ in
                Circle()
                    // lightBorder in light — same visual weight as
                    // card borders on cream
                    .fill(isLight ? AppColors.lightBorder : AppColors.border)
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func toggleSelection(
        _ key: String,
        in set: Binding<Set<String>>,
        section: PickerSection
    ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if set.wrappedValue.contains(key) {
                set.wrappedValue.remove(key)
            } else {
                set.wrappedValue.insert(key)
            }
        }

        let newCount = set.wrappedValue.count

        // Gate 2 — fires once on the first Section 1 selection
        if section == .one
            && newCount == 1
            && !section2HasAppeared {

            section2HasAppeared = true

            if config.showSection2 {
                withAnimation(.easeOut(duration: 0.5).delay(0.30)) {
                    section2Visible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.65)) {
                    reassuranceVisible = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.5).delay(0.30)) {
                    reassuranceVisible = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    triggerCTAAppearance()
                }
            }
        }

        // Gate 3 — fires once on the first Section 2 selection
        if section == .two
            && newCount == 1
            && !ctaHasAppeared {
            triggerCTAAppearance()
        }
    }

    private func triggerCTAAppearance() {
        guard !ctaHasAppeared else { return }
        ctaHasAppeared = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeOut(duration: 0.4)) {
                ctaExpanding = true
            }
        }
    }

    private func restoreSelectionsIfNeeded() {
        isRestoringState = true
        let hasComms    = !data.communicationGoals.isEmpty
        let hasLearning = !data.learningGoals.isEmpty

        // On the browsing path, previous selections were written
        // to data.learningGoals. Restore them into the Section 1
        // state var, which is the only active section.
        if !config.showSection2 {
            if hasLearning {
                selectedCommunicationGoals = Set(data.learningGoals)
            }
        } else {
            if hasComms    { selectedCommunicationGoals = Set(data.communicationGoals) }
            if hasLearning { selectedLearningGoals      = Set(data.learningGoals) }
        }

        // Fast-forward gate flags if Section 1 had selections.
        // Do not animate — set all visibility flags to true directly
        // so the screen renders fully formed without replaying the
        // entrance sequence.
        if !selectedCommunicationGoals.isEmpty {
            headerVisible       = true
            section1Visible     = true
            section2HasAppeared = true
            section2Visible     = true
            reassuranceVisible  = true
        }

        // Fast-forward Gate 3 flags if Section 2 had selections,
        // or if browsing path had any Section 1 selections.
        let shouldShowCTA = !selectedLearningGoals.isEmpty
            || (!config.showSection2 && !selectedCommunicationGoals.isEmpty)
        if shouldShowCTA {
            ctaHasAppeared = true
            ctaExpanding   = true
        }
        isRestoringState = false
    }

    private func handleContinue() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if config.showSection2 {
            data.communicationGoals = Array(selectedCommunicationGoals).sorted()
            data.learningGoals      = Array(selectedLearningGoals).sorted()
        } else {
            // Browsing path — all selections are learning-oriented.
            // Note: selectedCommunicationGoals holds Section 1 state
            // even on browsing path; the field name mismatch is
            // intentional — see CuriosityScreenConfig.browsingConfig.
            data.communicationGoals = []
            data.learningGoals      = Array(selectedCommunicationGoals).sorted()
        }
        data.curiositySelections = data.communicationGoals + data.learningGoals
        onContinue?()
    }

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible   = true
            section1Visible = true
            return
        }
        #endif
        guard !headerVisible else { return }
        withAnimation(.easeOut(duration: 0.5).delay(0.10)) { headerVisible   = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { section1Visible = true }
    }
}

// MARK: - CuriosityPill

private struct CuriosityPill: View {
    let option:     CuriosityOption
    let isSelected: Bool
    let onTap:      () -> Void

    // RULE H — private struct needs its own @Environment
    @Environment(\.colorScheme) private var colorScheme

    // FIXED: Extracted from body, pillBackground, and pillBorder.
    // Same root cause as the parent view — `let isLight` inside @ViewBuilder
    // scopes captured across multiple closures exhausts the preview type-checker.
    private var isLight: Bool { colorScheme == .light }

    // Quiz and DesireMap options use magenta accent to signal
    // "this does something special"
    private var accentColor: Color {
        switch option.contentType {
        case .quiz, .desireMap: return AppColors.magenta
        default:                return AppColors.cyan
        }
    }

    // Dark-mode selected border gradient — unchanged
    private var darkSelectedBorder: LinearGradient {
        switch option.contentType {
        case .quiz, .desireMap:
            return LinearGradient(
                colors: [AppColors.magenta, AppColors.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        Button(action: onTap) {
            HStack(spacing: 10) {

                // Icon area — checkmark when selected,
                // ✦ when emphasized, empty otherwise.
                // Fully hidden from VoiceOver — selection state is
                // conveyed by the button's selected trait and label.
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                // Magenta reads clearly on both frost
                                // and dark fill in selected state
                                isLight ? AppColors.magenta : accentColor
                            )
                            .transition(.scale.combined(with: .opacity))
                    } else if option.isEmphasized {
                        Text("✦")
                            .font(.system(size: 8))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.purple.opacity(0.5)
                                    : AppColors.cyan.opacity(0.5)
                            )
                    }
                }
                .frame(width: 16, height: 16)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                .accessibilityHidden(true)

                Text(option.label)
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(
                        isSelected
                            ? (isLight
                                ? AnyShapeStyle(AppColors.lightCardTitle)
                                : AnyShapeStyle(AppColors.textPrimary))
                            : (isLight
                                ? AnyShapeStyle(AppColors.wineDark)
                                : AnyShapeStyle(Color.white))
                    )
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(pillBackground)
            .overlay(pillBorder)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : accentColor.opacity(0.20))
                    : (option.isEmphasized
                        ? (isLight
                            ? Color.clear
                            : AppColors.cyan.opacity(0.06))
                        : .clear),
                radius: isSelected ? 10 : 6,
                x: 0, y: 0
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    @ViewBuilder
    private var pillBackground: some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        RoundedRectangle(cornerRadius: 20)
            .fill(
                isSelected
                    ? (isLight
                        // lightFrostPillSel — frosted selected fill on cream
                        ? LinearGradient(
                            colors: [AppColors.lightFrostPillSel, AppColors.lightFrostPillSel],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [accentColor.opacity(0.08), AppColors.purple.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                    : (isLight
                        // lightFrostPill — frosted unselected fill on cream
                        ? LinearGradient(
                            colors: [AppColors.lightFrostPill, AppColors.lightFrostPill],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [AppColors.cardBg, AppColors.cardBg],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
            )
    }

    @ViewBuilder
    private var pillBorder: some View {
        // FIXED: uses struct-level `isLight` instead of local `let isLight`
        if isSelected {
            if isLight {
                // Light selected border — magentaGold with blur duplicate
                // for visual mass on cream (Rule G / border spec Section 6)
                ZStack {
                    // 1. Crisp stroke
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                    // 2. Blurred duplicate — gives border visual mass
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.50),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 6)
                        .opacity(0.25)
                }
                // 3. Shadow spread — three layers
                .shadow(color: AppColors.lightShadowMagenta, radius: 8,  x: 0, y: 3)
                .shadow(color: AppColors.lightShadowPurple,  radius: 16, x: 0, y: 5)
                .shadow(color: AppColors.lightShadowGold,    radius: 6,  x: 0, y: 2)
            } else {
                // Dark selected border — unchanged
                RoundedRectangle(cornerRadius: 20)
                    .stroke(darkSelectedBorder, lineWidth: 2)
            }
        } else if option.isEmphasized {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isLight
                        ? AppColors.lightBorder
                        : AppColors.cyan.opacity(0.15),
                    lineWidth: 1.5
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    OnboardingCuriosityPickerView(data: $data)
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    OnboardingCuriosityPickerView(data: $data)
        .preferredColorScheme(.light)
}

// Features/Onboarding/Views/OnboardingGroundRulesView.swift
//
// Screen 8: Before you dive in — honest framing of what this journey is and isn't.
// Must-acknowledge. No back button. No skipping.
// Writes data.groundRulesAcceptedAt, data.onboardingComplete, and data.completedAt
// on acknowledgment then calls onFinished.
//
// Layout strategy:
// - All devices use FlipPromiseCards — title front, detail back on tap
// - Card height scales: SE 72pt → mid 80pt → large 88pt
// - ScrollView with minHeight: fits without scroll on tall devices, scrolls on short ones

import SwiftUI

// MARK: - Main View

struct OnboardingGroundRulesView: View {
    @Binding var data: OnboardingData
    var onFinished: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var hasAnimated        = false
    @State private var atmosphereVisible  = false
    @State private var progressVisible    = false
    @State private var overlineVisible    = false
    @State private var subtextVisible     = false
    @State private var rulesVisible: Set<Int> = []
    @State private var frameVisible       = false
    @State private var ctaVisible         = false
    @State private var isPeeking          = false

    // MARK: - Pill Data

    private struct PillContent: Identifiable {
        let id: Int
        let icon: String
        let iconBg: AnyShapeStyle
        let title: String
        let detail: String
    }

    private var pills: [PillContent] {
        let pill2: PillContent = data.explorationMode == .couple
            ? PillContent(
                id: 1,
                icon: "heart.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This works best when you're both curious.",
                detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
              )
            : PillContent(
                id: 1,
                icon: "figure.walk",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This won't resolve things you're running from.",
                detail: "The best it can do is help you understand what you're running toward."
              )
        return [
            PillContent(
                id: 0,
                icon: "lightbulb.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.orangeHot],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "They say money shows you more of who you are.",
                detail: "This journey will do more of the same, if you see it through."
            ),
            pill2,
            PillContent(
                id: 2,
                icon: "hand.raised.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This is not therapy, and it's not trying to be.",
                detail: "Not every journey into this territory requires clinical support — but if yours does, the resources are here whenever you need them."
            ),
        ]
    }

    // MARK: - Computed helpers

    private var isLight: Bool { colorScheme == .light }

    private var subheadSuffix: String {
        ", the most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadFallback: String {
        "The most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadTextColor: Color {
        isLight ? AppColors.lightCardTitle : AppColors.textPrimary
    }

    private var italicLineStyle: AnyShapeStyle {
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
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Subhead View

    @ViewBuilder
    private func subheadView(h: CGFloat) -> some View {
        let font: Font = h < 700
            ? AppFonts.display(18)
            : h < 760
                ? AppFonts.display(20)
                : h < 820
                    ? AppFonts.display(21)
                    : AppFonts.screenTitle

        if data.displayName.isEmpty {
            Text(subheadFallback)
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(data.displayName)\(subheadSuffix)")
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Decoration Layers

    private var baseBackground: some View {
        Group {
            if isLight {
                AppColors.lightPageBg.ignoresSafeArea()
            } else {
                AppColors.pageBg.ignoresSafeArea()
            }
        }
    }

    private var glowOverlay: some View {
        Group {
            if isLight {
                AuroraGlowField(config: .groundRulesView)
            } else {
                OnboardingGlowField()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var sparkOverlay: some View {
        Group {
            if isLight {
                SparkField(config: .groundRulesView)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let isCompact = h < 720
            let isMid     = h >= 720 && h < 760
            let cardPad: CGFloat = isCompact ? 12 : isMid ? 10 : 14
            let cardGap: CGFloat = isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h) * 0.7
                    : OL.compact(h)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    contentBlock(
                        h: h, w: w,
                        isCompact: isCompact,
                        isMid: isMid,
                        cardPad: cardPad,
                        cardGap: cardGap
                    )
                    Spacer(minLength: 0)
                    ctaBlock(geo: geo)
                        .padding(.horizontal, 24)
                }
                .frame(minHeight: geo.size.height)
            }
            .background {
                ZStack {
                    baseBackground
                    atmosphereLayer
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    glowOverlay
                    sparkOverlay
                }
                .ignoresSafeArea()
            }
            .accessibilityLabel("Before you dive in. Screen 8 of 8.")
            .accessibilityAction(named: "I'm ready") { handleAcknowledge() }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                #if DEBUG
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    atmosphereVisible = true
                    progressVisible   = true
                    overlineVisible   = true
                    subtextVisible    = true
                    rulesVisible      = [0, 1, 2]
                    frameVisible      = true
                    ctaVisible        = true
                    return
                }
                #endif
                startAnimation()
            }
        }
    }

    // MARK: - Content Block

    @ViewBuilder
    private func contentBlock(
        h: CGFloat,
        w: CGFloat,
        isCompact: Bool,
        isMid: Bool,
        cardPad: CGFloat,
        cardGap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Progress bar
            OnboardingProgressBar(
                currentStep:          6,
                totalSteps:           6,
                progressDescription:  "Onboarding",
                showCompletionEffect: true
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, isCompact
                ? OL.navTop(h) + OL.compact(h)
                : OL.navTop(h) + OL.standard(h))
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : OL.standard(h))
            .opacity(progressVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: progressVisible)
            .accessibilityHidden(true)

            // Overline
            Group {
                if isLight {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta, location: 0.00),
                                    .init(color: AppColors.gold,    location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("BEFORE YOU DIVE IN")
                                    .font(AppFonts.overline)
                                    .tracking(2)
                            )
                        )
                } else {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.cyanLight)
                        .tracking(2)
                }
            }
            .opacity(overlineVisible ? 1 : 0)
            .offset(y: overlineVisible ? 0 : 8)
            .animation(.easeOut(duration: 0.6), value: overlineVisible)
            .padding(.horizontal, 24)
            .padding(.bottom, OL.compact(h))
            .accessibilityHidden(true)

            // Headline
            subheadView(h: h)
                .opacity(subtextVisible ? 1 : 0)
                .offset(y: subtextVisible ? 0 : 8)
                .animation(.easeOut(duration: 0.7), value: subtextVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, isCompact
                    ? OL.compact(h)
                    : isMid
                        ? OL.compact(h)
                        : OL.standard(h))

            // Promise Cards — all devices use FlipPromiseCard
            VStack(spacing: cardGap) {
                ForEach(pills) { pill in
                    let isVisible = rulesVisible.contains(pill.id)
                    FlipPromiseCard(
                        icon:         pill.icon,
                        iconGradient: pill.iconBg,
                        title:        pill.title,
                        detail:       pill.detail,
                        verticalPad:  cardPad,
                        cardHeight:   isCompact ? 72 : isMid ? 80 : 88
                    )
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 14)
                    .animation(.easeOut(duration: 0.7), value: isVisible)
                    .rotation3DEffect(
                        .degrees(pill.id == 0 && isPeeking ? 15 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h)
                    : OL.standard(h))
        }
        // NO Spacer, NO maxHeight frame, NO backgrounds
    }

    // MARK: - CTA Block

    private func ctaBlock(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let isCompact = h < 720
        let isMid = h >= 720 && h < 760
        let lifeguardFont: Font = isCompact
            ? AppFonts.body(16, weight: .medium)
            : isMid
                ? AppFonts.body(17, weight: .medium)
                : AppFonts.body(18, weight: .medium)
        return VStack(spacing: 0) {
            Text("Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one.")
                .font(lifeguardFont)
                .italic()
                .foregroundStyle(italicLineStyle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(frameVisible ? 1 : 0)
                .offset(y: frameVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.8), value: frameVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, OL.compact(h))
            HoloCTAButton(title: "I'm ready", isEnabled: true) {
                handleAcknowledge()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, geo.safeAreaInsets.bottom > 0
                ? geo.safeAreaInsets.bottom + 8
                : 24)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82),
                value: ctaVisible
            )
        }
    }

    // MARK: - Atmospheric Layer

    private var atmosphereLayer: some View {
        GeometryReader { geo in
            ZStack {
                if isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.magenta.opacity(0.12),
                                AppColors.gold.opacity(0.06),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.purple.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                } else {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.30),
                                AppColors.cyan.opacity(0.12),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.magenta.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)
                }
            }
        }
    }

    // MARK: - Animation Timeline

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 2.0)) { atmosphereVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.00) {
            withAnimation(.easeOut(duration: 0.6)) { progressVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.easeOut(duration: 0.6)) { overlineVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.7)) { subtextVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.7)) { _ = rulesVisible.insert(0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            withAnimation(.easeOut(duration: 0.7)) { _ = rulesVisible.insert(1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.easeOut(duration: 0.7)) { _ = rulesVisible.insert(2) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeOut(duration: 0.8)) { frameVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { ctaVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPeeking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPeeking = false }
        }
    }

    // MARK: - Acknowledge

    private func handleAcknowledge() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.groundRulesAcceptedAt = Date()
        data.onboardingComplete    = true
        data.completedAt           = Date()
        #if DEBUG
        assert(onFinished != nil,
            "OnboardingGroundRulesView: onFinished not injected — wire from coordinator.")
        #endif
        onFinished?()
    }
}

// MARK: - PromiseCard

private struct PromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 14

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                Text(detail)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, verticalPad)
        .cardSurface(isLight: isLight)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 40, height: 40)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - FlipPromiseCard

private struct FlipPromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 8
    var cardHeight:   CGFloat = 72

    @State private var isFlipped = false
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                iconBadge
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPad)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )

            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, verticalPad)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .cardSurface(isLight: isLight)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? detail : title)
        .accessibilityHint(isFlipped ? "Tap to show title" : "Tap to read more")
        .accessibilityAddTraits(.isButton)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 32, height: 32)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - Card Surface

private struct CardSurface: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight ? AppColors.lightCardFill : Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: AppColors.magenta.opacity(isLight ? 0.07 : 0),
                radius: 8, x: 0, y: 2
            )
            .modifier(PromiseCardBorder(isLight: isLight))
    }
}

private extension View {
    func cardSurface(isLight: Bool) -> some View {
        modifier(CardSurface(isLight: isLight))
    }
}

// MARK: - PromiseCardBorder

private struct PromiseCardBorder: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        if isLight {
            content
                .magentaGoldBorder(cornerRadius: 20, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        } else {
            content
                .pillBorder(cornerRadius: 20, lineWidth: 1, glowRadius: 3, opacity: 0.45)
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
    OnboardingGroundRulesView(data: $data, onFinished: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    OnboardingGroundRulesView(data: $data, onFinished: {})
        .preferredColorScheme(.light)
}

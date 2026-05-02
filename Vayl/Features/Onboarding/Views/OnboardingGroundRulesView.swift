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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasAnimated        = false
    @State private var atmosphereVisible  = false
    @State private var progressVisible    = false
    @State private var overlineVisible    = false
    @State private var subtextVisible     = false
    @State private var rulesVisible: Set<Int> = []
    @State private var frameVisible       = false
    @State private var ctaVisible         = false
    @State private var isPeeking          = false
    @State private var hasAcknowledged    = false

    // MARK: - Pill Data

    private struct PillContent: Identifiable {
        let id:       Int
        let icon:     String
        let iconBg:   AnyShapeStyle
        let title:    String
        let detail:   String
    }

    private var pills: [PillContent] {
        let pill2: PillContent = data.appMode == .together
            ? PillContent(
                id: 1,
                icon: AppIcons.heartFill,
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.progressBarLeading, AppColors.safetyAccent],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This works best when you're both curious.",
                detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
              )
            : PillContent(
                id: 1,
                icon: AppIcons.figureWalk,
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.progressBarLeading, AppColors.safetyAccent],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This won't resolve things you're running from.",
                detail: "The best it can do is help you understand what you're running toward."
              )
        return [
            PillContent(
                id: 0,
                icon: AppIcons.lightbulb,
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.accentTertiary, AppColors.progressBarLeading],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "They say money shows you more of who you are.",
                detail: "This journey will do more of the same. The people who go deepest with it are the ones who surprise themselves."
            ),
            pill2,
            PillContent(
                id: 2,
                icon: AppIcons.handRaised,
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.accentTertiary, AppColors.safetyAccent],
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
        isLight ? AppColors.textPrimary : AppColors.textPrimary
    }

    private var italicLineStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.accentTertiary,    location: 0.00),
                    .init(color: AppColors.progressBarLeading, location: 0.55),
                    .init(color: AppColors.safetyAccent,       location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Subhead View

    @ViewBuilder
    private func subheadView(h: CGFloat) -> some View {
        let font: Font = h < 700
            ? AppFonts.display(18, weight: .bold, relativeTo: .title3)
            : h < 760
                ? AppFonts.display(20, weight: .bold, relativeTo: .title3)
                : h < 820
                    ? AppFonts.display(21, weight: .bold, relativeTo: .title3)
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
                        .padding(.horizontal, AppSpacing.lg)
                }
                .frame(minHeight: geo.size.height)
            }
            .safeAreaPadding(.bottom, AppSpacing.sm)
            .background {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    atmosphereLayer
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
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
            .animation(AppAnimation.slow, value: progressVisible)
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
                                    .init(color: AppColors.accentTertiary,    location: 0.00),
                                    .init(color: AppColors.progressBarLeading, location: 0.55),
                                    .init(color: AppColors.safetyAccent,       location: 1.00),
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
                        .foregroundStyle(AppColors.accentPrimary)
                        .tracking(2)
                }
            }
            .opacity(overlineVisible ? 1 : 0)
            .scaleEffect(overlineVisible ? 1.0 : 0.95)
            .animation(AppAnimation.spring, value: overlineVisible)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, OL.compact(h))
            .accessibilityHidden(true)

            // Headline
            subheadView(h: h)
                .opacity(subtextVisible ? 1 : 0)
                .scaleEffect(subtextVisible ? 1.0 : 0.95)
                .animation(AppAnimation.spring, value: subtextVisible)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, isCompact
                    ? OL.compact(h)
                    : isMid
                        ? OL.compact(h)
                        : OL.standard(h))

            // Promise Cards
            VStack(spacing: cardGap) {
                ForEach(pills) { pill in
                    let isVisible = rulesVisible.contains(pill.id)
                    let cardView = FlipPromiseCard(
                        icon:         pill.icon,
                        iconGradient: pill.iconBg,
                        title:        pill.title,
                        detail:       pill.detail,
                        verticalPad:  cardPad,
                        cardHeight:   isCompact ? 72 : isMid ? 80 : 88
                    )
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1.0 : 0.95)
                    .animation(AppAnimation.spring, value: isVisible)

                    if pill.id == 0 {
                        cardView
                            .rotation3DEffect(
                                .degrees(isPeeking ? 15 : 0),
                                axis: (x: 1, y: 0, z: 0),
                                perspective: 0.5
                            )
                    } else {
                        cardView
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h)
                    : OL.standard(h))
        }
    }

    // MARK: - CTA Block

    private func ctaBlock(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let isCompact = h < 720
        let isMid = h >= 720 && h < 760
        let lifeguardFont: Font = isCompact
            ? AppFonts.body(16, weight: .medium, relativeTo: .body)
            : isMid
                ? AppFonts.body(17, weight: .medium, relativeTo: .body)
                : AppFonts.body(18, weight: .medium, relativeTo: .body)

        return VStack(spacing: 0) {
            Text("Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one.")
                .font(lifeguardFont)
                .italic()
                .foregroundStyle(italicLineStyle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(frameVisible ? 1 : 0)
                .scaleEffect(frameVisible ? 1.0 : 0.95)
                .animation(AppAnimation.spring, value: frameVisible)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, OL.compact(h))

            Text("When you're ready, we'll get started.")
                .font(AppFonts.caption)
                .foregroundStyle(isLight
                    ? AppColors.textSecondary
                    : AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(ctaVisible ? 1 : 0)
                .animation(AppAnimation.spring, value: ctaVisible)
                .padding(.bottom, AppSpacing.md)

            HoloCTAButton(title: "I'm ready", isEnabled: true) {
                handleAcknowledge()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, AppSpacing.lg)
            .opacity(ctaVisible ? 1 : 0)
            .animation(AppAnimation.spring, value: ctaVisible)
        }
    }

    // MARK: - Atmospheric Layer
    // .easeInOut(duration: 2.0) — intentional above-ceiling atmospheric weight.
    // One-time reveal, not an ambient loop. Not a token candidate.

    private var atmosphereLayer: some View {
        GeometryReader { geo in
            ZStack {
                if isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.accentTertiary.opacity(0.12),
                                AppColors.safetyAccent.opacity(0.06),
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
                            colors: [AppColors.accentSecondary.opacity(0.08), Color.clear],
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
                                AppColors.accentSecondary.opacity(0.30),
                                AppColors.accentPrimary.opacity(0.12),
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
                            colors: [AppColors.accentTertiary.opacity(0.08), Color.clear],
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
        if reduceMotion {
            withAnimation(AppAnimation.fast) {
                atmosphereVisible = true
                progressVisible   = true
                overlineVisible   = true
                subtextVisible    = true
                rulesVisible      = [0, 1, 2]
                frameVisible      = true
                ctaVisible        = true
            }
            return
        }

        // Three-slot spring cascade:
        // Slot A (header — progress + overline + subtext): 0ms, 50ms, 100ms
        // Slot B (body  — cards staggered):               100ms, 150ms, 200ms
        // Slot C (CTA   — lifeguard line + button):       300ms
        withAnimation(.easeInOut(duration: 2.0)) { atmosphereVisible = true }

        // Slot A
        withAnimation(AppAnimation.spring) { progressVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(AppAnimation.spring) { overlineVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(AppAnimation.spring) { subtextVisible = true }
        }

        // Slot B
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(AppAnimation.spring) { _ = rulesVisible.insert(0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(AppAnimation.spring) { _ = rulesVisible.insert(1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(AppAnimation.spring) { _ = rulesVisible.insert(2) }
        }

        // Slot C
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(AppAnimation.spring) { frameVisible = true }
            withAnimation(AppAnimation.spring) { ctaVisible   = true }
        }

        // Peek effect — intentional low-damping springs for physical bounce feel.
        // response: 0.3 / damping: 0.5 attack and response: 0.4 / damping: 0.6
        // release are deliberately bouncier than AppAnimation.spring (0.85 damping).
        // Migrating to AppAnimation.spring would kill the bounce.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPeeking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(AppAnimation.spring) { isPeeking = false }
        }
    }

    // MARK: - Acknowledge

    private func handleAcknowledge() {
        guard !hasAcknowledged else { return }
        hasAcknowledged = true
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
            HStack(spacing: AppSpacing.md) {
                iconBadge
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.textPrimary : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: AppIcons.arrowTurnUpLeft)
                    // .caption2 scales with Dynamic Type — correct for
                    // small decorative flip indicator at this visual weight.
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isLight
                        ? AppColors.textTertiary
                        : AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, verticalPad)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )

            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.textSecondary : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, verticalPad)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight)
        .cardSurface(isLight: isLight)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(AppAnimation.spring) {
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
                            colors: [AppColors.accentPrimary.opacity(0.20), AppColors.accentSecondary.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                // .caption scales with Dynamic Type — correct for icon badges
                // inside a fixed 32pt circle at this visual weight.
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.accentTertiary,    location: 0.00),
                                .init(color: AppColors.progressBarLeading, location: 0.55),
                                .init(color: AppColors.safetyAccent,       location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.accentPrimary, AppColors.accentSecondary],
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
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(isLight ? AppColors.cardBackground : Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(
                color: AppColors.accentTertiary.opacity(isLight ? 0.07 : 0),
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
                .magentaGoldBorder(cornerRadius: AppRadius.xl, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        } else {
            content
                .pillBorder(cornerRadius: AppRadius.xl, lineWidth: 1, glowRadius: 3, opacity: 0.45)
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        d.appMode     = .solo
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        d.appMode     = .solo
        return d
    }()
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.light)
}

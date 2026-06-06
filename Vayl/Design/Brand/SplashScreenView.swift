import SwiftUI

// MARK: - Glyph origin preference

private struct LOriginKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Splash Screen View

struct SplashScreenView<Destination: View>: View {

    var onComplete:  () -> Void
    var onTearBegan: () -> Void
    var destination: Destination

    private let seamFadeHeight: CGFloat = 30

    @State private var screenW: CGFloat = 0
    @State private var screenH: CGFloat = 0

    private var lineY: CGFloat { (screenH * 0.50).rounded(.down) }

    private var wordmarkSize: CGFloat {
        if screenW <= 375 { return 70 }
        if screenW >= 428 { return 96 }
        return 84
    }

    private var tearDistance: CGFloat { screenH * 0.70 }

    // MARK: - Animation state

    @State private var revealProgress:     CGFloat = 0
    @State private var lineOpacity:        CGFloat = 0
    @State private var lineBloom:          CGFloat = 0
    @State private var linePulse:          CGFloat = 1.0
    @State private var textOpacity:        CGFloat = 1.0
    @State private var zoomScale:          CGFloat = 1.0
    @State private var tearOffset:         CGFloat = 0
    @State private var tearIntensity:      CGFloat = 0
    @State private var destinationOpacity: CGFloat = 0
    @State private var splashOpacity:      CGFloat = 1
    @State private var backgroundOpacity:  CGFloat = 1
    @State private var animationTask:      Task<Void, Never>?
    @State private var capturedLineY:      CGFloat = 0
    @State private var capturedTearDist:   CGFloat = 0

    @State private var hasAnimated:    Bool    = false

    @State private var wordmarkFrame:  CGRect  = .zero
    @State private var lGlyphOriginX:  CGFloat = 0

    @State private var capturedLineLeft:  CGFloat = 0
    @State private var capturedLineRight: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Derived mask depth

    private var effectiveSeamFadeHeight: CGFloat {
        guard capturedTearDist > 0 else { return 0 }
        return seamFadeHeight * min(tearOffset / capturedTearDist, 1.0)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                destination
                    .opacity(destinationOpacity)

                if screenW > 0 && screenH > 0 && splashOpacity > 0 {
                    ZStack {
                        ZStack {
                            AppColors.pageBackground
                                .ignoresSafeArea()
                            OnboardingAtmosphere()
                                .ignoresSafeArea()
                        }
                        .opacity(backgroundOpacity)

                        splashContent
                    }
                    .opacity(splashOpacity)
                }
            }
            .onAppear {
                screenW = geo.size.width
                screenH = geo.size.height
                guard screenW > 0, screenH > 0 else { return }
                launchSequence()
            }
            .onChange(of: geo.size) { _, newSize in
                let previousW = screenW
                screenW = newSize.width
                screenH = newSize.height

                capturedLineY    = (newSize.height * 0.50).rounded(.down)
                capturedTearDist = newSize.height * 0.70

                if newSize.width != previousW, capturedLineLeft > 0 {
                    animationTask?.cancel()
                    animationTask      = nil
                    capturedLineLeft   = 0
                    capturedLineRight  = 0
                    wordmarkFrame      = .zero
                    lGlyphOriginX      = 0
                    revealProgress     = 0
                    lineOpacity        = 0
                    lineBloom          = 0
                    linePulse          = 1.0
                    textOpacity        = 1.0
                    zoomScale          = 1.0
                    tearOffset         = 0
                    tearIntensity      = 0
                    destinationOpacity = 0
                    splashOpacity      = 1
                    backgroundOpacity  = 1
                }

                if animationTask == nil, newSize.width > 0, newSize.height > 0 {
                    launchSequence()
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onDisappear {
            animationTask?.cancel()
        }
    }

    // MARK: - Sequence launcher

    private func launchSequence() {
        guard !hasAnimated else { return }
        hasAnimated      = true
        capturedLineY    = lineY
        capturedTearDist = tearDistance

        animationTask = Task { @MainActor in
            if reduceMotion {
                await runReducedMotionSequence()
            } else {
                await runFullSequence()
            }
            animationTask = nil
        }
    }

    // MARK: - Lock geometry

    private func lockLineGeometry() async {
        let pollInterval = 20
        let maxWait      = 200
        var elapsed      = 0

        while elapsed < maxWait {
            if wordmarkFrame.width > 0, lGlyphOriginX > 0 { break }
            try? await sleep(ms: pollInterval)
            elapsed += pollInterval
        }

        let g = computedLineGeometry
        capturedLineLeft  = g.left
        capturedLineRight = g.right
    }

    // MARK: - Splash content
    //
    // spectrumLineView sits above both panels so it is never subject to
    // either panel's mask.  The .scaleEffect on this ZStack still applies
    // to it so zoom behaviour is unchanged.

    private var splashContent: some View {
        ZStack {
            topPanel
            bottomPanel
            spectrumLineView
        }
        .scaleEffect(
            zoomScale,
            anchor: UnitPoint(x: 0.5, y: capturedLineY / max(screenH, 1))
        )
    }

    // MARK: - Top panel

    private var topPanel: some View {
        ZStack(alignment: .bottom) {
            AppColors.pageBackground
                .ignoresSafeArea()
            OnboardingAtmosphere()
                .ignoresSafeArea()

            wordmarkReveal(isTop: true)

            tearEdgeGlow(isTop: true)
                .frame(width: screenW)
                .opacity(tearIntensity)
        }
        .frame(width: screenW, height: screenH)
        .clipped()
        .offset(y: -tearOffset)
        .mask(
            VStack(spacing: 0) {
                Color.black
                    .frame(height: max(capturedLineY - effectiveSeamFadeHeight, 0))
                // FIX 1 (top panel): use .black.opacity(0) instead of .clear to
                // avoid premultiplied-alpha dark fringe after compositing.
                LinearGradient(
                    colors: [.black, .black.opacity(0)],
                    startPoint: .top,
                    endPoint:   .bottom
                )
                .frame(height: min(effectiveSeamFadeHeight, capturedLineY))
                Color.clear
            }
            .frame(width: screenW, height: screenH, alignment: .top)
        )
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        ZStack(alignment: .top) {
            AppColors.pageBackground
                .ignoresSafeArea()
            OnboardingAtmosphere()
                .ignoresSafeArea()

            // ── Measurement anchor 1 — full wordmark frame ─────────────────
            Text("VAYL")
                .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
                .tracking(wordmarkSize * 0.07)
                .fixedSize()
                .hidden()
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                wordmarkFrame = proxy.frame(in: .named("panel"))
                            }
                            .onChange(of: proxy.size) { _, _ in
                                if capturedLineLeft == 0 {
                                    wordmarkFrame = proxy.frame(in: .named("panel"))
                                }
                            }
                    }
                )
                .position(x: screenW / 2, y: capturedLineY)
                .frame(width: screenW, height: screenH)

            // ── Measurement anchor 2 — L glyph origin ─────────────────────
            HStack(spacing: 0) {
                Text("V")
                    .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
                    .tracking(wordmarkSize * 0.07)
                    .hidden().fixedSize()
                Text("A")
                    .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
                    .tracking(wordmarkSize * 0.07)
                    .hidden().fixedSize()
                Text("Y")
                    .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
                    .tracking(wordmarkSize * 0.07)
                    .hidden().fixedSize()
                Text("L")
                    .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
                    .hidden().fixedSize()
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: LOriginKey.self,
                                value: proxy.frame(in: .named("panel")).minX
                            )
                        }
                    )
            }
            .fixedSize()
            .position(x: screenW / 2, y: capturedLineY)
            .frame(width: screenW, height: screenH)
            .onPreferenceChange(LOriginKey.self) { newValue in
                if capturedLineLeft == 0 {
                    lGlyphOriginX = newValue
                }
            }

            wordmarkReveal(isTop: false)

            // spectrumLineView intentionally absent — lives in splashContent.

            tearEdgeGlow(isTop: false)
                .frame(width: screenW)
                .opacity(tearIntensity)
        }
        .coordinateSpace(name: "panel")
        .frame(width: screenW, height: screenH)
        .clipped()
        .offset(y: tearOffset)
        .mask(
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: capturedLineY)
                // FIX 1 (bottom panel): use .black.opacity(0) instead of .clear
                // to avoid premultiplied-alpha dark fringe after compositing.
                LinearGradient(
                    colors: [.black.opacity(0), .black],
                    startPoint: .top,
                    endPoint:   .bottom
                )
                .frame(height: effectiveSeamFadeHeight)
                Color.black
            }
            .frame(width: screenW, height: screenH, alignment: .top)
        )
    }

    // MARK: - Wordmark reveal

    private func wordmarkReveal(isTop: Bool) -> some View {
        let halfH:   CGFloat = isTop ? capturedLineY : (screenH - capturedLineY)
        let revealH: CGFloat = revealProgress * halfH

        return wordmarkText(isTop: isTop)
            .position(x: screenW / 2, y: capturedLineY)
            .frame(width: screenW, height: screenH)
            .mask(
                GeometryReader { _ in
                    if isTop {
                        Rectangle()
                            .frame(width: screenW, height: revealH)
                            .position(
                                x: screenW / 2,
                                y: capturedLineY - (revealH / 2)
                            )
                    } else {
                        Rectangle()
                            .frame(width: screenW, height: revealH)
                            .position(
                                x: screenW / 2,
                                y: capturedLineY + (revealH / 2)
                            )
                    }
                }
                .frame(width: screenW, height: screenH)
            )
    }

    // MARK: - Wordmark text  ← DO NOT TOUCH

    private func wordmarkText(isTop: Bool) -> some View {
        Text("VAYL")
            .font(AppFonts.display(wordmarkSize, weight: .bold, relativeTo: .largeTitle))
            .tracking(wordmarkSize * 0.07)
            .foregroundStyle(
                isTop
                    ? AnyShapeStyle(topWordmarkColor)
                    : AnyShapeStyle(bottomWordmarkGradient)
            )
            .shadow(
                color: (isTop
                    ? AppColors.spectrumCyan.opacity(0.28)
                    : AppColors.spectrumPurple.opacity(0.38))
                    .opacity(textOpacity),
                radius: 14
            )
            .shadow(
                color: (isTop
                    ? AppColors.spectrumPurple.opacity(0.18)
                    : AppColors.spectrumMagenta.opacity(0.18))
                    .opacity(textOpacity),
                radius: 32
            )
            .opacity(textOpacity)
    }

    private var topWordmarkColor: Color {
        Color(red: 0.902, green: 0.933, blue: 1.0).opacity(0.97)
    }

    private let bottomWordmarkGradient = LinearGradient(
        stops: [
            .init(color: AppColors.spectrumCyan,    location: 0.0),
            .init(color: AppColors.spectrumPurple,  location: 0.5),
            .init(color: AppColors.spectrumMagenta, location: 1.0),
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )

    // MARK: - Spectrum line
    //
    // The top-level .blendMode(.plusLighter) that was previously on the
    // outermost ZStack has been removed (FIX 2).  Placing a blend mode on a
    // child ZStack whose ancestor carries .scaleEffect / .opacity forces
    // SwiftUI to resolve the entire subtree into an off-screen buffer that is
    // initialised to opaque black; .plusLighter then adds the glow to that
    // black fill rather than to the real content behind it, producing a solid
    // black box artefact during zoom.  The individual .plusLighter modifiers
    // on the two glow ellipses are sufficient — they blend correctly against
    // the live compositor output without triggering an off-screen pass.

    private var spectrumLineView: some View {
        let geo   = spectrumLineGeometry
        let width = geo.right - geo.left
        let midX  = (geo.left + geo.right) / 2

        let bloomOpacity = min(sqrt(max(lineBloom, 0)), 1.0)

        return ZStack {

            // ── Outer glow halo ──────────────────────────────────────────
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.spectrumCyan.opacity(0),       location: 0.00),
                            .init(color: AppColors.spectrumCyan.opacity(0.14),    location: 0.20),
                            .init(color: AppColors.spectrumPurple.opacity(0.24),  location: 0.50),
                            .init(color: AppColors.spectrumMagenta.opacity(0.14), location: 0.80),
                            .init(color: AppColors.spectrumMagenta.opacity(0),    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: width, height: 18)
                .blur(radius: 4)
                .blendMode(.plusLighter)
                .opacity(bloomOpacity)

            // ── Tight inner glow ─────────────────────────────────────────
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.spectrumCyan.opacity(0),       location: 0.00),
                            .init(color: AppColors.spectrumCyan.opacity(0.50),    location: 0.15),
                            .init(color: AppColors.spectrumPurple.opacity(0.65),  location: 0.50),
                            .init(color: AppColors.spectrumMagenta.opacity(0.50), location: 0.85),
                            .init(color: AppColors.spectrumMagenta.opacity(0),    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: width * 0.94, height: 5)
                .blur(radius: 1.5)
                .blendMode(.plusLighter)
                .opacity(bloomOpacity)

            // ── Spectrum razor line ──────────────────────────────────────
            Rectangle()
                .fill(spectrumGradient)
                .frame(width: width, height: 3.5)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.04),
                            .init(color: .black, location: 0.10),
                            .init(color: .black, location: 0.90),
                            .init(color: .clear, location: 0.96),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )

            // ── White centre hotspot ─────────────────────────────────────
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0),    location: 0.00),
                            .init(color: .white.opacity(0),    location: 0.15),
                            .init(color: .white.opacity(0.95), location: 0.50),
                            .init(color: .white.opacity(0),    location: 0.85),
                            .init(color: .white.opacity(0),    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: width, height: 1)
                .opacity(min(lineBloom, 1.0))
        }
        // FIX 2: top-level .blendMode(.plusLighter) removed.  See note above.
        .scaleEffect(x: 1.0, y: linePulse, anchor: .center)
        .opacity(lineOpacity)
        .position(x: midX, y: capturedLineY)
        .frame(width: screenW, height: screenH)
    }

    // MARK: - Tear edge glow

    private func tearEdgeGlow(isTop: Bool) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.spectrumCyan.opacity(0),       location: 0.00),
                            .init(color: AppColors.spectrumCyan.opacity(0.12),    location: 0.20),
                            .init(color: AppColors.spectrumPurple.opacity(0.22),  location: 0.50),
                            .init(color: AppColors.spectrumMagenta.opacity(0.12), location: 0.80),
                            .init(color: AppColors.spectrumMagenta.opacity(0),    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: screenW * 0.90, height: 52)
                .blur(radius: 14)
                .offset(y: isTop ? 20 : -20)
                .opacity(0.80)

            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.spectrumCyan.opacity(0),       location: 0.00),
                            .init(color: AppColors.spectrumCyan.opacity(0.45),    location: 0.15),
                            .init(color: AppColors.spectrumPurple.opacity(0.60),  location: 0.50),
                            .init(color: AppColors.spectrumMagenta.opacity(0.45), location: 0.85),
                            .init(color: AppColors.spectrumMagenta.opacity(0),    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(width: screenW * 0.82, height: 14)
                .blur(radius: 5)
                .offset(y: isTop ? 6 : -6)

            Rectangle()
                .fill(Color.white.opacity(0.80))
                .frame(width: screenW * 0.78, height: 1)
        }
        // FIX 3: frame increased from 72 to 140 so the blur kernel on the
        // outer ellipse (radius 14, needing ≈84 pt headroom) can fully
        // resolve on both the top and bottom edges without being clipped to
        // a soft rectangular box.
        .frame(height: 140)
    }

    // MARK: - Shared gradient

    private let spectrumGradient = LinearGradient(
        stops: [
            .init(color: AppColors.spectrumCyan,    location: 0.0),
            .init(color: AppColors.spectrumPurple,  location: 0.5),
            .init(color: AppColors.spectrumMagenta, location: 1.0),
        ],
        startPoint: .leading,
        endPoint:   .trailing
    )

    // MARK: - Spectrum line geometry

    private var spectrumLineGeometry: (left: CGFloat, right: CGFloat) {
        if capturedLineLeft > 0 {
            return (left: capturedLineLeft, right: capturedLineRight)
        }
        return computedLineGeometry
    }

    private var computedLineGeometry: (left: CGFloat, right: CGFloat) {
        guard wordmarkFrame.width > 0, lGlyphOriginX > 0 else {
            return (left: screenW * 0.10, right: screenW * 0.90)
        }

        let font   = UIFont(name: "ClashDisplay-Bold", size: wordmarkSize)
                     ?? UIFont.boldSystemFont(ofSize: wordmarkSize)
        let ctFont = font as CTFont

        func glyphAdvance(_ char: String) -> CGFloat {
            var utf16 = Array(char.utf16)
            var glyph = CGGlyph(0)
            CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
            var adv = CGSize.zero
            CTFontGetAdvancesForGlyphs(ctFont, .horizontal, &glyph, &adv, 1)
            return adv.width
        }

        func glyphBbox(_ char: String) -> CGRect {
            var utf16 = Array(char.utf16)
            var glyph = CGGlyph(0)
            CTFontGetGlyphsForCharacters(ctFont, &utf16, &glyph, 1)
            var bbox = CGRect.zero
            CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, &bbox, 1)
            return bbox
        }

        let vBbox = glyphBbox("V")
        let lAdv  = glyphAdvance("L")

        let lineLeft  = wordmarkFrame.minX + vBbox.minX
        let lineRight = lGlyphOriginX + lAdv * 0.38

        return (left: lineLeft, right: lineRight)
    }

    // MARK: - Full animation sequence

    @MainActor
    private func runFullSequence() async {

        // ── ATMOSPHERE SETTLE ─────────────────────────────────────────────
        try? await sleep(ms: 420)
        guard !Task.isCancelled else { return }

        // ── APPEAR ───────────────────────────────────────────────────────
        await lockLineGeometry()
        withAnimation(AppAnimation.splashLineAppear)                  { lineOpacity = 1 }
        withAnimation(AppAnimation.splashReveal)                      { revealProgress = 1.0 }
        withAnimation(.easeInOut(duration: 0.30)) /* TODO: AppAnimation.splashBloomCreep — no token, spec gap */ { lineBloom = 0.58 }

        // ── IGNITION BLOOM ────────────────────────────────────────────────
        try? await sleep(ms: 600)
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.splashBloomIgnite) { lineBloom = 1.0; linePulse = 1.6 }

        // ── HOLD SETTLE ───────────────────────────────────────────────────
        try? await sleep(ms: 600)
        guard !Task.isCancelled else { return }
        withAnimation(AppAnimation.splashBloomSettle) { lineBloom = 0.65; linePulse = 1.0 }

        // ── ZOOM ──────────────────────────────────────────────────────────
        try? await sleep(ms: 450)
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.22)) /* TODO: AppAnimation token — textFade has no spec equivalent */ { textOpacity = 0 }
        withAnimation(AppAnimation.splashZoom)          { zoomScale = 3.5; lineBloom = 3.0; linePulse = 1.4 }
        withAnimation(AppAnimation.splashZoomAnticipate) { tearIntensity = 0.8 }

        // 350 ms zoom — tear fires 50 ms early so zoom momentum transfers
        // directly into the rip with no dead-air pause.
        try? await sleep(ms: 300)
        guard !Task.isCancelled else { return }

        // ── TEAR ──────────────────────────────────────────────────────────
        onTearBegan()
        withAnimation(.easeIn(duration: 0.30)) /* TODO: AppAnimation token — destination reveal has no spec equivalent */ { destinationOpacity = 1.0 }
        withAnimation(AppAnimation.splashTear)          { tearOffset = capturedTearDist; backgroundOpacity = 0 }
        withAnimation(.easeOut(duration: 0.10)) /* TODO: AppAnimation token — tearIntensity spike has no spec equivalent */ { tearIntensity = 1.0 }

        // FIX 1: line vaporizes instantly the moment the seam opens.
        // The tearEdgeGlow on the parting panels immediately inherits the
        // visual energy — no zombie line floating in the void.
        withAnimation(.easeOut(duration: 0.25)) /* TODO: AppAnimation token — line vaporize has no spec equivalent */ { lineOpacity = 0 }

        try? await sleep(ms: 100)
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: 0.35)) /* TODO: AppAnimation token — tearIntensity decay has no spec equivalent */ { tearIntensity = 0 }
        withAnimation(.linear(duration: 0.08)) /* TODO: AppAnimation.splashTearFade — no token, spec gap */              { lineBloom = 0; linePulse = 1.0 }

        // Wait for panels to mostly clear before dismissing the overlay.
        try? await sleep(ms: 250)
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.30)) /* TODO: AppAnimation.splashDismiss — no token, spec gap */ { splashOpacity = 0 }

        // ── COMPLETE ──────────────────────────────────────────────────────
        try? await sleep(ms: 300)
        guard !Task.isCancelled else { return }
        onComplete()
    }

    // MARK: - Reduced motion sequence

    @MainActor
    private func runReducedMotionSequence() async {
        let staticDisplayMs: Int = 800
        let fadeDurationMs:  Int = 250

        await lockLineGeometry()
        lineOpacity    = 1
        lineBloom      = 0.35
        revealProgress = 1.0

        try? await sleep(ms: staticDisplayMs)
        guard !Task.isCancelled else { return }

        // FIX 4: fire onTearBegan so the caller can prepare the destination,
        // then cross-fade the destination in while the splash fades out.
        // Previously destinationOpacity was never set, leaving the caller
        // trapped on a transparent screen after splashOpacity reached zero.
        onTearBegan()
        withAnimation(AppAnimation.standard) {
            destinationOpacity = 1.0
            splashOpacity      = 0
        }

        try? await sleep(ms: fadeDurationMs + 50)
        guard !Task.isCancelled else { return }
        onComplete()
    }

    // MARK: - Sleep helper

    private func sleep(ms: Int) async throws {
        try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    }
}

// MARK: - Previews

#Preview("Splash — cold launch") {
    SplashScreenView(
        onComplete:  {},
        onTearBegan: {},
        destination: Color.black
    )
    .preferredColorScheme(.dark)
}

#Preview("Splash — reduced motion") {
    SplashScreenView(
        onComplete:  {},
        onTearBegan: {},
        destination: Color.black
    )
    .preferredColorScheme(.dark)
}

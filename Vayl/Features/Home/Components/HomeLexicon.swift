// Features/Home/Components/HomeLexicon.swift
// Vayl
//
// Module 3 — "Today": a card-less, auto-advancing daily 5.
//
// A small finite ritual (5 a day, a different 5 every 24h, deterministic so both
// partners get the same set), NOT an infinite feed. Each page is centered type on
// the void — the quiet "type" layer — so it never competes with the deck (object)
// or the Pulse (light). No card in-app (one card, the Pulse, is enough); the word
// carries real spectrum colour so it has presence without a frame.
//
// Per-kind layouts:
//   • research  → the stat leads (big, spectrum) + the claim
//   • term      → the word leads (big, spectrum) + the definition
//   • sentence  → a pull-quote leads + the term + meaning
//
// Sharing exports a foil COLLECTIBLE card (LexiconShareCard, VaylCardFace language:
// spectrum border + ✦ corners) rendered to a 9:16 image via ImageRenderer — a real,
// branded Story poster, not a text share.
//
// Behaviour (feel values — tune on device): full-page paged, NO dots; gently
// auto-advances with a smooth slide and loops seamlessly; a horizontal swipe pauses
// the auto-advance and resumes after a beat; Reduce Motion = swipe only.

import SwiftUI
import UIKit

struct HomeLexicon: View {

    /// Server-overridden content, injected from HomeStore via HomeDashboardView
    /// (nil → bundled baseline). The view never fetches content itself (H-2).
    var remotePool: LexiconRemotePool?
    /// Tapping a page routes to its destination (the dossier / Learn).
    var onOpen: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var index = 0          // 0...daily.count (last is the clone)
    @State private var dragX: CGFloat = 0
    @State private var paused = false
    @State private var resumeItem: DispatchWorkItem?
    @State private var kept = false
    @State private var shareImage: ShareImage?
    /// Each page's measured content height (keyed by index). Used to reserve the tallest so the
    /// pager holds one stable height across the daily 5 rather than resizing per item.
    @State private var pageHeights: [Int: CGFloat] = [:]

    /// The tallest measured page — the pager reserves this so it never resizes between the daily
    /// 5. Falls back to `pageHeight` only for the first frame, before any measurement lands.
    private var maxPageHeight: CGFloat {
        pageHeights.values.max() ?? pageHeight
    }

    // Feel values (tunable on device).
    private let interval: TimeInterval = 12.0   // slow, ambient dwell (not a ticker)
    private let resumeDelay: TimeInterval = 12.0
    private let pageHeight: CGFloat      = 180     // FIRST-FRAME FALLBACK ONLY. Each page measures its own content
                                                     // height (PageHeightKey) and the pager animates to it, so this is
                                                     // used only for the one frame before measurement lands. It is NOT a
                                                     // gap dial: the Lexicon's rest position above the tab bar is owned by
                                                     // the column's bottom-anchor in HomeDashboardView (the flexible hero
                                                     // Spacer filling `safeContentH`), not by padding this page taller.
    private let slideDuration: Double       = 0.55

    // MARK: - Content

    enum LexCategory { case research, term, sentence, culture }

    /// Deterministic RNG so a given day's seed always yields the same shuffle.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 &+ 0x1 }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    private struct Item: Identifiable {
        let id = UUID()
        let category: LexCategory
        let label: String   // overline
        let keyword: String   // the canonical stat/term (share foil hero)
        let detail: String   // claim / definition / meaning
        var quote: String?  // sentence only — the usage example
        let act: String
    }

    // Bundled is the instant baseline + offline fallback; the injected remotePool
    // overrides it when present, so the daily-5 can change without an app build.
    private var pool: [Item] {
        guard let remotePool else { return Self.bundledPool }
        return Self.buildPool(
            remoteFindings: remotePool.findings,
            remoteTerms: remotePool.terms,
            remoteQuotes: remotePool.quotes
        )
    }

    private static let bundledPool: [Item] = buildPool()

    // Per-kind bundled caches: `pool` is computed per body evaluation (body runs every
    // frame during a drag), so the JSON decode must happen exactly once per launch —
    // never inside buildPool's fallback path.
    private static let bundledFindings: [ResearchFinding] =
        (try? ContentLoader.load(ResearchFinding.self, from: "research_findings")) ?? []
    private static let bundledTerms: [LexiconTerm] =
        (try? ContentLoader.load(LexiconTerm.self, from: "lexicon_terms")) ?? []
    private static let bundledQuotes: [MediaQuote] =
        (try? ContentLoader.load(MediaQuote.self, from: "media_quotes")) ?? []

    private static func buildPool(remoteFindings: [ResearchFinding]? = nil,
                                  remoteTerms: [LexiconTerm]? = nil,
                                  remoteQuotes: [MediaQuote]? = nil) -> [Item] {
        let findings = remoteFindings ?? bundledFindings
        let terms    = remoteTerms    ?? bundledTerms
        let quotes   = remoteQuotes   ?? bundledQuotes

        let researchItems: [Item] = findings.map { f in
            Item(category: .research, label: "From the Research",
                 keyword: f.stat ?? f.headline,
                 detail: f.finding,
                 quote: nil,
                 act: "See the research")
        }
        let termItems: [Item] = terms.map { t in
            switch t.kind {
            case .term:
                return Item(category: .term, label: "From the Lexicon",
                            keyword: t.term, detail: t.definition,
                            quote: nil, act: "There's a card about this")
            case .sentence:
                return Item(category: .sentence, label: "In a sentence",
                            keyword: t.term, detail: t.definition,
                            quote: t.example, act: "Open in the Lexicon")
            }
        }
        let cultureItems: [Item] = quotes.map { q in
            Item(category: .culture, label: "From the culture",
                 keyword: q.author, detail: q.source ?? "",
                 quote: q.quote, act: "Explore in Learn")
        }
        return researchItems + termItems + cultureItems
    }

    /// Today's 5 — deterministic per calendar day. A UTC day index seeds a stable
    /// shuffle, so both partners get the same 5 and it rotates every 24h.
    private var daily: [Item] {
        let p = pool
        guard p.count > 5 else { return p }
        let dayIndex = Int(Date().timeIntervalSince1970 / 86_400)
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(dayIndex)))
        return Array(p.shuffled(using: &rng).prefix(5))
    }

    /// A clone of the first page is appended so the forward loop is seamless.
    private var pages: [Item] {
        guard let first = daily.first else { return [] }
        return daily + [first]
    }

    // Contrast-aware overline tier.
    private var kindColor: Color { contrast == .increased ? AppColors.textSecondary : AppColors.textTertiary }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Static section header — stays fixed while the daily items swipe beneath
            // it (the per-page eyebrow used to slide/swap, which read as jittery).
            overline("From the Research")
                .frame(maxWidth: .infinity)

            pager
        }
        .vaylShareSheet(item: $shareImage) { [$0.image] }
    }

    private var pager: some View {
        GeometryReader { geo in
            let w = geo.size.width
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, item in
                    // Each page reports its OWN content height (measured below) so the pager can
                    // reserve the TALLEST across the daily 5 and hold one stable height — it must
                    // never resize as the rotation lands on a shorter or taller item.
                    page(item)
                        .frame(width: w, alignment: .top)
                        .background(
                            GeometryReader { p in
                                Color.clear.preference(key: PageHeightKey.self, value: [idx: p.size.height])
                            }
                        )
                }
            }
            .frame(width: w, alignment: .topLeading)
            .offset(x: -CGFloat(index) * w + dragX)
            .contentShape(Rectangle())
            .gesture(swipe(width: w))
        }
        // Size to the TALLEST measured page, never the current one. The daily 5 vary in length,
        // and sizing per-page made the pager grow/shrink on every auto-advance — a visible jump
        // that also shifted the bottom-anchored column. Reserving the max gives one stable height
        // that always fits the longest page; shorter pages top-align with breathing room below.
        // `pageHeight` is the first-frame fallback before measurement lands.
        .frame(height: maxPageHeight, alignment: .top)
        .animation(AppAnimation.spring, value: maxPageHeight)
        .onPreferenceChange(PageHeightKey.self) { pageHeights = $0 }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.07),
                    .init(color: .black, location: 0.93),
                    .init(color: .clear, location: 1.00)
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(alignment: .bottom) { keptToast }
        .task { await autoLoop() }
        .onDisappear { resumeItem?.cancel() }
    }

    // MARK: - Page (per-kind)

    @ViewBuilder
    private func page(_ item: Item) -> some View {
        Group {
            switch item.category {
            case .research: research(item)
            case .term:     term(item)
            case .sentence: sentence(item)
            case .culture:  culture(item)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.md)
        .contentShape(Rectangle())
        .onTapGesture { route() }
        .contextMenu {
            Button { keep() } label: {
                Label("Keep for the conversation", systemImage: "bookmark")
            }
            Button { share(item) } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.label). \(item.keyword). \(item.detail)")
        .accessibilityHint("\(item.act). Touch and hold for options.")
    }

    // Research & term share the hero word — the StatPhase glass effect (gradient +
    // traveling reflective glint). Big and bold so the sweep has surface to catch.
    private func research(_ item: Item) -> some View { heroWord(item) }
    private func term(_ item: Item) -> some View { heroWord(item) }

    private func heroWord(_ item: Item) -> some View {
        // Top-aligned: the word sits directly beneath the static header (a centered
        // layout pushed it ~half a page down, so the header read as floating high).
        VStack(spacing: 0) {
            HolographicText(
                text: item.keyword,
                // Three size tiers so a long research HEADLINE-as-keyword stays inside the
                // page (a punchy stat gets the big size; a full sentence shrinks to fit).
                font: AppFonts.display(item.keyword.count <= 9 ? 62 : (item.keyword.count <= 18 ? 48 : 38),
                                       weight: .bold, relativeTo: .largeTitle),
                lineLimit: 2,
                glowOpacity: 0.7   // slightly softer colored bloom than the baseline
            )
            .frame(maxWidth: 340)
            detailText(item.detail)
            cta(item.act)
        }
    }

    // Sentence — an editorial pull-quote with an oversized opening mark.
    private func sentence(_ item: Item) -> some View {
        VStack(spacing: 0) {
            Text("\u{201C}\(item.quote ?? "")\u{201D}")
                .font(AppFonts.body(24, weight: .medium, relativeTo: .title3))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
                // Oversized opening mark drawn BEHIND, out of layout flow (a ZStack
                // child would add its ~120pt height and clip the CTA).
                .background(alignment: .topLeading) {
                    Text("\u{201C}")
                        .font(AppFonts.display(120, weight: .semibold, relativeTo: .largeTitle))
                        .foregroundStyle(AppColors.spectrumText)
                        .opacity(0.16)
                        .offset(x: -10, y: -40)
                        .accessibilityHidden(true)
                }
                .padding(.top, AppSpacing.sm)
            Text(item.keyword)
                .font(AppFonts.display(20, weight: .semibold, relativeTo: .title3))
                .foregroundStyle(AppColors.spectrumText)
                .padding(.top, AppSpacing.md)
            Text(item.detail)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, AppSpacing.xxs)
            cta(item.act)
        }
    }

    // From the culture — an attributed pull-quote (the quote leads, attribution follows).
    private func culture(_ item: Item) -> some View {
        VStack(spacing: 0) {
            Text("\u{201C}\(item.quote ?? "")\u{201D}")
                .font(AppFonts.body(24, weight: .medium, relativeTo: .title3))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
                .background(alignment: .topLeading) {
                    Text("\u{201C}")
                        .font(AppFonts.display(120, weight: .semibold, relativeTo: .largeTitle))
                        .foregroundStyle(AppColors.spectrumText)
                        .opacity(0.16)
                        .offset(x: -10, y: -40)
                        .accessibilityHidden(true)
                }
                .padding(.top, AppSpacing.sm)

            Text("\u{2014} \(item.keyword)")   // — Author
                .font(AppFonts.display(16, weight: .semibold, relativeTo: .body))
                .foregroundStyle(AppColors.spectrumText)
                .padding(.top, AppSpacing.md)

            if !item.detail.isEmpty {
                Text(item.detail)              // the work / source
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.xxs)
            }

            cta(item.act)
        }
    }

    // Shared detail copy — readable body, the third rung of the contrast ladder
    // (overline faint → word vivid → detail readable → cta accent).
    private func detailText(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.body(16, weight: .regular, relativeTo: .body))
            .foregroundStyle(AppColors.textBody)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .lineLimit(3)   // 3 (was 4) so a long finding can't push the CTA behind the bar
            .minimumScaleFactor(0.85)
            .frame(maxWidth: 330)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, AppSpacing.sm)
    }

    private func overline(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.overline)
            .tracking(1.7)
            .textCase(.uppercase)
            .foregroundStyle(kindColor)
    }

    private func cta(_ text: String) -> some View {
        Text("\(text)  \u{2192}")
            .font(AppFonts.overline)
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textAccent)
            .padding(.top, AppSpacing.md)
    }

    // MARK: - Kept toast

    @ViewBuilder
    private var keptToast: some View {
        Text("kept \u{00B7} for the conversation")
            .font(AppFonts.buttonLabelSmall)
            .foregroundStyle(AppColors.spectrumMagenta)
            .opacity(kept ? 0.9 : 0)
            .offset(y: 8)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Auto-advance

    private func autoLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !reduceMotion, !paused else { continue }
            advance()
        }
    }

    private func advance() {
        withAnimation(AppAnimation.slow) { index += 1 }
        if index >= daily.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration) {
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { index = 0 }
            }
        }
    }

    // MARK: - Manual swipe (pauses auto)

    private func swipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                pauseAuto()
                dragX = v.translation.width
            }
            .onEnded { v in
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                let threshold = width * 0.18
                withAnimation(AppAnimation.spring) {
                    if v.translation.width < -threshold {
                        index = min(index + 1, daily.count - 1)
                    } else if v.translation.width > threshold {
                        index = max(index - 1, 0)
                    }
                    dragX = 0
                }
                scheduleResume()
            }
    }

    private func pauseAuto() {
        paused = true
        resumeItem?.cancel()
    }

    private func scheduleResume() {
        resumeItem?.cancel()
        let item = DispatchWorkItem { paused = false }
        resumeItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + resumeDelay, execute: item)
    }

    // MARK: - Actions

    private func route() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onOpen?()
    }

    private func keep() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(AppAnimation.enter) { kept = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(AppAnimation.exit) { kept = false }
        }
    }

    @MainActor
    private func share(_ item: Item) {
        let card = LexiconShareCard(label: item.label, keyword: item.keyword, detail: item.detail)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let img = renderer.uiImage {
            shareImage = ShareImage(image: img)
        }
    }
}

// MARK: - Share image wrapper + activity sheet

private struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Page height measurement

/// Reports each lexicon page's measured content height (keyed by index) so the pager can
/// size to the current item instead of being locked to one fixed height for all of them.
private struct PageHeightKey: PreferenceKey {
    static let defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Foil collectible share card (9:16, VaylCardFace language)

private struct LexiconShareCard: View {
    let label: String
    let keyword: String
    let detail: String

    var body: some View {
        ZStack {
            AppColors.void

            // Bloom rising from below — the OB canvas language.
            RadialGradient(
                colors: [AppColors.spectrumPurple.opacity(0.45), .clear],
                center: .init(x: 0.5, y: 1.0),
                startRadius: 0, endRadius: 480
            )

            VStack(spacing: 0) {
                Text(label)
                    .font(AppFonts.overline)
                    .tracking(2.0)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Text(keyword)
                    .font(AppFonts.display(46, weight: .bold, relativeTo: .largeTitle))
                    .foregroundStyle(AppColors.spectrumText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    // Color is already AppColors.spectrumPurple. No AppGlows preset matches
                    // this exact radius/opacity pair (cardBreathe is radius 18 but opacity
                    // 0.22, not 0.6) — left as a raw .shadow rather than round to a token
                    // that would change the rendered glow.
                    .shadow(color: AppColors.spectrumPurple.opacity(0.6), radius: 18)

                Text(detail)
                    .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                    .foregroundStyle(AppColors.textBody)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: 280)
                    .padding(.top, AppSpacing.lg)

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Text("✦").foregroundStyle(AppColors.spectrumText)
                    Text("VAYL")
                        .font(AppFonts.display(15, weight: .bold, relativeTo: .caption))
                        .tracking(2.0)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            // 36pt sits between AppSpacing.xl (32) and .xxl (48) — no exact match,
            // left as a raw literal rather than round to a token that would change
            // the card's rendered layout.
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ✦ corners + spectrum frame — the card language.
            // 28pt sits between AppRadius.xl (24) and .sheet (57) — no exact match,
            // left as a raw literal rather than round to a token that would change
            // the card's rendered corner.
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(AppColors.spectrumText, lineWidth: 1.5)
                .opacity(0.9)
                // 14pt sits between AppSpacing.sm (8) and .md (16) — no exact match,
                // left as a raw literal rather than round to a token that would
                // change the frame inset.
                .padding(14)
        }
        .frame(width: 360, height: 640)
    }
}

// MARK: - Preview

#Preview("Home Daily (Lexicon)") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HomeLexicon()
    }
    .preferredColorScheme(.dark)
}

#Preview("Lexicon Share Card") {
    LexiconShareCard(
        label: "From the Lexicon",
        keyword: "Compersion",
        detail: "Finding genuine joy in your partner's happiness with another person."
    )
    .preferredColorScheme(.dark)
}

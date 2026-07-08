//
//  SessionCloseView.swift
//  Vayl
//
//  Screen 7 of the couple session cover: the close.
//  A calm landing inside the cover — the afterglow, a breath not a badge —
//  then an optional private reflection that auto-raises on its own. Swipe it
//  down to skip; that is all it takes to say no. A word or two, two sliders,
//  an optional note — private to you, feeding your Map as trends, not grades.
//
//  Faithful to docs/prototypes/couple-session-close.html. The reflection is the
//  only place communication gets coached: after, by your own noticing.
//

import SwiftUI

struct SessionCloseView: View {

    @Bindable var store: CoupleSessionStore

    @State private var showReflection = false
    @State private var typedWord = ""
    @State private var showNote = false

    /// Word bank — spans warm → neutral → harder, so honest words are there too.
    private let bankWords = [
        "close", "seen", "warm", "light", "honest",
        "steady", "quiet", "full", "surface",
        "tender", "raw", "heavy", "distant"
    ]

    private var displayWords: [String] {
        let extras = store.reflectionWords.subtracting(bankWords).sorted()
        return bankWords + extras
    }

    var body: some View {
        landing
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    if store.phase == .close { showReflection = true }
                }
            }
            // Condensed full-bleed sheet (not full-screen); swipe the top down to skip.
            .vaylSheet(isPresented: $showReflection, heightFraction: 0.66) { reflectionSheet }
            .onChange(of: showReflection) { _, shown in
                // Swipe-down dismiss = skip (Save/Skip set phase to .done first).
                if !shown, store.phase == .close { store.skipReflection() }
            }
    }

    // MARK: - Landing

    private var landing: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Text("✦")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.spectrumText)
                Text("that's a wrap")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.lg)

            Text("You went \(store.discussedCount) \(store.discussedCount == 1 ? "card" : "cards")\ndeep together.")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(AppColors.spectrumMagenta)
                    .frame(width: 5, height: 5)
                Text(store.sessionStatLine)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xxl)
    }

    // MARK: - Reflection sheet

    private var reflectionSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("How was that, for you?")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("just for you · swipe down to skip")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xs)        // grabber (in .vaylSheet) supplies the top gap
            .padding(.bottom, AppSpacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    wordSection
                    ReflectionSlider(
                        label: "who carried it",
                        value: $store.carriedBalance,
                        balanced: true,
                        ends: ("you", "even", "partner")
                    )
                    ReflectionSlider(
                        label: "did you feel heard",
                        value: $store.feltHeard,
                        balanced: false,
                        ends: ("not really", nil, "fully")
                    )
                    noteSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wordSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("pick any that fit")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            FlowChips(words: displayWords,
                      selected: store.reflectionWords) { word in
                UISelectionFeedbackGenerator().selectionChanged()
                store.toggleWord(word)
            }

            TextField("add your own, then return…", text: $typedWord)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.inputBackground)
                )
                .submitLabel(.done)
                .onSubmit(addTypedWord)
        }
    }

    private func addTypedWord() {
        let w = typedWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !w.isEmpty else { return }
        store.reflectionWords.insert(w)
        typedWord = ""
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if showNote {
                Text("anything else? · optional")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                TextField("a line for future-you about tonight…",
                          text: $store.reflectionNote, axis: .vertical)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textBody)
                    .lineLimit(3, reservesSpace: true)
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(AppColors.inputBackground)
                    )
            } else {
                Button {
                    withAnimation(AppAnimation.standard) { showNote = true }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Text("+").foregroundStyle(AppColors.spectrumCyan)
                        Text("add a note")
                    }
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                store.skipReflection()
                showReflection = false
            } label: {
                Text("Skip")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.vertical, AppSpacing.md)
                    .padding(.horizontal, AppSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                store.saveReflection()
                showReflection = false
            } label: {
                Text("Save")
                    .font(AppFonts.ctaLabel)
                    .foregroundStyle(AppColors.void)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .fill(AppColors.spectrumBorder)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xl)
    }
}

// MARK: - FlowChips

/// Wrapping multi-select chip row for the reflection word bank.
private struct FlowChips: View {
    let words: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        FlexibleWrap(spacing: AppSpacing.sm, lineSpacing: AppSpacing.sm) {
            ForEach(words, id: \.self) { word in
                let on = selected.contains(word)
                Text(word)
                    .font(AppFonts.caption)
                    .foregroundStyle(on ? AppColors.void : AppColors.textBody)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        Capsule().fill(on ? AnyShapeStyle(AppColors.spectrumBorder)
                                          : AnyShapeStyle(AppColors.inputBackground))
                    )
                    .overlay(Capsule().strokeBorder(AppColors.borderDefault, lineWidth: on ? 0 : 1))
                    .contentShape(Capsule())
                    .onTapGesture { onTap(word) }
            }
        }
    }
}

// MARK: - FlexibleWrap

/// A wrapping flow layout — places subviews left to right, wrapping to a new
/// line when the next subview would overflow the proposed width.
private struct FlexibleWrap: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        let resolvedWidth = proposal.width ?? widest
        return CGSize(width: resolvedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - ReflectionSlider

/// A draggable 0…1 slider. `balanced` paints a you↔partner gradient track with a
/// centered knob; otherwise a left-fill mono track.
private struct ReflectionSlider: View {
    let label: String
    @Binding var value: Double
    let balanced: Bool
    let ends: (String, String?, String)

    private let knob: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(label)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textBody)

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(balanced
                              ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.spectrumCyan.opacity(0.4),
                                             AppColors.textPrimary.opacity(0.12),
                                             AppColors.spectrumMagenta.opacity(0.4)],
                                    startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(AppColors.textPrimary.opacity(0.12)))
                        .frame(height: 4)
                        .frame(maxHeight: .infinity, alignment: .center)

                    if !balanced {
                        Capsule()
                            .fill(LinearGradient(colors: [AppColors.spectrumCyan, AppColors.accentSecondary],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, w * value), height: 4)
                            .frame(maxHeight: .infinity, alignment: .center)
                    }

                    Circle()
                        .fill(LinearGradient(colors: [AppColors.spectrumCyan, AppColors.spectrumMagenta],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: knob, height: knob)
                        .overlay(Circle().strokeBorder(AppColors.textPrimary.opacity(0.14), lineWidth: 2))
                        .offset(x: max(0, min(w - knob, w * value - knob / 2)))
                        .frame(maxHeight: .infinity, alignment: .center)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            value = max(0, min(1, g.location.x / w))
                        }
                )
            }
            .frame(height: knob)

            HStack {
                Text(ends.0)
                Spacer()
                if let mid = ends.1 { Text(mid); Spacer() }
                Text(ends.2)
            }
            .font(AppFonts.overline)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview("Session Close") {
    ZStack {
        OnboardingAtmosphere(config: .stat)
        SessionCloseView(store: {
            let s = CoupleSessionStore(
                hand: Array(Card.samples.prefix(8)),
                modelContainer: .previewContainer,
                appState: AppState()
            )
            return s
        }())
    }
    .preferredColorScheme(.dark)
}

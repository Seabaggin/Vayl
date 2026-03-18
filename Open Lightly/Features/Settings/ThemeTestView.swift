//
//  ThemeTestView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


#if DEBUG
import SwiftUI

struct ThemeTestView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.theme) private var t
    @State private var noteText = ""
    @State private var selectedRating: Int? = nil

    var body: some View {
        @Bindable var tm = themeManager

        ScrollView {
            VStack(spacing: 24) {

                // Theme Picker
                ThemePickerView()

                // Accent Swatches
                section("Accents") {
                    HStack(spacing: 12) {
                        swatch("Cyan (UI)", t.cyan)
                        swatch("Magenta (UI)", t.magenta)
                        Divider().frame(height: 40)
                        swatch("Navy (deco)", t.navy).opacity(0.6)
                    }
                }

                // Spectrum Bar
                section("Spectrum Bar") {
                    SpectrumBar()
                }

                // Score Ring
                section("Score Ring") {
                    ScoreRing(score: 73)
                }

                // Cards
                section("Cards") {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Normal Card")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(t.text)
                            Text("Hairline border visible?")
                                .font(.system(size: 11))
                                .foregroundStyle(t.textSecondary)
                        }
                        .padding(16)
                        .themedCard()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Card")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(t.text)
                            Text("Cyan border + AMOLED glow")
                                .font(.system(size: 11))
                                .foregroundStyle(t.textSecondary)
                        }
                        .padding(16)
                        .themedCard(selected: true)
                    }
                }

                // CTA
                section("Primary CTA") {
                    GradientButton(title: "Begin Together") {}
                }

                // Critical
                section("Critical Buttons") {
                    HStack(spacing: 8) {
                        CriticalButton(
                            title: "Skip",
                            icon: "forward.fill",
                            style: .neutral
                        )
                        CriticalButton(
                            title: "Safe Word",
                            icon: "hand.raised.fill",
                            style: .danger
                        )
                    }
                }

                // Input
                section("Input Field") {
                    InteractiveField(
                        placeholder: "Private note...",
                        icon: "✏️",
                        text: $noteText
                    )
                }

                // Rating Grid
                section("Rating Grid") {
                    let options: [(String, String, Color)] = [
                        ("❤️", "Love It", t.magenta),
                        ("🤔", "Curious", t.cyan),
                        ("😐", "Neutral", t.textSecondary),
                        ("🚫", "Hard No", t.error),
                    ]
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 10
                    ) {
                        ForEach(0..<4, id: \.self) { i in
                            let (emoji, label, color) = options[i]
                            let sel = selectedRating == i
                            Button {
                                withAnimation(.spring(response: 0.2)) {
                                    selectedRating = i
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                    Text(label)
                                        .font(.system(
                                            size: 12,
                                            weight: sel ? .semibold : .regular
                                        ))
                                        .foregroundStyle(
                                            sel ? color : t.textSecondary
                                        )
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    sel
                                        ? color.opacity(t.isAmoled ? 0.15 : 0.08)
                                        : (t.isAmoled
                                            ? .white.opacity(0.03)
                                            : t.surface1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            sel ? color : t.cardBorder,
                                            lineWidth: sel ? 2 : 1.5
                                        )
                                )
                                .shadow(
                                    color: sel && t.isAmoled
                                        ? color.opacity(0.2)
                                        : .clear,
                                    radius: 8
                                )
                                .scaleEffect(sel ? 1.03 : 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Text Hierarchy
                section("Text Hierarchy") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Primary — .text")
                            .foregroundStyle(t.text)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Secondary — .textSecondary")
                            .foregroundStyle(t.textSecondary)
                            .font(.system(size: 13))
                        Text("Muted — .textMuted")
                            .foregroundStyle(t.textMuted)
                            .font(.system(size: 12))
                        Text("Inline \(Text("cyan").foregroundStyle(t.cyan).fontWeight(.semibold)) and \(Text("magenta").foregroundStyle(t.magenta).fontWeight(.semibold))")

                        .font(.system(size: 13))
                        .foregroundStyle(t.textSecondary)
                    }
                }

                // Progress Bar
                section("Progress Bar") {
                    ProgressBar(value: 5, max: 8)
                }

                // Badge
                section("Badge") {
                    GradBadge(text: "Ready with Awareness")
                }

                Spacer(minLength: 40)
            }
        }
        .background(t.bg.ignoresSafeArea())
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(t.textMuted)
            content()
        }
        .padding(.horizontal, 16)
    }

    private func swatch(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 32, height: 32)
                .shadow(
                    color: t.isAmoled ? color.opacity(0.3) : .clear,
                    radius: 6
                )
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(t.textMuted)
        }
    }
}
#endif

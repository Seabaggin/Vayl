//
//  SegmentedPillGroup.swift
//  Vayl
//
//  The pill selector: a fully-rounded glass track holding equal segments, with
//  a single frosted capsule that slides to the selected option and carries that
//  option's accent (a 1px border + a soft blurred halo). The selected label and
//  icon brighten; the sub-label (a pace estimate, say) brightens too. Selection
//  is read from the capsule + accent, nothing more — distilled down from the
//  earlier dot + lift, which only restated what the capsule already said.
//
//  The app's single segmented control (session pre-roll, Learn hub, Vault, event
//  visibility). Tokens only; the tap trio (press-scale + light haptic) lives on
//  PressableCardStyle. The accent halo is a blurred stroke, never a `.shadow()`
//  (glow rule). The slide uses the reactive `spring` token, disabled under
//  Reduce Motion.
//

import SwiftUI

struct SegmentedPillGroup<Value: Hashable>: View {

    struct Option: Identifiable {
        var id: Value { value }
        let value: Value
        let label: String
        let sublabel: String?
        /// Optional SF Symbol above the label (content-hub tabs). When present,
        /// the icon carries the selection tint and the indicator dot is dropped
        /// (icon + accent already signal the selection; the dot would be noise).
        let icon: String?
        /// Per-option accent — the capsule border, halo, icon/dot tint.
        let accent: Color
        init(_ value: Value, label: String, sublabel: String? = nil, icon: String? = nil, accent: Color) {
            self.value = value
            self.label = label
            self.sublabel = sublabel
            self.icon = icon
            self.accent = accent
        }
    }

    let options: [Option]
    @Binding var selection: Value

    @Namespace private var capsuleNS
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { segment($0) }
        }
        .padding(AppSpacing.xxs)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.cardBg)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Segment

    private func segment(_ option: Option) -> some View {
        let on = option.value == selection
        return Button {
            guard !on else { return }
            withAnimation(reduceMotion ? nil : AppAnimation.spring) {
                selection = option.value
            }
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(AppFonts.body(15, weight: .medium, relativeTo: .body))
                        .foregroundStyle(on ? option.accent : AppColors.textSecondary)
                }

                Text(option.label)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)   // "Dealer's Choice" / long partner names

                if let sublabel = option.sublabel {
                    // Selected sub-label stays legible white, NOT the raw accent —
                    // spectrumPurple as text fails AA. The accent identity lives in
                    // the capsule border + halo (shapes, not text).
                    Text(sublabel)
                        .font(AppFonts.meta)
                        .foregroundStyle(on ? AppColors.textPrimary : AppColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)   // iOS tap-target floor
            .padding(.vertical, AppSpacing.sm)
            .background {
                if on {
                    capsuleFill(accent: option.accent)
                        .matchedGeometryEffect(id: "pillCapsule", in: capsuleNS)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Sliding capsule

    private func capsuleFill(accent: Color) -> some View {
        Capsule(style: .continuous)
            .fill(AppColors.glassFrostPillSelected)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(accent.opacity(0.45), lineWidth: 1)
            )
            .background(
                // Soft accent halo — a blurred stroke, not a `.shadow()` (glow rule).
                Capsule(style: .continuous)
                    .stroke(accent, lineWidth: 2)
                    .blur(radius: 7)
                    .opacity(0.35)
            )
    }

}

// MARK: - Preview

#Preview("Segmented pill group") {
    struct Wrapper: View {
        @State private var reader = "you"
        @State private var pace = "full"
        var body: some View {
            ZStack {
                AppColors.void.ignoresSafeArea()
                VStack(spacing: AppSpacing.xl) {
                    SegmentedPillGroup(
                        options: [
                            .init("you", label: "You", accent: AppColors.spectrumCyan),
                            .init("alex", label: "Alex", accent: AppColors.spectrumPurple),
                            .init("either", label: "Dealer's Choice", accent: AppColors.spectrumMagenta)
                        ],
                        selection: $reader
                    )
                    SegmentedPillGroup(
                        options: [
                            .init("short", label: "Short", sublabel: "~16 min", accent: AppColors.spectrumCyan),
                            .init("full", label: "Full", sublabel: "~28 min", accent: AppColors.spectrumPurple),
                            .init("open", label: "No Rush", sublabel: "no cap", accent: AppColors.spectrumMagenta)
                        ],
                        selection: $pace
                    )
                }
                .padding(AppSpacing.lg)
            }
        }
    }
    return Wrapper().preferredColorScheme(.dark)
}

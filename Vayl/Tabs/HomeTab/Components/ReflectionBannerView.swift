// Home/Components/ReflectionBannerView.swift

import SwiftUI

struct ReflectionBannerView: View {
    let sessionLabel: String
    let partnerName: String?
    var onDone: (([String], String?, Bool) -> Void)?
    var onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    // Reflection input state is owned by the presenting screen
    // (HomeDashboardView): the full pill sheet edits the same selection, and
    // that sheet must be presented at the screen root — a `.vaylSheet` anchors
    // to the view it's attached to, and this banner is a mid-screen card.
    @Binding var selectedPills: Set<String>
    @Binding var noteText: String
    @Binding var shareWithPartner: Bool
    /// Requests the full pill sheet from the presenting screen (see above).
    var onMore: () -> Void = {}

    @State private var isWritingNote: Bool = false

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    // Shared CTA / panel styling. Resolving these light/dark gradient ternaries
    // once (as typed properties) keeps `body` and `fullPillSheet` cheap to
    // type-check — inline they each rebuilt the same AnyShapeStyle gradients.
    private var ctaTextColor: Color { colorScheme == .light ? AppColors.textSecondary : .white }

    private var ctaFill: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary.opacity(0.18), AppColors.safetyAccent.opacity(0.14)],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading, endPoint: .trailing))
    }

    private var ctaBorder: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(Color.clear)
    }

    private var panelBorder: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.5))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary.opacity(0.4), AppColors.accentSecondary.opacity(0.3), AppColors.accentTertiary.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var panelShadow: Color {
        colorScheme == .light ? AppColors.shadowPurple : AppColors.accentSecondary.opacity(0.12)
    }

    private var accentEmphasis: Color {
        colorScheme == .light ? AppColors.accentTertiary : AppColors.accentPrimary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.15)
                    : Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)
                    Text("How did that land for you?")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }

                if isWritingNote {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 70)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(AppSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .stroke(AppColors.borderSubtle, lineWidth: 1)
                        }
                } else {
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: AppSpacing.sm), count: 3),
                        spacing: AppSpacing.sm
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            bannerPillButton(pill)
                        }
                    }

                    Button {
                        onMore()
                    } label: {
                        Text("More →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }

                // Mode toggle
                Button {
                    isWritingNote.toggle()
                } label: {
                    Text(isWritingNote
                         ? "← Use pills instead"
                         : "✎ Write a note instead")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle — only shown when partner is present
                if let name = partnerName {
                    HStack {
                        Text("Share with \(name)")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                }

                // Done + Not now
                HStack {
                    Button("Not now") {
                        dismiss()
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(ctaTextColor)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background {
                                Capsule().fill(ctaFill)
                            }
                            .overlay {
                                Capsule().stroke(ctaBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
        .background {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .fill(AppColors.cardBackground.opacity(0.85))
                }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(panelBorder, lineWidth: 1.5)
        }
        .shadow(color: panelShadow, radius: 20, y: 6)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        dismiss()
                    }
                }
        )
    }

    // MARK: - Pill Button

    private func bannerPillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected { selectedPills.remove(pill) } else { selectedPills.insert(pill) }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.textSecondary
                        : .white)
                    : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary.opacity(0.15),
                                             AppColors.safetyAccent.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary.opacity(0.35),
                                             AppColors.accentSecondary.opacity(0.25)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(Color.clear))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary,
                                             AppColors.safetyAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary,
                                             AppColors.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(AppColors.borderSubtle),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }

    // MARK: - Dismiss
    // TODO: withAnimation belongs in the caller, not here.
    // The banner's parent view should own the dismiss animation.
    // Move animation to HomeDashboardView when home dashboard is rebuilt.
    private func dismiss() {
        withAnimation(AppAnimation.spring) {
            onDismiss?()
        }
    }
}

// MARK: - Full Pill Sheet

/// The full reflection pill browser — presented by HomeDashboardView (the
/// screen root) as a `.vaylSheet`, NOT by ReflectionBannerView: the banner is
/// a mid-screen card, and a `.vaylSheet` anchors to the view it's attached to.
/// Content-only: the presenting `.vaylSheet` supplies chrome + grabber.
struct ReflectionPillSheet: View {
    @Binding var selectedPills: Set<String>
    @Binding var noteText: String
    @Binding var shareWithPartner: Bool
    var partnerName: String?
    /// Done: hand the reflection to the owner and let it close the sheet.
    var onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Mirrors ReflectionBannerView's CTA styling (same light/dark treatment).
    private var ctaTextColor: Color { colorScheme == .light ? AppColors.textSecondary : .white }

    private var ctaFill: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary.opacity(0.18), AppColors.safetyAccent.opacity(0.14)],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                startPoint: .leading, endPoint: .trailing))
    }

    private var ctaBorder: AnyShapeStyle {
        colorScheme == .light
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(Color.clear)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("How did that land?")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)

                pillSection(title: "HOW IT FELT", pills: ReflectionPillGroup.howItFelt)
                pillSection(title: "WHAT HAPPENED", pills: ReflectionPillGroup.whatHappened)
                pillSection(title: "WHAT YOU NEED NOW", pills: ReflectionPillGroup.whatYouNeedNow)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("ADD A NOTE")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)

                    TextEditor(text: $noteText)
                        .frame(minHeight: 80)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(AppSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .stroke(AppColors.borderSubtle, lineWidth: 1)
                        }
                }

                if let name = partnerName {
                    HStack {
                        Text("Share with \(name)")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }
                }

                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(AppFonts.ctaLabel)
                        .foregroundStyle(ctaTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.md).fill(ctaFill)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.md).stroke(ctaBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppSpacing.md)
            }
            .padding(AppSpacing.md)
        }
    }

    private func pillSection(title: String, pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: AppSpacing.sm), count: 2),
                spacing: AppSpacing.sm
            ) {
                ForEach(pills, id: \.self) { pill in
                    pillButton(pill)
                }
            }
        }
    }

    // Same visual treatment as ReflectionBannerView's pill button.
    private func pillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected { selectedPills.remove(pill) } else { selectedPills.insert(pill) }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.textSecondary
                        : .white)
                    : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary.opacity(0.15),
                                             AppColors.safetyAccent.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary.opacity(0.35),
                                             AppColors.accentSecondary.opacity(0.25)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(Color.clear))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary,
                                             AppColors.safetyAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary,
                                             AppColors.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(AppColors.borderSubtle),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Pill sheet — in rail") {
    @Previewable @State var pills: Set<String> = ["close", "seen"]
    @Previewable @State var note = ""
    @Previewable @State var share = true
    VaylSheetPreviewHost(heightFraction: 0.85) {
        ReflectionPillSheet(
            selectedPills: $pills,
            noteText: $note,
            shareWithPartner: $share,
            partnerName: "Alex",
            onDone: {}
        )
    }
}
#endif

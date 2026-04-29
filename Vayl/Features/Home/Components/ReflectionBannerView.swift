// Home/Components/ReflectionBannerView.swift

import SwiftUI

struct ReflectionBannerView: View {
    let sessionLabel: String
    let partnerName: String?
    var onDone: (([String], String?, Bool) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var shareWithPartner: Bool = true
    @State private var showFullPillSheet: Bool = false

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isVisible: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(colorScheme == .light
                    ? Color.black.opacity(0.15)
                    : Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Text("How did that land for you?")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                }

                if isWritingNote {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 70)
                        .font(AppFonts.bodyText)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .light
                                    ? Color.black.opacity(0.03)
                                    : Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .light
                                    ? AppColors.lightBorder
                                    : AppColors.border,
                                    lineWidth: 1)
                        }
                } else {
                    // 5 default pills in 2 rows
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            bannerPillButton(pill)
                        }
                    }

                    Button {
                        showFullPillSheet = true
                    } label: {
                        Text("More →")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyanLight)
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
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle (only if has partner)
                if let name = partnerName {
                    HStack {
                        Text("Share with \(name)")
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.magenta
                                : AppColors.cyan)
                    }
                }

                // Done + Not now
                HStack {
                    Button("Not now") {
                        dismiss()
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
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
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightBodyWineDark
                                : .white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty
                              && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill((colorScheme == .light
                            ? AppColors.lightCardFill
                            : AppColors.cardBg).opacity(0.85))
                }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .light
                    ? AnyShapeStyle(
                        AppColors.warmAuroraBorder.opacity(0.5))
                    : AnyShapeStyle(LinearGradient(
                        colors: [AppColors.cyan.opacity(0.4),
                                 AppColors.purple.opacity(0.3),
                                 AppColors.magenta.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)),
                    lineWidth: 1.5)
        }
        .shadow(
            color: colorScheme == .light
                ? AppColors.lightShadowPurple
                : AppColors.purple.opacity(0.12),
            radius: 20, y: 6
        )
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
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Pill Button

    private func bannerPillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected { selectedPills.remove(pill) }
            else          { selectedPills.insert(pill) }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.lightBodyWineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.35),
                                             AppColors.purple.opacity(0.25)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(Color.clear))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta,
                                             AppColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan,
                                             AppColors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                            : AnyShapeStyle(colorScheme == .light
                                ? AppColors.lightBorder
                                : AppColors.border),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pillSheetSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSheetSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSheetSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADD A NOTE")
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 80)
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextPrimary
                                : AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .light
                                        ? Color.black.opacity(0.03)
                                        : Color.white.opacity(0.04))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .light
                                        ? AppColors.lightBorder
                                        : AppColors.border,
                                        lineWidth: 1)
                            }
                    }

                    if let name = partnerName {
                        HStack {
                            Text("Share with \(name)")
                                .font(AppFonts.bodyText)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextSecondary
                                    : AppColors.textSecondary)
                            Spacer()
                            Toggle("", isOn: $shareWithPartner)
                                .labelsHidden()
                                .tint(colorScheme == .light
                                    ? AppColors.magenta
                                    : AppColors.cyan)
                        }
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText,
                                shareWithPartner)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightBodyWineDark
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta.opacity(0.18),
                                                     AppColors.gold.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.cyan,
                                                     AppColors.purple,
                                                     AppColors.magenta],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.magenta,
                                                     AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background((colorScheme == .light
                ? AppColors.lightPageBg
                : AppColors.pageBg).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSheetSection(title: String,
                                   pills: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            LazyVGrid(
                columns: Array(repeating:
                    GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(pills, id: \.self) { pill in
                    bannerPillButton(pill)
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35,
                               dampingFraction: 0.8)) {
            onDismiss?()
        }
    }
}

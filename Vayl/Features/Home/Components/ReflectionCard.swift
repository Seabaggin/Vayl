// Home/Components/ReflectionCard.swift

import SwiftUI

struct ReflectionCard: View {
    let state: ReflectionCardState
    var onMoreTap: (() -> Void)? = nil
    var onDone: (([String], String?) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPills: Set<String> = []
    @State private var noteText: String = ""
    @State private var isWritingNote: Bool = false
    @State private var showFullPillSheet: Bool = false
    @State private var shareWithPartner: Bool = true

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .pendingYours(let sessionLabel, let sessionDate):
            pendingCard(sessionLabel: sessionLabel,
                        sessionDate: sessionDate)

        case .waitingOnPartner(let sessionLabel, let yourPills):
            waitingCard(sessionLabel: sessionLabel,
                        yourPills: yourPills)

        case .bothReflected(let sessionLabel,
                            let yourName, let yourPills, let yourNote,
                            let partnerName, let partnerPills,
                            let partnerNote, let swipePosition):
            bothReflectedCard(
                sessionLabel: sessionLabel,
                yourName: yourName, yourPills: yourPills,
                yourNote: yourNote,
                partnerName: partnerName,
                partnerPills: partnerPills,
                partnerNote: partnerNote,
                swipePosition: swipePosition
            )

        case .summary(let arc, let yourName, let yourDots,
                      let partnerName, let partnerDots,
                      let swipePosition):
            summaryCard(
                arc: arc,
                yourName: yourName, yourDots: yourDots,
                partnerName: partnerName, partnerDots: partnerDots,
                swipePosition: swipePosition
            )
        }
    }

    // MARK: - Pending State

    private func pendingCard(sessionLabel: String,
                             sessionDate: Date) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(sessionLabel)
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.textTertiary)
                        Text(sessionDate.relativeString)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    Spacer()
                }

                Text("How did that land?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)

                if isWritingNote {
                    // Journal mode
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
                } else {
                    // Pill row — 5 inline defaults
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: AppSpacing.sm), count: 3),
                        spacing: AppSpacing.sm
                    ) {
                        ForEach(ReflectionPillGroup.inlineDefault,
                                id: \.self) { pill in
                            pillButton(pill)
                        }
                    }

                    HStack {
                        Button {
                            showFullPillSheet = true
                        } label: {
                            Text("More →")
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.accentTertiary
                                    : AppColors.accentPrimary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }

                // Switch mode link
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

                // Share toggle
                HStack {
                    Text("Share with partner")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Toggle("", isOn: $shareWithPartner)
                        .labelsHidden()
                        .tint(colorScheme == .light
                            ? AppColors.accentTertiary
                            : AppColors.accentPrimary)
                }

                // Done + Not now
                HStack {
                    Button("Not now") {}
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .buttonStyle(.plain)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.textSecondary
                                : .white)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background {
                                Capsule()
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentTertiary.opacity(0.18),
                                                     AppColors.safetyAccent.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentPrimary,
                                                     AppColors.accentSecondary,
                                                     AppColors.accentTertiary],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                Capsule()
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentTertiary,
                                                     AppColors.safetyAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPills.isEmpty && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(AppSpacing.md)
        }
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Waiting State

    private func waitingCard(sessionLabel: String,
                             yourPills: [String]) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    // Status dots
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                            .frame(width: 7, height: 7)
                        Circle()
                            .stroke(AppColors.textTertiary, lineWidth: 1)
                            .frame(width: 7, height: 7)
                    }
                }

                Text("You reflected.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)

                // Your pills read-only
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(yourPills, id: \.self) { pill in
                            Text(pill)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background {
                                    Capsule()
                                        .fill(colorScheme == .light
                                            ? AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.accentTertiary.opacity(0.12),
                                                         AppColors.safetyAccent.opacity(0.10)],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                            : AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.accentPrimary.opacity(0.2),
                                                         AppColors.accentSecondary.opacity(0.15)],
                                                startPoint: .leading,
                                                endPoint: .trailing)))
                                }
                        }
                    }
                }

                Text("Waiting for your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)

                cardFooter
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Both Reflected State

    private func bothReflectedCard(
        sessionLabel: String,
        yourName: String, yourPills: [String], yourNote: String?,
        partnerName: String, partnerPills: [String], partnerNote: String?,
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                            .frame(width: 7, height: 7)
                        Circle()
                            .fill(colorScheme == .light
                                ? AppColors.safetyAccent
                                : AppColors.accentSecondary)
                            .frame(width: 7, height: 7)
                    }
                }

                // Your section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(yourName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(AppColors.textTertiary)
                    pillsReadOnly(yourPills,
                                  color: colorScheme == .light
                                      ? AppColors.accentTertiary
                                      : AppColors.accentPrimary)
                    if let note = yourNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                Rectangle()
                    .fill(colorScheme == .light
                        ? Color.black.opacity(0.06)
                        : Color.white.opacity(0.06))
                    .frame(height: 1)

                // Partner section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(partnerName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(AppColors.textTertiary)
                    pillsReadOnly(partnerPills,
                                  color: colorScheme == .light
                                      ? AppColors.safetyAccent
                                      : AppColors.accentSecondary)
                    if let note = partnerNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                cardFooter
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Summary State

    private func summaryCard(
        arc: String,
        yourName: String, yourDots: [Bool],
        partnerName: String, partnerDots: [Bool],
        swipePosition: Int
    ) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Dot header
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < yourDots.count && yourDots[i]
                                  ? (colorScheme == .light
                                      ? AppColors.accentTertiary
                                      : AppColors.accentPrimary)
                                  : Color.clear)
                            .overlay {
                                if !(i < yourDots.count && yourDots[i]) {
                                    Circle()
                                        .stroke(AppColors.textTertiary, lineWidth: 1)
                                }
                            }
                            .frame(width: 7, height: 7)
                    }
                    Text("Last 3 sessions")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.leading, AppSpacing.xs)
                }

                // Arc copy
                Text(arc)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Timeline rows
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    timelineRow(name: yourName, dots: yourDots)
                    timelineRow(name: partnerName, dots: partnerDots)
                }

                cardFooter
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    pillSection(
                        title: "HOW IT FELT",
                        pills: ReflectionPillGroup.howItFelt
                    )
                    pillSection(
                        title: "WHAT HAPPENED",
                        pills: ReflectionPillGroup.whatHappened
                    )
                    pillSection(
                        title: "WHAT YOU NEED NOW",
                        pills: ReflectionPillGroup.whatYouNeedNow
                    )

                    // Optional note
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

                    // Share toggle
                    HStack {
                        Text("Share with partner")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(colorScheme == .light
                                ? AppColors.accentTertiary
                                : AppColors.accentPrimary)
                    }

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.textSecondary
                                : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentTertiary.opacity(0.18),
                                                     AppColors.safetyAccent.opacity(0.14)],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentPrimary,
                                                     AppColors.accentSecondary,
                                                     AppColors.accentTertiary],
                                            startPoint: .leading,
                                            endPoint: .trailing)))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(colorScheme == .light
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [AppColors.accentTertiary,
                                                     AppColors.safetyAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear),
                                        lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, AppSpacing.md)
                }
                .padding(AppSpacing.md)
            }
            .background((colorScheme == .light
                ? AppColors.pageBackground
                : AppColors.pageBackground).ignoresSafeArea())
            .navigationTitle("How did that land?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pillSection(title: String,
                             pills: [String]) -> some View {
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

    // MARK: - Shared Subviews

    private func pillButton(_ pill: String) -> some View {
        let isSelected = selectedPills.contains(pill)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected {
                selectedPills.remove(pill)
            } else {
                selectedPills.insert(pill)
            }
        } label: {
            Text(pill)
                .font(AppFonts.caption)
                .foregroundStyle(isSelected
                    ? (colorScheme == .light
                        ? AppColors.textSecondary
                        : .white)
                    : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary.opacity(0.15),
                                             AppColors.safetyAccent.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary.opacity(0.4),
                                             AppColors.accentSecondary.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                    } else {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(Color.clear)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentTertiary, AppColors.safetyAccent],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                                    startPoint: .leading, endPoint: .trailing)))
                            : AnyShapeStyle(AppColors.borderSubtle),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.fast, value: isSelected)
    }

    private func pillsReadOnly(_ pills: [String],
                               color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(pills, id: \.self) { pill in
                    Text(pill)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background {
                            Capsule()
                                .fill(color.opacity(0.15))
                        }
                        .overlay {
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        }
                }
            }
        }
    }

    private func timelineRow(name: String,
                             dots: [Bool]) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 60, alignment: .leading)

            // Fixed 9pt — intentional decorative connector glyph.
            // Dynamic Type scaling would make "──" oversized relative
            // to the 7pt dots it connects.
            Text("──")
                .font(Font.custom("Switzer-Regular", size: 9, relativeTo: .caption2))
                .foregroundStyle(AppColors.textTertiary)

            ForEach(0..<dots.count, id: \.self) { i in
                if dots[i] {
                    Circle()
                        .fill(colorScheme == .light
                            ? AppColors.accentTertiary
                            : AppColors.accentPrimary)
                        .frame(width: 7, height: 7)
                } else {
                    Circle()
                        .stroke(AppColors.textTertiary, lineWidth: 1)
                        .frame(width: 7, height: 7)
                }
                if i < dots.count - 1 {
                    Text("──")
                        .font(Font.custom("Switzer-Regular", size: 9, relativeTo: .caption2))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
    }

    private var cardFooter: some View {
        HStack {
            Spacer()
            Button {
                onMoreTap?()
            } label: {
                Text("More ↗")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.accentTertiary
                        : AppColors.accentPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func cardShell<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(colorScheme == .light
                        ? AppColors.glassFrostCard
                        : AppColors.cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            }
    }
}

// MARK: - Date Extension

private extension Date {
    var relativeString: String {
        let days = Calendar.current.dateComponents(
            [.day], from: self, to: Date()
        ).day ?? 0
        switch days {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        case 2:  return "Two days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last \(formatter.string(from: self))"
        }
    }
}

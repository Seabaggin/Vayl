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
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionLabel)
                            .font(AppFonts.overline)
                            .tracking(1.2)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                        Text(sessionDate.relativeString)
                            .font(AppFonts.caption)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary)
                    }
                    Spacer()
                }

                Text("How did that land?")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                if isWritingNote {
                    // Journal mode
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
                } else {
                    // Pill row — 5 inline defaults
                    LazyVGrid(
                        columns: Array(repeating:
                            GridItem(.flexible(), spacing: 8), count: 3),
                        spacing: 8
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
                                    ? AppColors.magenta
                                    : AppColors.cyanLight)
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
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                }
                .buttonStyle(.plain)

                // Share toggle
                HStack {
                    Text("Share with partner")
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

                // Done + Not now
                HStack {
                    Button("Not now") {}
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
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
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
                    .disabled(selectedPills.isEmpty && noteText.isEmpty)
                    .opacity(selectedPills.isEmpty
                             && noteText.isEmpty ? 0.4 : 1)
                }
            }
            .padding(18)
        }
        .sheet(isPresented: $showFullPillSheet) {
            fullPillSheet
        }
    }

    // MARK: - Waiting State

    private func waitingCard(sessionLabel: String,
                              yourPills: [String]) -> some View {
        cardShell {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    // Status dots
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                            .frame(width: 7, height: 7)
                    }
                }

                Text("You reflected.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)

                // Your pills read-only
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(yourPills, id: \.self) { pill in
                            Text(pill)
                                .font(AppFonts.caption)
                                .foregroundStyle(colorScheme == .light
                                    ? AppColors.lightTextPrimary
                                    : AppColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .fill(colorScheme == .light
                                            ? AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.magenta.opacity(0.12),
                                                         AppColors.gold.opacity(0.10)],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                            : AnyShapeStyle(LinearGradient(
                                                colors: [AppColors.cyan.opacity(0.2),
                                                         AppColors.purple.opacity(0.15)],
                                                startPoint: .leading,
                                                endPoint: .trailing)))
                                }
                        }
                    }
                }

                Text("Waiting for your partner.")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)

                cardFooter
            }
            .padding(18)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(sessionLabel)
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(colorScheme == .light
                            ? AppColors.magenta
                            : AppColors.cyan)
                            .frame(width: 7, height: 7)
                        Circle().fill(colorScheme == .light
                            ? AppColors.gold
                            : AppColors.purple)
                            .frame(width: 7, height: 7)
                    }
                }

                // Your section
                VStack(alignment: .leading, spacing: 6) {
                    Text(yourName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(yourPills,
                                  color: colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                    if let note = yourNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(partnerName.uppercased())
                        .font(AppFonts.overline)
                        .tracking(1.0)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                    pillsReadOnly(partnerPills,
                                  color: colorScheme == .light
                                      ? AppColors.gold
                                      : AppColors.purple)
                    if let note = partnerNote {
                        Text("\"\(note)\"")
                            .font(AppFonts.bodyText)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightTextSecondary
                                : AppColors.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }

                cardFooter
            }
            .padding(18)
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
            VStack(alignment: .leading, spacing: 12) {
                // Dot header
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < yourDots.count && yourDots[i]
                                  ? (colorScheme == .light
                                      ? AppColors.magenta
                                      : AppColors.cyan)
                                  : Color.clear)
                            .overlay {
                                if !(i < yourDots.count && yourDots[i]) {
                                    Circle()
                                        .stroke(colorScheme == .light
                                            ? AppColors.lightTextTertiary
                                            : AppColors.textTertiary,
                                            lineWidth: 1)
                                }
                            }
                            .frame(width: 7, height: 7)
                    }
                    Text("Last 3 sessions")
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .padding(.leading, 4)
                }

                // Arc copy
                Text(arc)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(colorScheme == .light
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Timeline rows
                VStack(alignment: .leading, spacing: 4) {
                    timelineRow(name: yourName, dots: yourDots)
                    timelineRow(name: partnerName, dots: partnerDots)
                }

                cardFooter
            }
            .padding(18)
        }
    }

    // MARK: - Full Pill Sheet

    private var fullPillSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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

                    // Share toggle
                    HStack {
                        Text("Share with partner")
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

                    Button {
                        showFullPillSheet = false
                        onDone?(Array(selectedPills),
                                noteText.isEmpty ? nil : noteText)
                    } label: {
                        Text("Done")
                            .font(AppFonts.ctaLabel)
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.wineDark
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

    private func pillSection(title: String,
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
                        ? AppColors.wineDark
                        : .white)
                    : (colorScheme == .light
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta.opacity(0.15),
                                             AppColors.gold.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan.opacity(0.4),
                                             AppColors.purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing)))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                            ? (colorScheme == .light
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.magenta, AppColors.gold],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [AppColors.cyan, AppColors.purple],
                                    startPoint: .leading, endPoint: .trailing)))
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

    private func pillsReadOnly(_ pills: [String],
                                color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(pills, id: \.self) { pill in
                    Text(pill)
                        .font(AppFonts.caption)
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(color.opacity(0.15))
                        }
                        .overlay {
                            Capsule()
                                .stroke(color.opacity(0.3),
                                        lineWidth: 1)
                        }
                }
            }
        }
    }

    private func timelineRow(name: String,
                              dots: [Bool]) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)
                .frame(width: 60, alignment: .leading)

            Text("──")
                .font(.system(size: 9))
                .foregroundStyle(colorScheme == .light
                    ? AppColors.lightTextTertiary
                    : AppColors.textTertiary)

            ForEach(0..<dots.count, id: \.self) { i in
                if dots[i] {
                    Circle().fill(colorScheme == .light
                        ? AppColors.magenta
                        : AppColors.cyan)
                        .frame(width: 7, height: 7)
                } else {
                    Circle()
                        .stroke(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary,
                            lineWidth: 1)
                        .frame(width: 7, height: 7)
                }
                if i < dots.count - 1 {
                    Text("──")
                        .font(.system(size: 9))
                        .foregroundStyle(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
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
                        ? AppColors.magenta
                        : AppColors.cyanLight)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light
                        ? AppColors.lightFrostCard
                        : AppColors.cardBg)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .light
                        ? AppColors.lightBorder
                        : AppColors.border,
                        lineWidth: 1)
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

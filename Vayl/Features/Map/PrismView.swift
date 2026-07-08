// Features/Home/Components/PrismView.swift
// Vayl
//
// Shell chrome (surface, orbs, rim, border, shadows, underglow)
// owned by HomeWidgetShell — this view provides zero chrome.
// PrismView renders content only — header, tabs, pill switcher.
//
// Wrapped in HomeWidgetShell in HomeDashboardView ambientZone.
// breathPhase driven externally — shared 8s cycle with GravLift.

import SwiftUI

// MARK: - Prism Mode

enum PrismMode: CaseIterable {
    case journal
    case reflect
    case agreements

    var label: String {
        switch self {
        case .journal:    return "Journal"
        case .reflect:    return "Reflect"
        case .agreements: return "Agreements"
        }
    }

    var color: Color {
        switch self {
        case .journal:    return AppColors.accentPrimary
        case .reflect:    return AppColors.accentSecondary
        case .agreements: return AppColors.accentTertiary
        }
    }

    var privateLabel: String {
        switch self {
        case .journal:    return "PRIVATE · NEVER SYNCED"
        case .reflect:    return "SOLO ONLY · NOT SHARED"
        case .agreements: return "READ ONLY · WITH ALEX"
        }
    }

    var timeAwarePrompt: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch self {
        case .journal:
            switch hour {
            case 5..<12:  return "What are you bringing into today?"
            case 12..<17: return "What's sitting underneath the surface right now?"
            case 17..<21: return "What happened today that you haven't processed yet?"
            default:      return "What are you not saying to anyone?"
            }
        case .reflect:
            switch hour {
            case 5..<12:  return "What do you need to look at before the day starts?"
            case 12..<17: return "What are you avoiding right now?"
            case 17..<21: return "What came up today that needs space?"
            default:      return "What truth are you sitting with?"
            }
        case .agreements:
            return "Your current agreements with Alex."
        }
    }
}

// MARK: - PrismView

struct PrismView: View {

    // MARK: - External breath phase
    // Driven by HomeDashboardView — shared 8s linear cycle.
    // Do not start a local animation for this.
    let breathPhase: CGFloat

    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - State
    @Namespace private var pillNamespace

    @State private var activeMode: PrismMode = .journal
    @State private var expanded: Bool      = false
    @State private var cursorOn: Bool      = true
    @State private var cursorTimer: Timer?
    @State private var cardDrawn: Bool      = false
    @State private var cardShimmer: Bool      = false
    @State private var journalText: String    = ""

    // MARK: - Derived
    private var modeColor: Color { activeMode.color }

    // Hoisted color choices. Resolving these isLight ternaries once (as typed
    // computed properties) keeps the agreements/pill view bodies cheap to
    // type-check — inline they forced repeated Color + CGFloat/Double inference.
    private var labelMutedColor: Color { isLight ? AppColors.textTertiary : AppColors.textMuted }
    private var secondaryQuoteColor: Color { AppColors.textSecondary.opacity(0.65) }
    private var cardFillColor: Color { isLight ? Color.black.opacity(0.03) : Color.white.opacity(0.03) }
    private var pillBackgroundColor: Color { isLight ? Color.black.opacity(0.04) : Color.white.opacity(0.03) }
    private var pillBorderColor: Color { isLight ? Color.black.opacity(0.07) : AppColors.borderSubtle }

    // MARK: - Body
    // Zero chrome — HomeWidgetShell owns surface, rim, border, shadows.
    // Content only rendered here.

    var body: some View {
        content
            .onAppear { startCursorBlink() }
            .onDisappear {
                cursorTimer?.invalidate()
                cursorTimer = nil
            }
            .animation(AppAnimation.standard, value: activeMode)
            .animation(AppAnimation.spring, value: expanded)
            .animation(AppAnimation.spring, value: cardDrawn)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)

            Divider()
                .background(
                    isLight
                        ? Color.black.opacity(0.07)
                        : AppColors.borderSubtle
                )
                .padding(.horizontal, AppSpacing.md)

            TabView(selection: $activeMode) {
                journalContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.journal)

                reflectContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.reflect)

                agreementsContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.agreements)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: expanded ? 280 : 196)
            .onChange(of: activeMode) { _, _ in
                withAnimation(AppAnimation.spring) {
                    expanded    = false
                    cardDrawn   = false
                    journalText = ""
                }
            }

            pillSwitcher
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.md)
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(modeColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: modeColor, radius: 4)
                    .animation(AppAnimation.standard, value: activeMode)

                Text(activeMode.privateLabel)
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(modeColor.opacity(0.55))
                    .animation(AppAnimation.fast, value: activeMode)
            }

            Spacer()

            if expanded {
                Button {
                    withAnimation(AppAnimation.spring) {
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                } label: {
                    Text("Close")
                        .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textTertiary
                                : AppColors.textTertiary
                        )
                        .padding(.leading, AppSpacing.sm)
                }
            }
        }
    }

    // MARK: - Journal Content

    @ViewBuilder
    private var journalContent: some View {
        if !expanded {
            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(activeMode.timeAwarePrompt)
                        .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textSecondary.opacity(0.80)
                                : AppColors.textSecondary.opacity(0.80)
                        )
                        .lineSpacing(4)
                    Text(cursorOn ? "|" : " ")
                        .font(AppFonts.body(15, weight: .regular, relativeTo: .body))
                        .foregroundStyle(AppColors.accentPrimary.opacity(0.65))
                }
                .padding(.bottom, AppSpacing.md)

                Button {
                    withAnimation(AppAnimation.spring) {
                        expanded = true
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColors.accentPrimary.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .strokeBorder(AppColors.accentPrimary.opacity(0.22), lineWidth: 1)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("+")
                                    .font(Font.custom("Switzer-Regular", size: 16, relativeTo: .body))
                                    .foregroundStyle(AppColors.accentPrimary)
                            )

                        Text("Write entry")
                            .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                            .foregroundStyle(AppColors.accentPrimary.opacity(0.65))

                        Spacer()

                        HStack(spacing: AppSpacing.xs) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i == 0
                                          ? AppColors.accentPrimary
                                          : (isLight ? Color.black.opacity(0.10) : AppColors.borderSubtle))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                .padding(.bottom, AppSpacing.md)

                Divider()
                    .background(
                        isLight
                            ? Color.black.opacity(0.07)
                            : AppColors.borderSubtle
                    )
                    .padding(.bottom, AppSpacing.md)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("LAST ENTRY · 2 DAYS AGO")
                        .font(AppFonts.overline)
                        .tracking(1.8)
                        .foregroundStyle(
                            isLight
                                ? AppColors.textTertiary
                                : AppColors.textMuted
                        )

                    Text("\"Didn't expect to feel that settled after the conversation about...\"")
                        .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                        .foregroundStyle(
                            isLight
                                ? AppColors.textSecondary.opacity(0.65)
                                : AppColors.textTertiary
                        )
                        .lineSpacing(3)
                        .lineLimit(2)
                }
                .padding(.bottom, AppSpacing.xs)
            }

        } else {

            VStack(alignment: .leading, spacing: AppSpacing.sm) {

                Text(activeMode.timeAwarePrompt)
                    .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
                    .foregroundStyle(
                        journalText.isEmpty
                            ? (isLight
                                ? AppColors.textSecondary.opacity(0.45)
                                : AppColors.textSecondary.opacity(0.45))
                            : (isLight
                                ? AppColors.textTertiary
                                : AppColors.textMuted)
                    )
                    .italic()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(
                            isLight
                                ? Color.black.opacity(0.03)
                                : Color.white.opacity(0.03)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.accentPrimary.opacity(0.18), lineWidth: 1)
                        )
                        .frame(minHeight: 110)

                    if journalText.isEmpty {
                        Text("Start writing...")
                            .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textTertiary
                                    : AppColors.textMuted
                            )
                            .padding(AppSpacing.md)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    Button { } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(AppIcons.mic)
                                .font(Font.custom("Switzer-Regular", size: 12, relativeTo: .caption))
                            Text("Dictate")
                                .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                        }
                        .foregroundStyle(AppColors.accentPrimary.opacity(0.65))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accentPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(AppColors.accentPrimary.opacity(0.18), lineWidth: 1)
                        )
                    }

                    Spacer()

                    Button {
                        withAnimation(AppAnimation.spring) {
                            expanded = false
                        }
                    } label: {
                        Text("Save")
                            .font(AppFonts.body(12, weight: .semibold, relativeTo: .caption))
                            .foregroundStyle(AppColors.accentPrimary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accentPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColors.accentPrimary.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, AppSpacing.xs)
            }
        }
    }

    // MARK: - Reflect Content

    @ViewBuilder
    private var reflectContent: some View {
        VStack(spacing: 0) {
            if !cardDrawn {

                Button {
                    if !expanded {
                        withAnimation(AppAnimation.spring) {
                            expanded = true
                        }
                    } else {
                        drawSoloCard()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.accentSecondary.opacity(0.16),
                                        AppColors.accentSecondary.opacity(0.07)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .strokeBorder(AppColors.accentSecondary.opacity(0.28), lineWidth: 1)
                            )
                            .frame(height: expanded ? 100 : 80)

                        ZStack {
                            ForEach([1.0, 0.65, 0.35], id: \.self) { scale in
                                Circle()
                                    .strokeBorder(
                                        AppColors.accentSecondary.opacity(0.10 + scale * 0.08),
                                        lineWidth: 1
                                    )
                                    .frame(width: 60 * scale, height: 60 * scale)
                            }
                            Circle()
                                .fill(AppColors.accentSecondary.opacity(0.20))
                                .frame(width: 8, height: 8)
                                .shadow(color: AppColors.accentSecondary, radius: 4)
                        }
                        .opacity(cardShimmer ? 0 : 1)

                        if expanded {
                            Text("Draw a card")
                                .font(AppFonts.body(13, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(AppColors.accentSecondary.opacity(0.75))
                                .offset(y: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.bottom, expanded ? 0 : AppSpacing.md)

                if !expanded {
                    Divider()
                        .background(
                            isLight
                                ? Color.black.opacity(0.07)
                                : AppColors.borderSubtle
                        )
                        .padding(.bottom, AppSpacing.md)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("LAST REFLECTION · 5 DAYS AGO")
                            .font(AppFonts.overline)
                            .tracking(1.8)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textTertiary
                                    : AppColors.textMuted
                            )

                        Text("You drew from the solo deck. No note saved.")
                            .font(AppFonts.body(12, weight: .regular, relativeTo: .caption))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.textSecondary.opacity(0.65)
                                    : AppColors.textTertiary
                            )
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppSpacing.xs)
                }

            } else {

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.04, blue: 0.16),
                                    AppColors.accentSecondary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .strokeBorder(AppColors.accentSecondary.opacity(0.40), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("SOLO · INNER WORK")
                                    .font(AppFonts.overline)
                                    .tracking(2.0)
                                    .foregroundStyle(AppColors.accentSecondary.opacity(0.65))

                                Text("When do you find yourself editing your feelings before sharing them?")
                                    .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
                                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                                    .lineSpacing(4)
                            }
                            .padding(AppSpacing.md)
                        }
                        .frame(minHeight: 100)

                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            withAnimation(AppAnimation.spring) {
                                cardDrawn = false
                            }
                        } label: {
                            Text("Draw another")
                                .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                                .foregroundStyle(
                                    isLight
                                        ? AppColors.textTertiary
                                        : AppColors.textTertiary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    isLight
                                        ? Color.black.opacity(0.04)
                                        : Color.white.opacity(0.04)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                        .strokeBorder(
                                            isLight
                                                ? Color.black.opacity(0.08)
                                                : AppColors.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                        }

                        Button { } label: {
                            Text("Write a note")
                                .font(AppFonts.body(12, weight: .semibold, relativeTo: .caption))
                                .foregroundStyle(AppColors.accentSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(AppColors.accentSecondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                        .strokeBorder(AppColors.accentSecondary.opacity(0.30), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, AppSpacing.xs)
                }
            }
        }
    }

    // MARK: - Agreements Content

    private var agreementsData: [(date: String, text: String)] {
        [
            (date: "Jun 12", text: "We check in before making plans that affect both of us."),
            (date: "Jun 8", text: "Sleepovers with new connections need 48 hours notice."),
            (date: "May 28", text: "No phones during our first hour back together.")
        ]
    }

    @ViewBuilder
    private var agreementsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !expanded {
                collapsedAgreements
            } else {
                expandedAgreements
            }
        }
    }

    @ViewBuilder
    private var collapsedAgreements: some View {
        let first = agreementsData[0]

        Text("\"\(first.text)\"")
            .font(AppFonts.body(14, weight: .regular, relativeTo: .callout))
            .foregroundStyle(secondaryQuoteColor)
            .lineSpacing(4)
            .padding(.bottom, AppSpacing.md)

        HStack {
            Text("Added \(first.date) · \(agreementsData.count) total")
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(labelMutedColor)

            Spacer()

            Button {
                withAnimation(AppAnimation.spring) {
                    expanded = true
                }
            } label: {
                Text("View all →")
                    .font(AppFonts.body(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(AppColors.accentTertiary.opacity(0.65))
            }
        }
        .padding(.bottom, AppSpacing.xs)
    }

    @ViewBuilder
    private var expandedAgreements: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(Array(agreementsData.enumerated()), id: \.offset) { i, a in
                agreementRow(index: i, date: a.date, text: a.text)
            }

            HStack {
                Text("Changes made in Map tab")
                    .font(AppFonts.body(11, weight: .regular, relativeTo: .caption2))
                    .foregroundStyle(labelMutedColor)
                Spacer()
                Text("Go to Map →")
                    .font(AppFonts.body(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(AppColors.accentTertiary.opacity(0.55))
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xs)
        }
    }

    private func agreementRow(index i: Int, date: String, text: String) -> some View {
        let border: Color = i == 0 ? AppColors.accentTertiary.opacity(0.25) : pillBorderColor

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(date)
                .font(AppFonts.overline)
                .tracking(1.2)
                .foregroundStyle(labelMutedColor)

            Text("\"\(text)\"")
                .font(AppFonts.body(13, weight: .regular, relativeTo: .caption))
                .foregroundStyle(AppColors.textSecondary.opacity(0.70))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        )
    }

    // MARK: - Pill Switcher

    private var pillSwitcher: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(PrismMode.allCases, id: \.label) { mode in
                pillButton(for: mode)
            }
        }
        .padding(AppSpacing.sm)
        .background(pillBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(pillBorderColor, lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    let all = PrismMode.allCases
                    guard let current = all.firstIndex(of: activeMode) else { return }
                    let next: Int
                    if value.translation.width < 0 {
                        next = min(current + 1, all.count - 1)
                    } else {
                        next = max(current - 1, 0)
                    }
                    guard next != current else { return }
                    withAnimation(AppAnimation.spring) {
                        activeMode  = all[next]
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                }
        )
    }

    private func pillButton(for mode: PrismMode) -> some View {
        let isActive: Bool = mode == activeMode
        let labelColor: Color = isActive ? mode.color : AppColors.textTertiary

        return Button {
            withAnimation(AppAnimation.spring) {
                activeMode  = mode
                expanded    = false
                cardDrawn   = false
                journalText = ""
            }
        } label: {
            Text(mode.label)
                .font(AppFonts.body(11, weight: isActive ? .semibold : .regular, relativeTo: .caption2))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(mode.color.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .strokeBorder(mode.color.opacity(0.35), lineWidth: 1.0)
                            )
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
        }
    }

    // MARK: - Helpers

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            cursorOn.toggle()
        }
    }

    private func drawSoloCard() {
        cardShimmer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(AppAnimation.spring) {
                cardDrawn   = true
                cardShimmer = false
            }
        }
    }
}

// MARK: - Previews
// Wrapped in HomeWidgetShell to match real usage context.

#Preview("Prism — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight: false,
                accentColor: AppColors.accentSecondary,
                rimVariant: .prism
            ) {
                ZStack {
                    OrbLayer(
                        accentColor: AppColors.accentSecondary,
                        height: 300,
                        variant: .prism
                    )
                    PrismView(breathPhase: 0)
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Prism — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight: true,
                accentColor: AppColors.accentSecondary,
                rimVariant: .prism
            ) {
                PrismView(breathPhase: 0)
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Prism — Journal expanded — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight: false,
                accentColor: AppColors.accentSecondary,
                rimVariant: .prism
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.accentSecondary, height: 300, variant: .prism)
                    PrismView(breathPhase: 0)
                }
            }
            .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

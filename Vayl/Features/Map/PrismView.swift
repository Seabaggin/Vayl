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
        case .journal:    return AppColors.cyan
        case .reflect:    return AppColors.purple
        case .agreements: return AppColors.magenta
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

    @State private var activeMode:  PrismMode = .journal
    @State private var expanded:    Bool      = false
    @State private var cursorOn:    Bool      = true
    @State private var cursorTimer: Timer?    = nil
    @State private var cardDrawn:   Bool      = false
    @State private var cardShimmer: Bool      = false
    @State private var journalText: String    = ""

    // MARK: - Derived
    private var modeColor: Color { activeMode.color }

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
            .animation(.easeInOut(duration: 0.35), value: activeMode)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: expanded)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cardDrawn)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider()
                .background(
                    isLight
                        ? Color.black.opacity(0.07)
                        : AppColors.border
                )
                .padding(.horizontal, 20)

            TabView(selection: $activeMode) {
                journalContent
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.journal)

                reflectContent
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .frame(
                        minHeight: expanded ? 200 : 180,
                        maxHeight: expanded ? .infinity : 180,
                        alignment: .top
                    )
                    .tag(PrismMode.reflect)

                agreementsContent
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expanded    = false
                    cardDrawn   = false
                    journalText = ""
                }
            }

            pillSwitcher
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Circle()
                    .fill(modeColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: modeColor, radius: 4)
                    .animation(.easeInOut(duration: 0.3), value: activeMode)

                Text(activeMode.privateLabel)
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(modeColor.opacity(0.55))
                    .animation(.easeOut(duration: 0.2), value: activeMode)
            }

            Spacer()

            if expanded {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                } label: {
                    Text("Close")
                        .font(AppFonts.body(12, weight: .medium))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextTertiary
                                : AppColors.textTertiary
                        )
                        .padding(.leading, 10)
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
                        .font(AppFonts.body(15, weight: .regular))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextSecondary.opacity(0.80)
                                : AppColors.textSecondary.opacity(0.80)
                        )
                        .lineSpacing(4)
                    Text(cursorOn ? "|" : " ")
                        .font(AppFonts.body(15, weight: .regular))
                        .foregroundStyle(AppColors.cyan.opacity(0.65))
                }
                .padding(.bottom, 16)

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        expanded = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.cyan.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(AppColors.cyan.opacity(0.22), lineWidth: 1)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("+")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(AppColors.cyan)
                            )

                        Text("Write entry")
                            .font(AppFonts.body(12, weight: .medium))
                            .foregroundStyle(AppColors.cyan.opacity(0.65))

                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i == 0
                                          ? AppColors.cyan
                                          : (isLight ? Color.black.opacity(0.10) : AppColors.border))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(
                        isLight
                            ? Color.black.opacity(0.07)
                            : AppColors.border
                    )
                    .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LAST ENTRY · 2 DAYS AGO")
                        .font(AppFonts.overline)
                        .tracking(1.8)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextTertiary
                                : AppColors.textMuted
                        )

                    Text("\"Didn't expect to feel that settled after the conversation about...\"")
                        .font(AppFonts.body(12, weight: .regular))
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextSecondary.opacity(0.65)
                                : AppColors.textTertiary
                        )
                        .lineSpacing(3)
                        .lineLimit(2)
                }
                .padding(.bottom, 4)
            }

        } else {

            VStack(alignment: .leading, spacing: 12) {

                Text(activeMode.timeAwarePrompt)
                    .font(AppFonts.body(13, weight: .regular))
                    .foregroundStyle(
                        journalText.isEmpty
                            ? (isLight
                                ? AppColors.lightTextSecondary.opacity(0.45)
                                : AppColors.textSecondary.opacity(0.45))
                            : (isLight
                                ? AppColors.lightTextTertiary
                                : AppColors.textMuted)
                    )
                    .italic()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isLight
                                ? Color.black.opacity(0.03)
                                : Color.white.opacity(0.03)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppColors.cyan.opacity(0.18), lineWidth: 1)
                        )
                        .frame(minHeight: 110)

                    if journalText.isEmpty {
                        Text("Start writing...")
                            .font(AppFonts.body(14, weight: .regular))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textMuted
                            )
                            .padding(14)
                    }
                }

                HStack(spacing: 10) {
                    Button { } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12))
                            Text("Dictate")
                                .font(AppFonts.body(12, weight: .medium))
                        }
                        .foregroundStyle(AppColors.cyan.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(AppColors.cyan.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppColors.cyan.opacity(0.18), lineWidth: 1)
                        )
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            expanded = false
                        }
                    } label: {
                        Text("Save")
                            .font(AppFonts.body(12, weight: .semibold))
                            .foregroundStyle(AppColors.cyan)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(AppColors.cyan.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppColors.cyan.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 4)
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
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            expanded = true
                        }
                    } else {
                        drawSoloCard()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.purple.opacity(0.16),
                                        AppColors.purple.opacity(0.07)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint:   .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppColors.purple.opacity(0.28), lineWidth: 1)
                            )
                            .frame(height: expanded ? 100 : 80)

                        ZStack {
                            ForEach([1.0, 0.65, 0.35], id: \.self) { scale in
                                Circle()
                                    .strokeBorder(
                                        AppColors.purple.opacity(0.10 + scale * 0.08),
                                        lineWidth: 1
                                    )
                                    .frame(width: 60 * scale, height: 60 * scale)
                            }
                            Circle()
                                .fill(AppColors.purple.opacity(0.20))
                                .frame(width: 8, height: 8)
                                .shadow(color: AppColors.purple, radius: 4)
                        }
                        .opacity(cardShimmer ? 0 : 1)

                        if expanded {
                            Text("Draw a card")
                                .font(AppFonts.body(13, weight: .semibold))
                                .foregroundStyle(AppColors.purple.opacity(0.75))
                                .offset(y: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.bottom, expanded ? 0 : 14)

                if !expanded {
                    Divider()
                        .background(
                            isLight
                                ? Color.black.opacity(0.07)
                                : AppColors.border
                        )
                        .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST REFLECTION · 5 DAYS AGO")
                            .font(AppFonts.overline)
                            .tracking(1.8)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textMuted
                            )

                        Text("You drew from the solo deck. No note saved.")
                            .font(AppFonts.body(12, weight: .regular))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextSecondary.opacity(0.65)
                                    : AppColors.textTertiary
                            )
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
                }

            } else {

                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.04, blue: 0.16),
                                    AppColors.purple.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppColors.purple.opacity(0.40), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SOLO · INNER WORK")
                                    .font(AppFonts.overline)
                                    .tracking(2.0)
                                    .foregroundStyle(AppColors.purple.opacity(0.65))

                                Text("When do you find yourself editing your feelings before sharing them?")
                                    .font(AppFonts.body(14, weight: .regular))
                                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                                    .lineSpacing(4)
                            }
                            .padding(16)
                        }
                        .frame(minHeight: 100)

                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                cardDrawn = false
                            }
                        } label: {
                            Text("Draw another")
                                .font(AppFonts.body(12, weight: .medium))
                                .foregroundStyle(
                                    isLight
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textTertiary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    isLight
                                        ? Color.black.opacity(0.04)
                                        : Color.white.opacity(0.04)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            isLight
                                                ? Color.black.opacity(0.08)
                                                : AppColors.border,
                                            lineWidth: 1
                                        )
                                )
                        }

                        Button { } label: {
                            Text("Write a note")
                                .font(AppFonts.body(12, weight: .semibold))
                                .foregroundStyle(AppColors.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(AppColors.purple.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(AppColors.purple.opacity(0.30), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    // MARK: - Agreements Content

    @ViewBuilder
    private var agreementsContent: some View {
        let agreements: [(date: String, text: String)] = [
            (date: "Jun 12", text: "We check in before making plans that affect both of us."),
            (date: "Jun 8",  text: "Sleepovers with new connections need 48 hours notice."),
            (date: "May 28", text: "No phones during our first hour back together."),
        ]

        VStack(alignment: .leading, spacing: 0) {
            if !expanded {

                Text("\"\(agreements[0].text)\"")
                    .font(AppFonts.body(14, weight: .regular))
                    .foregroundStyle(
                        isLight
                            ? AppColors.lightTextSecondary.opacity(0.65)
                            : AppColors.textSecondary.opacity(0.65)
                    )
                    .lineSpacing(4)
                    .padding(.bottom, 14)

                HStack {
                    Text("Added \(agreements[0].date) · \(agreements.count) total")
                        .font(AppFonts.overline)
                        .tracking(1.2)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextTertiary
                                : AppColors.textMuted
                        )

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            expanded = true
                        }
                    } label: {
                        Text("View all →")
                            .font(AppFonts.body(12, weight: .medium))
                            .foregroundStyle(AppColors.magenta.opacity(0.65))
                    }
                }
                .padding(.bottom, 4)

            } else {

                VStack(spacing: 10) {
                    ForEach(Array(agreements.enumerated()), id: \.offset) { i, a in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.date)
                                .font(AppFonts.overline)
                                .tracking(1.2)
                                .foregroundStyle(
                                    isLight
                                        ? AppColors.lightTextTertiary
                                        : AppColors.textMuted
                                )

                            Text("\"\(a.text)\"")
                                .font(AppFonts.body(13, weight: .regular))
                                .foregroundStyle(
                                    isLight
                                        ? AppColors.lightTextSecondary.opacity(0.70)
                                        : AppColors.textSecondary.opacity(0.70)
                                )
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            isLight
                                ? Color.black.opacity(0.03)
                                : Color.white.opacity(0.03)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    i == 0
                                        ? AppColors.magenta.opacity(0.25)
                                        : (isLight
                                            ? Color.black.opacity(0.07)
                                            : AppColors.border),
                                    lineWidth: 1
                                )
                        )
                    }

                    HStack {
                        Text("Changes made in Map tab")
                            .font(AppFonts.body(11, weight: .regular))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textMuted
                            )
                        Spacer()
                        Text("Go to Map →")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(AppColors.magenta.opacity(0.55))
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    // MARK: - Pill Switcher

    private var pillSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(PrismMode.allCases, id: \.label) { mode in
                let isActive = mode == activeMode
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        activeMode  = mode
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                } label: {
                    Text(mode.label)
                        .font(AppFonts.body(11, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(
                            isActive
                                ? mode.color
                                : (isLight
                                    ? AppColors.lightTextTertiary
                                    : AppColors.textTertiary)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if isActive {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(mode.color.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(mode.color.opacity(0.35), lineWidth: 1.0)
                                    )
                                    .matchedGeometryEffect(id: "pill", in: pillNamespace)
                            }
                        }
                }
            }
        }
        .padding(8)
        .background(
            isLight
                ? Color.black.opacity(0.04)
                : Color.white.opacity(0.03)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isLight
                        ? Color.black.opacity(0.07)
                        : AppColors.border,
                    lineWidth: 1
                )
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        activeMode  = all[next]
                        expanded    = false
                        cardDrawn   = false
                        journalText = ""
                    }
                }
        )
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.electricViolet,
                rimVariant:  .prism
            ) {
                ZStack {
                    OrbLayer(
                        accentColor: AppColors.electricViolet,
                        height:      300,
                        variant:     .prism
                    )
                    PrismView(breathPhase: 0)
                }
            }
            .padding(14)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Prism — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     true,
                accentColor: AppColors.purple,
                rimVariant:  .prism
            ) {
                PrismView(breathPhase: 0)
            }
            .padding(14)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Prism — Journal expanded — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            HomeWidgetShell(
                isLight:     false,
                accentColor: AppColors.electricViolet,
                rimVariant:  .prism
            ) {
                ZStack {
                    OrbLayer(accentColor: AppColors.electricViolet, height: 300, variant: .prism)
                    PrismView(breathPhase: 0)
                }
            }
            .padding(14)
        }
    }
    .preferredColorScheme(.dark)
}

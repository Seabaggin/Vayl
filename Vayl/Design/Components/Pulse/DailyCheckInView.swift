// Features/Pulse/CheckIn/DailyCheckInView.swift
// Open Lightly
//
// 5-question daily check-in panel.
// Rendered inside CheckInShell — not a full-screen view.
// Occupies bottom 40% of the shell. Graph lives above in top 60%.
// Controls PulseGraph camera via bindings owned by PulseWidget.
// Each pill answer moves liveScore → live dot moves on graph immediately.
// Cinematic resolution fires against the graph above — not a separate graph.
// On completion returns a PulseEntry to PulseWidget for persistence.
//
// IMPORTANT: This view renders NO background and NO glow field.
// Those live in CheckInShell which owns the container.
// This view renders only its phase content within the panel frame.

import SwiftUI

// MARK: - CheckInPhase

enum CheckInPhase: Equatable {
    case idle
    case questions
    case resolving
    case done
}

// MARK: - CheckInQuestion

private struct CheckInQuestion {
    let text:  String
    let pills: [CheckInPill]
}

private struct CheckInPill: Identifiable {
    let id            = UUID()
    let label:        String
    let dy:           Double
    let glowOverride: PulseCapacityColor?

    init(_ label: String, dy: Double = 0, glow: PulseCapacityColor? = nil) {
        self.label        = label
        self.dy           = dy
        self.glowOverride = glow
    }
}

// MARK: - DailyCheckInView

struct DailyCheckInView: View {

    // MARK: - Inputs

    let entries:     [PulseEntry]
    let graphWidth:  CGFloat      // actual rendered graph width — must match CheckInShell
    let graphHeight: CGFloat      // actual rendered graph height — must match CheckInShell

    // Camera bindings — control PulseGraph in CheckInShell
    @Binding var camScale:     CGFloat
    @Binding var camTx:        CGFloat
    @Binding var camTy:        CGFloat
    @Binding var liveScore:    Double?
    @Binding var drawProgress: CGFloat
    

    var onComplete: (PulseEntry) -> Void
    var onDismiss:  () -> Void

    // MARK: - State

    @State private var phase:       CheckInPhase      = .idle
    @State private var dotY:        Double            = 2.5
    @State private var glowColor:   PulseCapacityColor = .indigo
    @State private var qi:          Int               = 0
    @State private var chosen:      String?           = nil
    @State private var speed:       String?           = nil

    @State private var answerNS:    String = ""
    @State private var answerFocus: String = ""
    @State private var answerFeel:  String = ""

    @State private var msgVisible:     Bool                   = false
    @State private var resolutionAttempt: Int = 0
  

    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Questions

    private let questions: [CheckInQuestion] = [
        CheckInQuestion(
            text: "How is your nervous system right now?",
            pills: [
                CheckInPill("Overwhelmed",  dy: -1.0),
                CheckInPill("Exhausted",    dy: -0.5),
                CheckInPill("Stable",       dy:  0.0),
                CheckInPill("Recharging",   dy: +0.5),
                CheckInPill("Energized",    dy: +1.0),
            ]
        ),
        CheckInQuestion(
            text: "Where is your focus naturally pulling you?",
            pills: [
                CheckInPill("Deeply Inward",  dy: -0.75),
                CheckInPill("Just Me",        dy: +0.25),
                CheckInPill("Balanced",       dy:  0.0),
                CheckInPill("Reaching Out",   dy: +0.75),
            ]
        ),
        CheckInQuestion(
            text: "What's the loudest feeling underneath?",
            pills: [
                CheckInPill("Defensive",   dy: -0.5),
                CheckInPill("Anxious",     dy: -0.5),
                CheckInPill("Content",     dy: +0.5),
                CheckInPill("Secure",      dy: +0.75),
                CheckInPill("Adventurous", dy: +1.0),
            ]
        ),
        CheckInQuestion(
            text: "How is your overall capacity to hold space?",
            pills: [
                CheckInPill("Empty",    dy: 0, glow: .rose),
                CheckInPill("Low",      dy: 0, glow: .magenta),
                CheckInPill("Good",     dy: 0, glow: .indigo),
                CheckInPill("Abundant", dy: 0, glow: .cyan),
            ]
        ),
        CheckInQuestion(
            text: "What's the ideal speed for tonight?",
            pills: [
                CheckInPill("Solitude"),
                CheckInPill("Just Proximity"),
                CheckInPill("Light Connection"),
                CheckInPill("Deep Dive"),
                CheckInPill("Playful"),
            ]
        ),
    ]

    // MARK: - Computed

    private var currentQuestion: CheckInQuestion {
        questions[min(qi, questions.count - 1)]
    }

    private var currentTier: PulseTier {
        PulseTier.tier(for: dotY)
    }

    private var completionMessage: String {
        switch dotY {
        case 3.5...: return "You're expanded today. That's real."
        case 2.5...: return "Steady ground. This is enough."
        case 1.5...: return "Friction is honest data. Logged."
        default:     return "Your space is valid today. Logged."
        }
    }

    private var insightCopy: String {
        switch dotY {
        case 3.5...: return "You have room to give. Tonight is a good night to show up fully."
        case 2.5...: return "You're here. That's enough. Presence without performance."
        case 1.5...: return "Something's rubbing. That's not wrong — it's information."
        default:     return "Low capacity is valid data. Protect your energy first."
        }
    }

    // MARK: - Camera Geometry Helpers
    // Must replicate PulseGraph's internal constants and canvasWidth formula exactly.
    // PulseGraph constants: padLeft=10, padRight=28, padTop=16, padBot=24, minSpacing=44
    // If any of those change in PulseGraph they must change here too.

    private let padLeft:    CGFloat = 10
    private let padRight:   CGFloat = 28
    private let padTop:     CGFloat = 16
    private let padBot:     CGFloat = 24
    private let minSpacing: CGFloat = 44

    // Replicates PulseGraph.canvasWidth exactly.
    // liveScore is always non-nil during check-in so slotCount = entries.count + 1.
    // Root cause of camera targeting empty space: usableWidth was derived from
    // graphWidth (~390px) instead of canvasWidth (~654px for 14 entries).
    // Every xForIndex call was returning a coordinate ~240px short of the actual dot.
    private var canvasWidth: CGFloat {
        let slotCount = entries.count + 1   // +1 for live dot — always present during check-in
        let computed  = padLeft + CGFloat(max(1, slotCount - 1)) * minSpacing + padRight
        return max(graphWidth, computed)
    }

    // usableWidth derives from canvasWidth, not graphWidth.
    private var usableWidth:  CGFloat { canvasWidth  - padLeft - padRight }
    private var usableHeight: CGFloat { graphHeight  - padTop  - padBot   }

    private func xForIndex(_ index: Int) -> CGFloat {
        let totalSlots = entries.count + 1
        guard totalSlots > 1 else {
            return padLeft + usableWidth / 2
        }
        return padLeft + (CGFloat(index) / CGFloat(totalSlots - 1)) * usableWidth
    }

    private func yForScore(_ score: Double) -> CGFloat {
        padTop + CGFloat((4.0 - score) / 3.0) * usableHeight
    }

    // ADD THIS: The distance the ScrollView natively shifts the content left
    private var initialScrollOffset: CGFloat {
        max(0, canvasWidth - graphWidth)
    }

    // Camera step 1 — zoom to last historical entry.
    private var step1Values: (scale: CGFloat, tx: CGFloat, ty: CGFloat) {
        let lastX = xForIndex(entries.count - 1)
        let lastY = yForScore(entries.last?.capacityScore ?? 2.5)
        let s: CGFloat = 9.0
        
        // Calculate the actual visual X coordinate on screen
        let visibleX = lastX - initialScrollOffset
        return (
            scale: s,
            tx:    (graphWidth  / 2) - visibleX * s,
            ty:    (graphHeight / 2) - lastY * s
        )
    }

    // Camera step 2 — pan to midpoint (Unused if using the single linear block, but updated for safety)
    private var step2Values: (tx: CGFloat, ty: CGFloat) {
        let lastX  = xForIndex(entries.count - 1)
        let lastY  = yForScore(entries.last?.capacityScore ?? 2.5)
        let todayX = xForIndex(entries.count)
        let todayY = yForScore(dotY)
        let midX   = (lastX + todayX) / 2
        let midY   = (lastY + todayY) / 2
        let s: CGFloat = 9.0
        let visibleMidX = midX - initialScrollOffset
        
        return (
            tx: (graphWidth  / 2) - visibleMidX * s,
            ty: (graphHeight / 2) - midY * s
        )
    }

    // Camera step 3 — settle on today dot
    private var step3Values: (scale: CGFloat, tx: CGFloat, ty: CGFloat) {
        let todayX = xForIndex(entries.count)
        let todayY = yForScore(dotY)
        let s: CGFloat = 11.0   // change this number to change zoom level
        
        let visibleX = todayX - initialScrollOffset
        return (
            scale: s,
            tx:    (graphWidth  / 2) - visibleX * s,
            ty:    (graphHeight / 2) - todayY * s
        )
    }

    // MARK: - Body
    // Renders only the active phase content.
    // No background. No glow field. Those live in CheckInShell.
    // Frame is the bottom 40% panel — CheckInShell owns the layout.

    var body: some View {
        ZStack {
            switch phase {
            case .idle:
                idleView
                    .transition(.opacity.combined(with: .offset(y: 20)))

            case .questions:
                questionView
                    .transition(.opacity.combined(with: .offset(y: 20)))

            case .resolving:
                resolvingView
                    .transition(.opacity)

            case .done:
                doneView
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
        .animation(.easeOut(duration: 0.4), value: phase)
        .onAppear { startIdle() }
        .onDisappear { resolutionAttempt += 1 }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 20) {
            // Divider between graph and panel — subtle, not structural
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            Text("Daily Check-In")
                .font(AppFonts.screenTitle)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )

            Text("5 questions. Honest answers.\nNo judgment.")
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                )

            Spacer()

            HoloCTAButton(title: "Begin", isEnabled: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .questions
                }
                liveScore = 2.5
            }
            .padding(.horizontal, 32)

            Button("Not now") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                resetCamera()
                onDismiss()
            }
            .font(AppFonts.caption)
            .foregroundStyle(
                isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
            )
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            // Progress bar
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Question text
            Text(currentQuestion.text)
                .font(AppFonts.sectionHeading)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextPrimary : AppColors.textPrimary
                )
                .padding(.horizontal, 32)
                .id(qi)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal:   .opacity.combined(with: .offset(y: -12))
                ))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            // Pills
            pillGrid
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<questions.count, id: \.self) { i in
                Capsule()
                    .fill(
                        i < qi
                            ? AnyShapeStyle(LinearGradient(
                                colors: isLight
                                    ? [AppColors.purple, AppColors.magenta]
                                    : [AppColors.cyan,   AppColors.purple],
                                startPoint: .leading,
                                endPoint:   .trailing
                              ))
                            : i == qi
                                ? AnyShapeStyle(currentTier.color.opacity(0.6))
                                : AnyShapeStyle(
                                    (isLight ? Color.black : Color.white).opacity(0.08)
                                  )
                    )
                    .frame(height: 3)
                    .animation(.easeOut(duration: 0.3), value: qi)
            }
        }
    }

    // MARK: - Pill Grid

    private var pillGrid: some View {
        let pills = currentQuestion.pills

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 10),
                count: pills.count <= 3 ? pills.count : 2
            ),
            spacing: 10
        ) {
            ForEach(pills) { pill in
                SelectablePill(
                    label:      pill.label,
                    isSelected: chosen == pill.label,
                    intensity:  .warm
                ) {
                    handlePillTap(pill)
                }
            }
        }
        .id(qi)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 16)),
            removal:   .opacity.combined(with: .offset(y: -8))
        ))
    }

    // MARK: - Resolving View
    // Minimal UI — graph is the experience during resolution.
    // Completion message fades in after the line has drawn.

    private var resolvingView: some View {
        VStack {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            if msgVisible {
                Text(completionMessage)
                    .font(AppFonts.sectionHeading)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isLight
                                ? [AppColors.purple, AppColors.magenta]
                                : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta],
                            startPoint: .leading,
                            endPoint:   .trailing
                        )
                    )
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }

            Spacer()
        }
    }

    // MARK: - Done View

    private var doneView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, (isLight ? Color.black : Color.white).opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint:   .trailing
                    )
                )
                .frame(height: 1)

            Spacer()

            VStack(spacing: 6) {
                Text(PulseTier.tier(for: dotY).label)
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: isLight
                                ? [AppColors.purple, AppColors.magenta]
                                : [AppColors.cyan, AppColors.electricViolet, AppColors.magenta],
                            startPoint: .leading,
                            endPoint:   .trailing
                        )
                    )

                Text(PulseTier.tier(for: dotY).sublabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(
                        isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
                    )
            }
            .padding(.bottom, 16)

            Text(insightCopy)
                .font(AppFonts.bodyText)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    isLight ? AppColors.lightTextSecondary : AppColors.textSecondary
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

            HoloCTAButton(title: "Done", isEnabled: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                submitEntry()
            }
            .padding(.horizontal, 32)

            Button("Start over") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                resetAll()
            }
            .font(AppFonts.caption)
            .foregroundStyle(
                isLight ? AppColors.lightTextTertiary : AppColors.textTertiary
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Pill Tap Handler

    private func handlePillTap(_ pill: CheckInPill) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chosen = pill.label

        if let glow = pill.glowOverride {
            glowColor = glow
        } else {
            dotY = max(1.0, min(4.0, dotY + pill.dy))
        }

        switch qi {
        case 0: answerNS    = pill.label
        case 1: answerFocus = pill.label
        case 2: answerFeel  = pill.label
        case 4: speed       = pill.label
        default: break
        }

        // Move the live dot on the graph above — immediately visible to user
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            liveScore = dotY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if qi < questions.count - 1 {
                withAnimation(.easeOut(duration: 0.3)) {
                    qi     += 1
                    chosen  = nil
                }
            } else {
                // Q5 complete — fire cinematic resolution on the graph above
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = .resolving
                }
                triggerResolution()
            }
        }
    }

    // MARK: - Cinematic Resolution
    // Camera moves animate the PulseGraph in CheckInShell's top 60%.
    // The user watches the line draw in real time on the graph above.
  
    private func triggerResolution() {
        guard !reduceMotion else {
            drawProgress = 1.0
            msgVisible   = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { phase = .done }
                resetCamera()
            }
            return
        }

        resolutionAttempt += 1
        let currentAttempt = resolutionAttempt

        Task { @MainActor in

            // t=0.00s — Slow zoom to last historical entry
            let s1 = step1Values
            withAnimation(.easeInOut(duration: 1.8)) {
                camScale = s1.scale
                camTx    = s1.tx
                camTy    = s1.ty
            }

            try? await Task.sleep(for: .seconds(2.0))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=2.0s — Camera tracks pen tip, line draws
            let s3 = step3Values
            withAnimation(.linear(duration: 6.0)) {
                camTx        = s3.tx
                camTy        = s3.ty
                camScale     = s3.scale
                drawProgress = 1.0
            }

            try? await Task.sleep(for: .seconds(6.2))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=8.2s — Message fades in
            withAnimation(.easeOut(duration: 0.7)) {
                msgVisible = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            try? await Task.sleep(for: .seconds(1.8))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=10.0s — Pull back to full graph
            withAnimation(.easeInOut(duration: 1.8)) {
                camScale = 1.0
                camTx    = 0.0
                camTy    = 0.0
            }

            try? await Task.sleep(for: .seconds(1.6))
            guard currentAttempt == resolutionAttempt && !Task.isCancelled else { return }

            // t=11.6s — Done card
            withAnimation(.easeOut(duration: 0.5)) {
                phase = .done
            }
        }
    }

    // MARK: - Submit Entry

    private func submitEntry() {
        let entry = PulseEntry(
            date:          Date(),
            capacityScore: max(1.0, min(4.0, dotY)),
            glowColor:     glowColor,
            speed:         speed ?? "Light Connection",
            nervousSystem: answerNS.isEmpty    ? "Stable"   : answerNS,
            focus:         answerFocus.isEmpty  ? "Balanced" : answerFocus,
            feeling:       answerFeel.isEmpty   ? "Content"  : answerFeel
        )
        resetCamera()
        onComplete(entry)
    }

    // MARK: - Helpers

    private func startIdle() {
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            phase = .idle
        }
    }

    private func resetCamera() {
        withAnimation(.easeOut(duration: 0.5)) {
            camScale = 1.0
            camTx    = 0.0
            camTy    = 0.0
        }
    }

    private func resetAll() {
        resolutionAttempt += 1
        qi           = 0
        chosen       = nil
        speed        = nil
        answerNS     = ""
        answerFocus  = ""
        answerFeel   = ""
        msgVisible   = false
        drawProgress = 0.0
        liveScore    = 2.5
        resetCamera()
        withAnimation(.easeOut(duration: 0.3)) {
            phase = .questions
        }
    }
}

// MARK: - Previews
// Previews render the full shell so the graph is visible above the panel

#Preview("Idle — dark") {
    CheckInShell(
        entries:      PulseEntry.previews,
        camScale:     .constant(1.0),
        camTx:        .constant(0.0),
        camTy:        .constant(0.0),
        liveScore:    .constant(nil),
        drawProgress: .constant(0.0),
        onComplete:   { _ in },
        onDismiss:    {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Idle — light") {
    CheckInShell(
        entries:      PulseEntry.previews,
        camScale:     .constant(1.0),
        camTx:        .constant(0.0),
        camTy:        .constant(0.0),
        liveScore:    .constant(nil),
        drawProgress: .constant(0.0),
        onComplete:   { _ in },
        onDismiss:    {}
    )
    .preferredColorScheme(.light)
}

import SwiftUI

/// The "Path" overlay card — the couple's first steps to their reveal. Destination of the
/// matched-geometry morph from GettingStartedEntryCard. Presented over a blurred Home.
struct GettingStartedPathView: View {
    let gettingStarted: GettingStarted
    let namespace: Namespace.ID
    let onSelect: (GettingStartedStepKind) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Begin together")
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.cardBackground))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text("Three steps to your first reveal.")
                .font(AppFonts.cardTitle)
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.sm)

            Text("Each one brings the two of you closer to what you share.")
                .font(AppFonts.bodyText)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, AppSpacing.xs)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(gettingStarted.steps.enumerated()), id: \.element.id) { idx, step in
                    PathStepRow(
                        step: step,
                        isLast: idx == gettingStarted.steps.count - 1,
                        onTap: { if step.state == .active { onSelect(step.kind) } }
                    )
                }
            }
            .padding(.top, AppSpacing.lg)

            Text("🔒 Private to you: only what you both share is ever revealed")
                .font(AppFonts.meta)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.lg)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.cardBg)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: AppRadius.pill)
                .fill(AppColors.spectrumBorder)
                .frame(height: 2)
                .padding(.horizontal, AppSpacing.lg)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(AppColors.spectrumBorder, lineWidth: 1)
                .opacity(0.5)
        )
        .matchedGeometryEffect(id: "gettingStartedPath", in: namespace, anchor: .center, isSource: true)
    }
}

/// One node on the Path: a spectrum rail + a state-styled node + copy.
private struct PathStepRow: View {
    let step: GettingStartedStep
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(rail)
                        .frame(width: 2)
                        .padding(.top, 30)
                }
                node
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(step.title)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(step.state == .active ? AppColors.textPrimary : AppColors.textSecondary)
                Text(step.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                if step.state == .active {
                    Text("Start →")
                        .font(AppFonts.caption.weight(.semibold))
                        .foregroundColor(AppColors.spectrumCyan)
                        .padding(.top, AppSpacing.xs)
                }
            }
            .padding(.bottom, isLast ? 0 : AppSpacing.lg)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var rail: Color {
        switch step.state {
        case .done:    return AppColors.spectrumPurple
        default:       return AppColors.textTertiary.opacity(0.25)
        }
    }

    @ViewBuilder private var node: some View {
        switch step.state {
        case .done:
            Circle().fill(AppColors.spectrumBorder)
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: "checkmark").font(AppFonts.caption).foregroundColor(.white))
        case .active:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(AppColors.spectrumCyan, lineWidth: 2))
                .spectrumBorderGlow(intensity: 0.6)
        case .upcoming:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 2))
        case .locked:
            Circle().fill(AppColors.cardBg)
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: "lock.fill").font(AppFonts.meta).foregroundColor(AppColors.textTertiary))
        }
    }
}

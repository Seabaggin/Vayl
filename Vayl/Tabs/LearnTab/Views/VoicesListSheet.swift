// Tabs/LearnTab/Views/VoicesListSheet.swift
//
// The full creator list, behind the hub's "See all".
//
// The hub panel shows a rotating handful; this is where the whole shelf lives, and
// where the topic filter belongs — a filter over four inline rows would be chrome,
// a filter over two dozen is the point.
//
// The filter is TOPIC (the shape of non-monogamy someone's work is about), never
// credential. The old Creators/Researchers control filtered on credential, which is
// why it collapsed the moment the researchers came out on consent grounds.

import SwiftUI

struct VoicesListSheet: View {
    let store: LearnStore
    var onSelect: (Voice) -> Void = { _ in }

    /// nil = all topics.
    @State private var topic: VoiceTopic?

    /// Only offer a filter for topics the corpus actually has — no chip that
    /// leads to an empty list.
    private var topicsPresent: [VoiceTopic] {
        VoiceTopic.allCases.filter { t in store.voices.contains { $0.topic == t } }
    }

    private var visible: [Voice] {
        guard let topic else { return store.voices }
        return store.voices.filter { $0.topic == topic }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            if topicsPresent.count > 1 { topicChips }
            ScrollView {
                LazyVStack(spacing: 0) {
                    if visible.isEmpty {
                        VaylEmptyState(
                            icon: AppIcons.textMagnifyingglass,
                            headline: "None here yet",
                            message: "Nobody in this corner of the map yet."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.xxl)
                    } else {
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, voice in
                            if index > 0 { VaylHairline() }
                            Button { onSelect(voice) } label: { row(voice) }
                                .buttonStyle(PressableCardStyle())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Voices")
                .font(AppFonts.sheetTitle)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text("\(visible.count)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                chip("All", on: topic == nil) { topic = nil }
                ForEach(topicsPresent) { t in
                    chip(t.label, on: topic == t) { topic = t }
                }
            }
        }
    }

    private func chip(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(AppAnimation.standard) { action() }
        } label: {
            Text(label)
                .font(AppFonts.buttonLabelSmall)
                .foregroundStyle(on ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(minHeight: 44)
                .background(Capsule()
                    .fill(on ? AppColors.spectrumPurple.opacity(0.2) : AppColors.whisperFill)
                    .overlay(Capsule().stroke(on ? AppColors.spectrumPurple.opacity(0.45)
                                                 : AppColors.borderSubtle, lineWidth: 1)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    private func row(_ v: Voice) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // "Poly educator" — topic + mode, never exceeding their own claim.
                Text(v.label)
                    .overlineTracked()
                    .foregroundStyle(AppColors.textTertiary)
                Text(v.name)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(v.blurb)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: AppIcons.chevronRight)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.vertical, AppSpacing.md2)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        AppColors.modalBackground.ignoresSafeArea()
        VoicesListSheet(store: LearnStore())
    }
}

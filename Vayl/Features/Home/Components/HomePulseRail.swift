// Features/Home/Components/HomePulseRail.swift
// STUB: graph body removed. Will be rebuilt in Segment 6 as compact aura widget.

import SwiftUI

struct HomePulseRail: View {

    var onTap:     (() -> Void)? = nil
    var onCheckIn: (() -> Void)? = nil
    var onInfo:    (() -> Void)? = nil
    var expansion:      Double  = 1
    var maxGraphHeight: CGFloat = 160

    @Environment(PulseStore.self) private var pulse

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack {
                Text("The Pulse")
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Button("Check in") { onCheckIn?() }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentPrimary)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PulseInfoSheet stub (will be replaced in Segment 6)

struct PulseInfoSheet: View {
    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            Text("About the Pulse")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

#Preview {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HomePulseRail()
            .padding(AppSpacing.lg)
    }
    .environment(PulseStore())
    .preferredColorScheme(.dark)
}

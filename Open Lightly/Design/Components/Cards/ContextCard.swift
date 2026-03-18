import SwiftUI

struct ContextCard: View {
    let option: ContextOption
    let isFront: Bool
    let isConfirmed: Bool

    @State private var detailVisible = false
    @State private var isBreathing = false

    private var intensity: ContextIntensity { option.intensity }

    var body: some View {
        ZStack {
            // Background — flat or gradient depending on intensity
            if intensity.bgTintStart < 1.0 {
                LinearGradient(
                    stops: [
                        .init(color: AppColors.cardBg, location: intensity.bgTintStart),
                        .init(color: intensity.bgTintColor, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                AppColors.cardBg
            }

            // Internal glow — top-right, clipped to card
            if intensity.internalGlowSize > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Ellipse()
                            .fill(intensity.internalGlowColor)
                            .frame(
                                width:  intensity.internalGlowSize,
                                height: intensity.internalGlowSize
                            )
                            .blur(radius: intensity.internalGlowBlur)
                            .opacity(isBreathing ? 1.3 : 1.0)
                            .offset(x: 20, y: -20)
                    }
                    Spacer()
                }
            }

            // Watermark — top-right
            VStack {
                HStack {
                    Spacer()
                    Text("✦")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.06))
                        .padding(16)
                }
                Spacer()
            }

            // Content
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(option.subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                // Detail — fades in only when front card
                Text(option.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(13 * 0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(detailVisible ? 1 : 0)
            }
            .padding(28)
            .frame(width: 300, height: 340, alignment: .topLeading)
        }
        .frame(width: 300, height: 340)
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: isConfirmed ? 2 : 1.5
                )
                .opacity(isConfirmed ? 1.0 : intensity.borderOpacity)
        )
        .shadow(color: intensity.shadowColor, radius: intensity.shadowRadius)
        .shadow(
            color: isConfirmed ? AppColors.cyan.opacity(isBreathing ? 0.36 : 0.3) : .clear,
            radius: 8
        )
        .shadow(
            color: isConfirmed ? AppColors.magenta.opacity(isBreathing ? 0.24 : 0.2) : .clear,
            radius: 12
        )
        .onChange(of: isFront) { _, newFront in
            if newFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.2)) { detailVisible = true }
            } else {
                withAnimation(.easeOut(duration: 0.15)) { detailVisible = false }
            }
        }
        .onChange(of: isConfirmed) { _, confirmed in
            if confirmed {
                startBreathing()
            } else {
                stopBreathing()
            }
        }
        .onAppear {
            if isFront {
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) { detailVisible = true }
            }
            if isConfirmed {
                startBreathing()
            }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        isBreathing = false

        withAnimation(.easeInOut(duration: 0.2)) { isBreathing = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) { isBreathing = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.2)) { isBreathing = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.2)) { isBreathing = false }
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.2)) { isBreathing = false }
    }
}

// MARK: - Preview

#Preview("All Intensities") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach([
                ContextOption(id: "single",          context: .single,          intensity: .ember,   title: "I'm single",                subtitle: "No partner in the picture",      detail: "Your journey is yours alone."),
                ContextOption(id: "partnered_open",  context: .partneredOpen,   intensity: .spark,   title: "I have a partner",          subtitle: "They know I'm exploring",        detail: "We'll include prompts for transparency."),
                ContextOption(id: "partnered_hidden",context: .partneredHidden, intensity: .blaze,   title: "It's complicated",          subtitle: "I'm not sure how to bring it up", detail: "No pressure. We'll start with self-understanding."),
                ContextOption(id: "not_talked",      context: .notTalked,       intensity: .flame,   title: "Haven't talked about it",   subtitle: "One or both of us is curious",   detail: "We'll start with the basics."),
                ContextOption(id: "some_experience", context: .someExperience,  intensity: .inferno, title: "We've tried some things",   subtitle: "Good, bad, or in between",       detail: "We'll help you process what happened."),
                ContextOption(id: "needs_reset",     context: .needsReset,      intensity: .nova,    title: "We need a reset",           subtitle: "Something's off",                detail: "Let's rebuild with structure and care."),
            ], id: \.id) { option in
                ContextCard(option: option, isFront: true, isConfirmed: false)
            }
        }
        .padding(40)
    }
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

#Preview("Confirmed State") {
    let option = ContextOption(id: "needs_reset", context: .needsReset, intensity: .nova, title: "We need a reset", subtitle: "Something's off", detail: "Let's rebuild with structure and care.")
    HStack(spacing: 20) {
        ContextCard(option: option, isFront: true, isConfirmed: false)
        ContextCard(option: option, isFront: true, isConfirmed: true)
    }
    .padding(40)
    .background(AppColors.pageBg)
    .preferredColorScheme(.dark)
}

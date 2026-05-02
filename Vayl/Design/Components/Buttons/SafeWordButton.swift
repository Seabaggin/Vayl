// ✅ Design system audit — verified March 9, 2026
import SwiftUI

// MARK: - SafeWordButton
// Safety feature — always visible, functional, and unmissable
struct SafeWordButton: View {
    let onActivate: () -> Void
    @State private var showConfirmation: Bool = false
    @Environment(\.theme) private var t // ARCHITECTURAL FLAG: legacy theme env — do not migrate to AppColors until theme system is unified

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(AppIcons.handRaised)
                    .font(.system(size: 18, weight: .semibold)) // intentional exception: fixed-size safety icon for unmissable tap target
                Text("Safe Word")
                    .font(AppFonts.buttonLabel)
            }
            .foregroundColor(t.gold)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(t.isDark ? t.gold.opacity(0.08) : t.gold.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(t.gold.opacity(0.25), lineWidth: 1.5)
            )
        }
        .alert(
            "Use Safe Word?",
            isPresented: $showConfirmation,
            actions: {
                Button("Pause Session", role: .destructive) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showConfirmation = false
                    onActivate()
                }
                Button("Cancel", role: .cancel) {
                    showConfirmation = false
                }
            },
            message: {
                Text("This will pause the session. You can return anytime.")
            }
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        SafeWordButton { print("Safe word activated") }
    }
}

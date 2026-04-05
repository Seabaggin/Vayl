// ✅ Design system audit — verified March 9, 2026
import SwiftUI

// MARK: - SafeWordButton
// Safety feature — always visible, functional, and unmissable
struct SafeWordButton: View {
    let onActivate: () -> Void
    @State private var showConfirmation: Bool = false
    @Environment(\.theme) private var t

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Safe Word")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(t.gold)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(t.isDark ? t.gold.opacity(0.08) : t.gold.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
        Color.black.ignoresSafeArea()
        SafeWordButton { print("Safe word activated") }
    }
}

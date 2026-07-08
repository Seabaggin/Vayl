// ✅ Design system audit — verified March 9, 2026
import SwiftUI
import UIKit

// MARK: - ScreenshotProtectionModifier
struct ScreenshotProtectionModifier: ViewModifier {
    @State private var isObscured = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isObscured {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                        VStack(spacing: AppSpacing.sm) {
                            Image(AppIcons.eyeSlashScreen)
                                .font(.largeTitle)
                                .foregroundStyle(AppColors.safetyAccent)
                            Text("Content Protected")
                                .font(AppFonts.sectionHeading)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("This content is private and cannot be captured.")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(AppSpacing.xxl)
                    }
                    .transition(.opacity.animation(AppAnimation.fast))
                }
            }
            .onAppear { checkCaptureStatus() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                flashObscure()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                checkCaptureStatus()
            }
    }

    private func checkCaptureStatus() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
        isObscured = windowScene.screen.isCaptured
    }

    private func flashObscure() {
        isObscured = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            checkCaptureStatus()
        }
    }
}

// MARK: - View Extension
extension View {
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtectionModifier())
    }
}

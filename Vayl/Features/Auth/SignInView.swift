//
//  SignInView.swift
//  Vayl
//

import SwiftUI

struct SignInView: View {

    // MARK: - Dependencies

    var authService: AuthService

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let layout = AppLayout.from(geo)
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    VStack(spacing: AppSpacing.sm) {
                        Text("Vayl")
                            .font(Font.custom("ClashDisplay-Bold", size: 36, relativeTo: .largeTitle))
                            .foregroundStyle(.white)

                        Text("Explore intimacy at your own pace")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    VStack(spacing: AppSpacing.md) {
                        Button {
                            authService.signInWithApple()
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(AppIcons.appleLogo)
                                Text("Sign in with Apple")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        .padding(.horizontal, AppSpacing.xxl)
                        .disabled(authService.isLoading)

                        if authService.isLoading {
                            ProgressView()
                                .tint(.white)
                        }

                        if let error = authService.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, AppSpacing.xxl)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, layout.safeAreaInsets.bottom)
            }
        }
    }
}

#Preview {
    SignInView(authService: AuthService())
}

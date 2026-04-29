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
        ZStack {
            AppColors.pageBg
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text("Vayl")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Explore intimacy at your own pace")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        authService.signInWithApple()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .foregroundStyle(.black)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                    .disabled(authService.isLoading)

                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let error = authService.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

#Preview {
    SignInView(authService: AuthService())
}

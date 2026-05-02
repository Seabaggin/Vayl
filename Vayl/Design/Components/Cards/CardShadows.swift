//
//  CardShadows.swift
//  Open Lightly
//

import SwiftUI

extension View {
    func cardShadows(isLight: Bool) -> some View {
        self
            .shadow(
                color: isLight
                    ? AppColors.accentSecondary.opacity(0.10)
                    : AppColors.accentPrimary.opacity(0.14),
                radius: 20
            )
            .shadow(
                color: Color.black.opacity(isLight ? 0.06 : 0.85),
                radius: 25,
                y: 25
            )
    }
}

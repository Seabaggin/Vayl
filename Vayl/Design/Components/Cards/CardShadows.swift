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
                    ? AppColors.purple.opacity(0.10)
                    : AppColors.cyan.opacity(0.14),
                radius: 20
            )
            .shadow(
                color: Color.black.opacity(isLight ? 0.06 : 0.85),
                radius: 25,
                y: 25
            )
    }
}

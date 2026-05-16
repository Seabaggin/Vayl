//
//  SpectrumBar.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//


import SwiftUI

struct SpectrumBar: View {
    var height: CGFloat = 3

    var body: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(height: height)
    }
}
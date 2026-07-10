// Design/Components/VaylHairline.swift
//
// The one neutral divider. A 1px full-width line at `AppColors.borderSubtle`.
// The five hand-rolled divider dialects (Divider tints, opacity rectangles,
// bespoke strokes) collapse onto this. For the signature cyan→purple→magenta
// accent line, use `SpectrumHairline` instead — this is the quiet structural rule.

import SwiftUI

struct VaylHairline: View {
    /// Override for the rare divider that needs a different tint. Defaults to
    /// the app's structural border colour.
    var color: Color = AppColors.borderSubtle

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

#Preview("VaylHairline") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylHairline()
            .padding(AppSpacing.lg)
    }
    .preferredColorScheme(.dark)
}

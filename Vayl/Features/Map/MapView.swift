//
//  MapView.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/8/26.
//


// Features/Map/MapView.swift
// Open Lightly

import SwiftUI

struct MapView: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("Map")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
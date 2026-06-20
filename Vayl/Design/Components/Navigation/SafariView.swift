//
//  SafariView.swift
//  Vayl
//
//  Thin SwiftUI wrapper over SFSafariViewController for presenting web content
//  (legal pages) in-app via `.sheet(item:)`. Tinted to the Vayl palette.
//
//  Note: SFSafariViewController loads only live `https://` URLs — it CANNOT render
//  bundled/local HTML. That's why the legal docs are hosted (placeholder for now).
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .done
        // Bridge the SwiftUI color tokens to UIColor (iOS 14+). Keeps the slim
        // Safari chrome on-brand; the page body itself comes from the hosted URL.
        controller.preferredControlTintColor = UIColor(AppColors.accentPrimary)
        controller.preferredBarTintColor = UIColor(AppColors.modalBackground)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        // SFSafariViewController is configured at init; nothing to update.
    }
}

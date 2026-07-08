// Design/Components/Navigation/VaylPresentation.swift
// Vayl
//
// Presentation grammar — the navigation contract.
//
// Every modal in a feature view routes through `.vaylCover` or `.vaylSheet`.
// Never raw `.fullScreenCover` / `.sheet` in feature views — same discipline as
// design tokens: no raw primitives.
//
//   .vaylCover  = full-screen cover + dismiss-guard + confirm-on-exit.
//                 For protected, immersive modes (Card Session, OB, raters).
//                 Interactive dismiss is disabled; exit is explicit and confirmed.
//
//   .vaylSheet  = sheet + standard detents / grabber / modal background.
//                 For previewing-something-you-return-from and discrete tasks.
//
//   .vaylSafariSheet / .vaylShareSheet = sanctioned exemptions for modals that
//                 need a genuine UIKit presentation context (SFSafariViewController,
//                 UIActivityViewController) the custom `.vaylSheet` overlay can't
//                 host. Still routed through here, never a raw `.sheet` in a feature view.
//
// Protected content asks to leave by calling the `vaylDismiss` environment
// closure. The cover intercepts it and shows the confirm dialog (Duolingo-lesson
// logic) before actually dismissing. A plain `dismiss()` from inside the content
// would bypass the guard — always call `vaylDismiss` instead.

import SwiftUI
import UIKit

// MARK: - vaylDismiss Environment

/// A guarded dismiss request available to any view presented inside a `.vaylCover`.
///
/// Calling this asks the cover to leave. When the cover was configured with
/// `confirmOnExit` (the default), this surfaces the confirm dialog first; the
/// cover only closes if the user confirms. Outside a `.vaylCover` this is a no-op.
struct VaylDismissAction {
    fileprivate let action: (_ confirm: Bool) -> Void
    /// Request to leave the cover. `confirm: true` (default) surfaces the confirm
    /// dialog when the cover guards exit; `confirm: false` leaves immediately —
    /// use at a natural end, e.g. the session close.
    func callAsFunction(confirm: Bool = true) { action(confirm) }
}

private struct VaylDismissKey: EnvironmentKey {
    static let defaultValue = VaylDismissAction(action: { _ in })
}

extension EnvironmentValues {
    var vaylDismiss: VaylDismissAction {
        get { self[VaylDismissKey.self] }
        set { self[VaylDismissKey.self] = newValue }
    }
}

// MARK: - Cover

private struct VaylCoverModifier<CoverContent: View>: ViewModifier {

    @Binding var isPresented: Bool

    let confirmOnExit: Bool
    let confirmTitle: String
    let confirmMessage: String
    let confirmDiscardLabel: String
    let onExit: (() -> Void)?
    @ViewBuilder let coverContent: () -> CoverContent

    @State private var showConfirm = false

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            coverContent()
                .environment(\.vaylDismiss, VaylDismissAction { confirm in
                    if confirm && confirmOnExit {
                        showConfirm = true
                    } else {
                        close()
                    }
                })
                // A protected cover never dismisses interactively — exit is
                // always explicit, via vaylDismiss → confirm.
                .interactiveDismissDisabled(true)
                .confirmationDialog(
                    confirmTitle,
                    isPresented: $showConfirm,
                    titleVisibility: .visible
                ) {
                    Button(confirmDiscardLabel, role: .destructive) { close() }
                    Button("Keep going", role: .cancel) { }
                } message: {
                    Text(confirmMessage)
                }
        }
    }

    private func close() {
        onExit?()
        isPresented = false
    }
}

// MARK: - Sheet

private struct VaylSheetModifier<SheetContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let heightFraction: CGFloat
    /// When provided, the sheet height is this × heightFraction. Use it when the
    /// modifier is attached over tall/scrolling content, where the overlay's own
    /// GeometryReader measures the content height (not the screen) and the fraction
    /// would otherwise resolve too large. Defaults to the overlay geometry.
    let screenHeight: CGFloat?
    let showsGrabber: Bool
    @ViewBuilder let sheetContent: () -> SheetContent

    @State private var drag: CGFloat = 0

    /// Resting scrim opacity at full height. Scaled by heightFraction so a short
    /// sheet barely dims the world and a tall one dims more — Apple's detent behavior.
    private let scrimOpacityAtFull: Double = 0.5
    /// Drag past this fraction of the sheet's own height → dismiss on release
    /// (proportional, so short and tall sheets feel the same, not a fixed 120pt).
    private let dismissDistanceRatio: CGFloat = 0.25
    /// A fast flick whose projected travel exceeds this dismisses even below the
    /// distance threshold — the velocity path, so a quick flick throws it away.
    private let flingProjection: CGFloat = 240

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { geo in
                let sheetHeight = (screenHeight ?? geo.size.height) * heightFraction
                let dragProgress = sheetHeight > 0 ? min(1, max(0, drag) / sheetHeight) : 0
                let restingScrim = scrimOpacityAtFull * heightFraction

                ZStack(alignment: .bottom) {
                    if isPresented {
                        // Scrim dims with the detent (a short sheet barely dims) and
                        // lifts as you drag the sheet down. Tap to dismiss.
                        Color.black
                            .opacity(restingScrim * (1 - dragProgress))
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { dismiss() }
                            .transition(.opacity)

                        // Full-bleed bottom sheet at a fixed fraction of the screen.
                        // NOT a SwiftUI `.sheet` — iOS 26 insets those (side gaps);
                        // a custom overlay is the only way to full-bleed width,
                        // matching the OB sheets (FounderLetter / CredentialEditor).
                        VStack(spacing: 0) {
                            if showsGrabber { grabber }
                            sheetContent()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                        .frame(maxWidth: .infinity)
                        // Chrome FIRST (it applies .frame(maxHeight: .infinity) to fill
                        // its surface), then cap the height — otherwise the chrome
                        // re-expands the sheet to full height and the fraction is lost.
                        .vaylSheetChrome()
                        .frame(height: sheetHeight, alignment: .top)
                        .offset(y: max(0, drag))
                        // Drag-to-dismiss on the top chrome zone only, so the
                        // content's own ScrollViews aren't hijacked.
                        .overlay(alignment: .top) {
                            Color.clear
                                .frame(height: 56)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { drag = max(0, $0.translation.height) }
                                        .onEnded { value in
                                            let past = value.translation.height > sheetHeight * dismissDistanceRatio
                                            let fling = value.predictedEndTranslation.height > flingProjection
                                            if past || fling { dismiss() } else { withAnimation(AppAnimation.arrive.reduceMotionSafe) { drag = 0 } }
                                        }
                                )
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(AppAnimation.arrive.reduceMotionSafe, value: isPresented)
            }
            .ignoresSafeArea()
            .allowsHitTesting(isPresented)
        }
    }

    /// Spectrum pull-tab — matches the OB sheets exactly (AppColors.spectrumBorder
    /// at 0.6), never a plain gray system grabber.
    private var grabber: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.6)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.sm)
    }

    private func dismiss() {
        drag = 0
        withAnimation(AppAnimation.arrive.reduceMotionSafe) { isPresented = false }
    }
}

// MARK: - View API

extension View {

    /// Present `content` as a protected full-screen cover.
    ///
    /// Interactive dismiss is disabled. The content leaves by calling the
    /// `\.vaylDismiss` environment action, which (when `confirmOnExit` is true)
    /// surfaces a confirm dialog before closing.
    ///
    /// Use for the most protected experiences: Card Session, OB, raters.
    func vaylCover<CoverContent: View>(
        isPresented: Binding<Bool>,
        confirmOnExit: Bool = true,
        confirmTitle: String = "Leave the session?",
        confirmMessage: String = "You can pick this hand up again later. Nothing here is saved until you finish.",
        confirmDiscardLabel: String = "Leave",
        onExit: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> CoverContent
    ) -> some View {
        modifier(VaylCoverModifier(
            isPresented: isPresented,
            confirmOnExit: confirmOnExit,
            confirmTitle: confirmTitle,
            confirmMessage: confirmMessage,
            confirmDiscardLabel: confirmDiscardLabel,
            onExit: onExit,
            coverContent: content
        ))
    }

    /// Present `content` as a full-bleed Vayl bottom sheet — the OB sheet look
    /// (rounded top, spectrum top-edge border, tinted surface, spectrum pull-tab),
    /// resting at `heightFraction` of the screen. Scrim-tap and a top drag-handle
    /// dismiss. A custom overlay, not a SwiftUI `.sheet` (those inset on iOS 26).
    ///
    /// Use for previewing-something-you-return-from and discrete tasks.
    /// `heightFraction`: portion of the screen height the sheet occupies (~0.5 = medium).
    func vaylSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        heightFraction: CGFloat = 0.55,
        screenHeight: CGFloat? = nil,
        showsGrabber: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(VaylSheetModifier(
            isPresented: isPresented,
            heightFraction: heightFraction,
            screenHeight: screenHeight,
            showsGrabber: showsGrabber,
            sheetContent: content
        ))
    }
}

// MARK: - Safari Sheet
//
// Sanctioned exemption: SFSafariViewController is system chrome — it needs its
// own navigation bar and dismiss affordance, which the custom `.vaylSheet`
// overlay can't host. This wrapper keeps that one exception in a single
// place, so a raw `.sheet` never appears in a feature view.

private struct VaylSafariSheetModifier<Item: Identifiable>: ViewModifier {

    @Binding var item: Item?
    let url: (Item) -> URL

    func body(content: Content) -> some View {
        content.sheet(item: $item) { value in
            SafariView(url: url(value))
        }
    }
}

// MARK: - Share Sheet
//
// Sanctioned exemption: UIActivityViewController is system chrome; the
// custom `.vaylSheet` overlay can't present it correctly. This wrapper keeps
// that one exception in a single place, so a raw `.sheet` never appears in
// a feature view.

private struct VaylActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {
        // UIActivityViewController is configured at init; nothing to update.
    }
}

private struct VaylShareSheetModifier<Item: Identifiable>: ViewModifier {

    @Binding var item: Item?
    let items: (Item) -> [Any]

    func body(content: Content) -> some View {
        content.sheet(item: $item) { value in
            VaylActivityView(items: items(value))
        }
    }
}

// MARK: - View API — System Chrome Exemptions

extension View {

    /// Presents `item` in a system Safari sheet (`SFSafariViewController`) — for
    /// content that must render a live web page, e.g. the legal documents on
    /// sign-in. See the "Safari Sheet" exemption note above.
    func vaylSafariSheet<Item: Identifiable>(
        item: Binding<Item?>,
        url: @escaping (Item) -> URL
    ) -> some View {
        modifier(VaylSafariSheetModifier(item: item, url: url))
    }

    /// Presents `item` in the system share sheet (`UIActivityViewController`) —
    /// for handing content off to the OS activity picker. See the "Share Sheet"
    /// exemption note above.
    func vaylShareSheet<Item: Identifiable>(
        item: Binding<Item?>,
        items: @escaping (Item) -> [Any]
    ) -> some View {
        modifier(VaylShareSheetModifier(item: item, items: items))
    }
}

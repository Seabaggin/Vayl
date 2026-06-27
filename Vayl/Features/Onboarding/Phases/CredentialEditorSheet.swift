//
//  CredentialEditorSheet.swift
//  Vayl
//

import SwiftUI

/// Edit half-sheet for a single onboarding credential, presented from
/// `OnboardingCanvasWrapper` during the ConfirmationPhase (the canvas itself
/// forbids `.sheet`). Writes straight back to `director.onboardingData`, so the
/// review fan reflects edits live.
///
/// On-brand styling: spectrum-bordered selectable rows (no bland system pickers),
/// spectrum hairlines, a themed name field, and a `VaylButton` CTA.
/// - Context shows ONLY the user's branch (appMode × nmStage), single-select.
/// - Curiosity shows every tag; kept = selected, skipped = greyed; tap toggles.
struct CredentialEditorSheet: View {

    @Bindable var director: VaylDirector
    let credential: OBCredential
    /// Dismiss action — supplied by the custom presenter (CredentialEditorOverlay).
    /// Closure rather than @Environment(\.dismiss) so the sheet renders as an
    /// in-canvas overlay (a window-level native .sheet insets in iOS 26 — this
    /// needs to be full-bleed width, matching FounderLetterSheet).
    var onDone: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            grabHandle
            header
            editorContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            VaylButton(label: "Done") { onDone() }
        }
        .padding(AppSpacing.lg)
        // Native-style chrome: full-bleed width, continuous rounded top corners,
        // spectrum border tracing the rounded top. Shared with FounderLetterSheet.
        .vaylSheetChrome()
    }

    // MARK: - Chrome

    private var grabHandle: some View {
        Capsule()
            .fill(AppColors.spectrumBorder)
            .frame(width: 40, height: 4)
            .opacity(0.6)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.xs)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("EDIT")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
            Text(credential.displayName)
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            SpectrumHairline().padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Editor router

    @ViewBuilder
    private var editorContent: some View {
        switch credential {
        case .snapshot:        snapshotEditor
        case .name:            nameEditor
        case .gender:          genderEditor
        case .mode:            modeEditor
        case .experienceLevel: experienceEditor
        case .context:         contextEditor
        case .curiosity:       curiosityEditor
        }
    }

    // MARK: - Snapshot (sealed — view-only for v1)
    //
    // The baseline snapshot is a sealed gut answer, not a re-editable credential.
    // Segment 4 surfaces the actual "I [verb] [noun]." sentence here; for now this
    // is a sealed placeholder so the editor sheet compiles and reads on-brand.

    private var snapshotEditor: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(AppColors.spectrumBorder)
                Text("Your baseline is sealed.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text("You set this on your first card. It stays as you left it.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.spectrumBorder)
                .opacity(0.06)
        )
    }

    // MARK: - Name

    private var nameEditor: some View {
        TextField("Your name", text: $director.onboardingData.displayName)
            .textFieldStyle(.plain)
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(RoundedRectangle(cornerRadius: AppRadius.md).fill(AppColors.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 1)
                    .opacity(0.30)
            )
    }

    // MARK: - Mode / Experience (selectable rows)

    private var modeEditor: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(AppMode.allCases, id: \.self) { mode in
                selectableRow(mode.displayName, selected: director.onboardingData.appMode == mode) {
                    director.onboardingData.appMode = mode
                }
            }
        }
    }

    private var experienceEditor: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(NMStage.allCases, id: \.self) { stage in
                selectableRow(stage.displayName, selected: director.onboardingData.nmStage == stage) {
                    director.onboardingData.nmStage = stage
                }
            }
        }
    }

    // MARK: - Gender / Pronouns (selectable rows off the canonical lists)

    private var genderEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                optionSection("Gender", options: director.gender.options,
                              current: director.onboardingData.genderA) {
                    director.onboardingData.genderA = $0
                }
                optionSection("Pronouns", options: director.gender.pronounsOptions,
                              current: director.onboardingData.pronounsA) {
                    director.onboardingData.pronounsA = $0
                }

                // Shared opt-out — mirrors the OB decline bar (clears both fields at once).
                selectableRow("Prefer not to say",
                              selected: director.onboardingData.genderA == nil
                                     && director.onboardingData.pronounsA == nil) {
                    director.onboardingData.genderA   = nil
                    director.onboardingData.pronounsA = nil
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }

    private func optionSection(_ title: String, options: [String], current: String?,
                               set: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel(title)
            ForEach(options, id: \.self) { option in
                selectableRow(option, selected: current == option) { set(option) }
            }
        }
    }

    // MARK: - Context (branched, single-select)

    private var contextEditor: some View {
        let options    = ContextOption.options(appMode: director.onboardingData.appMode,
                                                stage:   director.onboardingData.nmStage)
        let currentRaw = director.onboardingData.relationshipContext
        return ScrollView {
            VStack(spacing: AppSpacing.sm) {
                ForEach(options) { option in
                    selectableRow(option.title, subtitle: option.subtitle,
                                  selected: option.context.rawValue == currentRaw) {
                        selectContext(option)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: - Curiosity (all tags; kept = selected, skipped = greyed)

    private var curiosityEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                curiositySection(title: "What's drawing you here",
                                 cards: director.curiosity.buildCuriosityPile(round: 1, onboardingData: director.onboardingData))
                curiositySection(title: "What you're curious to try",
                                 cards: director.curiosity.buildCuriosityPile(round: 2, onboardingData: director.onboardingData))
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }

    private func curiositySection(title: String, cards: [CuriositySortCard]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel(title)
            ForEach(cards) { card in
                curiosityRow(card, selected: director.onboardingData.curiositySelections.contains(card.id))
                    .onTapGesture { toggleCuriosity(card) }
            }
        }
    }

    private func curiosityRow(_ card: CuriositySortCard, selected: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(card.text)
                .font(AppFonts.bodyText)
                .foregroundStyle(selected ? AppColors.textPrimary : AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? AppColors.accentPrimary : AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.spectrumBorder)
                .opacity(selected ? 0.07 : 0)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Shared building blocks

    private func selectableRow(_ title: String, subtitle: String? = nil,
                               selected: Bool, onTap: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(selected ? AppColors.textPrimary : AppColors.textSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: AppSpacing.sm)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? AppColors.accentPrimary : AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.spectrumBorder)
                .opacity(selected ? 0.08 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: selected ? 1.6 : 1)
                .opacity(selected ? 1 : 0.18)
        )
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .onTapGesture(perform: onTap)
    }

    private func sectionLabel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary)
            SpectrumHairline()
        }
    }

    // MARK: - Actions

    private func selectContext(_ option: ContextOption) {
        director.onboardingData.relationshipContext = option.context.rawValue
        director.onboardingData.situationalRegister = option.derivedRegister.rawValue
    }

    private func toggleCuriosity(_ card: CuriositySortCard) {
        if director.onboardingData.curiositySelections.contains(card.id) {
            director.onboardingData.curiositySelections.removeAll { $0 == card.id }
            if card.round == 1 { director.onboardingData.communicationGoals.removeAll { $0 == card.id } }
            else               { director.onboardingData.learningGoals.removeAll { $0 == card.id } }
        } else {
            director.onboardingData.curiositySelections.append(card.id)
            if card.round == 1 { director.onboardingData.communicationGoals.append(card.id) }
            else               { director.onboardingData.learningGoals.append(card.id) }
        }
    }
}

// MARK: - Custom presenter (full-bleed, partial-height bottom sheet)
//
// Replaces the native `.sheet` for the credential editor: iOS 26 native sheets
// render as inset floating cards (side gaps), so a full-width sheet is
// impossible through `.sheet`. This presents the editor as an in-canvas overlay
// that rests at a MEDIUM detent — the review fan stays visible above it (it must
// not obstruct the table/cards). Scrim-tap and a top drag-handle dismiss.
// Hosted by OnboardingCanvasWrapper, outside the canvas boundary.

struct CredentialEditorOverlay: View {
    @Bindable var director: VaylDirector
    let credential: OBCredential

    /// Sheet top as a fraction of screen height — a medium detent that sits over
    /// the content (table + cards stay visible behind/above it, just like the
    /// native .sheet it replaces). The editor occupies the lower ~half.
    private let topInsetFrac: CGFloat = 0.5

    @State private var drag: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.size.height * topInsetFrac
            ZStack(alignment: .bottom) {
                // Whisper scrim — a touch of focus without darkening the lifted
                // fan above. Tap to dismiss.
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)

                CredentialEditorSheet(director: director, credential: credential) { close() }
                    .frame(maxWidth: .infinity)
                    .frame(height: geo.size.height - topInset)
                    .offset(y: max(0, drag))
                    // Dismiss drag lives on the top chrome zone only, so the
                    // editor's own ScrollViews aren't hijacked.
                    .overlay(alignment: .top) {
                        Color.clear
                            .frame(height: 56)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { v in drag = max(0, v.translation.height) }
                                    .onEnded { v in
                                        if v.translation.height > 120 { close() }
                                        else { withAnimation(AppAnimation.spring.reduceMotionSafe) { drag = 0 } }
                                    }
                            )
                    }
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
    }

    private func close() {
        withAnimation(AppAnimation.standard.reduceMotionSafe) {
            director.editingCredential = nil
        }
    }
}


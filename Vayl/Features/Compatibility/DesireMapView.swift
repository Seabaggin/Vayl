import SwiftUI
import SwiftData

// ⚠️ BEFORE BUILDING: add the following to AppIcons before this file compiles:
//   static let chevronDown = "chevron.down"
// AppIcons.chevronUp already exists. AppIcons.chevronDown does not — Rule 8.

struct DesireMapView: View {
    // MARK: - State
    @State private var ratings: [String: DesireLevel] = [:]
    @State private var expandedCategory: String? = nil

    // Placeholder data until Batch 8 persistence
    private let desireCategories: [(name: String, items: [(id: String, name: String, description: String)])] = [
        ("Power Dynamics", [
            ("pd-1", "Dominant Role",   "Taking the lead in intimate scenarios"),
            ("pd-2", "Submissive Role", "Following your partner's guidance"),
            ("pd-3", "Switching",       "Alternating between roles fluidly")
        ]),
        ("Sensation", [
            ("sn-1", "Temperature Play", "Using warmth or coolness as stimulation"),
            ("sn-2", "Light Touch",      "Feather-light, teasing contact"),
            ("sn-3", "Firm Pressure",    "Deeper, grounding physical pressure")
        ]),
        ("Communication", [
            ("cm-1", "Dirty Talk",  "Verbal expression during intimacy"),
            ("cm-2", "Praise",      "Affirming words and compliments"),
            ("cm-3", "Instruction", "Giving or receiving specific guidance")
        ]),
        ("Exploration", [
            ("ex-1", "Role Play",      "Taking on characters or scenarios"),
            ("ex-2", "New Locations",  "Intimacy outside the usual setting"),
            ("ex-3", "Toys & Props",   "Introducing objects into play")
        ])
    ]

    private var ratedCount: Int { ratings.count }
    private var totalCount: Int { desireCategories.flatMap(\.items).count }

    @Environment(\.modelContext) private var modelContext
    // TODO: DataStore should be injected via init, not rebuilt from environment on every access
    private var store: DataStore { DataStore(context: modelContext) }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppSpacing.lg) {            // was 24 → lg, exact
                header
                progressSummary
                categoryList
            }
            .padding(.horizontal, AppSpacing.lg)        // was 20 → lg (24), snap
            .padding(.top, AppSpacing.md)               // was 16 → md, exact
            .padding(.bottom, AppSpacing.xxl)           // was 40 → xxl (48), snap per handoff
        }
        .background(AppColors.pageBackground.ignoresSafeArea())
        .onAppear { loadSavedRatings() }
        .screenshotProtected()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {                // was 6 → sm (8), snap per handoff
            Text("Desire Map")
                .font(AppFonts.screenTitle)
                .foregroundColor(AppColors.textPrimary)

            Text("Rate each item privately. Matches revealed only when both partners finish.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        SettingsCard {
            HStack(spacing: AppSpacing.md) {            // was 16 → md, exact
                ProgressRingView(
                    progress: totalCount > 0 ? Double(ratedCount) / Double(totalCount) : 0,
                    size: 48
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) { // was 4 → xs, exact
                    Text("\(ratedCount) of \(totalCount) rated")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Take your time — there's no rush")
                        .font(AppFonts.meta)
                        .foregroundColor(AppColors.textMuted)
                }

                Spacer()
            }
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(spacing: AppSpacing.md) {                // was 16 → md, exact
            ForEach(desireCategories, id: \.name) { category in
                categorySection(category)
            }
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(
        _ category: (name: String, items: [(id: String, name: String, description: String)])
    ) -> some View {
        let isExpanded    = expandedCategory == category.name
        let categoryRated = category.items.filter { ratings[$0.id] != nil }.count

        VStack(spacing: 0) {
            // Header row — tap to expand/collapse
            Button {
                withAnimation(AppAnimation.fast) {     // was .easeInOut(duration: 0.25) → fast
                    expandedCategory = isExpanded ? nil : category.name
                }
            } label: {
                HStack {
                    Text(category.name.uppercased())
                        .font(AppFonts.sectionLabelSmall)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    GradBadge(text: "\(categoryRated)/\(category.items.count)")

                    Image(isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
                    // was "chevron.up" / "chevron.down"
                    // ⚠️ AppIcons.chevronDown must be added to AppIcons before building
                        .font(
                            Font.custom("Switzer-Semibold", size: 12, relativeTo: .caption)
                        )                               // was .system(size: 12, weight: .semibold)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.horizontal, AppSpacing.md)   // was 16 → md, exact
                .padding(.vertical, AppSpacing.md)     // was 14 → md (16), snap per handoff
            }
            .accessibilityLabel("\(category.name) — \(categoryRated) of \(category.items.count) rated")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")

            if isExpanded {
                SpectrumBar()
                    .padding(.horizontal, AppSpacing.md) // was 16 → md, exact

                VStack(spacing: AppSpacing.sm) {        // was 12 → sm (8), snap per handoff
                    ForEach(category.items, id: \.id) { item in
                        desireItemRow(item)
                    }
                }
                .padding(AppSpacing.md)                 // was 16 → md, exact
            }
        }
        .cardStyle()
    }

    // MARK: - Desire Item Row

    private func desireItemRow(
        _ item: (id: String, name: String, description: String)
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) { // was 10 → sm (8), snap per handoff
            Text(item.name)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)

            Text(item.description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)

            RatingButtonGroup(
                selected: Binding(
                    get: { ratings[item.id] },
                    set: { newValue in
                        ratings[item.id] = newValue
                        if let rating = newValue {
                            let categoryName = desireCategories.first { cat in
                                cat.items.contains { $0.id == item.id }
                            }?.name ?? "Unknown"
                            saveRating(itemId: item.id, category: categoryName, rating: rating)
                        }
                    }
                )
            )
        }
        .padding(AppSpacing.sm)                         // was 12 → sm (8), snap per handoff
        .background(AppColors.modalBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md)) // was 10 → md (12), snap
    }

    // MARK: - Persistence

    /// Loads all previously saved desire map ratings via DataStore.
    private func loadSavedRatings() {
        // TODO: move to a DesireMapStore — data access should not live in a view
        let allItems = desireCategories.flatMap(\.items)
        for item in allItems {
            if let saved = store.fetchRating(forPromptId: item.id),
               let level = DesireLevel(rawValue: saved.reaction) {
                ratings[item.id] = level
            }
        }
    }

    /// Saves or updates a single desire map rating via DataStore.
    private func saveRating(itemId: String, category: String, rating: DesireLevel) {
        // TODO: move to a DesireMapStore
        store.saveDesireRating(itemId: itemId, category: category, level: rating)
    }
}

#Preview {
    DesireMapView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}

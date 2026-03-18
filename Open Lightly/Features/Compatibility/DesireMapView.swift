import SwiftUI
import SwiftData

struct DesireMapView: View {
    // MARK: - State
    @State private var ratings: [String: DesireLevel] = [:]
    @State private var expandedCategory: String? = nil
    
    // Placeholder data until Batch 8 persistence
    private let desireCategories: [(name: String, items: [(id: String, name: String, description: String)])] = [
        ("Power Dynamics", [
            ("pd-1", "Dominant Role", "Taking the lead in intimate scenarios"),
            ("pd-2", "Submissive Role", "Following your partner's guidance"),
            ("pd-3", "Switching", "Alternating between roles fluidly")
        ]),
        ("Sensation", [
            ("sn-1", "Temperature Play", "Using warmth or coolness as stimulation"),
            ("sn-2", "Light Touch", "Feather-light, teasing contact"),
            ("sn-3", "Firm Pressure", "Deeper, grounding physical pressure")
        ]),
        ("Communication", [
            ("cm-1", "Dirty Talk", "Verbal expression during intimacy"),
            ("cm-2", "Praise", "Affirming words and compliments"),
            ("cm-3", "Instruction", "Giving or receiving specific guidance")
        ]),
        ("Exploration", [
            ("ex-1", "Role Play", "Taking on characters or scenarios"),
            ("ex-2", "New Locations", "Intimacy outside the usual setting"),
            ("ex-3", "Toys & Props", "Introducing objects into play")
        ])
    ]
    
    private var ratedCount: Int { ratings.count }
    private var totalCount: Int { desireCategories.flatMap(\.items).count }
    
    @Environment(\.modelContext) private var modelContext
    /// Live DataStore instance built from the environment context.
    private var store: DataStore { DataStore(context: modelContext) }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                header
                progressSummary
                categoryList
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear { loadSavedRatings() }
        .screenshotProtected()
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
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
            HStack(spacing: 16) {
                ProgressRingView(progress: totalCount > 0 ? Double(ratedCount) / Double(totalCount) : 0, size: 48)

                VStack(alignment: .leading, spacing: 4) {
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
        VStack(spacing: 16) {
            ForEach(desireCategories, id: \.name) { category in
                categorySection(category)
            }
        }
    }
    
    // MARK: - Category Section
    @ViewBuilder
    private func categorySection(_ category: (name: String, items: [(id: String, name: String, description: String)])) -> some View {
        let isExpanded = expandedCategory == category.name
        let categoryRated = category.items.filter { ratings[$0.id] != nil }.count
        
        VStack(spacing: 0) {
            // Header row (tap to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedCategory = isExpanded ? nil : category.name
                }
            } label: {
                HStack {
                    Text(category.name.uppercased())
                        .font(AppFonts.sectionHeader)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    GradBadge(text: "\(categoryRated)/\(category.items.count)")
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            if isExpanded {
                SpectrumBar()
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    ForEach(category.items, id: \.id) { item in
                        desireItemRow(item)
                    }
                }
                .padding(16)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Desire Item Row
    private func desireItemRow(_ item: (id: String, name: String, description: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
                            // Find which category this item belongs to
                            let categoryName = desireCategories.first { cat in
                                cat.items.contains { $0.id == item.id }
                            }?.name ?? "Unknown"
                            saveRating(itemId: item.id, category: categoryName, rating: rating)
                        }
                    }
                )
            )
        }
        .padding(12)
        .background(AppColors.surfaceBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    /// Loads all previously saved desire map ratings via DataStore.
    private func loadSavedRatings() {
        let allItems = desireCategories.flatMap(\.items)
        for item in allItems {
            if let saved = store.fetchRating(forPromptId: item.id),
               let level = Int(saved.reaction).flatMap({ DesireLevel(rawValue: $0) }) {
                ratings[item.id] = level
            }
        }
    }

    /// Saves or updates a single desire map rating via DataStore.
    private func saveRating(itemId: String, category: String, rating: DesireLevel) {
        store.saveDesireRating(itemId: itemId, category: category, level: rating)
    }
}

#Preview {
    DesireMapView()
        .preferredColorScheme(.dark)
        .modelContainer(ModelContainer.previewContainer)
}

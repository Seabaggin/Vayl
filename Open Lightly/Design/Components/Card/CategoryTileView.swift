// ✅ Design system audit — verified March 9, 2026
import SwiftUI

// MARK: - CategoryTileView
// Home screen category grid tile
struct CategoryTileView: View {
    let emoji: String
    let title: String
    let completedCards: Int
    let totalCards: Int
    
    @Environment(\.theme) private var t
    
    var progress: Double {
        Double(completedCards) / Double(max(totalCards, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Emoji icon
            Text(emoji)
                .font(.system(size: 28))
                .padding(.bottom, 8)
            Spacer()
            // Category name
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(t.text)
                .padding(.bottom, 2)
            // Card count
            Text("\(completedCards) / \(totalCards) cards")
                .font(.system(size: 11))
                .foregroundStyle(t.textMuted)
                .padding(.bottom, 8)
            // Progress bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(t.surface3)
                    .frame(height: 3)
                Capsule()
                    .fill(t.buttonGradient)
                    .frame(width: max(1, progress * 64), height: 3)
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(width: 80, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(t.surface1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(t.isAmoled ? Color.white.opacity(0.04) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: t.isAmoled ? .clear : Color.black.opacity(0.06), radius: 12, y: 4)
        .aspectRatio(1/1.2, contentMode: .fit)
    }
}

// MARK: - Preview
struct CategoryTileView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTiles = [
            ("💬", "Communication", 4, 12),
            ("🛡️", "Boundaries", 8, 12),
            ("❤️", "Intimacy", 2, 12),
            ("🗓️", "Planning", 12, 12)
        ]
        ZStack {
            Color.black.ignoresSafeArea()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(sampleTiles, id: \ .1) { tile in
                    CategoryTileView(
                        emoji: tile.0,
                        title: tile.1,
                        completedCards: tile.2,
                        totalCards: tile.3
                    )
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

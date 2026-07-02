//
//  SessionBuilderView.swift
//  Vayl
//
//  Shape tonight's session (spec §4.4). Hosted as a .vaylSheet inside the
//  pre-session flow (PlayView presents it; PlayStore consumes onConfirm and
//  converts with plan.draft at the openSession call site). Discrete task you
//  return from — never a cover. All output is a SessionPlan.
//
//  Seam signature preserved from Section 2:
//  SessionBuilderView(deck:onConfirm:onCancel:) with onConfirm: (SessionPlan) -> Void.
//

import SwiftUI

struct SessionBuilderView: View {

    let deck: Deck
    /// The finished plan goes up; the host (PlayStore) calls openSession with
    /// it and moves to the lobby.
    let onConfirm: (SessionPlan) -> Void
    let onCancel: () -> Void
    /// The couple's composition, threaded from the host (seam ruling 6).
    /// Defaults .flexible when unknown — never blocks on a missing Couple.
    var composition: GenderDynamic = .flexible
    /// Resume point (DeckProgress.currentCardIndex), threaded from the host.
    var startIndex: Int = 0

    @State private var store: SessionBuilderStore?

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            if let store {
                if store.cardCount == 0 {
                    emptyState
                } else {
                    content(store)
                }
            }
        }
        .task {
            guard store == nil else { return }
            // Composition filter + resume index come from the host (PlayStore),
            // defaulted .flexible / 0 when unknown (seam ruling 6 — never block).
            store = SessionBuilderStore(
                deckId: deck.id,
                cards: deck.cards(for: composition),
                startIndex: startIndex
            )
        }
    }

    private func content(_ store: SessionBuilderStore) -> some View {
        VStack(spacing: 0) {
            header(store)
            fastPathRow(store)
            cardList(store)
            footer(store)
        }
    }

    // MARK: - Header

    private func header(_ store: SessionBuilderStore) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Shape tonight")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text("\(store.cardCount) cards, played in this order")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Fast paths

    private func fastPathRow(_ store: SessionBuilderStore) -> some View {
        HStack(spacing: AppSpacing.sm) {
            fastPathChip("Quick start") {
                onConfirm(store.quickStartPlan())
            }
            if let last = store.lastPlan {
                fastPathChip("Same as last time") {
                    onConfirm(last)
                }
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    private func fastPathChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule().stroke(AppColors.spectrumBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card list (reorder + trim + timer)

    private func cardList(_ store: SessionBuilderStore) -> some View {
        List {
            ForEach(Array(store.entries.enumerated()), id: \.element.id) { pair in
                row(store, index: pair.offset, entry: pair.element)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onMove { store.move(from: $0, to: $1) }

            if !store.trimmed.isEmpty {
                trimmedSection(store)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))   // always reorderable
    }

    private func row(_ store: SessionBuilderStore, index: Int, entry: SessionBuilderStore.Entry) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text("\(index + 1)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: AppSpacing.lg)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if entry.isCeremonial {
                    Text(entry.isClosingRitual ? "CLOSING · STAYS" : "RITUAL")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.spectrumText)
                }
                Text(entry.text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.sm)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.cycleTimer(for: entry.cardId)
            } label: {
                Text(timerLabel(entry.timerSeconds))
                    .font(AppFonts.caption)
                    .foregroundStyle(entry.timerSeconds == nil
                                     ? AppColors.textTertiary : AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Capsule().stroke(AppColors.borderDefault, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if entry.isClosingRitual {
                Image(systemName: "lock")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .accessibilityLabel("The closing ritual stays in the session")
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.trim(entry.cardId)
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(store.canTrim(entry.cardId)
                                         ? AppColors.textSecondary : AppColors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!store.canTrim(entry.cardId))
                .accessibilityLabel("Remove card \(index + 1)")
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }

    private func trimmedSection(_ store: SessionBuilderStore) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Set aside tonight")
                .font(AppFonts.overline)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textTertiary)
            ForEach(store.trimmed) { entry in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.restore(entry.cardId)
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AppColors.textTertiary)
                        Text(entry.text)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }

    private func timerLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "no timer" }
        return "\(seconds / 60)m"
    }

    // MARK: - Footer (global timer + start)

    private func footer(_ store: SessionBuilderStore) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("Whole-session budget")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                globalTimerChip(store)
            }
            .padding(.horizontal, AppSpacing.md)

            VaylButton(label: "Start with \(store.cardCount) cards") {
                onConfirm(store.start())
            }
            .padding(.horizontal, AppSpacing.md)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCancel()
            } label: {
                Text("Not tonight")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.plain)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.top, AppSpacing.sm)
    }

    /// 🎚️ Global budget ladder (minutes). nil = no budget (the default).
    private static let globalOptions: [Int?] = [nil, 15 * 60, 30 * 60, 45 * 60]

    private func globalTimerChip(_ store: SessionBuilderStore) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let options = Self.globalOptions
            let idx = options.firstIndex(where: { $0 == store.globalTimerSeconds }) ?? 0
            store.globalTimerSeconds = options[(idx + 1) % options.count]
        } label: {
            Text(store.globalTimerSeconds.map { "\($0 / 60) min" } ?? "none")
                .font(AppFonts.caption)
                .foregroundStyle(store.globalTimerSeconds == nil
                                 ? AppColors.textTertiary : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Capsule().stroke(AppColors.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(AppFonts.displayHero)
                .foregroundStyle(AppColors.textTertiary)
            Text("Nothing to shape")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("This deck has no cards for tonight. Try another deck.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCancel()
            } label: {
                Text("Back to decks")
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.spectrumText)
                    .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.xl)
    }
}

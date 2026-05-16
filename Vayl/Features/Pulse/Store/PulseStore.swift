//
//  PulseStore.swift
//  Vayl
//

import Foundation
import Observation

@Observable
final class PulseStore {

    // MARK: - State

    private(set) var entries: [PulseEntry] = []

    // MARK: - Private

    private let key = "pulse.entries.v1"

    // MARK: - Init

    init() {
        load()
        #if DEBUG
        if entries.isEmpty {
            PulseEntry.previews.forEach { add($0) }
        }
        #endif
    }

    // MARK: - Public

    func add(_ entry: PulseEntry) {
        let cal = Calendar.current
        entries.removeAll { cal.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    // MARK: - Private

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else {
            assertionFailure("PulseStore: encode failed")
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode([PulseEntry].self, from: data)
        else { return }
        entries = saved
    }
}

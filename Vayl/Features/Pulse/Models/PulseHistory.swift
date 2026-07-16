// Vayl/Core/Models/PulseHistory.swift
//
// Pure derivation functions over PulseEntry arrays. No state, no UI.
//
// "Last 30 logged" means the 30 most-recent check-ins by date — never calendar
// days. A daily logger and an occasional logger both see exactly their last 30
// entries, never empty cells, never streak-style gaps.

import Foundation

enum PulseHistory {

    // MARK: - Me (single)

    /// Last N logged entries, oldest first. Never padded — a 5-entry user yields 5.
    static func lastLogged(_ entries: [PulseEntry], count: Int = 30) -> [PulseEntry] {
        Array(entries.suffix(count))
    }

    /// Last N logged entries as (date, space) — the six-space classification per check-in,
    /// for the Me history grid. Oldest first, never padded.
    static func lastLoggedSpaces(_ entries: [PulseEntry], count: Int = 30) -> [(date: Date, space: PulseSpace)] {
        lastLogged(entries, count: count).map { (date: $0.date, space: $0.space) }
    }

    // MARK: - Us (paired)

    /// For each of YOUR last-N check-ins (oldest first), the partner's space at that time —
    /// carried forward from their most-recent entry on or before yours. Partner half is nil
    /// before the partner's first-ever entry.
    ///
    /// This is intentionally a CARRY-FORWARD, not a calendar-day join:
    ///   - Partner checked in 5 days ago, you checked in today → partner half = that space.
    ///   - Partner has never checked in → every partner half is nil.
    ///
    /// NOTE: this is the carry-forward-per-your-entry model, not the spec's §7 36hr timezone
    /// window — that change needs a schema migration and is deferred.
    static func pairedLastLoggedSpaces(
        mine: [PulseEntry],
        partner: [PulseEntry],
        count: Int = 30
    ) -> [(date: Date, mine: PulseSpace, partner: PulseSpace?)] {
        let myLast = lastLogged(mine, count: count)
        let sortedPartner = partner.sorted { $0.date < $1.date }

        return myLast.map { myEntry in
            let partnerEntry = sortedPartner.last { $0.date <= myEntry.date }
            return (
                date: myEntry.date,
                mine: myEntry.space,
                partner: partnerEntry?.space
            )
        }
    }
}

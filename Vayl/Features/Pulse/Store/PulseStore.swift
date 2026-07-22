//
//  PulseStore.swift
//  Vayl
//

import Foundation
import Observation

// MARK: - Sync seam (test injection)
//
// Minimal additive seam: PulseStore already took an injected `sync` instance,
// but PulseSyncService is a concrete struct with no fake-able surface. This
// protocol mirrors only the two methods PulseStore actually calls (not
// fetchPartnerEntries, which PulseStore never touches). Signature synced to
// PulseSyncService's tri-state fetch (PulseFetchOutcome: fetch-failure vs.
// confirmed-empty).
protocol PulseSyncing {
    func pushEntry(_ entry: PulseEntry) async
    func fetchOwnEntries() async -> PulseFetchOutcome
}

extension PulseSyncService: PulseSyncing {}

@Observable
@MainActor
final class PulseStore {

    // MARK: - State

    private(set) var entries: [PulseEntry] = []

    /// True only when a hydrate fetch failed WHILE the local cache was empty: a
    /// reinstall/new device whose history restore couldn't reach the server. Views
    /// use it to swap the first-run empty-state copy ("start your first check-in")
    /// for honest "couldn't reach your history" copy, so an unreachable history never
    /// masquerades as a blank slate. Cleared by any successful hydrate; never set
    /// when local entries exist (a failed refresh over real data isn't first-run).
    private(set) var lastHydrateFailed: Bool = false

    /// True once a hydrate has SUCCEEDED this launch — the missing half of
    /// `lastHydrateFailed`. The store knew when a restore had failed but not when one had
    /// finished, so `entries.isEmpty` alone could not tell "you have no history" apart from
    /// "I don't know yet." Any UI that makes a CLAIM about the user's history must wait for
    /// this; UI that merely renders history does not (it re-renders when data lands).
    private(set) var hasHydrated: Bool = false

    // MARK: - First-run framing gate

    /// Whether to show the one-time "Your First Pulse" doorway ahead of the check-in.
    ///
    /// Derived from the DATA, not from a stored flag: if a person has pulse entries they have
    /// obviously met Pulse already, so the entries ARE the record. That is what makes this
    /// correct across the cases a device flag gets wrong —
    ///   • reinstall / new device — history returns on hydrate, so no "Your First Pulse" for
    ///     a veteran (the `hasHydrated` term is what closes the race where entries are still
    ///     empty because the fetch hasn't landed).
    ///   • sign out, new account, same device — entries are wiped and per-account, so the
    ///     next person is correctly a first-timer.
    ///   • linking a NEW partner who has never used the app — they are a different person on
    ///     their own install; nothing here is couple state. Knowing what Pulse is belongs to
    ///     a person, not a pairing, which is also why unlinking must NOT reset it.
    ///
    /// `hasSeenPulseFraming` only ever SUPPRESSES. It cannot trigger the framing, so a lost or
    /// stale key can at worst show someone a nice intro twice.
    ///
    /// Failure direction is deliberate: offline on a genuine first run means no proof, so the
    /// framing is skipped and earned on a later launch (nothing marks it seen but "Begin").
    /// Skipping an intro is far cheaper than telling a veteran it is their first time.
    var shouldShowFraming: Bool {
        hasHydrated && entries.isEmpty && !hasSeenPulseFraming
    }

    var hasSeenPulseFraming: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.hasSeenPulseFraming)
    }

    /// Called when the user taps "Begin" — NOT when they finish a check-in. If they bail on
    /// question three they have still read the doorway; re-showing it would be nagging.
    /// "Maybe later" deliberately does not call this: they declined checking in, not learning.
    func markFramingSeen() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasSeenPulseFraming)
    }

    /// Today's entry, if any — the single source of truth for "have I checked in
    /// today" (was duplicated as a local `Calendar.current.isDateInToday` filter in
    /// both HomePulseRail and MapPulseHero).
    var todayEntry: PulseEntry? {
        entries.last(where: { Calendar.current.isDateInToday($0.date) })
    }

    /// The current circumplex position: the latest entry regardless of age, or
    /// dead-center if there isn't one yet. Distinct from `todayEntry` on purpose —
    /// Map shows "your last known position" even when it's a few days stale (see
    /// MapPulseHero's isStale handling for the softened copy that goes with it).
    var currentPosition: PulsePosition {
        entries.last?.resolvedPosition ?? PulsePosition(energy: 0.5, openness: 0.5)
    }

    /// Whether the check-in CTA should be offered right now — true when there's no
    /// entry yet today, or today's entry is still inside its edit window. False once
    /// today's entry has locked: a completed check-in is a sealed snapshot, not
    /// something to keep revising hours later. Single source of truth for Home,
    /// Map-Me, and Map-Us's "Check in" / "Edit check-in" pill.
    var canCheckInToday: Bool {
        todayEntry?.isEditable ?? true
    }

    /// True when `currentPosition` reflects a stale prior entry, not today's. Map's
    /// Me and Us lenses deliberately keep showing your last KNOWN position instead
    /// of going blank (unlike Home, which switches to its dormant state when there's
    /// no today entry) — but need to say so honestly rather than presenting a
    /// days-old reading with today's confidence. Single source of truth: was
    /// duplicated as MapPulseHero's own private `isStale`.
    var isPositionStale: Bool {
        todayEntry == nil && !entries.isEmpty
    }

    /// True once the last entry has gone quiet — the SAME `UsOrbState.quietAfterDays`
    /// (4-day) threshold the Us orb's ember state uses. This governs visual dimming
    /// (opacity), while `isPositionStale` only softens copy. Without this split, a
    /// 1-day-old reading rendered vividly in the Us orb (still "current") looked
    /// dead/dimmed in the Me aura (already "stale" at not-today) — same data, two
    /// thresholds, a visible mismatch between the two lenses on the same tab.
    var isPositionQuiet: Bool {
        guard let last = entries.last?.date else { return false }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? .max
        return days >= UsOrbState.quietAfterDays
    }

    /// Human copy for how stale a date is ("yesterday", "4 days ago"). Was
    /// MapPulseHero's own private `relativeDay` — promoted here so MapUsLayer can
    /// use the same phrasing for the partner's staleness, not just mine.
    func relativeDay(for date: Date) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: date),
            to: cal.startOfDay(for: Date())
        ).day ?? 0
        if days <= 1 { return "yesterday" }
        return "\(days) days ago"
    }

    /// "Brighter than yesterday" / "A bit quieter today" / "About the same as
    /// yesterday" — nil if either day is missing an entry. Was MapPulseHero's own
    /// private `weatherLine`; HomePulseRail needs the identical comparison (its own
    /// doc comment tracked this as the deferred "D1.5" item, now built).
    var weatherLine: String? {
        guard
            let today = entries.last(where: { Calendar.current.isDateInToday($0.date) }),
            let yesterday = entries.last(where: { Calendar.current.isDateInYesterday($0.date) })
        else { return nil }

        let delta = today.resolvedPosition.energy - yesterday.resolvedPosition.energy
        if abs(delta) < 0.05 { return "About the same as yesterday" }
        return delta > 0 ? "Brighter than yesterday" : "A bit quieter today"
    }

    // MARK: - Private

    private let key = "pulse.entries.v1"

    private let sync: PulseSyncing

    // MARK: - Init

    /// `sync` nil-resolves inside the MainActor-isolated body (a `= .shared`
    /// default argument would evaluate nonisolated — same pattern as SettingsStore).
    init(sync: PulseSyncing? = nil) {
        self.sync = sync ?? PulseSyncService.shared
        load()
        #if DEBUG
        // Xcode PREVIEWS only, never a debug device/simulator run: add() pushes to
        // the real backend via pushEntry, so an unguarded seed was shipping 13 fake
        // entries straight into prod for any signed-in debug session.
        if entries.isEmpty,
           ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            PulseEntry.previews.forEach { add($0) }
        }
        #endif
    }

    // MARK: - Public

    func add(_ entry: PulseEntry) {
        let cal = Calendar.current
        var entry = entry
        // Carry the ORIGINAL createdAt forward across a same-day re-edit — a fresh
        // `Date()` here would reset the edit-window clock on every redo, letting
        // someone extend how long today stays editable indefinitely.
        if let existing = entries.first(where: { cal.isDate($0.date, inSameDayAs: entry.date) }) {
            entry.createdAt = existing.resolvedCreatedAt
        } else if entry.createdAt == nil {
            entry.createdAt = entry.date
        }
        // Stamp the last-write time on EVERY save (unlike createdAt, which is
        // carried forward): this is what the newest-wins hydrate merge compares.
        entry.updatedAt = Date()
        entries.removeAll { cal.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        save()
        // Push the full entry to Supabase (fire-and-forget; local save above is already
        // the source of truth for this session). `pulse_entries` RLS gates partner
        // visibility on the existing share_pulse_with_partner consent flag.
        Task { await sync.pushEntry(entry) }
    }

    /// Pulls the caller's full history down from `pulse_entries` and merges it into the
    /// local cache — the reinstall/new-device recovery path (a fresh install has an empty
    /// local cache but a populated server history). NEWEST WINS per calendar day: when
    /// both sides have a row for the same day, the one with the later resolvedUpdatedAt
    /// survives (a same-day re-edit on this device must not be clobbered by the stale
    /// server copy its push raced against, and vice versa). Any local entry for a day the
    /// server doesn't have yet (e.g. logged offline, not synced) is left alone rather
    /// than dropped; both cases are pushed back up in the bounded reconciliation pass
    /// below. Called at cold launch and again on every return to foreground (VaylApp's
    /// scenePhase handler), after auth is confirmed ready.
    func hydrateFromServer() async {
        guard case .success(let serverEntries) = await sync.fetchOwnEntries() else {
            // Only a reinstall whose restore failed counts (see lastHydrateFailed's
            // doc): a failed refresh over existing local data isn't a first-run lie.
            if entries.isEmpty { lastHydrateFailed = true }
            return
        }
        lastHydrateFailed = false
        // Set BEFORE the merge: the fetch succeeded, so the question "does this person have
        // history" is now answerable either way. See shouldShowFraming.
        hasHydrated = true

        let cal = Calendar.current
        var merged = entries
        // Days where the LOCAL copy beat the server row on resolvedUpdatedAt: the
        // server copy is stale for these, so the push-back pass below re-uploads them.
        var localWonDays: Set<Date> = []
        for serverEntry in serverEntries {
            if let local = merged.first(where: { cal.isDate($0.date, inSameDayAs: serverEntry.date) }),
               local.resolvedUpdatedAt > serverEntry.resolvedUpdatedAt {
                localWonDays.insert(cal.startOfDay(for: local.date))
                continue
            }
            merged.removeAll { cal.isDate($0.date, inSameDayAs: serverEntry.date) }
            merged.append(serverEntry)
        }
        merged.sort { $0.date < $1.date }
        entries = merged
        save()

        // Push back any RECENT local day the server lacks OR where the local copy won
        // the merge above — a check-in made offline (or whose push silently failed)
        // would otherwise never reach the server, since add()'s push is fire-and-forget
        // and only fires once, at creation. Bounded to the last 7 days on purpose, for
        // two reasons: (1) a connectivity-caused sync gap should surface well within a
        // week of normal app use, so there's no real recovery value in reaching further
        // back; and (2) reaching further back risks re-pushing a genuinely old,
        // pre-unlink entry after a user re-pairs with a NEW partner — pushEntry stamps
        // couple_id from the CURRENT profile at push time, so an unbounded reach-back
        // could silently attach an old, prior-relationship entry to a new partner's
        // couple_id. A 7-day cap keeps this a narrow connectivity fix, not a
        // history-resurrection path. 🎚️ the exact window is tunable.
        let cutoff = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let serverDays = Set(serverEntries.map { cal.startOfDay(for: $0.date) })
        let unsynced = entries.filter {
            let day = cal.startOfDay(for: $0.date)
            return $0.date >= cutoff && (!serverDays.contains(day) || localWonDays.contains(day))
        }
        for entry in unsynced {
            await sync.pushEntry(entry)
        }
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

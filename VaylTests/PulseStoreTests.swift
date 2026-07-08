//
//  PulseStoreTests.swift
//  VaylTests
//
//  PulseStore against a fake PulseSyncing seam (added alongside this suite —
//  see PulseStore.swift's "Sync seam" section). Covers construction, check-in
//  submission (add()'s same-day replace + createdAt-carry-forward), and
//  hydrateFromServer()'s merge — NOT PulseAnswers' quadrant math, which
//  PulseAnswersTests / PulsePositionTests already cover.
//
//  NOTE: PulseSyncing mirrors only the two methods PulseStore calls
//  (pushEntry, fetchOwnEntries), using the tri-state PulseFetchOutcome
//  (fetch-failure vs. confirmed-empty) that landed 2026-07-08.
//
//  DEBUG seeding caveat: PulseStore's init seeds PulseEntry.previews (13
//  entries, days 13..1 ago — never today) when the local cache is empty, and
//  tests build in DEBUG. So these tests never assert absolute entry counts,
//  only relative/day-scoped facts that hold with or without the seed.
//
//  Isolation: PulseStore reads/writes the real `UserDefaults.standard` under
//  a fixed key (no injectable defaults suite), so setUp/tearDown clear that
//  key directly rather than adding a bigger seam for this pass.
//

import XCTest
@testable import Vayl

@MainActor
private final class FakePulseSyncing: PulseSyncing {
    private(set) var pushedEntries: [PulseEntry] = []
    /// nil = simulate a fetch failure (.failure); non-nil = .success(these rows).
    var serverEntries: [PulseEntry]?

    func pushEntry(_ entry: PulseEntry) async {
        pushedEntries.append(entry)
    }

    func fetchOwnEntries() async -> PulseFetchOutcome {
        guard let serverEntries else { return .failure }
        return .success(serverEntries)
    }
}

@MainActor
final class PulseStoreTests: XCTestCase {

    // Isolated-deinit workaround (same gotcha as the DM/Airlock suites): retain
    // every @Observable @MainActor store + its fake for the process lifetime.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private func makeStore(sync: FakePulseSyncing) -> PulseStore {
        let store = PulseStore(sync: sync)
        Self.retain(store, sync)
        return store
    }

    private static let key = "pulse.entries.v1"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Self.key)
        super.tearDown()
    }

    /// `add()` pushes fire-and-forget via an un-awaited `Task`, so a push lands
    /// asynchronously relative to the synchronous call that triggered it. Poll
    /// briefly rather than asserting an exact count right after `add()`.
    private func waitUntil(
        _ message: String,
        timeout: TimeInterval = 2,
        _ condition: () -> Bool
    ) async {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting: \(message)")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func makeEntry(
        day: Date,
        nervousSystem: String = "Balanced",
        focus: String = "Reaching Out",
        feeling: String = "Content",
        createdAt: Date? = nil
    ) -> PulseEntry {
        PulseEntry(
            date: day,
            capacityScore: 2,
            glowColor: .indigo,
            speed: "Steady",
            nervousSystem: nervousSystem,
            focus: focus,
            feeling: feeling,
            createdAt: createdAt
        )
    }

    // MARK: Construction

    func test_init_withEmptyServerAndNoLocalCache_startsEmptyOutsideDebugSeeding() {
        // DEBUG builds seed PulseEntry.previews when entries.isEmpty (see init).
        // That's an intentional dev convenience, not app behavior to assert on;
        // this test only confirms construction doesn't crash and produces a
        // valid dead-center resting position when there's truly nothing.
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        XCTAssertNotNil(store.currentPosition)
        XCTAssertEqual(store.canCheckInToday, true)
    }

    // MARK: add() — same-day replace + createdAt carry-forward

    func test_add_firstCheckInToday_becomesTodayEntry() async {
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let entry = makeEntry(day: Date())

        store.add(entry)

        XCTAssertEqual(store.todayEntry?.id, entry.id)
        await waitUntil("add() pushes the new entry to sync") {
            fake.pushedEntries.contains { $0.id == entry.id }
        }
    }

    func test_add_secondCheckInSameDay_replacesRatherThanAccumulates() {
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let today = Date()

        store.add(makeEntry(day: today, feeling: "Content"))
        store.add(makeEntry(day: today, feeling: "Defensive"))

        XCTAssertEqual(store.todayEntry?.feeling, "Defensive", "the redo replaces, not appends")
    }

    func test_add_sameDayRedo_carriesOriginalCreatedAtForward() {
        // Guards the edit-window contract: a redo must not reset the clock that
        // decides when today's check-in locks (isEditable).
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let today = Date()
        let originalCreated = today.addingTimeInterval(-3600)

        store.add(makeEntry(day: today, createdAt: originalCreated))
        store.add(makeEntry(day: today, feeling: "Defensive", createdAt: today))

        XCTAssertEqual(
            store.todayEntry?.resolvedCreatedAt.timeIntervalSince1970 ?? -1,
            originalCreated.timeIntervalSince1970,
            accuracy: 0.001,
            "the FIRST completion time must survive a same-day redo"
        )
    }

    func test_add_keepsEntriesSortedByDate() {
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let today = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        store.add(makeEntry(day: today))
        store.add(makeEntry(day: twoDaysAgo))
        store.add(makeEntry(day: yesterday))

        let dates = store.entries.map(\.date)
        XCTAssertEqual(dates, dates.sorted(), "entries must stay date-ascending after out-of-order adds")
    }

    // MARK: hydrateFromServer() — merge, server wins per day

    func test_hydrateFromServer_onFetchFailure_leavesLocalEntriesUntouched() async {
        let fake = FakePulseSyncing()
        fake.serverEntries = nil   // .failure
        let store = makeStore(sync: fake)
        store.add(makeEntry(day: Date()))
        let before = store.entries.count

        await store.hydrateFromServer()

        XCTAssertEqual(store.entries.count, before, "a failed fetch means keep local, never treat as empty")
        XCTAssertNotNil(store.todayEntry, "today's local check-in must survive a failed hydrate")
    }

    func test_hydrateFromServer_serverEntryForSameDay_winsOverLocal() async {
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let today = Date()
        store.add(makeEntry(day: today, feeling: "Content"))

        fake.serverEntries = [makeEntry(day: today, feeling: "Defensive", createdAt: today)]
        await store.hydrateFromServer()

        XCTAssertEqual(store.todayEntry?.feeling, "Defensive", "server's same-day row replaces the local one")
    }

    func test_hydrateFromServer_addsServerDaysMissingLocally() async {
        let fake = FakePulseSyncing()
        let store = makeStore(sync: fake)
        let today = Date()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -10, to: today)!
        store.add(makeEntry(day: today))

        let serverEntry = makeEntry(day: lastWeek, createdAt: lastWeek)
        fake.serverEntries = [serverEntry]
        await store.hydrateFromServer()

        XCTAssertTrue(
            store.entries.contains { $0.id == serverEntry.id },
            "a server day missing locally is merged in"
        )
        XCTAssertNotNil(store.todayEntry, "today's local entry survives the merge (server didn't have it)")
    }
}

import Foundation

/// Pure win-condition for the two-device lock-in. `you` and `partner` are each
/// partner's release point as a fraction of the ring arc (0…1). They're "in sync"
/// when the two release points land within `tolerance` of each other.
enum SyncMatch {
    static func isSynced(you: Double, partner: Double, tolerance: Double) -> Bool {
        abs(you - partner) <= tolerance
    }
}

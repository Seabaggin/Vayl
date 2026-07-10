// supabase/functions/compute-desire-matches/match-logic.ts
//
// Pure match-computation logic for the Desire Map, extracted from index.ts so it can be
// unit-tested in isolation (see match-logic.test.ts). index.ts imports these and adds only
// the I/O (auth, DB reads/writes). Keep this file free of Deno / Supabase imports — pure
// functions only, so the tests need no network or service role.
//
// The invariants encoded here are the privacy + conversion contract:
//   • notForMe is NEVER surfaced — items where either partner said notForMe are dropped.
//   • Only items BOTH partners rated can match.
//   • Output carries ONLY the alignment signal (mutual / adjacent) — never a raw answer.
//   • Exactly one match is the free reveal (prefer a mutual, else the first match).

export type Alignment = "mutual" | "adjacent"

/// Positive-match rule on the shared weight.
/// mutual = both Excited; adjacent = one Excited + one Open, or both Open. Weaker → no match.
export function matchType(a: string, b: string): Alignment | null {
  const positive = (v: string) => v === "excitedAboutIt" || v === "openToIt"
  if (a === "excitedAboutIt" && b === "excitedAboutIt") return "mutual"
  if (positive(a) && positive(b)) return "adjacent" // (E+O) or (O+O); (E+E) already returned
  return null
}

export interface MatchRow {
  desire_item_id: string
  alignment_level: Alignment
}

/// Compute positive matches over the items BOTH partners rated, EXCLUDING any item where
/// either said notForMe (the boundary — obscured, never surfaced). Deterministic: sorted by id.
export function computeMatches(
  byA: Record<string, string>,
  byB: Record<string, string>,
): MatchRow[] {
  const rows: MatchRow[] = []
  for (const itemId of Object.keys(byA).sort()) {
    const a = byA[itemId]
    const b = byB[itemId]
    if (b === undefined) continue // only items BOTH rated
    if (a === "notForMe" || b === "notForMe") continue // boundary → obscured, never surfaced
    const mt = matchType(a, b)
    if (!mt) continue
    rows.push({ desire_item_id: itemId, alignment_level: mt })
  }
  return rows
}

/// Index of the single free reveal. PINNING RULE (review 2026-07-09): once a couple has a
/// free reveal, recomputes keep it on the SAME item as long as that item still matches —
/// otherwise a re-rate would move the hero star the couple already saw (and let a free
/// couple enumerate the map by flipping answers). Only when the pinned item no longer
/// qualifies does selection fall back to: first mutual, else the first match.
/// Returns -1 for an empty set (nothing to flag).
export function freeRevealIndex(
  rows: { alignment_level: string; desire_item_id?: string }[],
  pinnedItemId?: string | null,
): number {
  if (rows.length === 0) return -1
  if (pinnedItemId) {
    const pinned = rows.findIndex((r) => r.desire_item_id === pinnedItemId)
    if (pinned >= 0) return pinned
  }
  return Math.max(0, rows.findIndex((r) => r.alignment_level === "mutual"))
}

/// Locked-stub category per item (review 2026-07-09, server-enforced paywall).
/// The value stored on a match row and shown for LOCKED stubs pre-purchase. Categories
/// with fewer than 3 items on the V1 (curious) track are collapsed to null — the viewer
/// rated every item and knows the list, so a 1-item category ("sexual", "health") would
/// identify the item and reopen the enumeration hole the paywall closes.
/// Source of truth mirrors Vayl/Resources/Content/desire_items.json — regenerate on
/// content changes (see docs/handoffs/2026-07-09-desire-map-pretestflight-review.md).
export const STUB_CATEGORIES: Record<string, string | null> = {
  opening: "structures",
  recalibrating: null,          // established-only (not on the V1 track)
  swinging: "structures",
  trips_apart: "structures",
  polyamory: "structures",
  hierarchy: "structures",
  emotional_connections: "emotional",
  nre: "emotional",
  partner_falling_in_love: "emotional",
  jealousy: "emotional",
  group_sexual: null,           // sole "sexual" item — category would identify it
  intimate_details: "communication",
  safer_sex: null,              // sole "health" item — category would identify it
  overnight_stays: "logistics",
  time_attention: "logistics",
  finances: "logistics",
  reconnection: "emotional",
  metamours: "communication",
  social_disclosure: "communication",
}

export function stubCategory(itemId: string): string | null {
  return STUB_CATEGORIES[itemId] ?? null
}

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

/// Index of the single free reveal: prefer the first mutual, else the first match.
/// Returns -1 for an empty set (nothing to flag).
export function freeRevealIndex(rows: { alignment_level: string }[]): number {
  if (rows.length === 0) return -1
  return Math.max(0, rows.findIndex((r) => r.alignment_level === "mutual"))
}

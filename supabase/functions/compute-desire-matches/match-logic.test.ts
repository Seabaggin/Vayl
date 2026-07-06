// supabase/functions/compute-desire-matches/match-logic.test.ts
//
// Unit tests for the Desire Map match logic — the privacy + conversion contract.
// Run:  deno test supabase/functions/compute-desire-matches/match-logic.test.ts
//
// These cover the backend rules that have no UI to catch a regression:
//   • the positive-match rule (mutual / adjacent / none),
//   • notForMe is never surfaced,
//   • only items both partners rated can match,
//   • output is alignment-only (no raw answer leaks),
//   • exactly one free reveal, preferring a mutual.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts"
import {
  computeMatches,
  freeRevealIndex,
  matchType,
} from "./match-logic.ts"

// ── matchType: the positive-match rule ───────────────────────────────

Deno.test("matchType — both excited is mutual", () => {
  assertEquals(matchType("excitedAboutIt", "excitedAboutIt"), "mutual")
})

Deno.test("matchType — excited + open is adjacent (either order)", () => {
  assertEquals(matchType("excitedAboutIt", "openToIt"), "adjacent")
  assertEquals(matchType("openToIt", "excitedAboutIt"), "adjacent")
})

Deno.test("matchType — both open is adjacent", () => {
  assertEquals(matchType("openToIt", "openToIt"), "adjacent")
})

Deno.test("matchType — anything with probablyNot is no match", () => {
  assertEquals(matchType("excitedAboutIt", "probablyNot"), null)
  assertEquals(matchType("probablyNot", "openToIt"), null)
  assertEquals(matchType("probablyNot", "probablyNot"), null)
})

Deno.test("matchType — anything with notForMe is no match", () => {
  assertEquals(matchType("excitedAboutIt", "notForMe"), null)
  assertEquals(matchType("notForMe", "openToIt"), null)
  assertEquals(matchType("notForMe", "notForMe"), null)
})

// ── computeMatches: aggregation + privacy ────────────────────────────

Deno.test("computeMatches — keeps only positive overlap, sorted by item id", () => {
  const byA = { item_c: "excitedAboutIt", item_a: "openToIt", item_b: "probablyNot" }
  const byB = { item_c: "excitedAboutIt", item_a: "openToIt", item_b: "excitedAboutIt" }
  const rows = computeMatches(byA, byB)
  assertEquals(rows, [
    { desire_item_id: "item_a", alignment_level: "adjacent" }, // O + O
    { desire_item_id: "item_c", alignment_level: "mutual" },   // E + E
    // item_b dropped: A said probablyNot
  ])
})

Deno.test("computeMatches — notForMe is never surfaced, even when the partner is excited", () => {
  const byA = { secret: "notForMe", shared: "excitedAboutIt" }
  const byB = { secret: "excitedAboutIt", shared: "excitedAboutIt" }
  const rows = computeMatches(byA, byB)
  assertEquals(rows.map((r) => r.desire_item_id), ["shared"])
  assert(!rows.some((r) => r.desire_item_id === "secret"), "notForMe item must not leak")
})

Deno.test("computeMatches — an item only one partner rated cannot match", () => {
  const byA = { solo: "excitedAboutIt", both: "excitedAboutIt" }
  const byB = { both: "excitedAboutIt" } // never rated `solo`
  const rows = computeMatches(byA, byB)
  assertEquals(rows.map((r) => r.desire_item_id), ["both"])
})

Deno.test("computeMatches — output carries ONLY id + alignment, no raw answer", () => {
  const byA = { x: "excitedAboutIt" }
  const byB = { x: "openToIt" }
  const rows = computeMatches(byA, byB)
  assertEquals(rows.length, 1)
  assertEquals(Object.keys(rows[0]).sort(), ["alignment_level", "desire_item_id"])
})

Deno.test("computeMatches — no overlap yields no matches", () => {
  assertEquals(computeMatches({ a: "excitedAboutIt" }, { b: "excitedAboutIt" }), [])
  assertEquals(computeMatches({}, {}), [])
})

// ── freeRevealIndex: exactly one, prefer mutual ──────────────────────

Deno.test("freeRevealIndex — prefers the first mutual over an earlier adjacent", () => {
  const rows = [
    { alignment_level: "adjacent" },
    { alignment_level: "mutual" },
    { alignment_level: "mutual" },
  ]
  assertEquals(freeRevealIndex(rows), 1)
})

Deno.test("freeRevealIndex — falls back to the first row when there is no mutual", () => {
  const rows = [{ alignment_level: "adjacent" }, { alignment_level: "adjacent" }]
  assertEquals(freeRevealIndex(rows), 0)
})

Deno.test("freeRevealIndex — empty set flags nothing", () => {
  assertEquals(freeRevealIndex([]), -1)
})

Deno.test("freeRevealIndex — selects exactly one across a realistic set", () => {
  const rows = computeMatches(
    { a: "openToIt", b: "excitedAboutIt", c: "openToIt" },
    { a: "openToIt", b: "excitedAboutIt", c: "excitedAboutIt" },
  )
  const idx = freeRevealIndex(rows)
  const flagged = rows.map((_, i) => i === idx)
  assertEquals(flagged.filter(Boolean).length, 1, "exactly one free reveal")
  assertEquals(rows[idx].alignment_level, "mutual", "the free reveal is the mutual (item b)")
})

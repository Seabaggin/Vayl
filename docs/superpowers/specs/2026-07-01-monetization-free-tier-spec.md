# Vayl Monetization — Free Tier & Core Spec
**Status: Confirmed · 2026-07-01**

This is the canonical reference for what is free, what is gated, and what is outside the monetization frame entirely. Supersedes all earlier free-tier notes in docs and memory.

---

## The model

| | |
|---|---|
| **Free** | Permanent. No time limit, no nag. |
| **Core** | $24.99 · couple lifetime. One person buys, both unlock. Server-authoritative (`couples.access_tier`). |
| **SKUs at launch** | Two: Free + Core. Multi-partner and Pro subscription are post-launch. |

---

## Free tier — what you get

### Decks
- `the-opener` — the foundational couple deck
- `the-check-in` — the recurring couple ritual deck
- `the-night-of` — the tool/event deck (first event prep, fun + practical)
- 1 solo deck per person (gender-resolved at pairing; e.g. `solo-man` / `solo-woman` / `solo-tbd`)

The free deck set is designed to feel complete, not thin. A free couple can play real sessions with real content before the paywall enters the picture.

### Desire Map
- Full input (rate everything)
- 1 match revealed — the `is_free_reveal` star (the server-set emotional-peak match)
- The rest are visible but locked; the full reveal is the primary conversion moment

### The Pathway (couple journey map)
- The Swinging pathway is free — the full 13-landmark journey at no cost
- Other pathway styles (polyamory, solo poly, etc.) are Core
- Same mechanic as the DM reveal: one free taste that shows the full value of the feature

### Everything else that is free
- Pulse — fully free, no insight tier or gating whatsoever
- Agreements — free safety primitive; paywalling a couple's rules or safe word is wrong for this product
- Journaling — free

---

## Core — what you unlock

- Full Desire Map reveal (all matches, consent openings on every match)
- All remaining decks (couple decks 4+, additional solo decks, additional tool decks)
- All Pathway styles beyond swinging
- Event Log

---

## Outside the monetization frame

These are not features. Do not describe them in paywall copy, free-tier lists, or upgrade CTAs. They exist at the product layer, not the content layer.

- **Lock In** — the two-device session container. It is how sessions work, not something you upgrade into.
- **Safe word** — a product primitive inside Lock In. Same category. Never gated, never marketed.

If these ever appear in a "what you get free" list or an upgrade sheet, that is a copy error.

---

## Conversion moments (ordered by priority)

1. **Desire Map full reveal** — 1 free match in, rest locked. The strongest moment in the product: personal, earned, shared. $24.99 at peak intent.
2. **Locked deck in Play** — browsing the catalog, tapping a locked deck, seeing the preview. The deck wall is the storefront.
3. **Pathway styles** — a free couple who has walked their swinging path and wants the polyamory one hits the gate naturally.
4. **Settings upgrade banner** — passive, quiet. Not a nag.

---

## Catalog decisions still open

- Exact deck IDs for the free solo deck per gender — confirm when catalog is finalized
- Confirm `the-night-of` is the correct ID for the tool/event deck in `deck-catalog.json`
- `solo-prep` is currently `is_locked: true` in the catalog but PaywallSheet copy implies solo decks are free — reconcile before M3 ships

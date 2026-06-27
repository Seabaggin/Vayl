# Discussion Card ("Talk about this") — Implementation Plan

**Date:** 2026-06-26
**Scope:** a sub-implementation of the Desire Map. The plumbing is built; this turns the placeholder discussion card into a real "what's next after the map" bridge.
**Sits on:** the main DM plan (`docs/superpowers/specs/2026-06-26-desire-map-ui-implementation-plan.md`) and the Vault consent spec (`docs/superpowers/specs/2026-06-24-vault-design.md` §4). Read both first.
**Gate:** §2 (the MARK) resolved 2026-06-27. §3 is now executable.

---

## 1. What already exists — the plumbing (reuse, do not rebuild)

Two entry points both want to land on "a discussion card for a desire":
- **"Talk about this"** on a revealed **mutual** match (no consent needed; both already want it). Button exists, action is a stub.
- **Consent "open"** on a **disagreed/private** desire (the asker requested, the partner opened). The consent mechanic is fully built and privacy-correct; the card it points to is a placeholder.

Built today (verified):
- **`CompanionCard`** (`Core/Models/CompanionCard.swift`) — the data shape: `id, desireItemId, title, prompt, suggestedDeckId?`. The intended card = **a conversation prompt + a deck to open together.**
- **`CompanionCardStore`** (`Features/Desire Map/Store/CompanionCardStore.swift`) — **STUB**: returns one generic placeholder per match (`title: "Talk about it together"`, a generic prompt, `suggestedDeckId: nil`). `suggestedDeckId(for:)` returns `nil`.
- **`DesireMatch.bridgeCardId`** (`Core/Models/DesireMatch.swift:37`) — `String?`, always `nil`. The server selects `bridge_card_id` (`DesireSyncService.swift:160`) but nothing populates it.
- **Consent flow** — `consent-ask` / `consent-respond` edge functions. On open, `consent-respond` stamps `discussion_card_id: "neutral"` (a hardcoded placeholder, `supabase/functions/consent-respond/index.ts:68`). **The decline-never-discloses guarantee is real and correct — do not touch it.** `VaultStore.openedConsent` carries `discussionCardId`; `VaultDesireSection` renders opened rows.
- **`onTalkTapped`** (`DesireMatchDetail.swift:17`, `DesireStarDetailSheet.swift:44`) — `nil` stub; the button renders and does nothing.
- **`ConversationCard` / `ConversationCardTypes`** (`Design/Components/Cards/`) — the existing, canonical conversation-card render system used by sessions/decks. **The card view should reuse this, not fork it** (read it before §3.2).
- The **session/deck** system (Play tab) — what `suggestedDeckId` resolves into.

---

## 2. ⚑ THE MARK — HOW WE IMPLEMENT THE CARD (RESOLVED 2026-06-27)

**Q1 — What is the card?**
**(c) Prompt + optional deck.** A `ConversationCard`-rendered prompt is always present. A "Open the deck" CTA renders only when `suggestedDeckId != nil`. V1 is prompt-only in practice (`suggestedDeckId: nil` everywhere); adding a deck later automatically activates the CTA without touching the card view.

**Q2 — Presentation.**
The discussion card's **permanent home is the Vault** (`VaultDesireSection`), presented as a `.vaylSheet`. The reveal's `DesireStarDetailSheet` gets a **low-hierarchy wayfinder** (ghost button or text link, not a primary CTA) — tapping it dismisses the reveal cover and routes to the Map tab's Vault with the relevant match surfaced. The reveal does not host the card; it points there. The card view is a thin `DiscussionCardView` wrapping `ConversationCard`.

**Q3 — One card or two paths.**
**One card per desire item, one resolver.** Both entry points ("Talk about this" on a mutual/adjacent match, and the consent-opened row in the Vault) route through `CompanionCardStore`. The card is neutral by construction — it never references who asked or who wanted it. Neutrality is enforced at the prompt content level (tier sets tone, not asker/responder identity).

**Q4 — Content granularity.**
**Per-tier prompts.** Three tiers; a small pool of prompts per tier. The desire item name is the context (displayed above the card); the prompt opens the conversation and works for any item at that tier. No per-item or per-category authoring needed.

| Tier | Signal | Prompt register |
|---|---|---|
| `mutual` | `matchType: .mutual` | celebratory, "you both want this" |
| `adjacent` | `matchType: .adjacent` | curious, "you're both drawn here" |
| `consent_opened` | consent-opened path | careful, low-pressure, "what would this feel like" |

`companion_cards.json` shape: `{ tier, prompts: [{ id, text }] }`. `CompanionCardStore` selects a prompt from the matching tier pool using `desireItemId` as a stable seed (same couple sees the same prompt for a given match).

**Q5 — Deck mapping.**
**Deferred post-launch.** `suggestedDeckId: nil` for V1. No deck CTA renders. Wiring a deck to a desire later is a content config change only.

**Q6 — V1 vs parked.**
**Ships with the Vault build** (not gated on the reveal launch). The reveal's wayfinder is included when the reveal ships; the card content + Vault wiring land when the Vault Desire segment is built. The consent ask still works at launch; the opened-consent card content is the Vault segment's deliverable.

---

## 3. Segments (buildable once §2 lands)

Each is "done" when it compiles AND matches the resolved §2 AND Bryan confirms on device.

- **D1 — Content pipeline.** Author `Resources/Content/companion_cards.json` as `{ tier: "mutual"|"adjacent"|"consent_opened", prompts: [{ id, text }] }`. Add `ContentLoader.loadCompanionCards()` (mirror `loadDesireItems()`). Replace `CompanionCardStore`'s placeholder with real load + tier lookup: mutual matches use `mutual` pool, adjacent matches use `adjacent` pool, consent-opened path uses `consent_opened` pool. Use `desireItemId` as a stable seed to select a prompt within the pool (same couple, same prompt for a given match). *Done:* `CompanionCardStore.card(for:path:)` returns real, tier-appropriate content.
- **D2 — The card view.** A thin `DiscussionCardView` wrapping `ConversationCard`: desire item name as context above, tier prompt as the card body, no deck CTA (V1). Hosted as a `.vaylSheet` from `VaultDesireSection`. *Done:* a real card renders for a desire item in the Vault.
- **D3 — Wire the two entry points.** (a) `onTalkTapped` in the reveal's `DesireStarDetailSheet` → low-hierarchy wayfinder (ghost button/text link) that dismisses the cover and routes to the Map tab's Vault with the match surfaced. (b) The opened-consent row in `VaultDesireSection` → presents `DiscussionCardView` as a `.vaylSheet`. Both route through `CompanionCardStore`, same card, no duplication. *Done:* both paths surface the correct card; consent-opened path reveals nothing about who asked.
- **D4 — Real ids (server).** The card is resolved client-side from `desireItemId` + tier, so `bridge_card_id` / `discussion_card_id` server ids are not needed. `consent-respond`'s `discussion_card_id: "neutral"` placeholder can stay as-is; the client ignores it and resolves the card locally. **This segment is skipped.**

---

## 4. Constraints + gotchas

- **Neutrality is law for the consent-opened path.** The card content must be identical regardless of who asked or who declined-then-opened — it can never say "you asked," "they wanted this," etc. Decline-never-discloses extends to the card. (Easiest guarantee: one card per *item*, no asker/answer state in it.)
- **Do NOT touch the consent privacy mechanic** (`consent-respond` / `consent-ask` / `consent_declines`). It is correct.
- **Reuse `ConversationCard` + the session/deck system**; do not fork a second card renderer.
- **Tier:** consent openings ride on Desire Map access (a free couple gets their one free match's conversation; more requires Core). Gate via `EntitlementStore.isCore`, do not invent a new SKU.
- 4-layer (View → `CompanionCardStore` → `ContentLoader`/services → `CompanionCard`); tokens only; `.vaylSheet`/`.vaylCover`; empty/fallback state on the card; no em dashes in copy.
- The reveal's wayfinder ships with the reveal (low-hierarchy, points to Vault). The card content + Vault wiring are the Vault Desire segment's deliverable.

---

## 5. Segment checklist

- **D0** ✅ §2 resolved 2026-06-27.
- **D1** `companion_cards.json` (3-tier pool) + `ContentLoader.loadCompanionCards()` + real `CompanionCardStore` tier lookup.
- **D2** `DiscussionCardView` wrapping `ConversationCard`, `.vaylSheet` from Vault.
- **D3** Reveal wayfinder (low-hierarchy, dismiss + route to Vault) + Vault opened-consent row → same card via `CompanionCardStore`.
- **D4** ~~Server ids~~ — skipped; card resolves client-side from `desireItemId` + tier.

---

## 6. References

- Built plumbing: `Core/Models/CompanionCard.swift`, `Features/Desire Map/Store/CompanionCardStore.swift`, `Core/Models/DesireMatch.swift`, `Core/Services/ConsentService.swift`, `supabase/functions/consent-respond/`, `Features/Map/Vault/VaultStore.swift`, `Features/Map/Vault/Components/VaultDesireSection.swift`, `Features/Desire Map/Views/Components/DesireMatchDetail.swift`.
- Reuse for the card view: `Design/Components/Cards/ConversationCard.swift`, `ConversationCardTypes.swift`, the session/deck system (Play).
- Decisions of record: `docs/superpowers/specs/2026-06-24-vault-design.md` §4 (consent), `docs/superpowers/specs/2026-06-26-desire-map-ui-implementation-plan.md` (the main DM plan; "Explore in Learn" is parked, §7b).

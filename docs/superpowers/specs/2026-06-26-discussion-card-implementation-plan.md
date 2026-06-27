# Discussion Card ("Talk about this") — Implementation Plan

**Date:** 2026-06-26
**Scope:** a sub-implementation of the Desire Map. The plumbing is built; this turns the placeholder discussion card into a real "what's next after the map" bridge.
**Sits on:** the main DM plan (`docs/superpowers/specs/2026-06-26-desire-map-ui-implementation-plan.md`) and the Vault consent spec (`docs/superpowers/specs/2026-06-24-vault-design.md` §4). Read both first.
**Gate:** §2 (the MARK) is an OPEN design decision. **Do not build §3 until §2 is resolved.**

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

## 2. ⚑ THE MARK — HOW WE IMPLEMENT THE CARD (OPEN — decide before building)

> This is the one genuinely-open decision. Everything in §3 is blocked on it. Fill in the DECISION lines, then build.

The card's *shape* is half-decided by the `CompanionCard` model (a prompt + a suggested deck). What's undecided is what it actually **is, contains, and opens.** Resolve these:

**Q1 — What is the card?**
- (a) A single **conversation prompt** (one question to discuss), lightweight, opens as a small card/sheet.
- (b) A link into a **topic deck** (a curated set of session cards for that desire, played two-device like a session).
- (c) **Both** — a prompt that sits on top of / opens into a suggested deck.
- *Lean:* (c), since the model already carries `prompt` + `suggestedDeckId`, and it degrades gracefully (prompt always present, deck optional).
- **DECISION: ________**

**Q2 — Presentation.** A `.vaylSheet` off the match detail? A push? A route into the Play/session tab (open the deck there)? A new lightweight `DiscussionCardView`, or reuse `ConversationCard`?
- **DECISION: ________**

**Q3 — Mutual vs consent-opened: one card or two paths?** A mutual match has no privacy concern; a consent-opened desire **must stay neutral** (the card cannot reference who asked or who wanted it — decline-never-discloses extends to the card content). Cleanest is **one card per desire item, neutral by construction**, reached from both paths.
- **DECISION: ________**

**Q4 — Content granularity.** Per-desire-**item** (19 items), per-**category**, or a generic fallback? This sets the `companion_cards.json` shape and the authoring load.
- *Lean:* per-category prompts + a generic fallback, with per-item override where it earns it (keeps authoring small).
- **DECISION: ________**

**Q5 — Deck mapping.** Does `suggestedDeckId` point at an existing Play deck (which?), or is "the deck for this desire" net-new content? If decks don't exist yet, ship the prompt-only card and leave `suggestedDeckId: nil` (graceful).
- **DECISION: ________**

**Q6 — V1 vs parked.** Like "Explore in Learn," this can be parked. If parked: hide "Talk about this" + the opened-consent card content at launch (the consent *ask* still works), and ship §3 post-V1.
- **DECISION: ________**

*(When these are answered, delete the "OPEN" framing and the plan below becomes executable.)*

---

## 3. Segments (buildable once §2 lands)

Each is "done" when it compiles AND matches the resolved §2 AND Bryan confirms on device.

- **D1 — Content pipeline.** Author `Resources/Content/companion_cards.json` at the §2-Q4 granularity (prompt + optional `suggestedDeckId`). Add a `ContentLoader.loadCompanionCards()` (mirror `loadDesireItems()`). Replace `CompanionCardStore`'s placeholder with a real load + lookup by `desireItemId`/category, and a generic fallback. *Done:* `CompanionCardStore.companions(for:)` returns real, non-placeholder content.
- **D2 — The card view.** Per §2-Q1/Q2: reuse `ConversationCard` (or a thin `DiscussionCardView`) to render the companion (prompt + optional "Open the deck" CTA → the session/deck system). Host per the resolved presentation (likely a `.vaylSheet`). Neutral copy only. *Done:* a real card renders for a desire item.
- **D3 — Wire the two entry points.** (a) `onTalkTapped` on the mutual-match detail → present the card for that item. (b) The opened-consent row in `VaultDesireSection` → present the **same** card (one card per item, neutral). Route both through one resolver (`CompanionCardStore`), no duplication. *Done:* both paths open the same card; the consent-opened path reveals nothing about who asked.
- **D4 — Real ids (server).** Populate `bridge_card_id` on matches (in the `compute-desire-matches` edge fn) and a real `discussion_card_id` on open (in `consent-respond`, replacing `"neutral"`), if §2 decided per-item ids. If the card is resolved client-side from `desireItemId`, this segment is optional — the client already has the item id. *Done:* ids are real, or this segment is consciously skipped.

---

## 4. Constraints + gotchas

- **Neutrality is law for the consent-opened path.** The card content must be identical regardless of who asked or who declined-then-opened — it can never say "you asked," "they wanted this," etc. Decline-never-discloses extends to the card. (Easiest guarantee: one card per *item*, no asker/answer state in it.)
- **Do NOT touch the consent privacy mechanic** (`consent-respond` / `consent-ask` / `consent_declines`). It is correct.
- **Reuse `ConversationCard` + the session/deck system**; do not fork a second card renderer.
- **Tier:** consent openings ride on Desire Map access (a free couple gets their one free match's conversation; more requires Core). Gate via `EntitlementStore.isCore`, do not invent a new SKU.
- 4-layer (View → `CompanionCardStore` → `ContentLoader`/services → `CompanionCard`); tokens only; `.vaylSheet`/`.vaylCover`; empty/fallback state on the card; no em dashes in copy.
- If §2-Q6 parks it: hide `Talk about this` and the opened-consent card content at launch; leave the seam.

---

## 5. Segment checklist

- **D0** Resolve §2 (the MARK). *Gate for everything below.*
- **D1** `companion_cards.json` + `ContentLoader.loadCompanionCards()` + real `CompanionCardStore` load.
- **D2** The card view (reuse `ConversationCard`), neutral copy, prompt (+ optional deck CTA).
- **D3** Wire `onTalkTapped` (mutual) + the opened-consent row (Vault) to one resolver → the same card.
- **D4** (Optional) real `bridge_card_id` / `discussion_card_id` server-side.

---

## 6. References

- Built plumbing: `Core/Models/CompanionCard.swift`, `Features/Desire Map/Store/CompanionCardStore.swift`, `Core/Models/DesireMatch.swift`, `Core/Services/ConsentService.swift`, `supabase/functions/consent-respond/`, `Features/Map/Vault/VaultStore.swift`, `Features/Map/Vault/Components/VaultDesireSection.swift`, `Features/Desire Map/Views/Components/DesireMatchDetail.swift`.
- Reuse for the card view: `Design/Components/Cards/ConversationCard.swift`, `ConversationCardTypes.swift`, the session/deck system (Play).
- Decisions of record: `docs/superpowers/specs/2026-06-24-vault-design.md` §4 (consent), `docs/superpowers/specs/2026-06-26-desire-map-ui-implementation-plan.md` (the main DM plan; "Explore in Learn" is parked, §7b).

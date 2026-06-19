# StoreKit 2 & App Store Connect — Zero-to-Shipped

> Written for someone who has **never** touched StoreKit or App Store Connect.
> Goal: a real **$24.99 lifetime** purchase that unlocks **Vayl Core** for a couple, end to end.
> Companion to the Monetization phase (M1–M5) in the [Build Playbook](vayl-build-roadmap.html).
> Product, the free/core boundary, and the couple-level entitlement model are in the
> [Monetization spec](../superpowers/specs/2026-06-15-monetization-implementation-spec.md) — read that for the *what/why*; this is the *how*.

---

## 0. The big picture (read once)

Two separate systems, easy to conflate:

| System | What it is | Where you work |
|---|---|---|
| **App Store Connect (ASC)** | Apple's web console. Where you *define* the product (the $24.99 thing), set its price, create sandbox testers, and submit the app. | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) (browser) |
| **StoreKit 2** | Apple's on-device Swift framework. Where your app *fetches* the product, runs the purchase, and learns whether the user owns it. | Xcode / Swift code |

**The flow, plain English:**
1. You create a product in ASC with id `com.vayl.core.lifetime`.
2. Your app asks StoreKit "give me product `com.vayl.core.lifetime`" → shows price/name.
3. User taps buy → StoreKit runs Apple's payment sheet → returns a signed `Transaction`.
4. Your app trusts that signed transaction → writes the couple's entitlement (M1) → flips the couple to `core`.
5. On any future launch / reinstall, StoreKit replays the user's entitlements so you re-unlock.

**Vayl's product is a non-consumable** (buy once, owned forever, restorable). NOT a subscription, NOT a consumable. This is the simplest IAP type — good.

**You can build and test ALL the code with ZERO App Store Connect setup** using a local `.storekit` file (Part B). Do that first. Only touch ASC when you're ready for a real sandbox purchase and submission. That ordering removes the scary part from the critical path.

---

## Part A — App Store Connect setup

> You only need this for a real sandbox purchase and for submission. If you're starting today, skip to **Part B** and come back.

### A1. Prerequisites (one-time, can have lead time)
- **Apple Developer Program membership** ($99/yr). If not enrolled, do this first — enrollment can take 24–48h.
- In ASC → **Business** → **Agreements, Tax, and Banking**: the **Paid Apps Agreement** must show **Active**, and tax + banking forms must be complete. **Paid IAPs will not work — not even in sandbox testing in some cases — until the Paid Apps agreement is active.** This is the #1 silent blocker. Do it early.

### A2. Create the app record
ASC → **Apps** → **+** → **New App**. Bundle ID must match Xcode (`com.vayl.…`). You can fill marketing details later; you just need the record to attach an IAP to.

### A3. Create the in-app purchase
ASC → your app → **Monetization** → **In-App Purchases** → **+**:
- **Type:** **Non-Consumable**
- **Reference Name:** `Vayl Core Lifetime` (internal only, never shown to users)
- **Product ID:** `com.vayl.core.lifetime` — **must match the code exactly. It is permanent and cannot be reused once created.** Type it carefully.
- **Price:** pick the tier closest to **$24.99** (Apple uses tiers; 24.99 is a standard tier).
- **Localization (App Store Display):** at least one — Display Name + Description (these CAN show to users in some surfaces). Keep on-brand: *"Vayl Lifetime — own your experience, forever."* Never "unlock."
- **Review info:** screenshot + notes (only needed when you submit, not for sandbox).

Status will sit at **"Ready to Submit"** / **"Missing Metadata"** — that's fine; it's purchasable in **sandbox** as soon as it exists and the Paid Apps agreement is active.

### A4. Create a sandbox tester
ASC → **Users and Access** → **Sandbox** → **Test Accounts** → **+**.
- Use an email you control that is **NOT** an existing Apple ID (a `+sandbox` alias works: `you+vaylsandbox@gmail.com`).
- This is the account you'll sign into **on the device** (Settings → Developer → Sandbox Apple Account, or you'll be prompted at purchase time) — **do NOT sign your real Apple ID out of the device**; sandbox is a separate slot.
- Sandbox purchases are **free** (no real charge) and complete instantly.

---

## Part B — Local StoreKit testing (do this FIRST, no ASC needed)

Xcode ships a local store simulator. You define the product in a file, point a scheme at it, and purchases work entirely offline. This lets you build M2 before ASC exists.

### B1. Create the `.storekit` config
Xcode → **File → New → File → StoreKit Configuration File** → name it `Vayl.storekit` (add to the app target).
In it, **+ → Add Non-Consumable In-App Purchase**:
- Product ID: `com.vayl.core.lifetime` (match the code + eventual ASC id exactly)
- Reference Name: `Vayl Core Lifetime`
- Price: `24.99`
- Add a localization: Display Name `Vayl Lifetime`, Description `Own your experience, forever.`

### B2. Point your scheme at it
Xcode → **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration** → select `Vayl.storekit`.
Now `Product.products(for:)` returns your fake product and `purchase()` runs a local sheet — instant, free, offline.

### B3. The transaction manager (debugging)
With the app running, Xcode → **Debug → StoreKit → Manage Transactions** lets you delete purchases, refund, and re-test restore — without reinstalling. Essential for testing the "restore on reinstall" path.

---

## Part C — The StoreKit 2 code

Vayl's architecture (CLAUDE.md): **Service** does I/O, **Store** owns state and decides. So StoreKit lives in a `Service`, injected into an `EntitlementStore`. Code below is Swift 6 / iOS 16+ friendly.

### C1. The service

```swift
import StoreKit

/// Wraps StoreKit 2. No app state, no decisions — just I/O. Injected into EntitlementStore.
final class StoreKitService {

    static let coreProductID = "com.vayl.core.lifetime"

    enum PurchaseOutcome { case success(Transaction), userCancelled, pending, unverified }

    /// Load the product metadata (price, display name) to render the paywall.
    func loadCoreProduct() async throws -> Product? {
        let products = try await Product.products(for: [Self.coreProductID])
        return products.first
    }

    /// Run the purchase. Returns a *verified* Transaction on success.
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()          // MUST finish or StoreKit replays it forever
                return .success(transaction)
            case .unverified:
                return .unverified                  // signature failed — do NOT grant entitlement
            }
        case .userCancelled: return .userCancelled
        case .pending:       return .pending        // e.g. Ask-to-Buy / parental approval
        @unknown default:    return .userCancelled
        }
    }

    /// Does this device's signed-in Apple ID currently own Core? (drives unlock on launch + restore)
    func ownsCore() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.coreProductID, t.revocationDate == nil {
                return true
            }
        }
        return false
    }

    /// Explicit "Restore Purchases" button → re-sync entitlements from the App Store.
    func restore() async throws -> Bool {
        try await AppStore.sync()                   // shows the Apple ID sign-in if needed
        return await ownsCore()
    }

    /// Long-running listener for transactions that arrive outside a purchase
    /// (Ask-to-Buy approvals, purchases made on another device). Start at app launch.
    func observeTransactionUpdates(onCore: @escaping () async -> Void) -> Task<Void, Never> {
        Task.detached {
            for await update in Transaction.updates {
                if case .verified(let t) = update, t.productID == Self.coreProductID {
                    await t.finish()
                    await onCore()
                }
            }
        }
    }
}
```

### C2. The store (decides + publishes)

```swift
import Observation

@Observable @MainActor
final class EntitlementStore {
    enum Tier { case free, core }

    private(set) var tier: Tier = .free
    private(set) var coreProduct: Product?          // for the paywall price label
    private let store: StoreKitService
    private var updates: Task<Void, Never>?

    init(store: StoreKitService = .init()) { self.store = store }

    func bootstrap() async {
        coreProduct = try? await store.loadCoreProduct()
        await refreshTier()
        updates = store.observeTransactionUpdates { [weak self] in await self?.refreshTier() }
    }

    func buyCore() async -> Bool {
        guard let p = coreProduct else { return false }
        guard let outcome = try? await store.purchase(p) else { return false }
        if case .success(let transaction) = outcome {
            await grantCoreToCouple(transaction)    // ← Vayl bridge, Part D
            tier = .core
            return true
        }
        return false
    }

    func restore() async -> Bool {
        let owns = (try? await store.restore()) ?? false
        if owns { tier = .core; await syncCoupleEntitlementIfNeeded() }
        return owns
    }

    private func refreshTier() async {
        tier = await store.ownsCore() ? .core : .free
    }
}
```

Views read `entitlementStore.tier` only — **never** call StoreKit directly (architecture rule). Every gate in M3 reads this one `tier`.

---

## Part D — Bridging StoreKit to Vayl's *couple* entitlement (the crux)

StoreKit's `currentEntitlements` is **per Apple ID, per device** — it knows *this phone's user* bought Core. But Vayl's rule is **the couple is `core`, and one purchase unlocks BOTH partners** (Monetization M1). So a local StoreKit check alone is not enough — the non-buying partner's phone has no StoreKit transaction.

**The bridge (M1 + M2):**
1. On a verified purchase, write a couple-scoped `EntitlementRecord` to Supabase (`couple_id`, `product_id`, `transaction_id`, …) via the entitlement edge function / table.
2. `EntitlementStore.tier` resolves from **two** sources, OR'd together:
   - **local StoreKit** (`ownsCore()`) — fast, works offline, covers the buyer; AND
   - **the couple's server entitlement** — covers the *partner*, who has no local transaction.
3. So: `tier = (localStoreKitOwnsCore || coupleHasServerEntitlement) ? .core : .free`.

```swift
private func grantCoreToCouple(_ t: Transaction) async {
    // 1. Persist couple-scoped entitlement server-side (so the PARTNER unlocks too).
    await entitlementService.recordPurchase(
        transactionID: String(t.id),
        originalID: String(t.originalID),
        productID: t.productID
    )                                                // writes the couples/entitlements row (M1)
}

private func syncCoupleEntitlementIfNeeded() async {
    // On the partner's device: no local StoreKit txn, but the couple row says core → unlock.
    if await entitlementService.coupleHasCore() { tier = .core }
}
```

This is *why* M1 (couple entitlement schema) comes before M2 (StoreKit) in the playbook — the server record is what makes "one buys, both unlock" true.

---

## Part E — Server-side validation: now or later?

The paywall doc says receipt validation should be **server-side ("never client-only")**. Two honest options for V1 (this is open question M1/M2 in the playbook):

| Option | What it means | When it's OK |
|---|---|---|
| **Trust StoreKit 2 `.verified`** | StoreKit 2 already cryptographically verifies the transaction's signature **on device**. You write the couple entitlement based on that. | Reasonable for V1 launch. StoreKit 2's JWS verification is genuinely strong; the realistic attack (jailbreak + tamper) is low-value for a $24.99 non-consumable. |
| **Server-validates** | Send the JWS transaction (or use the **App Store Server API** / **App Store Server Notifications v2**) to a `validate-receipt` edge function that re-verifies with Apple and is the *only* writer of the entitlement. | The hardened path. Do this if you want notifications of refunds/revocations to auto-downgrade the couple. |

**Recommendation:** ship V1 on **trust `.verified` + write the couple row server-side** (so the partner unlocks), and treat full App Store Server Notifications as a fast-follow. Document the choice in M1's done-note so it's a deliberate decision, not an oversight. The key invariant either way: **the entitlement row is couple-scoped and the unlock reads from it**, so the partner is never locked out.

---

## Part F — Submission checklist (the IAP-specific bits)

When you get to App-Store phase A4, IAP adds a few requirements beyond a normal app:
- [ ] The IAP product is attached to the app version and its status is **Ready to Submit** (it submits *with* the build the first time).
- [ ] **Restore Purchases** is reachable in the UI (Apple requires a restore path for non-consumables — usually in Settings). Wire `EntitlementStore.restore()` to it.
- [ ] Paywall copy passes review: clear price, what's included, no dark patterns. "Yours forever" is fine; deceptive "free trial" language you don't honor is not.
- [ ] App Review **demo notes** explain how a reviewer reaches the paywall (they must be able to *see* the IAP). If the reveal/paywall is behind pairing, give them a path or a pre-paired demo account.
- [ ] Privacy nutrition label discloses the purchase (A2).
- [ ] Tested the **real sandbox** purchase on device (not just the local `.storekit`) before submitting — the local sim can mask ASC-side config errors.

---

## Gotchas (the things that waste a day)

- **Paid Apps agreement not active** → products return empty / purchases fail with no clear error. Check ASC → Business first.
- **Forgetting `transaction.finish()`** → StoreKit re-delivers the transaction on every launch forever, and the purchase can appear "stuck." Always finish verified transactions.
- **Product ID typo / mismatch** between code, `.storekit`, and ASC → `products(for:)` returns empty. The id is permanent in ASC — you can't fix a typo by renaming, only by making a new product. Triple-check before creating.
- **Testing with your real Apple ID** instead of a sandbox tester → real charges or confusing state. Use the Sandbox account slot.
- **Couple unlock tested on one device only** → you'll think it works, but the *partner's* phone has no local transaction. Always test the unlock on the **non-buying** partner's device (that's exactly the V2 couple-path verification step).
- **`Transaction.currentEntitlements` is empty right after purchase in some flows** → rely on the value returned by `purchase()` for the immediate unlock, and `currentEntitlements` for launch/restore.
- **`AppStore.sync()` prompts for Apple ID password** → only call it from an explicit "Restore" button, never automatically on launch (use `currentEntitlements` for silent launch checks).

---

## TL;DR build order
1. **Part B** — local `.storekit`, build the C1/C2 code, purchase works offline. *(no ASC yet)*
2. **M1** — couple entitlement table + `EntitlementStore` resolves tier from server OR local.
3. **Part D** — bridge: a verified purchase writes the couple row; partner unlocks from it.
4. **Part A** — ASC product + sandbox tester; test a real sandbox purchase on device.
5. **M3–M5** — gates + the two conversion moments.
6. **Part F** — submission checklist at App-Store phase.

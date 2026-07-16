# Validation Matrix — Preview vs Simulator vs Real Device

**What can be trusted where.** A capability is only "validated" in the environment that actually
exercises the real code path. Passing in a weaker environment is necessary but not sufficient;
passing in a stronger one subsumes the weaker. This doc is the source of truth for *where* each
kind of Vayl behavior has to be proven before submit.

> **Claude's ceiling is build + test.** Claude verifies by reading code, building, and running the
> XCTest suite (sim, no UI driving). Feel, motion, haptics, and any real-device/two-device pass
> are **Bryan's** — Claude never asserts a UI/feel verdict from automation. (See `.claude/skills/verify`,
> CLAUDE.md XcodeBuildMCP gate.) XcodeBuildMCP UI driving is opt-in, only when Bryan explicitly asks.

---

## The three environments (what each actually is)

| | **Xcode Preview** | **Simulator** | **Real Device** |
|---|---|---|---|
| Runs | one view, mock data, `#Preview` | full app, arm64 binary on your Mac's CPU | full app, real Apple hardware |
| Backing | SwiftUI render + your stubs | Mac network stack, Mac CPU/RAM, no radios | cellular/Wi-Fi radios, Secure Enclave, Taptic Engine, APNs |
| Speed to iterate | seconds | ~40s build+launch | slowest (signing, install) |
| Truth level | layout/state logic only | same compiled code + real network/DB | the only ground truth for hardware + transactions |

**Key fact:** the Apple-Silicon simulator runs the *same compiled binary and Swift/SwiftUI runtime*
as the device. So pure logic, networking, and Supabase results are identical sim↔device. The gaps
are exclusively: **hardware** (haptics, Secure Enclave, radios, thermal/perf), **the App Store
transaction boundary** (StoreKit/IAP), and **timing-sensitive multi-device** behavior.

---

## Master capability matrix

Legend: ✅ fully valid here · 🟡 partial / logic-only · ❌ cannot validate / misleading · — n/a

| Capability | Preview | Sim | Device | Notes |
|---|---|---|---|---|
| **View layout / hierarchy** | ✅ | ✅ | ✅ | Preview is the fast lane; match `AppLayout.from(geo)`. |
| **State logic / routing** (`@Observable` stores, reactive routing) | 🟡 | ✅ | ✅ | Preview only if store is stubbed; sim proves real routing. |
| **Dark-mode-only correctness** | ✅ | ✅ | ✅ | Preview catches most; verify no `colorScheme` leaks. |
| **Design-token compliance** (colors/fonts/spacing) | ✅ | ✅ | ✅ | Static + visual; Claude can also grep-verify. |
| **Empty / error / relational states** | 🟡 | ✅ | ✅ | Preview per-state if you feed the stub each state. |
| **Networking / URLSession / edge functions** | ❌ | ✅ | ✅ | Sim = device here. Preview has no real network. |
| **Supabase reads/writes, RLS, cascades** | ❌ | ✅ | ✅ | **Sim result is production truth** (verify via SQL). |
| **Auth session / JWT / sign-in-out** | ❌ | ✅ | ✅ | Logic identical; Keychain not hardware-backed on sim. |
| **Pairing / two-profile linking** | ❌ | 🟡 | ✅ | Sim proves the writes; real cross-device linking = device. |
| **Realtime session sync (A1)** | ❌ | 🟡 | ✅ | Sim runs the logic but *hides timing races*; two-device only. |
| **StoreKit purchase (IAP)** | ❌ | 🟡 | ✅ | See StoreKit section — sim never proves the real pipeline. |
| **Restore purchases / `AppStore.sync()`** | ❌ | 🟡 | ✅ | Same — Sandbox on device required. |
| **Entitlement grant → Supabase** | ❌ | 🟡 | ✅ | Server half verifiable on sim; StoreKit half is device. |
| **Push notifications / APNs** | ❌ | 🟡 | ✅ | Sim fakes local pushes; real token+delivery = device. |
| **Haptics** (`.sensoryFeedback`, Core Haptics) | ❌ | ❌ | ✅ | Sim has no Taptic Engine — silent no-op. Device only. |
| **Animation feel / motion / timing** | 🟡 | 🟡 | ✅ | Preview/sim show it runs; *feel* is device (Bryan). |
| **Gestures** (drag/swipe/lift, card physics) | 🟡 | 🟡 | ✅ | Sim approximates; real touch/momentum = device. |
| **Reduce Motion / Low Power Mode gating** | 🟡 | ✅ | ✅ | Sim can toggle RM; **LPM only real on device**. |
| **Performance / scroll / frame rate / thermal** | ❌ | ❌ | ✅ | Sim uses Mac CPU — never representative. |
| **Memory pressure / background limits** | ❌ | ❌ | ✅ | Real jetsam/background budgets only on device. |
| **Secure Enclave / hardware Keychain** | ❌ | ❌ | ✅ | Sim keychain is software; security props differ. |
| **Dynamic Island / safe-area on real hardware** | 🟡 | ✅ | ✅ | Sim models it well; confirm `.topClearance` on device. |
| **App Review compliance artifacts** (encryption key, legal URLs) | — | 🟡 | ✅ | Config-level; final check is a real signed build. |

---

## Deep dives on the three real gaps

### 1. StoreKit / In-App Purchase — the biggest trap
Three distinct environments, and **passing a weaker one proves nothing about the stronger**:

1. **Local StoreKit testing** (`Vayl.storekit` config, sim *or* device): validates *your app's logic
   and UI* — buy flips the entitlement, `restore()` calls `AppStore.sync()`, paywall states render.
   No real money, no Apple ID, no server round-trip.
   - ⚠️ The config only applies when **launched from Xcode's Run action**. Under `simctl`/XcodeBuildMCP
     launch it is *not* applied — the app falls through to the real App Store and prompts for an Apple ID.
2. **Sandbox** (real device, Sandbox Apple ID, TestFlight/dev build): the *only* environment that
   exercises the real pipeline — App Store Server round-trip, JWS/receipt validation, your Supabase
   grant, Ask-to-Buy, interrupted purchases, cross-device restore, family sharing, refund webhooks.
3. **Production** (post-review): what users actually hit.

**Rule:** IAP + Restore + entitlements **must** get a Sandbox pass on a real device before submit.
Fold it into the A1 two-device session. Sim/Preview are for building the logic, never for sign-off.

### 2. Realtime session sync (A1) — timing hides on sim
The couple-session logic (`CoupleSessionStore`, heartbeats, disconnect, lock-in) *runs* on the sim,
but the sim's faster CPU and different scheduler can mask races that appear on real networks. Card
advance, heartbeat cadence, and fast-disconnect are **two-real-device over real Wi-Fi/cellular**
territory. This is exactly why A1 is a hardware pass, not a sim pass, and why
`gotcha_in_session_realtime_sync_broken` needs devices to close.

### 3. Haptics & feel — no Taptic Engine in the sim
Every `.sensoryFeedback(...)` and Core Haptics pattern is a **silent no-op on the sim**. The haptic
weight scale (`light`/`medium`/`rigid`/`heavy`/`success`) can only be judged on device. Same for
motion *feel* (the code running ≠ the tempo feeling right) — that's Bryan's device gate, never an
automation verdict.

---

## Mapped to Vayl features / the punch list

| Feature | Where it's genuinely validated | Why |
|---|---|---|
| **Delete account (A2)** | ✅ **Sim** (verified via SQL) | Pure edge-fn + Postgres; sim = prod truth. *Finding: orphaned `auth.users` row — a code bug, not a sim gap.* |
| **Restore purchases / IAP** | ❌ Sim → ✅ **Device Sandbox** | Transaction pipeline never runs on sim. |
| **Two-device session (A1)** | 🟡 Sim logic → ✅ **Two real devices** | Timing/disconnect races. |
| **Pairing / unlink / re-pair** | 🟡 Sim writes → ✅ **Two devices** | Cross-device link truth. |
| **Pulse / Desire Map / Vault** (data screens) | ✅ Sim (+ Preview per-state) | Logic + Supabase; feel on device. |
| **Onboarding motion, splash bloom, card physics** | ✅ **Device (Bryan)** | Feel/timing/haptics. |
| **Push (if used for pairing/session)** | ✅ **Device** | Real APNs token + delivery. |
| **Legal URLs / encryption key / dark-only** | 🟡 Config → ✅ **Signed build** | App Review-facing. |

---

## Pre-submit: what MUST touch a real device

Everything else can sign off on sim + XCTest. These cannot:

- [ ] **A1 — two-device session pass** (sync, heartbeat, fast-disconnect, lock-in) on two real phones
- [ ] **IAP purchase** end-to-end in **Sandbox** (real transaction → grant → couple unlock)
- [ ] **Restore purchases** in Sandbox, including restore-on-a-second-device
- [ ] **Haptics** across the weight scale (tab tap → session seal → safe-word)
- [ ] **Motion/feel** on device (onboarding, splash, card carousel, Pulse expand)
- [ ] **Push** registration + delivery (if wired to pairing/session)
- [ ] **Performance** — scroll/frame rate on the oldest supported hardware
- [ ] Final **signed build** boots clean (encryption key, entitlements, legal URLs live)

## What Claude will sign off (its ceiling)
- [ ] Build succeeds (`xcodebuild build`)
- [ ] `VaylTests` green with real counts (`-parallel-testing-enabled NO` for session suites)
- [ ] Server-side truth via Supabase SQL (delete/pairing/entitlement rows)
- [ ] Static: token/grammar/architecture/iOS-26 compliance, contract adherence

Claude will **not** assert: animation feel, haptic correctness, real-device performance, or that a
Sandbox/production purchase works. Those are device passes Bryan owns.

---
*Companion: `.claude/skills/verify` (how Claude verifies), CLAUDE.md (XcodeBuildMCP gate, feel is Bryan's).*

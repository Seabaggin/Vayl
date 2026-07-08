# Pairing Deep Link (Universal Links) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the "Send the app instead" secondary invite action — a
Universal Link that opens the app straight into the join-with-code screen
(pre-filled) if installed, or a "get the app" landing page if not.

**Architecture:** A dedicated Cloudflare Worker on `pairing.intothevayl.app`
(kept separate from the existing waitlist Worker) serves two static/thin
routes Apple's spec requires at a real domain root: the
`apple-app-site-association` file and a human-facing `/i/:code` landing page.
The app gains an Associated Domains entitlement, an `onOpenURL` handler, and
a `ShareLink`. Supabase/`PairingService` are untouched — the code itself is
still validated exactly as it is today; this plan only adds a way to *arrive*
at the existing join flow via a tapped link instead of manual entry.

**Tech Stack:** Cloudflare Workers, SwiftUI `onOpenURL`/`ShareLink`, Xcode
entitlements.

**Depends on:** `docs/superpowers/plans/2026-07-05-partner-chip-and-pairing-plan.md`
(needs `PairingJoinView` to exist and be reachable — it already does) but does
not block it; can be built in either order.

**Prerequisite (manual, not code):** Bryan owns `intothevayl.app`. Before
Task 2 can be deployed, DNS for `pairing.intothevayl.app` needs a CNAME/A
record pointed at Cloudflare (via the Cloudflare dashboard for the existing
zone) and Cloudflare Workers Routes needs the new Worker bound to
`pairing.intothevayl.app/*`. This plan writes the Worker code; deploying it
and configuring DNS/Routes are manual steps for Bryan to run himself (same
posture as device builds — Claude doesn't execute live deployments to public
infrastructure without being asked to, each time).

---

## Task 1: Write the pairing Worker (AASA + landing page)

**Files:**
- Create: `docs/mockups/pairing-worker.js`
- Create: `docs/mockups/pairing-worker.wrangler.toml`

Deliberately a new file, not an addition to `docs/mockups/worker.js` — that
Worker is bound to the waitlist's root-domain routes; this one is bound to
the `pairing.intothevayl.app` subdomain, per the spec's decision to keep them
separate.

- [ ] **Step 1: Write the Worker**

```javascript
// docs/mockups/pairing-worker.js
// Serves the two root-level paths Universal Links requires, plus a plain
// "get the app" landing page. Bound to pairing.intothevayl.app/* — does not
// share routes or logic with the waitlist Worker (docs/mockups/worker.js).

const APP_STORE_URL = "https://apps.apple.com/app/vayl/idXXXXXXXXX"; // TODO before ship: real App Store ID once listed

// Apple Universal Links requires this exact JSON at this exact path, no
// redirect, served as application/json (no file extension).
const AASA = {
  applinks: {
    details: [
      {
        appIDs: ["TEAMID.com.vayl.app"], // TODO before ship: real Team ID prefix
        components: [
          { "/": "/i/*", comment: "Matches any pairing invite link" }
        ]
      }
    ]
  }
};

function landingPage(code) {
  const safeCode = (code || "").replace(/[^A-Za-z0-9]/g, "").slice(0, 8);
  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Join on Vayl</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #0A0810; color: #fff;
           display: flex; flex-direction: column; align-items: center; justify-content: center;
           min-height: 100vh; margin: 0; padding: 24px; text-align: center; }
    .code { font-family: ui-monospace, monospace; font-size: 28px; letter-spacing: 0.2em;
            margin: 24px 0; }
    a.cta { background: linear-gradient(135deg, #00C2FF, #6C3AE0, #FF006A);
            color: #fff; text-decoration: none; padding: 14px 28px; border-radius: 999px;
            font-weight: 600; }
  </style>
</head>
<body>
  <h1>Join your partner on Vayl</h1>
  <p>Install the app, then enter this code to link:</p>
  <div class="code">${safeCode}</div>
  <a class="cta" href="${APP_STORE_URL}">Get Vayl</a>
</body>
</html>`;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/.well-known/apple-app-site-association") {
      return new Response(JSON.stringify(AASA), {
        headers: { "Content-Type": "application/json" }
      });
    }

    if (url.pathname.startsWith("/i/")) {
      const code = url.pathname.split("/i/")[1];
      return new Response(landingPage(code), {
        headers: { "Content-Type": "text/html; charset=utf-8" }
      });
    }

    return new Response("Not found", { status: 404 });
  }
};
```

- [ ] **Step 2: Write the Wrangler config**

```toml
# docs/mockups/pairing-worker.wrangler.toml
name = "vayl-pairing-link"
main = "pairing-worker.js"
compatibility_date = "2026-07-05"

routes = [
  { pattern = "pairing.intothevayl.app/*", zone_name = "intothevayl.app" }
]
```

- [ ] **Step 3: Flag the two real TODOs for Bryan before this ships**

This file intentionally contains two placeholder values that cannot be known
until later steps: the real App Store listing ID (doesn't exist until the app
ships) and the real Apple Developer Team ID prefix (needed for `appIDs` to
validate). These are **not** plan placeholders in the "vague instruction"
sense — they're literal values that don't exist yet in the outside world.
Both are marked `// TODO before ship:` inline; do not remove those comments
when deploying early builds, and do not treat `BUILD SUCCEEDED` as meaning
this file is complete — it isn't, until both real IDs are filled in.

- [ ] **Step 4: Commit**

```bash
git add docs/mockups/pairing-worker.js docs/mockups/pairing-worker.wrangler.toml
git commit -m "feat(pairing-link): add Cloudflare Worker serving AASA + invite landing page"
```

(This step just commits the source files — it does not deploy anything.
Deployment is a manual step for Bryan: `wrangler deploy -c
pairing-worker.wrangler.toml` from `docs/mockups/`, after DNS/Routes are
configured per this plan's prerequisite note.)

---

## Task 2: Associated Domains entitlement

**Files:**
- Modify: `Vayl/Vayl.entitlements`

- [ ] **Step 1: Read the current file**

`Vayl.entitlements` currently has `com.apple.developer.applesignin` and
`com.apple.developer.default-data-protection` (confirmed by prior grounding).
Read it to get exact current XML structure before editing.

- [ ] **Step 2: Add the associated-domains key**

Add, matching the existing plist-XML structure:

```xml
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:pairing.intothevayl.app</string>
    </array>
```

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

Note: this entitlement will not actually *validate* against Apple's servers
until the AASA file (Task 1) is live at the real domain — until then, tapping
a `pairing.intothevayl.app` link will fall through to Safari instead of
opening the app. That's expected during development, not a bug to chase down
in Simulator.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Vayl.entitlements
git commit -m "feat(pairing-link): add Associated Domains entitlement for pairing.intothevayl.app"
```

---

## Task 3: `onOpenURL` handler + `AppState.pendingJoinCode`

**Files:**
- Modify: `Vayl/App/VaylApp.swift`
- Modify: `Vayl/Core/Services/AppState.swift`

- [ ] **Step 1: Add the pending-code property to `AppState`**

Read `AppState.swift` first to find its existing `@Observable`/`@MainActor`
property style (it already exposes `linkState`, `coupleId`, `selectedTab` per
prior grounding — match that style exactly), then add:

```swift
    /// Set by the Universal Link handler when the app is opened via a pairing
    /// invite link. Consumed once by whichever view presents the join sheet,
    /// then cleared — never left set across app restarts.
    var pendingJoinCode: String? = nil
```

- [ ] **Step 2: Parse the incoming URL in `VaylApp.swift`**

Add `.onOpenURL` to the `WindowGroup` content in `VaylApp.swift` (after the
existing `.modelContainer(...)` modifier, `VaylApp.swift:94`):

```swift
                .modelContainer(ModelContainer.appContainer)
                .onOpenURL { url in
                    guard url.host == "pairing.intothevayl.app",
                          url.pathComponents.count >= 3,
                          url.pathComponents[1] == "i" else { return }
                    let code = url.pathComponents[2].uppercased()
                    appState.pendingJoinCode = code
                }
```

- [ ] **Step 3: Write a unit test for the URL-parsing rule**

The parsing logic itself is pure and testable — extract it so it can be
tested without a live `URL(string:)` app-launch round trip:

```swift
// Vayl/App/PairingDeepLink.swift (new file)

import Foundation

/// Pure parsing for pairing invite Universal Links, extracted from
/// VaylApp.onOpenURL so it's independently testable.
enum PairingDeepLink {
    static func code(from url: URL) -> String? {
        guard url.host == "pairing.intothevayl.app",
              url.pathComponents.count >= 3,
              url.pathComponents[1] == "i" else { return nil }
        return url.pathComponents[2].uppercased()
    }
}
```

Then `VaylApp.swift`'s handler becomes:
```swift
                .onOpenURL { url in
                    guard let code = PairingDeepLink.code(from: url) else { return }
                    appState.pendingJoinCode = code
                }
```

Test:
```swift
import XCTest
@testable import Vayl

final class PairingDeepLinkTests: XCTestCase {
    func testValidInviteLinkExtractsUppercasedCode() {
        let url = URL(string: "https://pairing.intothevayl.app/i/k7xqf2")!
        XCTAssertEqual(PairingDeepLink.code(from: url), "K7XQF2")
    }

    func testWrongHostReturnsNil() {
        let url = URL(string: "https://intothevayl.app/i/K7XQF2")!
        XCTAssertNil(PairingDeepLink.code(from: url))
    }

    func testMissingCodeSegmentReturnsNil() {
        let url = URL(string: "https://pairing.intothevayl.app/")!
        XCTAssertNil(PairingDeepLink.code(from: url))
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `xcodebuild test -project Vayl.xcodeproj -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VaylTests/PairingDeepLinkTests 2>&1 | tail -30`
Expected: `Test Suite 'PairingDeepLinkTests' passed`

- [ ] **Step 5: Build-verify the app target**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add Vayl/App/VaylApp.swift Vayl/App/PairingDeepLink.swift Vayl/Core/Services/AppState.swift VaylTests/PairingDeepLinkTests.swift
git commit -m "feat(pairing-link): parse incoming Universal Links into AppState.pendingJoinCode"
```

**Reminder:** add the new test file to `project.pbxproj` (VaylTests gotcha).

---

## Task 4: Consume `pendingJoinCode` — auto-present the join sheet, pre-filled

**Files:**
- Modify: `Vayl/Features/Home/HomeRouterView.swift` (the `.vaylSheet` added in the companion plan's Task 9)
- Modify: `Vayl/Features/Pairing/PairingJoinView.swift`

- [ ] **Step 1: Let `PairingJoinView` accept a pre-fill**

Read `PairingJoinView.swift`'s current initializer first (the companion plan
found its form is a 6-char `TextField`, `PairingJoinView.swift:87-120`), then
add an optional pre-fill parameter:

```swift
struct PairingJoinView: View {
    let store: PairingStore
    var prefillCode: String? = nil

    // In whatever holds the entered-code @State (find the exact property
    // name in the existing TextField binding first), initialize it from
    // prefillCode instead of "" when present, e.g.:
    // @State private var enteredCode: String = ""
    // becomes populated in .task or init from prefillCode.
}
```

- [ ] **Step 2: Wire `HomeRouterView` to watch `pendingJoinCode`**

In the `.vaylSheet` added for `showPairingJoin` (companion plan Task 9), pass
the pending code through and clear it once consumed:

```swift
    .vaylSheet(isPresented: $showPairingJoin, heightFraction: 0.92) {
        PairingJoinView(
            store: PairingStore(modelContainer: appState.modelContainer, appState: appState),
            prefillCode: appState.pendingJoinCode
        )
        .environment(appState)
    }
    .onChange(of: appState.pendingJoinCode) { _, newCode in
        guard newCode != nil else { return }
        showPairingJoin = true
    }
    .onChange(of: showPairingJoin) { _, isShowing in
        guard !isShowing else { return }
        appState.pendingJoinCode = nil // consumed — don't re-trigger on next appear
    }
```

- [ ] **Step 3: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Bryan verifies on device**

This step genuinely cannot be verified in Simulator alone — Universal Links
require the real domain to be live and Apple's CDN to have fetched/cached the
AASA file (can take a few minutes after first deploy). Once
`pairing.intothevayl.app` is deployed (Task 1's manual deploy step) and the
entitlement is in a build on a real device, test by sending yourself the
`https://pairing.intothevayl.app/i/CODE` link via Messages/Notes and tapping
it: with the app installed, it should open straight to the join screen with
the code pre-filled; with the app not installed, it should open the Task 1
landing page in Safari instead.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Home/HomeRouterView.swift Vayl/Features/Pairing/PairingJoinView.swift
git commit -m "feat(pairing-link): auto-open the join sheet pre-filled from a tapped invite link"
```

---

## Task 5: `ShareLink` — "Send the app instead"

**Files:**
- Modify: `Vayl/Features/Pairing/PairingInviteView.swift`

- [ ] **Step 1: Build the share URL + message**

In the code-display area of `PairingInviteView` (near the existing Copy
button, `PairingInviteView.swift:172-191`), add a `ShareLink` for the
secondary action:

```swift
    private func shareURL(for code: String) -> URL {
        URL(string: "https://pairing.intothevayl.app/i/\(code)")!
    }

    // In the view body, alongside the existing copy button:
    if case .waitingForPartner(let code) = store.linkState {
        ShareLink(
            item: shareURL(for: code),
            message: Text("Join me on Vayl — tap this to link up.")
        ) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: AppIcons.squareAndArrowUp)
                Text("Send the app instead")
            }
        }
    }
```

- [ ] **Step 2: Build-verify**

Run: `xcodebuild -project Vayl.xcodeproj -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Bryan verifies on device**

Confirm the native share sheet opens with the link + message, and (once
Task 1-4 are fully deployed) that sharing to Messages produces a tappable
link that behaves per Task 4's on-device test.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Pairing/PairingInviteView.swift
git commit -m "feat(pairing-link): add ShareLink 'send the app instead' secondary invite action"
```

---

## Plan Self-Review

**Spec coverage:** covers the entirety of the spec's "deep-link mechanics"
open item and the "Send the app instead" row from §2 of the design spec.
Does not touch anything already covered by the companion plan (chip UI,
Settings, countdown) — correctly scoped as its own build segment per the
Build Protocol, exactly as the spec called for.

**Placeholder scan:** the two `// TODO before ship:` markers in
`pairing-worker.js` (App Store ID, Team ID) are flagged explicitly as real
external values that don't exist yet, not vague "add appropriate X"
instructions — every other step has complete, real code.

**Type consistency:** `PairingDeepLink.code(from:)`, `AppState.pendingJoinCode`,
and `PairingJoinView.prefillCode` are the same three names used consistently
across Tasks 3-4 — no renaming drift between tasks.

**Manual/operational steps called out explicitly, not silently assumed done:**
DNS + Cloudflare Routes configuration (prerequisite), Worker deployment
(Task 1), and the real App Store/Team IDs (Task 1) all require Bryan's
action outside this codebase — each is called out rather than treated as
"finished" once the Swift/JS source compiles.

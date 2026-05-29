# ExperienceLevelPhase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ExperienceLevelPhase — a "Three Card Monte" that deals three candle cards, shuffles them (lift-and-toss theatre), reveals Curious/Exploring/Experienced, and lets the user pick their experience level, writing `nmStage` and advancing to ContextPhase.

**Architecture:** A dedicated `CardThreeMonteController` (`@Observable @MainActor`, in `CardPhysics/`, modeled on `CardMirrorDeal`) owns the whole deal/organize/shuffle/flip/lift/confirm lifecycle. `CardFlightScene` flies the face-down deal-in only. A pure `CandleCardFace` (`Canvas`, in `CardFaces/`) is a verbatim port of the validated `docs/mockups/real-card-scale.html` `drawFrame`. `ExperienceLevelPhase` is a thin View that renders from controller state and owns one `TimelineView(.animation)` flame clock. `VaylDirector` only fires `advance(to: .context)`.

**Tech Stack:** SwiftUI (`Canvas`, `GraphicsContext`, `TimelineView`), SpriteKit (`CardFlightScene`, existing), Swift 6, iOS 16+ baseline. Design tokens: `AppColors`, `AppFonts`, `AppSpacing`, `AppRadius`, `AppLayout`, `AppAnimation`, `AppElevation`.

**Spec:** [`docs/superpowers/specs/2026-05-28-experience-level-phase-design.md`](../specs/2026-05-28-experience-level-phase-design.md)

---

## Conventions for this plan

**Project facts (verified):**
- Xcode project `Vayl.xcodeproj`, single app scheme `Vayl`, targets `Vayl` / `VaylTests` / `VaylUITests`.
- `objectVersion = 77` with synchronized file groups — **new `.swift` files placed in the correct folder auto-join their target**. No `.pbxproj` editing required.
- `VaylTests` exists but is empty; new test files go in `VaylTests/` and auto-join.

**Build command (compile check):**
```bash
xcodebuild -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

**Unit-test command:**
```bash
xcodebuild test -project Vayl.xcodeproj -scheme Vayl \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:VaylTests 2>&1 | tail -15
```

**Verification reality (per CLAUDE.md Build Protocol):** This is animation/feel work. Pure logic (Tasks 1–2) gets real XCTest. Everything visual is verified by **Xcode `#Preview` + simulator/device + a human feel-confirm checkpoint** — "Build succeeds is not done. Feel is correct is done." A 🧍 **HUMAN CHECKPOINT** marks where Bryan must confirm feel on-device before the next task starts.

**Mockup reference server (already configured):** `docs/mockups/real-card-scale.html` is the candle source of truth. To view it: `preview_start` the `mockup` config (port 7331), open `/real-card-scale.html`. Port Swift against it side-by-side.

---

## Canvas API translation guide (Canvas 2D → SwiftUI `GraphicsContext`)

The candle is a verbatim port of `drawFrame`. Use this mapping for every pass. **The mockup is the line-by-line source; do not redesign — translate.**

| Canvas 2D (mockup) | SwiftUI `GraphicsContext` |
|---|---|
| `new Path2D(); p.moveTo(x,y)` | `var p = Path(); p.move(to: CGPoint(x:y:))` |
| `p.lineTo(x,y)` | `p.addLine(to:)` |
| `p.quadraticCurveTo(cpx,cpy,x,y)` | `p.addQuadCurve(to:control:)` |
| `p.bezierCurveTo(c1x,c1y,c2x,c2y,x,y)` | `p.addCurve(to:control1:control2:)` |
| `p.closePath()` | `p.closeSubpath()` |
| `p.ellipse(cx,cy,rx,ry,rot,0,2π)` | `Path(ellipseIn: CGRect).applying(rotation)` or `p.addEllipse(in:)` |
| `ctx.createLinearGradient(x0,y0,x1,y1)` + stops | `GraphicsContext.Shading.linearGradient(Gradient(stops:), startPoint:, endPoint:)` |
| `ctx.createRadialGradient(cx,cy,0,cx,cy,r)` | `.radialGradient(Gradient(stops:), center:, startRadius: 0, endRadius: r)` |
| `ctx.stroke(path)` w/ `strokeStyle`,`lineWidth`,`lineCap`,`lineJoin` | `ctx.stroke(p, with: shading, style: StrokeStyle(lineWidth:lineCap:lineJoin:))` |
| `ctx.fill(path)` w/ `fillStyle` | `ctx.fill(p, with: shading)` |
| `ctx.fillRect(x,y,w,h)` w/ gradient | `ctx.fill(Path(CGRect(...)), with: shading)` |
| `ctx.filter='blur(Npx)'` … draw … `filter='none'` | `var layer = ctx; layer.addFilter(.blur(radius: N)); layer.stroke(...)` inside `ctx.drawLayer { $0.addFilter(.blur(radius:N)); ... }` |
| `ctx.globalAlpha = a` | set `ctx.opacity = a` (or per-layer) |
| `ctx.clip(path)` | `ctx.clip(to: path)` (inside a `drawLayer`) |

**Spectrum stops (constant):** cyan `#00C2FF`, purple `#6C3AE0`, magenta `#FF006A`. Define once as `CandlePalette` in the candle file. All hex via `Color(red:green:blue:)` literals — do NOT use `Color(hex:)` raw (CLAUDE.md). cyan = `Color(red: 0, green: 0.761, blue: 1)`, purple = `Color(red: 0.424, green: 0.227, blue: 0.878)`, magenta = `Color(red: 1, green: 0, blue: 0.416)`.

**Scale factor:** every absolute px in the mockup is multiplied by `S = cardWidth / 160`. Carry `S` through every helper.

---

## File structure

| File | Responsibility |
|---|---|
| `Vayl/App/Theme/AppLayout.swift` (modify) | Add `monteRowCenters(in:)` — canonical 3-slot frame |
| `Vayl/Core/Models/Enums/AppCardEnums.swift` (modify) | Add `CandleIntensity` enum + `nmStage` mapping |
| `Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift` (create) | Pure `Canvas` candle, verbatim v12 port |
| `Vayl/Design/Components/Cards/VaylCardContent.swift` (modify) | Add `.candle(intensity:time:)` case |
| `Vayl/Design/Components/Cards/VaylCardFace.swift` (modify) | Route `.candle` content case |
| `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift` (create) | `CardThreeMonteController` — full lifecycle |
| `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift` (rewrite) | Thin View + flame clock |
| `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` (modify) | `runExperienceLevelEntry` hook (line 197) |
| `VaylTests/MonteRowGeometryTests.swift` (create) | Unit test for `monteRowCenters` |
| `VaylTests/CandleIntensityTests.swift` (create) | Unit test for intensity → `NMStage` |

---

## Task 1: Canonical row geometry + unit test

**Files:**
- Modify: `Vayl/App/Theme/AppLayout.swift`
- Test: `VaylTests/MonteRowGeometryTests.swift` (create)

- [ ] **Step 1: Write the failing test**

Create `VaylTests/MonteRowGeometryTests.swift`:
```swift
import XCTest
@testable import Vayl

final class MonteRowGeometryTests: XCTestCase {

    func test_threeCentersReturned() {
        XCTAssertEqual(AppLayout.monteRowCenters(in: 393).count, 3)
    }

    func test_symmetricAroundMidpoint() {
        let c = AppLayout.monteRowCenters(in: 393)
        XCTAssertEqual(c[1], 393 / 2, accuracy: 0.001)               // center slot at midpoint
        XCTAssertEqual(c[0] + c[2], 393, accuracy: 0.001)            // left/right mirror
    }

    func test_pitchIsCardWidthPlusSmallGap() {
        let w: CGFloat = 393
        let expectedPitch = AppLayout.obTableCardWidth(in: w) + AppSpacing.sm
        let c = AppLayout.monteRowCenters(in: w)
        XCTAssertEqual(c[1] - c[0], expectedPitch, accuracy: 0.001)
        XCTAssertEqual(c[2] - c[1], expectedPitch, accuracy: 0.001)
    }

    func test_rowFitsOnSmallestPhone() {
        let w: CGFloat = 320
        let c = AppLayout.monteRowCenters(in: w)
        let halfCard = AppLayout.obTableCardWidth(in: w) / 2
        XCTAssertGreaterThanOrEqual(c[0] - halfCard, 0)             // left edge on-screen
        XCTAssertLessThanOrEqual(c[2] + halfCard, w)               // right edge on-screen
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run the unit-test command. Expected: FAIL — `monteRowCenters` does not exist (compile error).

- [ ] **Step 3: Implement `monteRowCenters`**

In `AppLayout.swift`, near `obTableCardWidth` (line ~215), add:
```swift
/// X-centers (absolute, container coords) of the three Three-Card-Monte row slots.
/// Slot 0 = left, 1 = center, 2 = right. The canonical reference frame that
/// shuffle swaps between, organize snaps to, and lift/dismiss derive from.
static func monteRowCenters(in containerWidth: CGFloat) -> [CGFloat] {
    let cardW = obTableCardWidth(in: containerWidth)
    let pitch = cardW + AppSpacing.sm
    let mid   = containerWidth / 2
    return [mid - pitch, mid, mid + pitch]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run the unit-test command. Expected: PASS (4 tests). If `test_rowFitsOnSmallestPhone` fails, the gap is too large — confirm `AppSpacing.sm == 8`; the math fits on 320pt with sm=8.

- [ ] **Step 5: Commit**

```bash
git add Vayl/App/Theme/AppLayout.swift VaylTests/MonteRowGeometryTests.swift
git commit -m "feat(ExperienceLevel): add canonical Monte row geometry + tests"
```

---

## Task 2: `CandleIntensity` enum + `NMStage` mapping + unit test

**Files:**
- Modify: `Vayl/Core/Models/Enums/AppCardEnums.swift`
- Test: `VaylTests/CandleIntensityTests.swift` (create)

- [ ] **Step 1: Write the failing test**

Create `VaylTests/CandleIntensityTests.swift`:
```swift
import XCTest
@testable import Vayl

final class CandleIntensityTests: XCTestCase {

    func test_orderedCasesMatchRowSlots() {
        // Slot 0 (left) = curious, 1 = exploring, 2 = experienced
        XCTAssertEqual(CandleIntensity.ordered, [.curious, .exploring, .experienced])
    }

    func test_mapsToNMStage() {
        XCTAssertEqual(CandleIntensity.curious.nmStage, .curious)
        XCTAssertEqual(CandleIntensity.exploring.nmStage, .exploring)
        XCTAssertEqual(CandleIntensity.experienced.nmStage, .experienced)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run the unit-test command. Expected: FAIL — `CandleIntensity` undefined.

- [ ] **Step 3: Implement the enum**

In `AppCardEnums.swift`, add:
```swift
/// Experience-level candle states. Render-layer enum (decoupled from the
/// domain `NMStage`); maps 1:1 onto it for selection.
public enum CandleIntensity: String, CaseIterable, Equatable {
    case curious, exploring, experienced

    /// Left → right row order.
    static var ordered: [CandleIntensity] { [.curious, .exploring, .experienced] }

    var nmStage: NMStage {
        switch self {
        case .curious:     return .curious
        case .exploring:   return .exploring
        case .experienced: return .experienced
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run the unit-test command. Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Vayl/Core/Models/Enums/AppCardEnums.swift VaylTests/CandleIntensityTests.swift
git commit -m "feat(ExperienceLevel): add CandleIntensity enum + NMStage mapping"
```

---

## Task 3: `CandleCardFace` skeleton — noise, geometry, body + flame (static)

**Files:**
- Create: `Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift`

This task ports the *pure-math* foundation (`smoothNoise`, `fbm`, `getGeo`, `buildTaperedRun`) — which is written in full below — plus the body path and crisp flame edges for `.exploring`, rendered static (`time = 0`). Later tasks add the remaining passes and motion.

- [ ] **Step 1: Create the file with palette, noise, geometry, and the View shell**

```swift
import SwiftUI

// MARK: - Palette (spectrum; sanctioned candle exception to outline-only OB rule)
enum CandlePalette {
    static let cyan    = Color(red: 0,     green: 0.761, blue: 1)
    static let purple  = Color(red: 0.424, green: 0.227, blue: 0.878)
    static let magenta = Color(red: 1,     green: 0,     blue: 0.416)
}

// MARK: - Noise (verbatim port of mockup smoothNoise/fbm, lines 39–40)
enum CandleNoise {
    static func smooth(_ t: Double, seed: Double = 0) -> Double {
        let p = t + seed * 127.1
        let i = floor(p)
        let f = p - i
        let fc = f * f * (3 - 2 * f)
        let a = sin(i * 127.1 + 311.7) * 43758.5453
        let b = sin((i + 1) * 127.1 + 311.7) * 43758.5453
        return (a - floor(a)) * (1 - fc) + (b - floor(b)) * fc
    }
    static func fbm(_ t: Double, seed: Double = 0, octaves: Int = 4) -> Double {
        var v = 0.0, amp = 0.5, freq = 1.0, maxV = 0.0
        for o in 0..<octaves {
            v += smooth(t * freq, seed: seed + Double(o)) * amp
            maxV += amp; amp *= 0.5; freq *= 2.1
        }
        return v / maxV
    }
}

// MARK: - Geometry (verbatim port of getGeo, mockup line 46)
struct CandleGeo {
    let bW, bH, cx, bY, bBY, bL, bR, wickH, wickBot, wickTip, wickTipX: CGFloat
    init(w: CGFloat, h: CGFloat) {
        let S = w / 160
        bW = w * 0.33
        bH = h * 0.46
        cx = w / 2
        bY = h * 0.28
        bBY = bY + bH
        bL = cx - bW / 2
        bR = cx + bW / 2
        wickH = bH * 0.072
        wickBot = bY + 4.0 * S
        wickTip = wickBot - wickH
        wickTipX = cx + 1.2 * S
    }
}

// MARK: - Tapered run (verbatim port of buildTaperedRun, mockup line 47)
// Builds a closed Path from a quadratic spine with per-point width.
func candleTaperedRun(sx: CGFloat, sy: CGFloat, endX: CGFloat, endY: CGFloat,
                      cpx: CGFloat, cpy: CGFloat, wStart: CGFloat, wEnd: CGFloat,
                      steps: Int = 16) -> Path {
    var left: [CGPoint] = [], right: [CGPoint] = []
    for i in 0...steps {
        let u = CGFloat(i) / CGFloat(steps), mu = 1 - u
        let px = mu*mu*sx + 2*mu*u*cpx + u*u*endX
        let py = mu*mu*sy + 2*mu*u*cpy + u*u*endY
        let tx = 2*mu*(cpx - sx) + 2*u*(endX - cpx)
        let ty = 2*mu*(cpy - sy) + 2*u*(endY - cpy)
        let len = max(sqrt(tx*tx + ty*ty), 1)
        let w = wStart + (wEnd - wStart) * u
        let nx = -ty/len, ny = tx/len
        left.append(CGPoint(x: px + nx*w/2, y: py + ny*w/2))
        right.append(CGPoint(x: px - nx*w/2, y: py - ny*w/2))
    }
    var p = Path()
    p.move(to: left[0])
    left.forEach { p.addLine(to: $0) }
    right.reversed().forEach { p.addLine(to: $0) }
    p.closeSubpath()
    return p
}

// MARK: - The face
struct CandleCardFace: View {
    let intensity: CandleIntensity
    var time: Double = 0
    var reduceMotion: Bool = false

    var body: some View {
        Canvas { ctx, size in
            CandleRenderer.draw(into: &ctx, size: size,
                                intensity: intensity, time: time,
                                reduceMotion: reduceMotion)
        }
        .drawingGroup()   // CLAUDE.md: required on card faces — never remove
    }
}
```

- [ ] **Step 2: Add the renderer with a linear spectrum helper, body path, and crisp flame edges (exploring, static)**

Add to the same file. Port the `bodyPath` (mockup line 65, the `curious||exploring` branch), `leftEdge`/`rightEdge` (lines 70–71, non-notch branch), and the crisp flame stroke (line 91). Use the API translation guide. Spectrum gradient via the helper.
```swift
enum CandleRenderer {

    static func spectrum(_ g: CandleGeo, topY: CGFloat, botY: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: [
                .init(color: CandlePalette.cyan,    location: 0),
                .init(color: CandlePalette.purple,  location: 0.5),
                .init(color: CandlePalette.magenta, location: 1),
            ]),
            startPoint: CGPoint(x: g.cx, y: topY),
            endPoint:   CGPoint(x: g.cx, y: botY))
    }

    static func draw(into ctx: inout GraphicsContext, size: CGSize,
                     intensity: CandleIntensity, time t: Double, reduceMotion: Bool) {
        let w = size.width, h = size.height, S = w / 160
        let g = CandleGeo(w: w, h: h)
        let body = bodyPath(g, S: S, intensity: intensity)
        let bodyShade = spectrum(g, topY: g.bY, botY: g.bBY)

        // Crisp body stroke (mockup line 81)
        ctx.stroke(body, with: bodyShade,
                   style: StrokeStyle(lineWidth: 1.30 * S, lineCap: .square, lineJoin: .miter))

        // Crisp flame edges (mockup line 91), static for now
        let flame = flameEdges(g, S: S, intensity: intensity, t: t)
        let flameShade = spectrum(g, topY: flame.tipY, botY: g.wickTip)
        ctx.stroke(flame.left,  with: flameShade,
                   style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
        ctx.stroke(flame.right, with: flameShade,
                   style: StrokeStyle(lineWidth: 1.60 * S, lineCap: .round))
    }

    // Port of bodyPath (mockup line 65). Curious/Exploring = bowed cylinder.
    static func bodyPath(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity) -> Path {
        var p = Path()
        // PORT mockup line 65, curious||exploring branch:
        //   bow = bW*0.04; midY = bY+bH*0.5
        //   moveTo(bL,bY); bezier(bL-bow,midY-bH*0.12, bL-bow,midY+bH*0.12, bL,bBY)
        //   lineTo(bR,bBY); bezier(bR+bow,midY+bH*0.12, bR+bow,midY-bH*0.12, bR,bY); close
        let bow = g.bW * 0.04, midY = g.bY + g.bH * 0.5
        p.move(to: CGPoint(x: g.bL, y: g.bY))
        p.addCurve(to: CGPoint(x: g.bL, y: g.bBY),
                   control1: CGPoint(x: g.bL - bow, y: midY - g.bH*0.12),
                   control2: CGPoint(x: g.bL - bow, y: midY + g.bH*0.12))
        p.addLine(to: CGPoint(x: g.bR, y: g.bBY))
        p.addCurve(to: CGPoint(x: g.bR, y: g.bY),
                   control1: CGPoint(x: g.bR + bow, y: midY + g.bH*0.12),
                   control2: CGPoint(x: g.bR + bow, y: midY - g.bH*0.12))
        p.closeSubpath()
        return p
        // NOTE: the experienced (notched/dripping) body is line 65's else-branch,
        // added in Task 4. For Task 3 only the curious/exploring body is needed.
    }

    // Port of leftEdge/rightEdge (mockup lines 70–71), non-notch branch.
    // Returns the two flame silhouette curves + the computed tip.
    static func flameEdges(_ g: CandleGeo, S: CGFloat, intensity: CandleIntensity, t: Double)
        -> (left: Path, right: Path, tipY: CGFloat) {
        let cfg = FlameCfg.of(intensity)
        let flameH = g.bH * cfg.baseH
        let flameW = g.bW * cfg.baseW
        // Static (t=0) sway/flicker = 0 → tip straight above wick. Motion added Task 5.
        let fH = flameH
        let tipX = g.wickTipX
        let tipY = g.wickTip - fH
        let fWL = flameW, fWR = flameW * 0.72
        // leftEdge non-notch (line 70 else): cm=0 when sway=0
        var lp = Path()
        lp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        lp.addCurve(to: CGPoint(x: tipX, y: tipY),
                    control1: CGPoint(x: g.wickTipX - fWL*1.08, y: g.wickTip - fH*0.32),
                    control2: CGPoint(x: g.wickTipX - fWL*0.52, y: tipY + fH*0.14))
        // rightEdge (line 71)
        var rp = Path()
        rp.move(to: CGPoint(x: g.wickTipX, y: g.wickTip))
        rp.addCurve(to: CGPoint(x: tipX, y: tipY),
                    control1: CGPoint(x: g.wickTipX + fWR*1.02, y: g.wickTip - fH*0.28),
                    control2: CGPoint(x: tipX + fWR*0.42, y: tipY + fH*0.12))
        return (lp, rp, tipY)
    }
}

// Per-intensity flame config — verbatim port of FLAME_CFG (mockup lines 41–45).
struct FlameCfg {
    let baseH, baseW, crispAlpha, glowAlpha, swayAmp, swayFreq, flickerAmp, turbFreq, innerScale, innerAlpha: Double
    let dim: Bool
    let hasNotch: Bool
    static func of(_ i: CandleIntensity) -> FlameCfg {
        switch i {
        case .curious:     return .init(baseH:0.20, baseW:0.36, crispAlpha:0.38, glowAlpha:0.07, swayAmp:0.58, swayFreq:0.26, flickerAmp:0.55, turbFreq:1.8, innerScale:0.32, innerAlpha:0.42, dim:true,  hasNotch:false)
        case .exploring:   return .init(baseH:0.42, baseW:0.54, crispAlpha:0.94, glowAlpha:0.40, swayAmp:0.12, swayFreq:0.55, flickerAmp:0.07, turbFreq:2.1, innerScale:0.52, innerAlpha:0.80, dim:false, hasNotch:false)
        case .experienced: return .init(baseH:0.42, baseW:0.54, crispAlpha:0.94, glowAlpha:0.40, swayAmp:0.14, swayFreq:0.55, flickerAmp:0.09, turbFreq:2.4, innerScale:0.52, innerAlpha:0.80, dim:false, hasNotch:true)
        }
    }
}
```

- [ ] **Step 3: Add a `#Preview` at 177pt**

```swift
#Preview("Candle — exploring @177pt") {
    ZStack {
        Color.black
        CandleCardFace(intensity: .exploring)
            .frame(width: 177, height: 177 * 1.5)
    }
    .ignoresSafeArea()
}
```

- [ ] **Step 4: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Visual check vs mockup**

Open the preview in Xcode (or run in sim). Open `docs/mockups/real-card-scale.html` (the lifted/exploring frame) side-by-side. The body cylinder and flame silhouette outline should match in shape and proportion. Fills/glows are not present yet — that's Task 4.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift
git commit -m "feat(ExperienceLevel): CandleCardFace skeleton — noise, geometry, body+flame"
```

---

## Task 4: Complete v12 passes + all three intensities (static)

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift`

Port the remaining `drawFrame` passes in the **exact draw order** (mockup lines 76–95) and the `experienced` body branch (line 65 else). Each pass is a mechanical translation using the API guide; the mockup is the source. Work pass-by-pass, rebuilding and eyeballing against the mockup after each.

- [ ] **Step 1: Add the experienced body path branch** — port mockup line 65 `else` block into `bodyPath` (the multi-bezier notched/dripping silhouette). Add `topRim()` (line 67) and `waxPool()` (line 68) path builders.

- [ ] **Step 2: Add the glow passes** — in draw order: ambient warm radial (line 76, non-dim only), blurred flame glow (line 77: `blur(dim?6:12 * S)`, `lineWidth dim?5:12 * S`), blurred body glow (line 78: `blur 6*S`, alpha `dim?0.13:0.28`, `lineWidth 10*S`), experienced extra body glow (line 79). Use `ctx.drawLayer { $0.addFilter(.blur(radius:)); ... }` per the guide.

- [ ] **Step 3: Add the curious cylinder fill** — port `drawCuriousFill` (line 66): clip to body path, fill three stacked linear gradients. Only when `intensity == .curious`.

- [ ] **Step 4: Add top rim + wax pool strokes** — lines 82–84: blurred + crisp top rim per intensity; wax pool glow + crisp stroke for non-curious; experienced inner pool highlight.

- [ ] **Step 5: Add texture lines + side runs + exploring rim drip** — lines 85–87.

- [ ] **Step 6: Add ember, wick, crisp flame edges, inner core, tip glow** — lines 88–93. Add `innerCore()` (line 72) path builder. (Edges/inner already partially present from Task 3; ensure full passes match.)

- [ ] **Step 7: Add curious smoke wisp + experienced wax drips** — lines 94–95. Add `buildDrip` (line 73) using `candleTaperedRun`; render the 4 `dripDefs`.

- [ ] **Step 8: Add a preview of all three at table size**

```swift
#Preview("Candles — all three @118pt") {
    ZStack {
        Color.black
        HStack(spacing: AppSpacing.sm) {
            ForEach(CandleIntensity.ordered, id: \.self) { i in
                CandleCardFace(intensity: i)
                    .frame(width: 118, height: 118 * 1.5)
            }
        }
    }
    .ignoresSafeArea()
}
```

- [ ] **Step 9: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 10: 🧍 HUMAN CHECKPOINT — visual parity + legibility**

Side-by-side with `real-card-scale.html`: all three candles match the mockup (fills, drips, glows, notch). At 118pt the three are distinguishable. Bryan confirms before continuing. **Build succeeds is not done — visual parity is done.**

- [ ] **Step 11: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift
git commit -m "feat(ExperienceLevel): complete v12 candle port — all passes, 3 intensities"
```

---

## Task 5: Wire the flame clock (motion)

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift`

- [ ] **Step 1: Replace static tip with fbm-driven motion**

In `flameEdges`, replace the `t=0` block by porting mockup lines 54–60 exactly:
```swift
let slowSway = (CandleNoise.fbm(t * cfg.swayFreq, seed: 0) - 0.5) * 2
let midTurb  = (CandleNoise.fbm(t * cfg.turbFreq, seed: 1) - 0.5) * 2
let fastFlick = (CandleNoise.fbm(t * 9.2, seed: 2) - 0.5) * 2
let sway = slowSway * cfg.swayAmp * flameW
let flicker = fastFlick * cfg.flickerAmp
let heightMod = 1.0 - abs(flicker) * 0.22 + midTurb * 0.06
let fH = flameH * heightMod
let tipX = g.wickTipX + sway
let tipY = g.wickTip - fH
let breathe = 1.0 + midTurb * 0.06
let fWL = flameW * breathe
let fWR = flameW * breathe * 0.72
```
Then port the full `leftEdge` including the notch branch (line 70 `if cfg.hasNotch`) using `sway`/`slowSway`/`midTurb`. Apply `baseAlpha`/`glowAlpha` flicker modulation (lines 59–60) to the relevant passes from Task 4. Add the ember/tip pulse (`emberScale = 1 + sin(t·π)·0.35`, line 88) and curious smoke `sin(t·0.7)` (line 94) and experienced drip `termPulse` (line 95).

- [ ] **Step 2: Drive the preview with a `TimelineView`**

```swift
#Preview("Candles — animated") {
    TimelineView(.animation) { tl in
        let t = tl.date.timeIntervalSinceReferenceDate
        ZStack {
            Color.black
            HStack(spacing: AppSpacing.sm) {
                ForEach(CandleIntensity.ordered, id: \.self) { i in
                    CandleCardFace(intensity: i, time: t)
                        .frame(width: 118, height: 118 * 1.5)
                }
            }
        }.ignoresSafeArea()
    }
}
```

- [ ] **Step 3: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: 🧍 HUMAN CHECKPOINT — flame motion on device**

Run the animated preview on device/sim next to the mockup loop. Curious wavers weakly with a smoke wisp; exploring is a steady burn; experienced burns tall with a notch and pulsing drip. Motion matches the mockup feel, no stutter. Bryan confirms.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift
git commit -m "feat(ExperienceLevel): living flame — fbm sway/flicker/breathe + pulses"
```

---

## Task 6: Reduce Motion fallback

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift`

- [ ] **Step 1: Freeze motion when `reduceMotion`**

At the top of `CandleRenderer.draw`, clamp the time used for motion:
```swift
let t = reduceMotion ? 0.0 : time   // representative static frame
```
Pass `t` (not `time`) into `flameEdges` and all pulse calculations. With `t = 0`, sway/flicker/breathe are 0 and the candle renders a calm representative frame. Ensure the curious scale pulse (added below) is also disabled.

- [ ] **Step 2: Add the curious ambient scale pulse, motion-gated**

Wrap the curious flame in the `0.88 → 1.0` pulse only when not reduced. In `CandleCardFace.body`, apply a `scaleEffect` driven by an `.ambientAnimation()`-wrapped state ONLY for `.curious` and only when `!reduceMotion`. (Per CLAUDE.md `.ambientAnimation()` is required on looping animations.) When `reduceMotion`, scale is fixed at 1.0.

- [ ] **Step 3: Add a Reduce-Motion preview**

```swift
#Preview("Candles — reduce motion") {
    ZStack {
        Color.black
        HStack(spacing: AppSpacing.sm) {
            ForEach(CandleIntensity.ordered, id: \.self) { i in
                CandleCardFace(intensity: i, time: 5.0, reduceMotion: true)
                    .frame(width: 118, height: 118 * 1.5)
            }
        }
    }.ignoresSafeArea()
}
```

- [ ] **Step 4: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: 🧍 HUMAN CHECKPOINT — Reduce Motion on device**

Enable Settings → Accessibility → Motion → Reduce Motion on the sim/device. Candles render still and legible; no flicker, no pulse. Bryan confirms.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/CandleCardFace.swift
git commit -m "feat(ExperienceLevel): Reduce Motion fallback for candle"
```

---

## Task 7: Wire candle into card shell + static row on the real phase

**Files:**
- Modify: `Vayl/Design/Components/Cards/VaylCardContent.swift`
- Modify: `Vayl/Design/Components/Cards/VaylCardFace.swift`
- Create: `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift`
- Rewrite: `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`

- [ ] **Step 1: Add the `.candle` content case**

In `VaylCardContent.swift`, add to the enum:
```swift
/// Experience-level candle face. `time` is the shared flame clock from the phase.
case candle(intensity: CandleIntensity, time: Double)
```

- [ ] **Step 2: Route the case in `VaylCardFace`**

In `VaylCardFace.swift`, in the `content` switch (the block starting ~line 64), add:
```swift
case .candle(let intensity, let time):
    CandleCardFace(intensity: intensity, time: time)
```

- [ ] **Step 3: Create the controller skeleton**

Create `CardPhysics/CardThreeMonte.swift` with the state shape from the spec, starting in `.faceUp` with cards at the canonical row (deal/shuffle/flip added in Tasks 9–11):
```swift
import SwiftUI

enum ThreeMonteState: Equatable {
    case idle, dealing, organizing, shuffling, revealing, faceUp
    case lifted(CandleIntensity), confirming(CandleIntensity), done(CandleIntensity)
}

@Observable
@MainActor
final class CardThreeMonteController {
    var state: ThreeMonteState = .idle

    var offsets:    [CGSize] = [.zero, .zero, .zero]
    var angles:     [Double] = [0, 0, 0]
    var scales:     [Double] = [1, 1, 1]
    var alphas:     [Double] = [1, 1, 1]
    var flipScaleX: [Double] = [1, 1, 1]
    var showFace:   [Bool]   = [true, true, true]   // Task 9 starts these false
    var elevations: [Double] = [0, 0, 0]
    var zIndices:   [Double] = [0, 1, 2]
    var confirmHapticTrigger = false

    /// Slot index → intensity (ordered L→R).
    let intensities = CandleIntensity.ordered

    private var dealTask: Task<Void, Never>?

    /// Lay the three cards directly in the clean row, face-up. (Pre-deal placeholder
    /// for Task 7; Tasks 8–11 replace this with deal→organize→shuffle→reveal.)
    func placeStaticRow(screenSize: CGSize) {
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            offsets[i] = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            showFace[i] = true
        }
        state = .faceUp
    }

    func cancel() { dealTask?.cancel() }
}
```

- [ ] **Step 4: Rewrite `ExperienceLevelPhase` to render the row + own the flame clock**

Replace the file body:
```swift
import SwiftUI

struct ExperienceLevelPhase: View {
    let director:   VaylDirector
    let screenSize: CGSize

    @State private var monte = CardThreeMonteController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardW: CGFloat { AppLayout.obTableCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { cardW * 1.5 }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()

            TimelineView(.animation) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ForEach(0..<3, id: \.self) { i in
                    VaylCardFace(content: .candle(intensity: monte.intensities[i], time: t))
                        .frame(width: cardW, height: cardH)
                        .scaleEffect(monte.scales[i])
                        .rotationEffect(.degrees(monte.angles[i]))
                        .offset(monte.offsets[i])
                        .opacity(monte.alphas[i])
                        .zIndex(monte.zIndices[i])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { monte.placeStaticRow(screenSize: screenSize) }
        .onDisappear { monte.cancel() }
        .accessibilityLabel("Experience level phase")
    }
}
```

- [ ] **Step 5: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: 🧍 HUMAN CHECKPOINT — row on the real phase**

Navigate OB to ExperienceLevelPhase on the sim/device. Three live candle cards sit in a clean row at table size at the canonical centers, ordered Curious | Exploring | Experienced. Tune `AppSpacing.sm` gap feel if needed. Bryan confirms.

- [ ] **Step 7: Commit**

```bash
git add Vayl/Design/Components/Cards/VaylCardContent.swift Vayl/Design/Components/Cards/VaylCardFace.swift Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift
git commit -m "feat(ExperienceLevel): candle card shell + static Monte row on phase"
```

---

## Task 8: Pick + confirm (functional screen, end-to-end)

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift`
- Modify: `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`
- Modify: `Vayl/Features/Onboarding/Canvas/VaylDirector.swift`

This makes the screen fully functional before the spectacle: tap to lift, swipe up to confirm, write `nmStage`, advance. Deal/shuffle/reveal come after.

- [ ] **Step 1: Add `lift` and `confirm` to the controller**

```swift
func lift(_ intensity: CandleIntensity, screenSize: CGSize) {
    guard case .faceUp = state else {
        if case .lifted = state {} else { return }
    }
    state = .lifted(intensity)
    let liftY = screenSize.height * 0.42 - screenSize.height / 2
    let centers = AppLayout.monteRowCenters(in: screenSize.width)
    for i in 0..<3 {
        if intensities[i] == intensity {
            offsets[i] = CGSize(width: 0, height: liftY)
            scales[i]  = AppLayout.obTableCardCinematicScale
            angles[i]  = 0
            alphas[i]  = 1
            zIndices[i] = 99            // lifted card above all (the z-exception)
        } else {
            let restY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
            offsets[i] = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            scales[i]  = 0.92
            alphas[i]  = 0.30
            zIndices[i] = Double(i)     // deal-order z resumes
        }
    }
}

func confirm(_ intensity: CandleIntensity, screenSize: CGSize,
             onConfirm: @escaping (CandleIntensity) -> Void) {
    guard case .lifted(let held) = state, held == intensity else { return }
    state = .confirming(intensity)
    confirmHapticTrigger.toggle()
    dealTask = Task { @MainActor in
        // Pocket the lifted card to the corner deck (reuse AppLayout corner geometry).
        let cornerX = screenSize.width - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth / 2
        let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
        if let idx = intensities.firstIndex(of: intensity) {
            withAnimation(AppAnimation.cardPocket) {
                offsets[idx] = CGSize(width: cornerX - screenSize.width / 2,
                                      height: cornerY - screenSize.height / 2)
                scales[idx]  = AppLayout.cornerDeckWidth / AppLayout.obTableCardWidth(in: screenSize.width)
                alphas[idx]  = 0
            }
        }
        try? await Task.sleep(for: .milliseconds(520))
        guard !Task.isCancelled else { return }
        state = .done(intensity)
        onConfirm(intensity)
    }
}
```

- [ ] **Step 2: Add the director hook**

In `VaylDirector.swift`, replace the empty stub at line 197:
```swift
private func runExperienceLevelEntry() {}
```
with:
```swift
private func runExperienceLevelEntry() {
    // Controller is View-owned (@State in ExperienceLevelPhase); nothing to reset here yet.
    // Selection is committed via commitExperienceLevel(_:) below.
}

/// Called by ExperienceLevelPhase on confirm. Writes nmStage and advances.
func commitExperienceLevel(_ intensity: CandleIntensity) {
    onboardingData.nmStage = intensity.nmStage
    advance(to: .context)
}
```

- [ ] **Step 3: Wire taps + swipe + haptics in the phase**

In `ExperienceLevelPhase`, add a tap gesture per card (lift) and a swipe-up gesture on the lifted card (confirm), plus the press/haptic trinity (CLAUDE.md). Add to each card view:
```swift
.onTapGesture { monte.lift(monte.intensities[i], screenSize: screenSize) }
.gesture(
    DragGesture().onEnded { v in
        if case .lifted(let held) = monte.state,
           held == monte.intensities[i],
           v.translation.height < -55, abs(v.translation.width) < 80 {
            monte.confirm(held, screenSize: screenSize) { director.commitExperienceLevel($0) }
        }
    }
)
.sensoryFeedback(.selection, trigger: monte.state)
.sensoryFeedback(.impact(weight: .medium), trigger: monte.confirmHapticTrigger)
```
Wrap state mutations in `withAnimation(AppAnimation.standard)` where the lift should animate (mirror CardMirrorDeal: animate at the View layer).

- [ ] **Step 4: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: 🧍 HUMAN CHECKPOINT — end-to-end on device**

On device/sim: tap a candle → it lifts to cinematic size, others dim/fold; swipe up → it pockets to the corner deck and the phase advances to ContextPhase. Re-run OB and confirm `nmStage` persisted correctly for each of the three picks. Bryan confirms. **The screen is now fully functional; Tasks 9–11 are spectacle.**

- [ ] **Step 6: Commit**

```bash
git add Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift Vayl/Features/Onboarding/Canvas/VaylDirector.swift
git commit -m "feat(ExperienceLevel): pick + confirm + advance — functional screen"
```

---

## Task 9: Reveal flip

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift`
- Modify: `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`

- [ ] **Step 1: Start cards face-down; add `reveal()`**

Change the controller defaults to face-down (`showFace = [false, false, false]`, `flipScaleX = [1,1,1]`). Add a flip that reveals in succession, ordered L→R (mirror CardMirrorDeal's flip, lines 140–151):
```swift
func reveal() async {
    state = .revealing
    for i in 0..<3 {                       // left → right succession
        withAnimation(AppAnimation.cardFlip) { flipScaleX[i] = 0.0 }
        try? await Task.sleep(for: .milliseconds(160))
        showFace[i] = true                 // identity assigned here
        withAnimation(AppAnimation.cardFlip) { flipScaleX[i] = 1.0 }
        try? await Task.sleep(for: .milliseconds(140))
    }
    state = .faceUp
}
```
Apply `flipScaleX[i]` as a horizontal `scaleEffect(x:)` on each card in the phase, and render the card back (face-down) when `!showFace[i]`. Use the existing OB card-back face for the down state (match what GenderPhase/CardMirrorDeal show for a face-down card).

- [ ] **Step 2: Replace `placeStaticRow` call with a face-down place + reveal**

In the controller add `placeRowFaceDown(screenSize:)` (same positions, `showFace=false`). In the phase `.onAppear`, call it then `Task { await monte.reveal() }`.

- [ ] **Step 3: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: 🧍 HUMAN CHECKPOINT — flip feel**

Cards start face-down in the clean row, then flip up one-by-one L→R revealing Curious → Exploring → Experienced. Timing feels good; lift/confirm from Task 8 still works after reveal. Bryan confirms.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift
git commit -m "feat(ExperienceLevel): succession flip reveal, ordered L→R"
```

---

## Task 10: Deal-in via CardFlightScene

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift`
- Modify: `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`

- [ ] **Step 1: Add `deal()` using a `CardFlightScene`**

The controller holds a `CardFlightScene` and flies three face-down backs from the dealer point to the row, with `zPosition = dealIndex`. On each `onCardRested`, settle that card's SwiftUI transform; when all three rest, transition `.dealing → .organizing`. Pattern (mirror `VaylDirector.dealCards` / `CardFlightScene.dealCard`):
```swift
let flightScene = CardFlightScene()

func deal(screenSize: CGSize, backImage: UIImage) async {
    state = .dealing
    let centers = AppLayout.monteRowCenters(in: screenSize.width)
    let restYAbs = AppLayout.obTableCardCenterY(in: screenSize.height)
    let dealer = CGPoint(x: screenSize.width / 2, y: AppLayout.dealPointY(in: screenSize.height))
    var rested = 0
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        for i in 0..<3 {
            let id = "monte-\(i)"
            flightScene.onCardRested[id] = { [weak self] _, _, _ in
                guard let self else { return }
                rested += 1
                if rested == 3 { cont.resume() }
            }
            flightScene.dealCard(
                id: id, image: backImage,
                from: dealer,
                to: CGPoint(x: centers[i], y: restYAbs),
                zPosition: CGFloat(i),            // deal-order stacking
                duration: 0.55)
        }
    }
    state = .organizing
}
```
> NOTE: confirm the exact dealer-point helper name in `AppLayout` (the spec references `dealPointYFrac(.32)`); use whatever `VaylDirector.dealCards` already uses for the OB deal origin so the deal matches the rest of onboarding.

- [ ] **Step 2: Host the `CardFlightScene` in the phase**

Add a `SpriteView(scene: monte.flightScene)` layer behind the SwiftUI cards (transparent background), shown during `.dealing`/`.organizing`/`.shuffling`, hidden once `.revealing`/`.faceUp` (SwiftUI live cards take over). Snapshot the card back via the existing `VaylDirector.snapshotCardBack(screenSize:)`-style helper for `backImage`.

- [ ] **Step 3: Sequence on appear** — `.onAppear`: `Task { await monte.deal(...); await monte.organize(...); await monte.reveal() }` (organize is Task 11; for this task, after deal call `reveal()` directly to verify the deal in isolation).

- [ ] **Step 4: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: 🧍 HUMAN CHECKPOINT — deal feel**

Three card-backs fly in from the dealer point to the row with the two-phase flight physics; the 1st-dealt stays underneath where they overlap. Hand-off to the SwiftUI flip is seamless. Bryan confirms.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift
git commit -m "feat(ExperienceLevel): deal-in via CardFlightScene, deal-order z"
```

---

## Task 11: Organize + lift-and-toss shuffle

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift`
- Modify: `Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift`

- [ ] **Step 1: Add `organize()`** — animate all three from their post-deal positions to exact `monteRowCenters` slots, upright (angle 0), even spacing — the clean row from the reference image. `withAnimation(AppAnimation.standard)`, ~0.4s. Sets `state = .shuffling` when done? No — leaves `.organizing`; shuffle is called next.

- [ ] **Step 2: Add `shuffle()` — lift-and-toss, 3–4s**

Several position swaps between the three `monteRowCenters` slots. Each swap: the moving card's `elevation` ramps `0→1→0` (drives scale bump ~1.0→1.06 and `AppElevation.cardShadow`), travels a shallow **arc** (animate offset via an intermediate raised control point or a keyframe), respecting the permanent `zIndices` for over/under. Pure theatre — track only *positions*, not identity.
```swift
func shuffle(screenSize: CGSize) async {
    state = .shuffling
    let centers = AppLayout.monteRowCenters(in: screenSize.width)
    let restY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
    // slotOfCard[i] = which row slot card i currently occupies
    var slotOf = [0, 1, 2]
    let swaps: [(Int, Int)] = [(0,1),(1,2),(0,2),(1,2),(0,1)]   // tune count/pairs on-device
    for (a, b) in swaps {
        let ia = slotOf.firstIndex(of: a)!, ib = slotOf.firstIndex(of: b)!
        // lift both, arc-cross, drop — elevation 0→1→0 with scale bump
        withAnimation(.easeInOut(duration: 0.34)) {
            elevations[ia] = 1; elevations[ib] = 1
            scales[ia] = 1.06; scales[ib] = 1.06
            offsets[ia] = CGSize(width: centers[b] - screenSize.width/2, height: restY)
            offsets[ib] = CGSize(width: centers[a] - screenSize.width/2, height: restY)
        }
        try? await Task.sleep(for: .milliseconds(340))
        withAnimation(.easeOut(duration: 0.14)) {
            elevations[ia] = 0; elevations[ib] = 0
            scales[ia] = 1; scales[ib] = 1
        }
        slotOf.swapAt(ia, ib)
        try? await Task.sleep(for: .milliseconds(120))
    }
    // restore canonical order positions before reveal
    withAnimation(AppAnimation.standard) {
        for i in 0..<3 { offsets[i] = CGSize(width: centers[i] - screenSize.width/2, height: restY) }
    }
    try? await Task.sleep(for: .milliseconds(300))
}
```
Apply `elevations[i]` in the phase as `AppElevation.cardShadow(elevation:)` shadow + the scale bump (already via `scales`). For the arc, if a straight tween reads flat, add a vertical lift to the offset midpoint via `.keyframeAnimator` (tune on-device).

- [ ] **Step 3: Full sequence on appear** — `.onAppear`: `Task { await monte.deal(...); await monte.organize(...); await monte.shuffle(screenSize:); await monte.reveal() }`.

- [ ] **Step 4: Reduce Motion branch** — when `reduceMotion`, skip `shuffle`'s swaps: place directly into the clean row (short fade) and go straight to `reveal`. Guard inside the sequence.

- [ ] **Step 5: Build** — run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: 🧍 HUMAN CHECKPOINT — full Monte feel**

Full sequence on device: deal → cards tidy into the clean row → 3–4s lift-and-toss shuffle (cards lift, arc, drop, over/under correct) → flip reveal ordered → pick → confirm → advance. Tune swap count, lift height, arc curvature, durations until it feels like a real monte. Verify Reduce Motion path skips the theatre cleanly. Bryan confirms. **Feel is correct is done.**

- [ ] **Step 7: Commit**

```bash
git add Vayl/Design/Components/Cards/CardPhysics/CardThreeMonte.swift Vayl/Features/Onboarding/Phases/ExperienceLevelPhase.swift
git commit -m "feat(ExperienceLevel): organize + lift-and-toss shuffle"
```

---

## Task 12: Performance pass + Metal gate decision

**Files:** none unless profiling fails.

- [ ] **Step 1: Profile on a real device**

Build to a physical device. Open Instruments → Core Animation / SwiftUI. Capture the **post-reveal three-flame steady state** (worst case — three live `Canvas` flames) and the lift transition.

- [ ] **Step 2: Read the gate**

- Holds 60fps (120 on ProMotion): **done — stay in pure SwiftUI `Canvas`.** Record the result in the commit message. No code change.
- Drops frames: move **only** the blurred glow pass of `CandleCardFace` to a Metal `.layerEffect` shader (precedent: `HolographicShimmer.metal`, `VaylBorderEffect`), keep all vector geometry in `Canvas`. This becomes its own sub-plan — do not pre-optimize.

- [ ] **Step 3: 🧍 HUMAN CHECKPOINT — performance sign-off**

Bryan confirms the phase holds frame rate on-device, or approves opening a Metal sub-plan.

- [ ] **Step 4: Commit (result note, if no code change)**

```bash
git commit --allow-empty -m "perf(ExperienceLevel): profiled — three-flame steady state holds 60/120fps on device"
```

---

## Self-Review

**Spec coverage:**
- §1 Scale → Task 1 (geometry) + Task 7 (row at table size) + Task 8 (cinematic lift). ✓
- §2 CandleCardFace (v12 verbatim) → Tasks 3–6. ✓
- §3 Controller / engine boundary / z-invariant / identity-at-reveal / row frame → Tasks 1, 7, 9, 10, 11. ✓
- §3 flame clock in View → Task 7. ✓
- §3 director touch points → Task 8. ✓
- §4 Build segments 1–9 → Tasks 3–11 (1:1). ✓
- §5 Reduce Motion → Tasks 6, 11; performance gate → Task 12. ✓
- Architecture contracts (VaylCardFace shell, .drawingGroup, advance-only gate, no raw values) → Tasks 3, 7, 8. ✓

**Placeholder scan:** Candle path-port steps in Task 4 reference exact mockup line numbers rather than re-transcribing ~50 lines of bezier soup — the mockup is the literal source and is committed in-repo; the API translation guide makes each a mechanical translation. Pure-math functions (noise, fbm, getGeo, taperedRun) and all structural code are written in full. Two NOTE callouts (dealer-point helper name, arc keyframe) flag on-device confirmation points, not missing logic.

**Type consistency:** `CandleIntensity` (Task 2) used consistently in `VaylCardContent.candle`, `CandleCardFace`, `CardThreeMonteController.intensities`, `commitExperienceLevel`. `ThreeMonteState` cases consistent across Tasks 7–11. `monteRowCenters` signature consistent (Tasks 1, 7, 8, 11). `flipScaleX`/`showFace`/`elevations`/`zIndices` array fields consistent Tasks 7→11.

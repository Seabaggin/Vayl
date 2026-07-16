# PostHog Self-driving setup report

PostHog Self-driving is now configured for Vayl. Error tracking, session replay, and conversations sources are wired to the inbox, and the scout troop is tuned to watch Vayl's product-analytics funnel and revenue/purchase surface. Findings will start appearing in the [Self-driving inbox](https://us.posthog.com/project/512827/inbox) within ~30 minutes of the first scout coordinator tick.

---

## AI data processing

**Approved.** Organization-level AI data processing consent was granted before this run started.

---

## GitHub

**Already connected** — GitHub account "Seabaggin" was connected to the PostHog project before this run (id: 185570, connected 2026-07-15). No action needed. Self-driving can research and open fixes against this repo's code.

---

## Products enabled

`products-enable` is not available in the current MCP version. Since Vayl is a native iOS app (not `posthog-js`), the server-side product toggle is inert regardless — product capture is controlled by the iOS SDK config directly.

| Product | Status | Notes |
|---|---|---|
| Error Tracking | **Enabled (SDK)** | `errorTrackingConfig.autoCapture = true` is already set in `PostHogService.swift:27`. Exceptions are being captured. |
| Session Replay | **Inert — SDK config needed** | The iOS SDK supports session replay but it requires explicit opt-in in the SDK config. Not yet configured in `PostHogService.swift`. |
| Support (Conversations) | **Enabled (source armed)** | The `conversations / ticket` signal source is wired. Tickets only reach the inbox once an inbound channel (email / inbox / Slack) is connected in PostHog Settings. |

---

## Signal sources

| source\_product | source\_type | Action | Notes |
|---|---|---|---|
| `signals_scout` | `cross_source_issue` | **On by default** | Scout gate is always-on; no config row needed. |
| `error_tracking` | `issue_created` | **Enabled** | id: `019f63ad-45cc-72b9-9f3e-c25cc011bfe0` |
| `error_tracking` | `issue_reopened` | **Enabled** | id: `019f63ad-4823-7371-8c50-c9bd6fd80af1` |
| `error_tracking` | `issue_spiking` | **Enabled** | id: `019f63ad-4c0d-7e28-a2b8-10168310f9b2` |
| `session_replay` | `session_analysis_cluster` | **Enabled** | id: `019f63ad-4fcf-7735-9296-4b5d782a71ab` — armed now; will activate once session replay is configured in the iOS SDK. |
| `conversations` | `ticket` | **Enabled** | id: `019f63ad-51f7-723e-b04f-aa46fa1b3b24` — dormant until an inbound channel is connected. |
| `llm_analytics` | `*` | **Skipped** | Internal-only; no LLM usage in this project. |
| `logs` | `*` | **Skipped** | Not a v1 responder; PostHog logs product not in use. |

---

## Connected tools

| Tool | Status |
|---|---|
| GitHub Issues | Not used (not selected) |
| Linear | Not used (not selected) |
| Zendesk | Not used (not selected) |
| pganalyze | Not used (not selected) |

---

## Scout troop

**Enabled (3):**

| Scout | Reason |
|---|---|
| `signals-scout-general` | Always on — cross-product correlations and surfaces no specialist covers. Was already enabled at sync. |
| `signals-scout-product-analytics` | Enabled — Vayl has rich user journey funnels (auth, onboarding→pairing, session lifecycle) with 5 saved insights. Watches for conversion/retention regressions in those saved flows. |
| `signals-scout-revenue-analytics` | Enabled — StoreKit monetization is a key surface (`purchase_completed`, `EntitlementStore`). Watches for purchase capture regressions and goal-miss escalations. |

**Disabled (23):**

| Scout | Reason |
|---|---|
| `signals-scout-error-tracking` | Covered by native `error_tracking` sources (3 rows in step 4). Intentional — not a re-enable follow-up. |
| `signals-scout-session-replay` | Covered by native `session_replay` source. Intentional — not a re-enable follow-up. |
| `signals-scout-ai-observability` | No `$ai_*` events or LLM usage in this project. |
| `signals-scout-anomaly-detection` | No dashboards with significant data yet; not a priority at this stage. Enable later if needed. |
| `signals-scout-apm` | No distributed tracing (OpenTelemetry) in this iOS app. |
| `signals-scout-csp-violations` | Native iOS app — no Content Security Policy applies. |
| `signals-scout-customer-analytics` | Consumer B2C app (couples), not a B2B/accounts product. |
| `signals-scout-data-pipelines` | No CDP destinations, batch exports, or hog flows configured. |
| `signals-scout-data-warehouse` | No external warehouse sources connected. |
| `signals-scout-experiments` | No active A/B experiments in this project. Enable if experiments are added. |
| `signals-scout-feature-flags` | No feature flags in active use. Enable if flags are introduced. |
| `signals-scout-health-checks` | Low priority at initial setup; enable later for PostHog setup health. |
| `signals-scout-inbox-validation` | Fresh setup — no shipped fixes to validate yet. |
| `signals-scout-ingestion-warnings` | Low priority; enable if ingestion anomalies are suspected. |
| `signals-scout-insight-alerts` | No configured insight alerts yet. |
| `signals-scout-logs` | PostHog logs product not in use. Enable if logs are added. |
| `signals-scout-mcp-tool-calls` | No MCP tool call telemetry from this app. |
| `signals-scout-observability-gaps` | Could be useful once more data lands; enable after initial events stabilize. |
| `signals-scout-replay-vision` | No Replay Vision scanners configured. |
| `signals-scout-skills-store` | Skill hygiene — not a priority at initial setup. |
| `signals-scout-surveys` | No surveys in use (0 surveys found at setup time). Enable if surveys are launched. |
| `signals-scout-web-analytics` | Native iOS app — no web traffic or pageviews. |
| `signals-scout-web-vitals` | Native iOS app — no Core Web Vitals. |

---

## Custom scouts

**Proposed (1), declined (1):**

**Couple activation scout** (`signals-scout-vayl-couple-activation`) was proposed but declined.

- **Surface**: The transition from `pairing_join_succeeded` → `session_started` within 7 days — the dyadic activation window unique to Vayl's couples product.
- **Why uncovered**: No saved funnel spans this transition (the saved "Onboarding to pairing funnel" stops at pairing; "Session lifecycle" starts at session invite). Product-analytics scout only watches saved flows.
- **Discriminator**: 7-day session activation rate for new pairs vs rolling 30-day average.

**Considered and ruled out:**

| Surface | Filter that killed it |
|---|---|
| Auth flow regression | Covered — saved "Auth sign-in attempts" insight means product-analytics monitors it. |
| Pairing invite → join drop-off | Covered — saved "Pairing outcomes" insight; product-analytics covers the funnel. |
| Session completion vs abandonment | Covered — saved "Session lifecycle" insight; product-analytics covers it. |
| Purchase conversion health | Covered — revenue-analytics watches `purchase_completed` capture regressions. |
| Ingestion / SDK health | Better covered by `signals-scout-ingestion-warnings` or `signals-scout-health-checks` (both can be enabled later if needed). |

**Noise escape hatch:** If any scout turns out noisy, set `emit: false` on its config in PostHog → Self-driving → Scouts. This switches it to dry-run (runs and logs, emits nothing to the inbox) without disabling it entirely.

---

## Follow-ups

- [ ] **Enable session replay on iOS**: Add `config.sessionReplayConfig.enabled = true` (and any desired masking rules) in `PostHogService.swift` to enable mobile session recording. The signal source is already armed and will activate once recordings arrive.
- [ ] **Connect a Support channel**: In PostHog → Settings → Conversations, connect an inbound channel (email, inbox, or Slack) so support tickets route to the Self-driving inbox. The `conversations / ticket` source is already enabled and waiting.
- [ ] **Enable `products-enable` via project admin**: The `products-enable` MCP tool was unavailable in this run. Confirm Session Replay and Error Tracking are toggled ON in PostHog → Settings → Recordings and Error Tracking respectively (they may already be on from prior configuration).

---

## What happens next

The scout coordinator picks up the new configs on its next tick (within ~30 minutes). Scouts run on a 24-hour interval by default and file findings as reports in the [Self-driving inbox](https://us.posthog.com/project/512827/inbox). Error tracking issues surface immediately as they're created (the native source responds in real time). Anomaly and funnel-regression reports from the scouts will appear after the first full run — typically within the first day.

# PostHog post-wizard report

The wizard completed a SwiftUI PostHog integration for Vayl by adding the PostHog iOS SDK through Swift Package Manager in the Xcode project, initializing the SDK at app launch through a shared `PostHogService`, wiring host and token through environment-backed Info.plist values, and instrumenting key product events across authentication, onboarding, pairing, sessions, reflections, and purchases. The run also created a PostHog dashboard and five saved insights for the implemented events.

| Event name | Description | File |
| --- | --- | --- |
| `auth_sign_in_started` | Tracks when a user starts the Sign in with Apple flow. | `Vayl/Core/Services/AuthService.swift` |
| `auth_sign_in_succeeded` | Tracks when authentication succeeds and a user session is established. | `Vayl/Core/Services/AuthService.swift` |
| `auth_sign_in_failed` | Tracks when authentication fails before a user session is established. | `Vayl/Core/Services/AuthService.swift` |
| `auth_signed_out` | Tracks when a signed-in user logs out and their analytics state resets. | `Vayl/Core/Services/AuthService.swift` |
| `onboarding_completed` | Tracks when onboarding is successfully committed and the user reaches the app experience. | `Vayl/Features/Onboarding/Store/OnboardingStore.swift` |
| `pairing_invite_generated` | Tracks when a user creates a pairing invite code for their partner. | `Vayl/Features/Settings/Pairing/PairingStore.swift` |
| `pairing_join_succeeded` | Tracks when a user successfully joins a partner with a pairing code. | `Vayl/Features/Settings/Pairing/PairingStore.swift` |
| `session_invite_accepted` | Tracks when a pending couple session invite is accepted from the banner. | `Vayl/Features/Play/Sessions/Store/SessionEntryStore.swift` |
| `session_started` | Tracks when a couple session actually begins after the intro transition completes. | `Vayl/Features/Play/Sessions/Store/CoupleSessionStore.swift` |
| `session_completed` | Tracks when a couple session is finished and persisted. | `Vayl/Features/Play/Sessions/Store/CoupleSessionStore.swift` |
| `session_reflection_saved` | Tracks when a user saves a reflection after a completed session. | `Vayl/Features/Play/Sessions/Store/CoupleSessionStore.swift` |
| `purchase_completed` | Tracks when a StoreKit purchase completes successfully for the core entitlement. | `Vayl/Core/Services/StoreKitService.swift` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- [Analytics basics (wizard)](https://us.posthog.com/project/512827/dashboard/1850081)
- [Auth sign-in attempts (wizard)](https://us.posthog.com/project/512827/insights/YIu6riB9)
- [Onboarding to pairing funnel (wizard)](https://us.posthog.com/project/512827/insights/nHU3liDq)
- [Session lifecycle (wizard)](https://us.posthog.com/project/512827/insights/XyvCSa2G)
- [Pairing outcomes (wizard)](https://us.posthog.com/project/512827/insights/VCytibDi)
- [Purchase completions (wizard)](https://us.posthog.com/project/512827/insights/T40GtvHR)

## Verify before merging

- [ ] Run a full production build (the wizard only verified the files it touched) and fix any lint or type errors introduced by the generated code.
- [ ] Run the test suite — call sites that were rewritten or instrumented may need updated mocks or fixtures.
- [ ] Add the exact PostHog env var names you added to `.env.example` and any monorepo/bootstrap scripts so collaborators know what to set.
- [ ] Confirm the returning-visitor path also calls `identify` — a handler that only identifies on fresh login can leave returning sessions on anonymous distinct IDs.

### Agent skill

We've left an agent skill folder in your project. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

# Open Lightly — Vibe Coding Prompts & Audit Guide

> **Purpose:** Copy-paste prompts for safe AI-assisted development, twice-weekly codebase audits, and a curriculum for what to self-study. This file assumes you're using Claude Code or a similar AI assistant to build the app.

---

## Part 1 — Safe Prompting: The Master Safety Prefix

Paste this at the TOP of any message where you ask Claude to write real feature code. It activates professional-grade defaults that AI skips without being asked.

---

### The Master Prefix (copy this every time)

```
Before writing any code, confirm:
1. Every async/network operation has a do/catch with a user-visible error state
2. No user data is logged with print() — use OSLog only
3. Any new SwiftData model property is optional OR has a default value (migration safety)
4. All UI state mutations go through @MainActor
5. No force-unwrap (!) on anything that could realistically be nil in production

This app stores sexual preferences and intimate conversation data. Privacy is non-negotiable:
- Hard No kink ratings NEVER leave the device and NEVER appear in any payload
- Assessment raw answers NEVER sync to Supabase
- Safe word usage is NEVER logged anywhere

Now write the code.
```

---

## Part 2 — Feature-Specific Safe Prompts

Use the relevant prompt when building a specific part of the app. These replace the master prefix — they're already more specific.

---

### Any Supabase / Network Feature

```
Write [DESCRIBE FEATURE] for the Open Lightly iOS app.

Stack: SwiftUI (iOS 26), SwiftData (local-first), Supabase (free tier), Sign in with Apple.

Requirements:
- All Supabase calls wrapped in do/catch — show a user-facing error state on failure, never crash silently
- UI mutations on @MainActor only
- Show a loading state while the request is in flight
- Show a meaningful empty state if the result is empty (not a blank screen)
- No print() — use Logger(subsystem: "com.openlightly.app", category: "[FEATURE]")
- No hardcoded Supabase URLs or keys — read from Config.swift (which reads from Info.plist / xcconfig)
- If this touches kink ratings or assessment answers, those fields NEVER appear in any Supabase write

Privacy context:
- kinkRatings where rating == .hardNo → local SwiftData only, never in any payload
- assessmentResponses → local SwiftData only, never in any payload
- Only aggregated scores and positive kink matches go to Supabase

Show the complete Swift file(s), including error handling and all state management.
```

---

### Any New SwiftData Model or Model Change

```
I need to [ADD / MODIFY / RENAME] a SwiftData model in the Open Lightly app.

Before writing anything, tell me:
1. Is this change purely additive (new optional property with default)? If yes, is a migration needed?
2. If the change is a rename, type change, or non-optional addition — write the full SchemaMigrationPlan

Then write:
- The updated @Model class with all properties typed correctly
- A migration plan if needed (VersionedSchema + MigrationStage)
- A comment on any property that holds sensitive data explaining what CAN and CANNOT be synced

Current models that hold sensitive data:
- UserProfile.kinkRatings → encrypted, hardNo never leaves device
- UserProfile.assessmentResponses → encrypted, never leaves device

Show me how to test that a fresh install AND an upgrade from the previous version both work.
```

---

### Any Session / Card Flow Feature

```
Write the [SESSION / CARD] feature for Open Lightly.

Card action model:
- "We Discussed This" → CardStatus.discussed (primary CTA, gradient button)
- "Not Ready" → CardStatus.skipped (secondary, no shame copy)
- "Bookmark" → CardStatus.bookmarked (icon button)
- Safe Word button always visible, gold color only, never hidden

Requirements:
- Card state persists to SwiftData immediately on tap (don't wait for Supabase sync)
- Supabase sync happens in background via SyncManager — queued if offline
- If offline, show subtle "Sync pending" indicator, not an error modal
- Session summary shows: discussed count, skipped count ("no pressure"), bookmarked count ("saved for later")
- No CardStatus.thumbsUp / thumbsDown — those enums are removed

Privacy: Session notes are SwiftData only, never synced. Card statuses (discussed/skipped/bookmarked) CAN sync.
```

---

### Any Authentication / Pairing Feature

```
Write [AUTH / PAIRING] for Open Lightly.

Auth flow: Sign in with Apple → Supabase Auth (JWT stored in Keychain, never UserDefaults)

Pairing architecture (individual-first, Feeld model):
- Each user has their own UserProfile — pairing is additive, not destructive
- Pairing creates a Couple record linking two UserProfile IDs
- Deleting a Couple does NOT delete UserProfiles
- Pairing code format: WORD (from fixed word bank) + 2-digit number, expires 24 hours
- Three methods: QR code (primary), verbal code, share link

Requirements:
- Supabase Realtime listener for pairing confirmation — show "Partner joined!" without polling
- If pairing times out (>30 seconds), show retry option, not a spinner forever
- Auth tokens: Keychain only, never UserDefaults, never logged
- Pairing codes: ephemeral, Supabase only, never stored locally after use

RLS reminder: The couples table and kink_ratings table have RLS — test that a user can only see their own data after pairing.
```

---

### Any StoreKit / Entitlement Feature

```
Write [PURCHASE / ENTITLEMENT] feature for Open Lightly using StoreKit 2.

Product IDs:
- com.openlightly.core ($14.99 one-time)
- com.openlightly.communication ($9.99 one-time)
- com.openlightly.education ($9.99 one-time)
- com.openlightly.scenarios ($14.99 one-time)
- com.openlightly.bundle ($34.99 one-time)
- com.openlightly.aicoach (monthly subscription)

Requirements:
- Entitlement check must be server-verifiable (use Transaction.currentEntitlements, not just a local Bool)
- Restore purchases must work on a fresh install — test this explicitly
- Gating: if user lacks entitlement, show upgrade prompt, not a crash or silent failure
- Handle interrupted purchases (network drop mid-transaction) gracefully
- Never gate the free tier features: onboarding, 3 prompts, assessment preview, desire map teaser
- All purchases via StoreKit 2 only — no Stripe, no PayPal, no web checkout

Show the entitlement check as a reusable function that all gated views can call.
```

---

### Any AI / Drop Box Feature

```
Write [DROP BOX / AI COACH] feature for Open Lightly.

AI stack: OpenAI GPT-4o or Claude via API. Level 1 (system prompt + context injection) for launch.

Privacy rules for AI calls:
- NEVER send raw assessment answers to the API
- NEVER send kink ratings (individual) to the API
- NEVER send partner-identifying information in the same message as sensitive content
- OK to send: persona tag (solo-curious etc.), desire map domain scores (aggregated), archetype tag
- Drop Box input is anonymous — strip any identifying context before sending
- AI responses are ephemeral — not stored in Supabase

Requirements:
- Loading state while waiting for API response (these take 2-10 seconds)
- Error state if API call fails — "Couldn't connect right now, try again"
- Rate limit: cap Drop Box at 100 messages for free tier, unlimited for AI Coach subscribers
- Check entitlement before making any API call — don't burn API credits for non-subscribers
- Never log the API response content — log only: "Drop Box translation completed" (category, no data)

Show the complete API call with the system prompt, context injection, and error handling.
```

---

### Any New View or Screen

```
Write the [SCREEN NAME] SwiftUI view for Open Lightly.

Design system:
- Colors: AppColors only (no hex literals, no Color("name"))
- Fonts: AppFonts only (no Font.system, no hardcoded sizes)
- Gradient/spectrum colors: prompt cards and interactive CTAs only, not static UI
- Gold (AppColors.gold): safe word and warnings ONLY — never decorative
- Dark background: AppColors.pageBg (#030305)
- Screenshot protection (.screenshotProtected()): required on assessment, kink map, session notes, results

State requirements:
- This view needs: loading state, empty state, error state, AND content state
- If any async data is loaded: show skeleton or spinner while loading
- If the result could be empty: show a helpful empty state with a CTA, not a blank screen
- Error state: "Something went wrong" + retry button

Accessibility:
- All Image(systemName:) buttons need .accessibilityLabel()
- Decorative images: .accessibilityHidden(true)
- Scrollable content: use LazyVStack inside ScrollView, not VStack

Show the complete view file.
```

---

## Part 3 — Twice-Weekly Codebase Audits

Run one of these every Monday and Thursday. Paste the relevant prompt into Claude Code (in your project directory). These catch problems before they become user-facing bugs.

---

### Monday Audit — Security & Privacy

```
Audit the Open Lightly codebase for security and privacy issues. Check the following and report findings:

SECRETS & KEYS
1. Search for any hardcoded Supabase URLs, API keys, or tokens (not in Config.xcconfig or read from Bundle)
2. Search for any occurrence of the service role key pattern (longer JWT starting with "eyJ" hardcoded in Swift files)
3. Confirm Config.xcconfig is listed in .gitignore

LOGGING
4. Search all Swift files for `print(` — list every occurrence with file and line number
5. For each print(), flag any that include: user names, IDs, ratings, assessment data, tokens, or pairing codes
6. Confirm Logger(subsystem:category:) is used everywhere else

SENSITIVE DATA FLOWS
7. Find every place KinkRating or kinkRatings is referenced — confirm none of them build a Supabase payload that includes .hardNo ratings
8. Find every Supabase `.upsert` or `.insert` call that touches assessmentResponses — there should be zero
9. Find every place where safe word state changes — confirm there is no analytics call or logging near it

AUTHENTICATION
10. Search for any JWT or auth token stored in UserDefaults — should be zero (Keychain only)
11. Confirm Sign in with Apple is required before any Supabase query (no unauthenticated queries)

Report: list each finding with file name and line number. Flag CRITICAL (data breach risk), WARNING (bad practice), or OK.
```

---

### Thursday Audit — Code Quality & Resilience

```
Audit the Open Lightly codebase for code quality and resilience issues. Check the following:

ERROR HANDLING
1. Find every `try await` call that is NOT inside a do/catch block — list file and line
2. Find every async function that has no error state propagation to the UI
3. Find any view that loads remote data but has no error state (just a loading state and content state)
4. Find any network call with no timeout or that could hang indefinitely

THREAD SAFETY
5. Find any @Published property mutation that is NOT on @MainActor — list file and line
6. Find any ViewModel class that is missing @MainActor at the class level
7. Find any Task { } closure that captures self strongly without [weak self]

SWIFTDATA SAFETY
8. List every @Model class. For each one, flag any non-optional property WITHOUT a default value — these are migration bombs
9. Check if there is a SchemaMigrationPlan defined — if not, note that one is needed before the first model change post-launch

EMPTY STATES
10. Find every ForEach in the codebase — check if each one has a guard for the empty case
11. Find every view that uses @Query — check if the empty array case shows an EmptyStateView, not nothing

FORCE UNWRAP
12. Search for `!` used as force-unwrap (not in comments, not as `!=`) — list each occurrence and whether it could crash in production

ACCESSIBILITY
13. Find every Button that contains only an Image(systemName:) — check if it has .accessibilityLabel()
14. Find Image views that convey meaning — check if they have .accessibilityLabel()

Report: CRITICAL (crashes or data loss), WARNING (poor practice), OK. Include file and line for each finding.
```

---

## Part 4 — What to Go Learn

> These are the concepts that matter for this app specifically. You don't need to become an expert — you need to understand enough to recognize when AI code is wrong and ask better questions. Each topic has a **why it matters for Open Lightly** note.

---

### Tier 1 — Learn These Before Shipping

These are the highest-leverage concepts. A gap here = a shippable bug.

---

#### 1. Swift Concurrency (async/await, actors, MainActor)
**Why it matters:** Every Supabase call, every sync operation, every AI API call is async. Without understanding this, you can't tell if AI-generated async code is safe or a latent crash.

**What to learn:**
- What `async` and `await` mean (not how to write it — how to read it)
- What `@MainActor` does and why UI code needs it
- What a `Task` is and when `[weak self]` matters inside one
- What a data race is (two threads touching the same data)

**Best resource:** [Swift by Sundell — Async/await in Swift](https://www.swiftbysundell.com/articles/async-await-in-swift/) — free, clear, no assumed knowledge. Also: Apple's "Meet Swift Concurrency" WWDC 2021 video (free on developer.apple.com).

**The test:** After reading, you should be able to look at an async function and spot if it's missing error handling or making a UI update off the main thread.

---

#### 2. SwiftData Fundamentals + Migrations
**Why it matters:** A bad migration after you have real users = their data is gone. Permanently. This is the most catastrophic technical mistake you can make post-launch.

**What to learn:**
- What `@Model` is and how SwiftData tracks changes
- The difference between optional and required properties (and why required = dangerous after launch)
- What a schema version is and when you need to increment it
- How `SchemaMigrationPlan` works at a conceptual level

**Best resource:** Apple's [Meet SwiftData WWDC 2023](https://developer.apple.com/videos/play/wwdc2023/10187/) and [Model your schema with SwiftData WWDC 2023](https://developer.apple.com/videos/play/wwdc2023/10195/). Both free, both ~20 minutes.

**The test:** You should be able to answer: "If I rename a property on UserProfile after users have installed the app, what happens?"

---

#### 3. Row Level Security (RLS) in Supabase
**Why it matters:** RLS is the only thing preventing any authenticated user from reading any other user's kink ratings. Without understanding it, you can't verify AI-generated SQL policies are correct.

**What to learn:**
- What `auth.uid()` is in a Supabase policy
- What `USING` vs `WITH CHECK` means in a policy
- How to test a policy (impersonate a user in the Supabase dashboard)
- Why the anon key is safe (with RLS) but the service role key is not

**Best resource:** Supabase's own docs: [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) — genuinely well written. Takes ~30 minutes to read. Then test every policy you have using the "Role: authenticated" impersonation feature in the Supabase SQL editor.

**The test:** Log into Supabase dashboard → SQL Editor → run a query as User A to fetch User B's kink_ratings → should return 0 rows.

---

#### 4. iOS Keychain vs UserDefaults
**Why it matters:** Auth tokens in UserDefaults = extractable from a non-encrypted backup. This is how users get their accounts stolen.

**What to learn:**
- What UserDefaults stores (user preferences, settings — NOT secrets)
- What Keychain stores (passwords, tokens, encryption keys)
- The difference between `kSecAttrAccessibleWhenUnlocked` and `kSecAttrAccessibleAfterFirstUnlock`
- How to verify what your app stores (use the iOS Simulator's data container inspection)

**Best resource:** [Apple's Keychain documentation](https://developer.apple.com/documentation/security/keychain_services) is dense but the concepts section is clear. Practically: look at how Supabase Swift SDK handles token storage — it uses Keychain by default, but verify it in your implementation.

**The test:** Find every `UserDefaults.standard.set(` call in your codebase and confirm none of them store anything resembling a token, key, or password.

---

#### 5. Git Fundamentals (beyond just committing)
**Why it matters:** One accidental commit of Config.xcconfig to a public repo and your Supabase project is compromised within minutes.

**What to learn:**
- How `.gitignore` works and how to verify a file is actually ignored (it's not enough to just add it to the file)
- How to check git history for a file that should never have been committed (`git log -- Config.xcconfig`)
- What `git diff --staged` shows before you commit
- How branches work: creating, switching, merging to main

**Best resource:** [Oh My Git!](https://ohmygit.org/) — a free, visual, interactive game that teaches git concepts. Takes 2-3 hours. Don't skip it — git mistakes are permanent.

**The test:** Verify that `git ls-files Config.xcconfig` returns nothing (meaning it's correctly ignored and never committed).

---

### Tier 2 — Learn These in the First 3 Months Post-Launch

These matter a lot but won't sink the ship immediately.

---

#### 6. StoreKit 2 Receipt Validation
**Why it matters:** Without server-side validation, sophisticated users can fake purchases and access paid content. At small scale this is low risk, but you should understand how it works.

**What to learn:**
- The difference between client-side and server-side validation
- What `Transaction.currentEntitlements` does
- What `Transaction.updates` is and why you need to listen to it (subscription renewals)
- What "restore purchases" actually does under the hood

**Best resource:** Apple's [StoreKit 2 WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10114/) session. Also [RevenueCat's StoreKit 2 guide](https://www.revenuecat.com/blog/engineering/storekit-2/) — they explain it plainly.

---

#### 7. App Store Review Guidelines — The Ones That Apply to You
**Why it matters:** Knowing the guidelines before submission prevents a 3-week rejection cycle.

**What to learn:** Read these specific guidelines in full:
- **1.1.6** — Objectionable content in dating-adjacent apps
- **3.1.1** — All digital goods via IAP (no Stripe)
- **5.1** — Privacy (what you must disclose)
- **5.1.1** — Data collection and storage (privacy policy requirements)
- **4.2** — Minimum functionality

**Best resource:** [Apple's App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — not exciting reading, but 45 minutes now saves weeks of rejection delays later.

---

#### 8. Instruments — Time Profiler and Leaks
**Why it matters:** Performance issues are invisible until real users hit them. Instruments shows you exactly where time is being wasted.

**What to learn:**
- How to launch Instruments from Xcode (Cmd+I, or Product → Profile)
- How to read a Time Profiler flame graph (the wider the bar, the more time it takes)
- How to run the Leaks instrument and what "leaked memory" means
- How to profile on a real device, not the simulator

**Best resource:** [Apple's Instruments documentation](https://help.apple.com/instruments/). Also search YouTube for "Xcode Instruments tutorial iOS" — there are solid 20-minute walkthroughs. WWDC "Analyze heap memory" (2021) is excellent.

---

#### 9. Privacy Policy Writing (the actual legal part)
**Why it matters:** Apple requires one. More importantly, you handle genuinely sensitive data — your users deserve to know what you do with it.

**What to learn:**
- CCPA (California Consumer Privacy Act) — applies to California users
- GDPR basics — applies to EU users, even if you don't target them
- What "right to deletion" means in practice (user deletes account → what gets deleted where?)
- What you must disclose: data collected, how it's used, who it's shared with, retention period

**Best resource:** [Termly's privacy policy generator](https://termly.io/) generates a usable first draft for free. Then read through it and make it accurate for your specific data practices. Pay particular attention to the "sensitive data" category — sexual orientation and sexual preferences fall under this.

**The test:** Your privacy policy should be able to answer: "If I delete my account, what data do you delete, and from where?"

---

### Tier 3 — Background Knowledge (Read, Don't Build)

You don't need to implement these, but understanding the concept prevents you from asking AI to implement them wrong.

---

#### 10. How Encryption Works (Conceptually)
**Not:** Learn to implement cryptography from scratch.
**Yes:** Understand what CryptoKit does, what "encrypted at rest" means, and why encrypting before storage is different from encrypting in transit (HTTPS).

**Best resource:** [Computerphile on YouTube](https://www.youtube.com/@Computerphile) — search "How AES Works" and "Public Key Cryptography." Both videos are under 20 minutes and use no math. After this you'll understand what you're asking AI to implement.

---

#### 11. What SQL and Database Queries Actually Do
**Not:** Become a SQL expert.
**Yes:** Understand what `SELECT`, `WHERE`, `JOIN` mean so you can read Supabase RLS policies and Edge Function queries and verify they're correct.

**Best resource:** [SQLZoo](https://sqlzoo.net/) — free, interactive, browser-based. Do only the first 4 tutorials (SELECT basics through WHERE). Takes ~2 hours. After this, the RLS policies in Section 19 will make complete sense.

---

#### 12. How REST APIs Work
**Not:** Build an API from scratch.
**Yes:** Understand HTTP methods (GET, POST, PUT, DELETE), status codes (200, 401, 403, 404, 500), and what a request/response cycle looks like. This is what Supabase's Swift SDK is doing under the hood.

**Best resource:** [What is an API? (video by MuleSoft)](https://www.youtube.com/watch?v=s7wmiS2mSXY) — 3 minutes. Then [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status) as a reference. After this you'll understand why a 403 from Supabase means "RLS blocked you" and a 401 means "not authenticated."

---

#### 13. What a JWT (JSON Web Token) Is
**Not:** Implement auth from scratch.
**Yes:** Understand what Sign in with Apple hands you, what Supabase does with it, and why this token should live in Keychain.

**Best resource:** [JWT.io's introduction](https://jwt.io/introduction) — 5-minute read. Then paste any JWT into the debugger at jwt.io and look at what's inside (never paste a real production token — use a test one). After this, you'll know why logging a JWT is a security issue.

---

## Part 5 — The Learning Schedule

A realistic plan given that you have a full life outside this app:

| Week | Topic | Time | Goal |
|------|-------|------|------|
| 1 | Swift Concurrency | 3 hrs | Understand async/await and @MainActor well enough to audit AI code |
| 2 | SwiftData + Migrations | 2 hrs | Know when a migration is required and what happens without one |
| 3 | Supabase RLS | 2 hrs | Test every policy in the dashboard manually |
| 4 | Git + .gitignore | 2 hrs | Play Oh My Git!, verify no secrets in history |
| 5 | iOS Keychain basics | 1 hr | Confirm auth tokens are NOT in UserDefaults |
| 6 | SQL basics (SQLZoo tutorials 1-4) | 2 hrs | Read and understand the RLS policies |
| 7 | REST APIs + HTTP | 1 hr | Understand what Supabase errors mean |
| 8 | JWT basics | 30 min | Know why tokens stay in Keychain |
| Month 2–3 | StoreKit 2, App Store Guidelines | Weekend | Before TestFlight and submission |
| Month 3+ | Instruments, Privacy Policy | When performance matters | Before scaling past 1K users |

**The meta-rule:** When Claude writes code you don't understand, stop and ask "can you explain what this does and why you wrote it this way?" before using it. Understanding the code you ship is more valuable than shipping it faster.

---

## Quick Reference — The 8 Questions to Ask After Every Code Generation

```
1. "What happens if this network call fails?"
2. "What happens if the user has no internet connection?"
3. "What happens if this data is nil or empty?"
4. "Is there any user data being logged or printed here?"
5. "Does this run on the main thread? Should it?"
6. "What happens if the user leaves this screen mid-operation?"
7. "Is there any way this could expose one user's data to another user?"
8. "What's the migration path if I need to change this SwiftData model later?"
```

Keep this visible. Paste it after any code generation prompt when you're not sure.

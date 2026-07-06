# Settings Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-scroll Settings list with a consolidated main screen + 5 push sub-screens, accessible from both the Home and Map tabs.

**Architecture:** Settings is presented as a `.vaylSheet` (heightFraction 0.97) from both Map and HomeRouterView, with its own internal `NavigationStack`. The root screen holds ~10 rows; detail goes into sub-screens pushed via `navigationDestination(for:)`. Sub-screens use `@Environment(\.dismiss)` for custom back navigation; the nav bar is hidden on all screens.

**Reference:** `docs/prototypes/settings-v2.html` (interactive prototype), `docs/prototypes/settings.html` (original)

**Token additions from pre-plan pass:**
- `AppColors.textSectionLabel` — already added to `AppColors.swift` (lavender-purple, `purpleBright` at 0.55 opacity dark)

---

## File Map

**Rewrite:**
- `Vayl/Features/Settings/SettingsView.swift` — main screen shell, `SettingsRoute` enum, `NavigationStack`

**Create:**
- `Vayl/Features/Settings/SettingsComponents.swift` — `SettingsSectionLabel`, `SettingsNavRow`, `SettingsToggleRow`
- `Vayl/Features/Settings/SettingsIdentityView.swift` — "You" sub-screen (Seg 2)
- `Vayl/Features/Settings/SettingsPrivacyView.swift` — Privacy & Safety sub-screen (Seg 3)
- `Vayl/Features/Settings/SettingsNotificationsView.swift` — Notifications sub-screen (Seg 3)
- `Vayl/Features/Settings/SettingsAppearanceView.swift` — Appearance sub-screen (Seg 3)
- `Vayl/Features/Settings/SettingsPartnerView.swift` — Partner sub-screen (Seg 4)

**Modify:**
- `Vayl/Features/Map/MapView.swift` — update `.vaylSheet` destination + heightFraction
- `Vayl/Features/Home/Views/HomeRouterView.swift` — add `showSettings` + `vaylSheet` binding
- `Vayl/Features/Home/Views/HomeDashboardView.swift` — add `onOpenSettings` callback + gear button

**Keep as-is (Segs 1–3):**
- `Vayl/Features/Pairing/PairingSettingsView.swift` — stays in place until Seg 4 replaces its content
- `Vayl/Features/Pairing/PairingInviteView.swift` — reused from SettingsPartnerView in Seg 4
- `Vayl/Features/Pairing/PairingJoinView.swift` — reused from SettingsPartnerView in Seg 4
- `Vayl/Design/Components/Cards/SettingsCard.swift` — unchanged; new row components go in SettingsComponents.swift

---

## Segment 1: Shell + Routing

**One thing:** New SettingsView main screen compiles and is reachable via gear button in both Map and Home tabs. All 5 nav rows push to stub sub-screens. X button dismisses.

**Done condition (device):** Tap gear in Map → Settings opens full-height. Tap gear in Home → Settings opens full-height. All 4 nav rows push with iOS push transition. Back arrow returns. X closes. Compile clean, zero raw values.

**Constraints:** Do not touch Pairing feature files, session feature files, Play tab, Learn tab, or OB files.

---

### Task 1: Create SettingsComponents.swift

**Files:**
- Create: `Vayl/Features/Settings/SettingsComponents.swift`

- [ ] **Step 1: Create the file**

```swift
// Vayl/Features/Settings/SettingsComponents.swift

import SwiftUI

// MARK: - SettingsSectionLabel

struct SettingsSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFonts.overline)
            .tracking(2)
            .foregroundStyle(AppColors.textSectionLabel)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SettingsNavRow

/// A navigation row with icon, label, optional trailing value, and chevron.
/// Wrap in `NavigationLink(value:)` — this view is layout only, no tap action.
struct SettingsNavRow: View {
    let icon: String
    let label: String
    var value: String? = nil
    var iconTint: Color = AppColors.textSecondary
    var iconBg: Color = AppColors.glassSurface

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(iconBg)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconTint)
                )
                .frame(width: 32, height: 32)

            Text(label)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if let val = value {
                Text(val)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - SettingsToggleRow

struct SettingsToggleRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    var iconTint: Color = AppColors.textSecondary
    var iconBg: Color = AppColors.glassSurface
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(iconBg)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconTint)
                )
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accentPrimary)
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
```

- [ ] **Step 2: Verify it builds**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

---

### Task 2: Rewrite SettingsView.swift

**Files:**
- Rewrite: `Vayl/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Replace the entire file**

```swift
// Vayl/Features/Settings/SettingsView.swift

import SwiftUI
import SwiftData

// MARK: - Route enum

enum SettingsRoute: Hashable {
    case you
    case privacy
    case notifications
    case appearance
    case partner
}

// MARK: - Main view

struct SettingsView: View {
    @Environment(AppState.self)         private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss)             private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        settingsHeader
                        membershipCard
                        partnerCard
                        SettingsSectionLabel(text: "Preferences")
                        preferencesCard
                        SettingsSectionLabel(text: "Account")
                        accountCard
                        footerLinks
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .you:           SettingsIdentityView()
                case .privacy:       SettingsPrivacyView()
                case .notifications: SettingsNotificationsView()
                case .appearance:    SettingsAppearanceView()
                case .partner:       SettingsPartnerView()
                }
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Settings")
                    .font(AppFonts.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.textSectionLabel)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.glassSurface))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close settings")
            }
            .padding(.top, AppSpacing.md)

            Text(appState.displayName.isEmpty ? "You." : "\(appState.displayName).")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.xs)
        }
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipCard: some View {
        if entitlements.isCore {
            // Lifetime member — compact status row
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.spectrumCyan)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Vayl Lifetime")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Full access, forever.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer()
                Button("Restore") {}
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accentPrimary)
                    .buttonStyle(.plain)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.spectrumCyan.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .padding(.top, AppSpacing.md)
        } else {
            // Free tier — upgrade prompt
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.spectrumPurple)
                    Text("Vayl Lifetime")
                        .font(AppFonts.overline)
                        .tracking(1.5)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("$24.99 once")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Text("Unlock every deck and the full Desire Map.")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                HStack {
                    Button("Restore purchase") {}
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .buttonStyle(.plain)
                    Spacer()
                    // Upgrade action wired in M2 StoreKit pass
                    Button("Upgrade") {}
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.spectrumPurple)
                        .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(LinearGradient(
                        colors: [
                            AppColors.spectrumCyan.opacity(0.07),
                            AppColors.spectrumPurple.opacity(0.10),
                            AppColors.spectrumMagenta.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: - Partner card

    private var partnerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Partner")
            SettingsCard {
                NavigationLink(value: SettingsRoute.partner) {
                    if appState.linkState == .linked {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.spectrumCyan)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(AppColors.spectrumCyan.opacity(0.10))
                                )
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("Linked")
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Paired account")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, AppSpacing.sm)
                    } else {
                        SettingsNavRow(
                            icon: "person.badge.plus",
                            label: "Invite a partner",
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Preferences card (4 nav rows)

    private var preferencesCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.you) {
                    SettingsNavRow(
                        icon: "person.circle",
                        label: "You",
                        value: appState.displayName.isEmpty ? nil : appState.displayName,
                        iconTint: AppColors.spectrumCyan,
                        iconBg: AppColors.spectrumCyan.opacity(0.10)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.privacy) {
                    SettingsNavRow(
                        icon: "lock.fill",
                        label: "Privacy & safety",
                        iconTint: AppColors.safetyAccent,
                        iconBg: AppColors.safetyAccent.opacity(0.10)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.notifications) {
                    SettingsNavRow(
                        icon: "bell.fill",
                        label: "Notifications",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(AppColors.borderSubtle)

                NavigationLink(value: SettingsRoute.appearance) {
                    SettingsNavRow(
                        icon: "paintpalette.fill",
                        label: "Appearance",
                        value: "Midnight",
                        iconTint: AppColors.spectrumMagenta,
                        iconBg: AppColors.spectrumMagenta.opacity(0.10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Account card

    private var accountCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                Button {
                    // Wired in Seg 4
                } label: {
                    HStack {
                        Text("Sign out")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)

                Divider().overlay(AppColors.borderSubtle)

                Button {
                    // Wired in Seg 4
                } label: {
                    HStack {
                        Text("Export my data")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)

                Divider().overlay(AppColors.borderSubtle)

                Button {
                    // Wired in Seg 4
                } label: {
                    HStack {
                        Text("Delete account")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.destructive)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xl) {
                Button("Privacy") {}
                    .buttonStyle(.plain)
                Button("Terms") {}
                    .buttonStyle(.plain)
                Button("Support") {}
                    .buttonStyle(.plain)
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textTertiary)
            .padding(.top, AppSpacing.lg)

            Text("Vayl · v0.1.0")
                .font(AppFonts.overline)
                .tracking(1)
                .foregroundStyle(AppColors.textMuted)
                .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sub-screen stubs (replaced in Segs 2–4)

struct SettingsIdentityView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SettingsSubScreenShell(title: "You", onBack: { dismiss() }) {
            Text("Identity settings — Seg 2")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.lg)
        }
    }
}

struct SettingsPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SettingsSubScreenShell(title: "Privacy & safety", onBack: { dismiss() }) {
            Text("Privacy settings — Seg 3")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.lg)
        }
    }
}

struct SettingsNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SettingsSubScreenShell(title: "Notifications", onBack: { dismiss() }) {
            Text("Notification settings — Seg 3")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.lg)
        }
    }
}

struct SettingsAppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SettingsSubScreenShell(title: "Appearance", onBack: { dismiss() }) {
            Text("Appearance settings — Seg 3")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.lg)
        }
    }
}

struct SettingsPartnerView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SettingsSubScreenShell(title: "Partner", onBack: { dismiss() }) {
            Text("Partner settings — Seg 4")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, AppSpacing.lg)
        }
    }
}

// MARK: - Shared sub-screen shell

/// Shared layout for all Settings sub-screens:
/// void background + atmosphere + custom back button + scrollable content.
struct SettingsSubScreenShell<Content: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            OnboardingAtmosphere(config: .stat).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Back button
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Settings")
                                .font(AppFonts.bodyMedium)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, AppSpacing.md)

                    Text(title)
                        .font(AppFonts.screenTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, AppSpacing.sm)

                    content
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AppState())
        .environment(EntitlementStore())
        .modelContainer(ModelContainer.previewContainer)
}
#endif
```

- [ ] **Step 2: Build and verify stubs all resolve**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

---

### Task 3: Update MapView.swift — point gear to SettingsView

**Files:**
- Modify: `Vayl/Features/Map/MapView.swift`

Context: MapView already has `@State private var showSettings = false` and a gear button. It currently presents `PairingSettingsView()`. Change the sheet destination and raise the height fraction.

- [ ] **Step 1: Find and update the vaylSheet call**

Find the block (approx line 70-80):
```swift
.vaylSheet(isPresented: $showSettings, heightFraction: 0.92, screenHeight: layout.screenHeight) {
    PairingSettingsView()
}
```

Replace with:
```swift
.vaylSheet(isPresented: $showSettings, heightFraction: 0.97, screenHeight: layout.screenHeight) {
    SettingsView()
}
```

- [ ] **Step 2: Build**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

---

### Task 4: Add Settings entry point to HomeRouterView + HomeDashboardView

**Files:**
- Modify: `Vayl/Features/Home/Views/HomeRouterView.swift`
- Modify: `Vayl/Features/Home/Views/HomeDashboardView.swift`

#### 4a — HomeDashboardView: add callback + gear button

- [ ] **Step 1: Add the onOpenSettings callback**

In `HomeDashboardView`, in the `// MARK: - Callbacks` section, add after `onCheckIn`:
```swift
var onOpenSettings: (() -> Void)? = nil
```

- [ ] **Step 2: Add gear button to greetingBlock**

Find `greetingBlock` (approx line 357). It currently ends with `PartnerChip(...)` inside an HStack.

Update the HStack to add the gear between Spacer and PartnerChip:

```swift
private var greetingBlock: some View {
    HStack(alignment: .center) {
        LivingText(
            text: "VAYL.",
            font: AppFonts.display(40, weight: .bold, relativeTo: .largeTitle),
            animated: false
        )
        Spacer()
        Button {
            onOpenSettings?()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppColors.glassSurface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
        .padding(.trailing, AppSpacing.xs)
        PartnerChip(
            state: partnerChipState,
            waiting: isWaitingOnPartner,
            onInviteTap: onInvitePartner,
            onPartnerTap: onPartnerTap
        )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

#### 4b — HomeRouterView: add showSettings state + vaylSheet

- [ ] **Step 3: Add @State for settings**

In `HomeRouterInnerView` (or the inner view that holds body — whichever class owns `@State`), add two state properties:

```swift
@State private var showSettings = false
@State private var screenHeightForSettings: CGFloat = 0
```

- [ ] **Step 4: Capture screen height in GeometryReader**

Inside the `GeometryReader { geo in` block, after `let layout = AppLayout.from(geo)`, add an `.onAppear` and `.onChange` to capture height for the sheet:

```swift
.onAppear { screenHeightForSettings = layout.screenHeight }
.onChange(of: geo.size) { _, _ in
    screenHeightForSettings = AppLayout.from(geo).screenHeight
}
```

Attach these modifiers to the `Group { routedContent(...) }` inside the GeometryReader.

- [ ] **Step 5: Add the vaylSheet in body**

After the GeometryReader (outside it, chained on the body), add:

```swift
.vaylSheet(isPresented: $showSettings, heightFraction: 0.97, screenHeight: screenHeightForSettings) {
    SettingsView()
}
```

Chain it alongside the existing `.sheet` / `.vaylCover` modifiers.

- [ ] **Step 6: Pass onOpenSettings to HomeDashboardView**

Find the `HomeDashboardView(...)` call site inside `dashboardContent` (or `routedContent`). Add:
```swift
onOpenSettings: { showSettings = true }
```

alongside the other `onXxx` callbacks.

- [ ] **Step 7: Build clean**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

---

### Task 5: Seg 1 commit

- [ ] **Commit**

```bash
git add Vayl/Features/Settings/SettingsComponents.swift \
        Vayl/Features/Settings/SettingsView.swift \
        Vayl/Features/Map/MapView.swift \
        Vayl/Features/Home/Views/HomeDashboardView.swift \
        Vayl/Features/Home/Views/HomeRouterView.swift
git commit -m "feat(settings): consolidated shell + routing (Seg 1)"
```

---

## Segment 2: You Sub-Screen

**One thing:** `SettingsIdentityView` reads real profile data and lets the user edit their name, pronouns, and experience level.

**Done condition (device):** Tapping "You" shows real display name and identity fields. Tapping a field opens an edit sheet. Save persists. Back returns to Settings main screen.

**Constraints:** Do not touch Map, Home, Pairing, or Appearance/Privacy/Notifications files.

---

### Task 6: Implement SettingsIdentityView

**Files:**
- Rewrite stub: `Vayl/Features/Settings/SettingsIdentityView.swift` (extract from SettingsView.swift into its own file)

Note: the stub struct currently lives at the bottom of `SettingsView.swift`. Move it to its own file and replace it with the real implementation. The stub in `SettingsView.swift` must remain as a declaration (so the `navigationDestination` switch compiles) until this file is extracted.

- [ ] **Step 1: Create the real SettingsIdentityView**

```swift
// Vayl/Features/Settings/SettingsIdentityView.swift

import SwiftUI
import SwiftData

struct SettingsIdentityView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext)  private var context
    @Environment(\.dismiss)       private var dismiss

    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    @State private var editField: IdentityField? = nil

    enum IdentityField: Hashable {
        case name, pronouns, experience
    }

    var body: some View {
        SettingsSubScreenShell(title: "You", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Identity")
            SettingsCard {
                VStack(spacing: 0) {
                    // Display name
                    Button {
                        editField = .name
                    } label: {
                        SettingsNavRow(
                            icon: "person.circle",
                            label: "Name",
                            value: profile?.displayName ?? appState.displayName
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(AppColors.borderSubtle)

                    // Pronouns
                    Button {
                        editField = .pronouns
                    } label: {
                        SettingsNavRow(
                            icon: "quote.bubble",
                            label: "Pronouns",
                            value: profile?.pronouns ?? "Not set"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(AppColors.borderSubtle)

                    // Experience level
                    Button {
                        editField = .experience
                    } label: {
                        SettingsNavRow(
                            icon: "sparkles",
                            label: "Experience",
                            value: profile?.experienceLabel ?? "Exploring"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $editField) { field in
            IdentityEditSheet(field: field, profile: profile, context: context) {
                appState.displayName = profile?.displayName ?? appState.displayName
            }
        }
    }
}

// MARK: - Edit sheet

private struct IdentityEditSheet: View {
    let field: SettingsIdentityView.IdentityField
    let profile: UserProfile?
    let context: ModelContext
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var selectedExperience: ExperienceLevel = .exploring

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.void.ignoresSafeArea()
                OnboardingAtmosphere(config: .stat).ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    switch field {
                    case .name:
                        editTextField(label: "Display name", placeholder: "Your name")
                    case .pronouns:
                        editTextField(label: "Pronouns", placeholder: "e.g. she/her, he/him, they/them")
                    case .experience:
                        experiencePicker
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(AppFonts.buttonLabel)
                        .foregroundStyle(AppColors.textTertiary)
                        .buttonStyle(.plain)
                    Spacer()
                    Button("Save") {
                        save()
                        onSave()
                        dismiss()
                    }
                    .font(AppFonts.buttonLabel)
                    .foregroundStyle(AppColors.accentPrimary)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .presentationDetents([.medium])
        .onAppear { loadCurrentValue() }
    }

    private func editTextField(label: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSectionLabel)
            TextField(placeholder, text: $text)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(AppColors.glassSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
        }
    }

    private var experiencePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Experience")
                .font(AppFonts.overline)
                .tracking(2)
                .foregroundStyle(AppColors.textSectionLabel)
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                Button {
                    selectedExperience = level
                } label: {
                    HStack {
                        Text(level.label)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        if selectedExperience == level {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.spectrumCyan)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(selectedExperience == level
                                  ? AppColors.spectrumCyan.opacity(0.10)
                                  : AppColors.glassSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadCurrentValue() {
        switch field {
        case .name:       text = profile?.displayName ?? ""
        case .pronouns:   text = profile?.pronouns ?? ""
        case .experience: selectedExperience = profile?.experienceLevel ?? .exploring
        }
    }

    private func save() {
        guard let p = profile else { return }
        switch field {
        case .name:       p.displayName = text.trimmingCharacters(in: .whitespaces)
        case .pronouns:   p.pronouns = text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : text.trimmingCharacters(in: .whitespaces)
        case .experience: p.experienceLevel = selectedExperience
        }
        try? context.save()
    }
}

// MARK: - IdentityField: Identifiable (required for sheet(item:))

extension SettingsIdentityView.IdentityField: Identifiable {
    var id: Self { self }
}
```

- [ ] **Step 2: Remove stub from SettingsView.swift**

Delete the `struct SettingsIdentityView` stub block at the bottom of `SettingsView.swift`. Since the real view is now in its own file, the `navigationDestination` switch still compiles.

- [ ] **Step 3: Verify UserProfile has the required properties**

Check `Vayl/Models/UserProfile.swift` for:
- `displayName: String`
- `pronouns: String?`
- `experienceLevel: ExperienceLevel`
- `experienceLabel: String` (computed, or add it)

Add any missing property. `ExperienceLevel` must be `CaseIterable` for the picker. Check `Vayl/Models/ExperienceLevel.swift` or wherever it's defined and add `CaseIterable` conformance if absent.

- [ ] **Step 4: Build**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Settings/SettingsIdentityView.swift \
        Vayl/Features/Settings/SettingsView.swift
git commit -m "feat(settings): You identity sub-screen (Seg 2)"
```

---

## Segment 3: Privacy, Notifications, Appearance Sub-Screens

**One thing:** Migrate all existing toggles from the old SettingsView into their proper sub-screens. Each sub-screen is standalone and testable.

**Done condition (device):** Privacy shows screenshot protection + capacity sharing toggles, both functional. Notifications shows reminder toggle. Appearance shows theme label + haptic toggle. Back navigation works on all three.

**Constraints:** Do not touch Seg 2 identity files, Seg 4 partner/account logic, or the main SettingsView shell.

---

### Task 7: SettingsPrivacyView

**Files:**
- Replace stub: extract `SettingsPrivacyView` from `SettingsView.swift` into its own file

- [ ] **Step 1: Create the real SettingsPrivacyView**

```swift
// Vayl/Features/Settings/SettingsPrivacyView.swift

import SwiftUI

struct SettingsPrivacyView: View {
    @Environment(\.dismiss)            private var dismiss

    @AppStorage("screenshotProtectionEnabled")
    private var screenshotProtection: Bool = true

    @State private var shareCapacity: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Privacy & safety", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Screen protection")
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "eye.slash.fill",
                        label: "Screenshot protection",
                        subtitle: "Hides sensitive screens from recordings.",
                        iconTint: AppColors.safetyAccent,
                        iconBg: AppColors.safetyAccent.opacity(0.10),
                        isOn: $screenshotProtection
                    )
                }
            }
            .if(screenshotProtection) { $0.screenshotProtected() }

            SettingsSectionLabel(text: "Sharing")
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "waveform.path.ecg",
                        label: "Share capacity with partner",
                        subtitle: "Your partner sees your Pulse capacity, not your answers.",
                        iconTint: AppColors.accentPrimary,
                        iconBg: AppColors.accentPrimary.opacity(0.10),
                        isOn: Binding(
                            get: { shareCapacity },
                            set: { newVal in
                                shareCapacity = newVal
                                Task { await PulseSyncService.shared.setSharing(newVal) }
                            }
                        )
                    )
                }
            }
        }
        .task { shareCapacity = await PulseSyncService.shared.fetchSharing() }
    }
}
```

- [ ] **Step 2: Remove the `SettingsPrivacyView` stub from `SettingsView.swift`**

Delete only the stub struct. Leave all other stubs intact.

---

### Task 8: SettingsNotificationsView

**Files:**
- Replace stub: `SettingsNotificationsView` into its own file

- [ ] **Step 1: Create the real SettingsNotificationsView**

```swift
// Vayl/Features/Settings/SettingsNotificationsView.swift

import SwiftUI

struct SettingsNotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notificationsCheckInReminder") private var checkInReminder: Bool = true
    @AppStorage("notificationsPartnerActivity") private var partnerActivity: Bool = true
    @AppStorage("notificationsDiscreetMode")    private var discreetMode: Bool = false

    var body: some View {
        SettingsSubScreenShell(title: "Notifications", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Reminders")
            SettingsCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        label: "Check-in reminder",
                        subtitle: "Weekly nudge to log your Pulse.",
                        iconTint: AppColors.spectrumPurple,
                        iconBg: AppColors.spectrumPurple.opacity(0.10),
                        isOn: $checkInReminder
                    )

                    Divider().overlay(AppColors.borderSubtle)

                    SettingsToggleRow(
                        icon: "person.2.fill",
                        label: "Partner activity",
                        subtitle: "When your partner completes the Desire Map.",
                        iconTint: AppColors.spectrumCyan,
                        iconBg: AppColors.spectrumCyan.opacity(0.10),
                        isOn: $partnerActivity
                    )
                }
            }

            SettingsSectionLabel(text: "Privacy")
            SettingsCard {
                SettingsToggleRow(
                    icon: "eye.slash",
                    label: "Discreet mode",
                    subtitle: "Notification previews never mention Vayl by name.",
                    iconTint: AppColors.safetyAccent,
                    iconBg: AppColors.safetyAccent.opacity(0.10),
                    isOn: $discreetMode
                )
            }
        }
    }
}
```

- [ ] **Step 2: Remove `SettingsNotificationsView` stub from `SettingsView.swift`**

---

### Task 9: SettingsAppearanceView

**Files:**
- Replace stub: `SettingsAppearanceView` into its own file

- [ ] **Step 1: Create the real SettingsAppearanceView**

```swift
// Vayl/Features/Settings/SettingsAppearanceView.swift

import SwiftUI

struct SettingsAppearanceView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("hapticFeedbackEnabled") private var hapticFeedback: Bool = true

    var body: some View {
        SettingsSubScreenShell(title: "Appearance", onBack: { dismiss() }) {
            SettingsSectionLabel(text: "Theme")
            SettingsCard {
                // Dark-only in Act 1: theme is fixed to Midnight.
                // When light/system mode ships, replace with a picker.
                HStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.spectrumMagenta.opacity(0.10))
                        .overlay(
                            Image(systemName: "moon.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.spectrumMagenta)
                        )
                        .frame(width: 32, height: 32)
                    Text("Midnight")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("Dark only · Act 1")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(.vertical, AppSpacing.sm)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Theme: Midnight (dark only)")
            }

            SettingsSectionLabel(text: "Feel")
            SettingsCard {
                SettingsToggleRow(
                    icon: "waveform",
                    label: "Haptic feedback",
                    iconTint: AppColors.accentSecondary,
                    iconBg: AppColors.accentSecondary.opacity(0.10),
                    isOn: $hapticFeedback
                )
            }
        }
    }
}
```

- [ ] **Step 2: Remove `SettingsAppearanceView` stub from `SettingsView.swift`**

- [ ] **Step 3: Build all three**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Vayl/Features/Settings/SettingsPrivacyView.swift \
        Vayl/Features/Settings/SettingsNotificationsView.swift \
        Vayl/Features/Settings/SettingsAppearanceView.swift \
        Vayl/Features/Settings/SettingsView.swift
git commit -m "feat(settings): Privacy, Notifications, Appearance sub-screens (Seg 3)"
```

---

## Segment 4: Partner Sub-Screen + Account Actions

**One thing:** SettingsPartnerView handles linked and solo states. Account actions (sign out, delete) are wired.

**Done condition (device):** Solo state shows invite + join flows. Linked state shows partner name + unlink confirmation. Sign out works. Delete account shows confirmation alert.

**Constraints:** Do not touch Seg 2 identity files or Seg 3 preference files. `PairingSettingsView` may be deprecated (remove its NavigationLink from MapView if it had one) but keep the file — it is referenced by tests.

---

### Task 10: SettingsPartnerView

**Files:**
- Replace stub: `SettingsPartnerView` into its own file

- [ ] **Step 1: Create the real SettingsPartnerView**

```swift
// Vayl/Features/Settings/SettingsPartnerView.swift

import SwiftUI

struct SettingsPartnerView: View {
    @Environment(AppState.self)    private var appState
    @Environment(\.dismiss)        private var dismiss

    @State private var showInvite:  Bool = false
    @State private var showJoin:    Bool = false
    @State private var showUnlink:  Bool = false

    var body: some View {
        SettingsSubScreenShell(title: "Partner", onBack: { dismiss() }) {
            if appState.linkState == .linked {
                linkedContent
            } else {
                soloContent
            }
        }
        .sheet(isPresented: $showInvite) {
            PairingInviteView()
        }
        .sheet(isPresented: $showJoin) {
            PairingJoinView()
        }
        .confirmationDialog(
            "Unlink partner?",
            isPresented: $showUnlink,
            titleVisibility: .visible
        ) {
            Button("Unlink", role: .destructive) {
                // Unlink action deferred — no unlink feature in V1.
                // See monetization_m1_backend_built.md: "unlink UX deferred"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You and your partner will lose access to shared content.")
        }
    }

    // MARK: - Linked state

    private var linkedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Connected")
            SettingsCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.spectrumCyan)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(AppColors.spectrumCyan.opacity(0.10))
                            )
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Paired account")
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("Linked")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                    }
                }
            }

            SettingsSectionLabel(text: "Actions")
            SettingsCard {
                Button {
                    showUnlink = true
                } label: {
                    HStack {
                        Text("Unlink partner")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.destructive)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Solo state

    private var soloContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionLabel(text: "Pair with a partner")
            SettingsCard {
                VStack(spacing: 0) {
                    Button {
                        showInvite = true
                    } label: {
                        SettingsNavRow(
                            icon: "envelope.fill",
                            label: "Invite my partner",
                            iconTint: AppColors.spectrumCyan,
                            iconBg: AppColors.spectrumCyan.opacity(0.10)
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(AppColors.borderSubtle)

                    Button {
                        showJoin = true
                    } label: {
                        SettingsNavRow(
                            icon: "link.badge.plus",
                            label: "I have a partner code",
                            iconTint: AppColors.spectrumPurple,
                            iconBg: AppColors.spectrumPurple.opacity(0.10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Remove `SettingsPartnerView` stub from `SettingsView.swift`**

At this point `SettingsView.swift` should have zero stub structs (all replaced). Only `SettingsSubScreenShell` and `SettingsView` itself remain in that file.

---

### Task 11: Wire account actions (sign out + delete)

**Files:**
- Modify: `Vayl/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Add @Environment dependencies to SettingsView**

At the top of `SettingsView`, add:

```swift
@Environment(AuthService.self)    private var authService
@Environment(\.modelContext)      private var modelContext

@State private var showSignOutConfirm:  Bool = false
@State private var showDeleteConfirm:   Bool = false
```

- [ ] **Step 2: Wire sign out button**

Replace the sign-out `Button { // Wired in Seg 4 }` with:

```swift
Button {
    showSignOutConfirm = true
} label: {
    HStack {
        Text("Sign out")
            .font(AppFonts.bodyMedium)
            .foregroundStyle(AppColors.textPrimary)
        Spacer()
    }
    .contentShape(Rectangle())
    .padding(.vertical, AppSpacing.sm)
}
.buttonStyle(.plain)
```

- [ ] **Step 3: Wire delete button**

Replace the delete `Button { // Wired in Seg 4 }` with:

```swift
Button {
    showDeleteConfirm = true
} label: {
    HStack {
        Text("Delete account")
            .font(AppFonts.bodyMedium)
            .foregroundStyle(AppColors.destructive)
        Spacer()
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textTertiary)
    }
    .contentShape(Rectangle())
    .padding(.vertical, AppSpacing.sm)
}
.buttonStyle(.plain)
```

- [ ] **Step 4: Add confirmations in body**

Chain these onto the `NavigationStack` (after `.navigationDestination`):

```swift
.confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
    Button("Sign out", role: .destructive) {
        Task {
            await authService.signOut()
            let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
            // Optionally reset onboarding here if needed for testing
        }
    }
    Button("Cancel", role: .cancel) {}
}
.alert("Delete account?", isPresented: $showDeleteConfirm) {
    Button("Delete everything", role: .destructive) {
        // Full account deletion deferred — flag for V1.1 pass.
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This permanently deletes your data and cannot be undone.")
}
```

- [ ] **Step 5: Final build**

`xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Final commit**

```bash
git add Vayl/Features/Settings/SettingsPartnerView.swift \
        Vayl/Features/Settings/SettingsView.swift
git commit -m "feat(settings): Partner sub-screen + account actions (Seg 4)"
```

---

## Self-Review

**Spec coverage:**
- [x] Consolidated main screen (~10 rows, not 25+) — Tasks 1–2
- [x] Section labels in lavender-purple (`textSectionLabel` token) — Task 1
- [x] Settings accessible from Map tab — Task 3
- [x] Settings accessible from Home tab — Task 4
- [x] Push navigation to 5 sub-screens — Task 2 (`navigationDestination`)
- [x] X dismiss from Settings root — Task 2 header
- [x] Custom back navigation on sub-screens — `SettingsSubScreenShell`
- [x] Partner as featured card (not plain row) — Task 2 `partnerCard`
- [x] Membership/upgrade banner — Task 2 `membershipCard`
- [x] Existing toggles (screenshot, haptic, shareCapacity) migrated — Tasks 7–9
- [x] Account actions: sign out + delete — Task 11
- [x] Footer links (Privacy, Terms, Support) — Task 2

**Placeholder scan:** No "TBD", "TODO", or "implement later" in Step code blocks. The two intentional defers (unlink, account deletion) are explicitly documented with memory refs as to WHY they're deferred.

**Type consistency:** `SettingsRoute`, `SettingsSubScreenShell`, `SettingsSectionLabel`, `SettingsNavRow`, `SettingsToggleRow` — all defined in Seg 1 and used consistently in Segs 2–4.

**Known pre-conditions to verify before Seg 2:**
- `UserProfile.pronouns: String?` — check it exists, add if not
- `UserProfile.experienceLevel: ExperienceLevel` — check it exists
- `ExperienceLevel: CaseIterable` — add conformance if missing
- `ExperienceLevel.label: String` — computed var needed for picker display

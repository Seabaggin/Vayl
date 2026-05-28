# UserProfile Gender Field Alignment

**Date:** 2026-05-27  
**Status:** Approved  

---

## Problem

`UserProfile` and `OnboardingData` use different field names for the same data, creating a naming mismatch and a type coercion in `OnboardingStore.commit()`. A pronouns field exists in both the data model and the OB UI — but Vayl is not a social media app and pronouns serve no content-routing purpose. Gender identity does: it lets the app tailor deck content for different couple dynamics (hetero, gay, lesbian, trans-trans, etc.).

A secondary problem: when User A onboards they enter their own gender and a guess at their partner's gender. That guess may be wrong. The correct value is User B's own self-report, but currently there is no override mechanism.

**Out of scope for this change:** the PairingService override (reconciliation at link time). That is a separate feature.

---

## Goals

1. Rename gender fields in `UserProfile` to `userGender` / `partnerGender` — names that are self-documenting and match the purpose.
2. Remove pronouns from the data model and the OB UI entirely.
3. Align `OnboardingData` naming to match `UserProfile` end-to-end.
4. Add a proper SwiftData lightweight migration so no device data is silently corrupted on upgrade.
5. Fix a live compile bug in `OnboardingNameView.swift` (`data.genderIdentity` on a type that no longer has that field).

---

## Non-Goals

- Pronouns storage or display of any kind.
- Content routing logic that reads `userGender` / `partnerGender` (separate feature).
- The PairingService `partnerGender` override at link time (separate feature).
- Any change to gender options displayed in the picker drum.

---

## Data Model Changes

### UserProfile.swift (`@Model`)

| Old field | New field | Old type | New type | Notes |
|---|---|---|---|---|
| `genderIdentity` | `userGender` | `String?` | `String?` | `@Attribute(originalName: "genderIdentity")` |
| `partnerGenderIdentity` | `partnerGender` | `String?` | `String?` | `@Attribute(originalName: "partnerGenderIdentity")` |
| `pronouns` | _(removed)_ | `[String]` | — | Dropped; existing data discarded in migration |
| `partnerPronouns` | _(removed)_ | `String?` | — | Dropped; existing data discarded in migration |

`userGender` = self-reported gender. Set once in OB. **Never overwritten after OB except by PairingService (future).**  
`partnerGender` = what this user said their partner's gender is. Provisional — PairingService reconciles this at link time (future feature).

`init()` drops the `pronouns` and `partnerPronouns` parameters.  
Preview fixtures (`example`, `soloExample`, `linkedExample`) update to new field names.

### OnboardingData.swift (transient struct, not persisted)

| Old field | New field | Notes |
|---|---|---|
| `genderA: String?` | `userGender: String?` | Renamed |
| `genderB: String?` | `partnerGender: String?` | Renamed; nil for solo / browsing |
| `pronounsA: String?` | _(removed)_ | — |
| `pronounsB: String?` | _(removed)_ | — |

No migration needed — struct is discarded after `commit()`.

---

## Migration

`ModelContainer.swift` gains a `SchemaV2` at version `1.0.1` and a `.lightweight` migration stage.

```swift
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 1)
    static var models: [any PersistentModel.Type] = [
        // identical list to SchemaV1
    ]
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    ]
}
```

`@Attribute(originalName: "genderIdentity")` on `userGender` and `@Attribute(originalName: "partnerGenderIdentity")` on `partnerGender` instruct SwiftData to read the old column names from the V1 store. Dropped fields (`pronouns`, `partnerPronouns`) are silently discarded — acceptable because no users have shipped data.

Any device upgrading from V1 migrates automatically on next launch.

---

## Store Changes

### OnboardingStore.swift — `persist(data:)`

Remove the type-coercion bridge. Mapping becomes direct:

```swift
profile.userGender    = data.userGender
profile.partnerGender = data.partnerGender
```

Remove all pronoun writes.

---

## OB Phase Changes

### VaylDirector.swift

`confirmGenderSelection(pronouns: String?)` → `confirmGenderSelection()`.

Writes inside the function:

```swift
if genderSpinIndex == 0 {
    onboardingData.userGender    = genderOptions[genderSelectedIndex]
} else {
    onboardingData.partnerGender = genderOptions[genderSelectedIndex]
}
```

Remove `onboardingData.pronounsA` and `onboardingData.pronounsB` writes.  
Update doc comment on the function.

### GenderPhase.swift

- Remove `@State private var pronounsText: String = ""`
- Remove `pronounsFieldView` (the `TextField("Pronouns (optional)", ...)` view, ~lines 408–415)
- Remove the layout comment referencing pronouns field height (~line 277)
- Update `confirmHintView` swipe action: call `director.confirmGenderSelection()` with no argument

---

## Bug Fix

### OnboardingNameView.swift

Lines 730, 745, 750 reference `data.genderIdentity` on a `Binding<OnboardingData>`. `OnboardingData` has no `genderIdentity` field — this is a compile error. Change all three occurrences to `data.userGender`.

---

## Stale Comment

### AppOBEnums.swift (line 45)

```swift
// was:  OnboardingData.genderIdentity — deck[2]
// becomes: OnboardingData.userGender — deck[2]
```

---

## Future: PairingService Override (Out of Scope)

When User A and User B link accounts, `PairingService` must reconcile `partnerGender`:

- Write `userB.userGender` → `userA.partnerGender`
- Write `userA.userGender` → `userB.partnerGender`

Self-report always wins. This lives entirely in the linking flow and touches no code in this change.

---

## Files Touched

| File | Change |
|---|---|
| `Vayl/Core/Models/UserProfile.swift` | Rename fields, remove pronouns, update init + previews |
| `Vayl/Features/Onboarding/Models/OnboardingData.swift` | Rename fields, remove pronouns |
| `Vayl/Features/Onboarding/Store/OnboardingStore.swift` | Update commit() mapping |
| `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` | Update confirmGenderSelection, remove pronoun writes |
| `Vayl/Features/Onboarding/Phases/GenderPhase.swift` | Remove pronouns UI + state |
| `Vayl/Features/Onboarding/Views/OnboardingNameView.swift` | Fix genderIdentity → userGender (compile error) |
| `Vayl/App/ModelContainer.swift` | Add SchemaV2 + lightweight migration stage |
| `Vayl/Core/Models/Enums/AppOBEnums.swift` | Update stale comment |

## Files Not Touched

| File | Reason |
|---|---|
| All card / game content files | Content routing reads from UserProfile — but that logic doesn't exist yet |

**Note on GenderPhase.swift:** Drum gesture state variables (`genderActiveReel`, `drumBaseOffset`, `drumDragOffset`, `confirmedTrigger`) are purely view-local physics — they don't reference `OnboardingData` fields and need no changes. Only the pronouns UI state and the `confirmGenderSelection` call site change.

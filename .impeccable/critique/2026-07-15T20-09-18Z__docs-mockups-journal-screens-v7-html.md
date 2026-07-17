---
target: docs/mockups/journal-screens-v7.html
total_score: 21
p0_count: 0
p1_count: 3
timestamp: 2026-07-15T20-09-18Z
slug: docs-mockups-journal-screens-v7-html
---
# Journal V7 design critique

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 2/4 | Saved and Dictating are present, but save failure and the meaning of Draft are undefined. |
| 2 | Match with the real world | 3/4 | The quiet prompt fits private reflection; separate Write and Speak paths over-model an input method. |
| 3 | User control and freedom | 2/4 | Exit, back, and delete confirmation exist; edit, recovery, and a clear completion model do not. |
| 4 | Consistency and standards | 2/4 | Several controls miss iOS touch targets, token values drift, and presentation behavior is unspecified. |
| 5 | Error prevention | 1/4 | Destructive confirmation is good, but save, exit, empty-entry, and dictation failure paths are absent. |
| 6 | Recognition rather than recall | 3/4 | Core actions are visible; the refresh icon and Tap to write with this instruction are ambiguous. |
| 7 | Flexibility and efficiency | 2/4 | Filtering exists, but twelve tags and two capture doors add work before the journal has enough data to need it. |
| 8 | Aesthetic and minimalist design | 2/4 | The atmosphere is coherent, but spectrum, glow, glass, and motion appear often enough that light stops feeling earned. |
| 9 | Error recovery | 1/4 | No save retry, dictation recovery, deletion undo, or draft-resume behavior is specified. |
| 10 | Help and documentation | 3/4 | Privacy and tag explanations are useful, but the privacy copy makes a storage claim the architecture has not established. |
| **Total** | | **21/40** | **Promising, but needs product-definition work before implementation.** |

## Anti-pattern verdict

The work does not read as generic AI overall. The copy, private-Me framing, and restraint around sharing are product-specific. The main slop risk is aesthetic repetition: gradient prompt, glowing cards, spectrum buttons, crown-lit sheets, animated aura, and grain all appear together. That starts to resemble a dark-tech template and weakens Vayl's earned-spectrum rule.

The deterministic scan returned 54 findings: one gradient-text warning, one dark-glow warning, and 52 token advisories. Many are false positives from the mock phone, keyboard, gallery annotations, or documented Vayl values. Real drift includes the 22px threshold radius, 6px draft radius, 44px sheet radius, several off-ramp type sizes, and the custom #FF9B9B destructive text. The gradient and glow warnings conflict with Vayl's deliberate brand permissions, so frequency rather than mere presence is the real issue.

## Overall impression

The strongest idea is a private, low-pressure room that asks one broad question and never analyzes the answer. The biggest opportunity is to make the behavior as calm and trustworthy as the surface: one capture path, one honest privacy promise, and one comprehensible save model.

## What's working

- The broad prompt, What's here right now?, invites naming without inference and preserves a genuine off-ramp.
- Privacy is surfaced at the threshold and in the list instead of being buried in settings.
- Write, dictation, reread, browse, deletion, and tagging share a recognizable visual language and calm voice.

## Priority issues

### P1: The privacy promise overreaches

The delete sheet says the entry has only ever been on your device, while the product architecture has not settled local-only storage, backups, or owner-only cloud sync. Speech-to-text data handling is also unspecified. Replace storage claims with the durable promise: Private to you. Your partner cannot access your journal in Vayl. Separately specify storage, encryption, backup, export, analytics exclusion, and dictation behavior. Prefer the system keyboard's dictation unless custom transcription earns its privacy and permission cost.

### P1: Saved and Draft describe no coherent state model

The composer reports Saved, while the list marks the same entry Draft, and no action finishes a draft. Choose the smallest model: non-empty text autosaves as an entry, empty text is discarded, and there is no Draft state. Specify Saving, Saved, and Couldn't save states plus exit behavior when persistence fails. If drafts remain, define exactly what creates, resumes, and completes one. Add editing for an existing entry.

### P1: The required failure and empty states are missing

The footer acknowledges missing empty states, and there are no permission-denied, interrupted-dictation, unavailable-dictation, save-failed, or recovery states. Add the mandatory threshold/list empty state and a compact state table before implementation. Define delete recovery or state explicitly that deletion is immediate and permanent.

### P2: Write and Speak should be one entry action

The spec says there is one compose surface, but the threshold asks the user to choose two equal doors. Speaking is an input method, not a separate journaling job. Use one New entry or Write button, then expose native dictation inside the editor. This removes a decision, a permission fork, and duplicated state handling.

### P2: The feature is visually and structurally over-equipped for V1

Twelve tags, a five-chip filter row for seven entries, glow on every entry, animated prompt text while writing, and a ceremonial sheet crown make a humble private notebook feel managed. Make tags optional and grouped by Feeling and Context, remove redundant Solo, cap selections, and hide filters until enough tagged entries exist. Keep the threshold hero alive, but make compose and reread typography static and quiet. Gold cannot mark Draft because gold is reserved for safety.

## Persona red flags

- A partner-cautious late-night writer will like Only you, but may stop at the microphone because it is unclear where audio or transcription goes. The delete sheet's device-only claim may later damage trust if backup or sync exists.
- A first-time journaler faces Write versus Speak, a refresh control, tags, Draft, Saved, and twelve tag choices before learning the simple rule of what gets kept. The experience asks them to manage the journal rather than use it.
- A Dynamic Type or VoiceOver user encounters 32pt close/back controls, a 34pt shuffle control, a 40pt add control, very small chips, low-contrast labels around 2.5:1, and a tag sheet with no demonstrated large-text layout.

## Minor observations

- Standardize Only you, just for you, and Private to you into one privacy phrase.
- Replace Tap to write with this with a label tied to the action, and give shuffle an accessible name such as Another prompt.
- Simplify delete copy; no one else loses anything introduces sharing into a feature that intentionally has none.
- State the native navigation contract: Map to Journal hierarchy, new-entry presentation, reread push, tag picker sheet, and guarded exit behavior.
- Bring all controls to 44pt minimum, use native Button semantics and SF Symbols, support Dynamic Type, and derive colors/radii/type from app tokens.
- The 1s dictation waveform and 1.1s caret loop violate Vayl's two-second motion floor; every loop also needs Low Power handling in Swift.

## Questions to consider

- Is the V1 journal a plain private notebook with optional prompts, or a lightly organized reflection system with tags and filters?
- Is storage guaranteed local-only, or is the durable promise owner-only privacy regardless of storage location?
- Should the threshold feel alive while the editor becomes nearly motionless once the user starts writing?

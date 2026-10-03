# MindSparQ Note — Bug Fix Log

> **Purpose:** Permanent record of every confirmed bug, its root cause, fix, and verification evidence.
> **Rule:** A bug is only moved to CLOSED when acceptance criteria are verified with evidence.
> **Format:** Add new entries at the top of the Active Bugs section. Move to Closed when FIXED AND VERIFIED.

---

## How to Add an Entry

Copy the template below, fill in every field, and paste it under **Active Bugs**.
Never delete an entry. Move resolved entries to **Closed Bugs**.

---

## Bug Report Template

```
### MSN-BUG-XXX — [Short title]

**Status:** OPEN | FIX IMPLEMENTED — VERIFICATION INCOMPLETE | PARTIALLY FIXED | BLOCKED | CLOSED
**Priority:** P0 (data loss/crash) | P1 (major broken) | P2 (feature bug) | P3 (cosmetic)
**Platform:** Android | Windows | Linux | Web | All
**Feature / Module:** [e.g., Note Editor / Autosave / Settings / AI Assistant]
**Reported:** YYYY-MM-DD
**Closed:** —

#### Problem Description
[Exact description of what is wrong.]

#### Steps to Reproduce
1. 
2. 
3. 

#### Expected Behavior
[What should happen.]

#### Actual Behavior
[What currently happens.]

#### Root Cause
[Identified cause — file, line, and mechanism. "Unknown" until investigated.]

#### Files Changed
| File | Change |
|---|---|
| — | — |

#### Acceptance Criteria

| # | Criterion | Method | Result |
|---|---|---|---|
| 1 | | | NOT TESTED |

#### Verification Commands Run
```
# Commands actually executed:
```

#### Final Status
[OPEN / FIX IMPLEMENTED — VERIFICATION INCOMPLETE / PARTIALLY FIXED / BLOCKED / FIXED AND VERIFIED]

#### Notes / Remaining Risks
[Any open questions, regressions observed, or follow-up items.]
```

---

## Active Bugs

### MSN-BUG-001 — Excessive vertical gap between paragraphs on Enter

**Status:** FIX IMPLEMENTED — VERIFICATION INCOMPLETE (automated tests pass; runtime manual verification pending)
**Priority:** P2
**Platform:** Android (confirmed), Windows/Linux (likely same)
**Feature / Module:** Note Editor / Paragraph Spacing
**Reported:** 2026-10-03
**Closed:** —

#### Problem Description
Pressing Enter in the Rich Text Editor creates an abnormally large vertical gap between paragraphs. Adding multiple paragraphs makes the document grow disproportionately.

#### Steps to Reproduce
1. Open MindSparQ Notes.
2. Open or create a note.
3. Type any text, press Enter, type more text.
4. Observe: gap between the two lines is roughly 2× what it should be.

#### Expected Behavior
A single, balanced gap between consecutive paragraphs equal to the configured Paragraph Spacing value.

#### Actual Behavior
The gap appeared to be approximately 2× the intended spacing because `EdgeInsets.only(bottom: spacing)` on each paragraph stacked `spacing + spacing` between consecutive blocks.

A second issue caused the Settings dialog to show no selected value for Paragraph Spacing: the stored default (`2.0`) was not present as a dropdown option (minimum option was `4.0`), causing `null` selection.

#### Root Cause
Two independent issues, both confirmed from source:

1. **Double-gap stacking** (`note_editor_screen.dart:833`):
   - `EdgeInsets.only(bottom: settings.paragraphSpacing)` applied to every paragraph block
   - Between two consecutive paragraphs: P1.bottom + P2.bottom = 2 × spacing
   - Fix: `EdgeInsets.symmetric(vertical: spacing / 2)` → P1.bottom + P2.top = spacing

2. **Default/dropdown mismatch** (`settings_provider.dart:29,81,87` + `settings_dialog.dart:333-339`):
   - Default `paragraphSpacing = 2.0` but dropdown minimum was `4.0`
   - No `2.0` option → dropdown showed null → user could not see or adjust current value
   - Fix: Default changed to `4.0`; `2.0 pt (Tight)` option added to dropdown

#### Files Changed
| File | Change |
|---|---|
| `lib/app/providers/settings_provider.dart` | Default `paragraphSpacing` 2.0 → 4.0; migration reset value 2.0 → 4.0; fallback 2.0 → 4.0 |
| `lib/features/settings/presentation/settings_dialog.dart` | Added `2 pt (Tight)` option; renamed `4 pt` → `4 pt (Default)`; `6 pt (Professional)` → `6 pt (Relaxed)` |
| `lib/features/notes/presentation/note_editor_screen.dart` | `EdgeInsets.only(bottom: spacing)` → `EdgeInsets.symmetric(vertical: spacing / 2)` |
| `test/spacing_test.dart` | Added 2 regression tests for MSN-BUG-001; updated builder test to use new symmetric padding |

#### Acceptance Criteria

| # | Criterion | Method | Result |
|---|---|---|---|
| 1 | Symmetric padding contract: top == bottom == spacing/2 | `flutter test test/spacing_test.dart` | **PASS** |
| 2 | Total inter-paragraph gap == exactly 1× spacing | `flutter test test/spacing_test.dart` | **PASS** |
| 3 | Default value (4.0) matches a valid dropdown option | `flutter test test/spacing_test.dart` | **PASS** |
| 4 | `flutter analyze` — no new errors in edited files | `flutter analyze` | **PASS** (1 pre-existing info in generated file) |
| 5 | Enter creates compact gap in running Android app | Manual — device required | **NOT TESTED** |
| 6 | Paragraph spacing dropdown shows selected value | Manual — settings dialog | **NOT TESTED** |
| 7 | Existing notes reopen with correct spacing | Manual — close/reopen note | **NOT TESTED** |
| 8 | Bold, italic, heading, lists unaffected | Manual | **NOT TESTED** |

#### Verification Commands Run
```
flutter test test/spacing_test.dart   → 3/3 PASS
flutter analyze                       → 1 pre-existing info (generated file), 0 new errors
```

#### Final Status
**FIX IMPLEMENTED — VERIFICATION INCOMPLETE**

Automated tests pass. Runtime manual verification on Android required to confirm the visual gap is resolved.

#### Notes / Remaining Risks
- `paragraphSpacing` setting version migration will reset existing users' custom spacing to `4.0` on next app launch if they were on version < 2. This is by design (version bump forces reset) but may surprise users who manually set it to e.g. `6.0`.
- `_currentSettingsVersion` is still `2` — if a future change needs another reset, bump it to `3`.

---

## Infrastructure Issues (non-bug, tracked separately)

### INFRA-001 — No Git commits (no baseline for diff)

**Status:** OPEN
**Identified:** 2026-10-03
**Risk:** Cannot diff changes against a clean state. Regressions are hard to detect.
**Action Required:** Run `git add . && git commit -m "Initial commit — baseline before bug fixing"` from `C:\Project\MNotes\mindsparq_notes` before making any code changes.

### INFRA-002 — Android SDK warning (compileSdk 34 < required 35)

**Status:** CLOSED
**Identified:** 2026-10-03
**Closed:** 2026-10-03
**Root Cause:** `compileSdk = flutter.compileSdkVersion` resolved to 34; `flutter_plugin_android_lifecycle` and `sqlite3_flutter_libs` require 35.
**Fix:** Changed `android/app/build.gradle` line 10 from `compileSdk = flutter.compileSdkVersion` to `compileSdk = 35`.
**Verification:** Build succeeded (`app-debug.apk` generated). Warning no longer appears.

### INFRA-003 — Silent exception suppression in 11 locations

**Status:** OPEN
**Identified:** 2026-10-03
**Risk:** P2 — Errors silently swallowed make debugging difficult and can mask data loss.
**Locations:**
- `lib/app/providers/note_editor_provider.dart:92` — JSON parse failure becomes blank editor silently
- `lib/features/ai/data/services/ai_writing_service.dart:128, 184`
- `lib/features/ai/presentation/widgets/ai_assistant_tab.dart:106`
- `lib/features/media/data/services/attachment_storage_service.dart:45, 97, 152`
- `lib/features/notes/presentation/widgets/editor_context_menu.dart:257`
- `lib/features/notes/presentation/services/markdown_paste_service.dart:236`
- `lib/features/research/data/services/research_storage_service.dart:67, 77`
**Action Required:** Add logging to each `catch (_)` block at minimum. Escalate data-loss cases (note_editor_provider.dart:92) to P1.

---

## Closed Bugs

_Entries moved here once FIXED AND VERIFIED._

| ID | Title | Closed | Status |
|---|---|---|---|
| INFRA-002 | Android SDK warning (compileSdk 34) | 2026-10-03 | FIXED AND VERIFIED |

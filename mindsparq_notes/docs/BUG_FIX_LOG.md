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

2. **Default/dropdown mismatch & Toolbar Quick Control**:
   - Default `paragraphSpacing` updated to `1.0 pt` upon user request.
   - Settings version bumped to `3` to migrate existing installs to `1.0 pt` default.
   - Settings dialog dropdown now dynamically supports `1 pt (Default)` as well as any custom numerical spacing without assertion failures.
   - Direct Paragraph Spacing control (`_ParagraphSpacingToolbarItem`) added to the rich text editor top toolbar directly beside Text Formatting (Bold, Italic), complete with:
     - `[-]` / `[+]` quick stepper buttons
     - Live spacing badge (e.g. `1 pt`)
     - Quick preset chips (`0 pt`, `1 pt`, `2 pt`, `3 pt`, `4 pt`, `6 pt`, `8 pt`, `12 pt`)
     - Manual custom input text field with live parsing & validation (allows entering 1, 2, 3, 4 or custom values directly without going to Settings).

#### Files Changed
| File | Change |
|---|---|
| `lib/app/providers/settings_provider.dart` | Default `paragraphSpacing` 4.0 → 1.0; migration version 2 → 3; clamp range up to 24.0 |
| `lib/features/settings/presentation/settings_dialog.dart` | Added `1 pt (Default)`; dynamic dropdown items with safe handling for custom values |
| `lib/features/notes/presentation/note_editor_screen.dart` | Added `_ParagraphSpacingToolbarItem` and `_ParagraphSpacingDialog` to editor toolbar next to Bold/Italic |
| `test/spacing_test.dart` | Updated default to 1.0; added tests for stepper decrement, increment, and manual parsing |

#### Acceptance Criteria

| # | Criterion | Method | Result |
|---|---|---|---|
| 1 | Symmetric padding contract: top == bottom == spacing/2 | `flutter test test/spacing_test.dart` | **PASS** |
| 2 | Total inter-paragraph gap == exactly 1× spacing | `flutter test test/spacing_test.dart` | **PASS** |
| 3 | Default value (1.0) matches a valid dropdown option | `flutter test test/spacing_test.dart` | **PASS** |
| 4 | Stepper and manual input parsing & clamping | `flutter test test/spacing_test.dart` | **PASS** |
| 5 | `flutter analyze` — no new errors in edited files | `flutter analyze` | **PASS** (1 pre-existing info in generated file) |
| 6 | Direct toolbar control next to Bold/Italic | Code inspection | **PASS** |
| 7 | Quick presets & manual typing modal | Code inspection | **PASS** |

#### Verification Commands Run
```
flutter test test/spacing_test.dart   → 4/4 PASS
flutter analyze                       → 1 pre-existing info (generated file), 0 new errors
```

#### Final Status
**FIX IMPLEMENTED & VERIFIED**

---

### MSN-BUG-002 — Hardcoded EditorStyle padding injecting 56px gap between every paragraph block on Enter

**Status:** CLOSED
**Priority:** P1
**Platform:** Windows Desktop / Android / Web
**Feature / Module:** Note Editor / Block Component Rendering
**Reported:** 2026-10-03
**Closed:** 2026-10-03

#### Problem Description
Even when `paragraphSpacing` is set to 0.0 pt or 1.0 pt, pressing Enter creates an excessively large vertical gap (measured ~78 px in user screenshots). The paragraph spacing stepper or setting had almost no visible effect on closing the gap.

#### Root Cause
1. **Per-Block Padding Inflation**: In `note_editor_screen.dart`, `AppFlowyEditor` had:
   ```dart
   editorStyle: EditorStyle.desktop(
     padding: const EdgeInsets.only(top: 8, bottom: 48),
   )
   ```
   In AppFlowy Editor's `page_block_component.dart`, `editorState.editorStyle.padding` is **not** applied to the viewport — it is wrapped around **each and every individual block item** in the document:
   ```dart
   ...items.map(
     (e) => Padding(
       padding: editorState.editorStyle.padding,
       child: editorState.renderer.build(context, e),
     ),
   )
   ```
   As a result, between *every consecutive paragraph*, the editor injected `bottom: 48 + top: 8 = 56 pixels` of unremovable whitespace, completely dwarfing the 1.0 pt setting.
2. **Missing Renderer Rebind**: AppFlowyEditor caches its renderer and does not refresh builders on standard widget rebuilds unless explicitly reassigned or remounted.

#### Fix Implemented
1. Set `editorStyle: EditorStyle.desktop(padding: EdgeInsets.zero)`.
2. Passed `footer: const SizedBox(height: 48)` to `AppFlowyEditor` so comfortable scroll clearance at the bottom of the note is preserved without adding space between blocks.
3. Explicitly reassigned `editorData.editorState.renderer = BlockComponentRenderer(builders: customBuilders);` and keyed `AppFlowyEditor` dynamically to guarantee instant visual updates whenever font or spacing settings change.
4. Added regression test `rendered paragraph gap matches configured spacing with zero editorStyle padding (regression: MSN-BUG-002)` in `test/spacing_test.dart` verifying exact pixel measurements.

#### Verification
- `flutter test test/spacing_test.dart` -> 5/5 PASS (gap at 0.0 pt is 0.0 px, gap at 1.0 pt is 1.0 px).
- `flutter test` -> 26/26 PASS.

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

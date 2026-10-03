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

_No active bugs recorded yet. Add entries here as bugs are confirmed._

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

# MindSparQ Note — Engineering Rules (AGENTS.md)

> **This file is the authoritative instruction set for every coding agent, AI assistant, or automated tool
> working on this project. Read it in full before touching any file.**

---

## 0. Core Principle

**Correct behaviour in the running application matters more than claiming completion.**

Compilation succeeding is not proof of correctness.
A changed file is not proof of a fix.
"It should work" is not an acceptable final status.

---

## 1. Technology Stack (read-only summary — verify against source before assuming)

| Layer | Technology |
|---|---|
| Language | Dart ≥ 3.5.0 |
| Framework | Flutter (multi-platform: Android, Windows, Linux, Web, iOS) |
| State management | Riverpod 2 (flutter_riverpod, riverpod_annotation, riverpod_generator) |
| Routing | go_router |
| Database | Drift + SQLite (sqlite3_flutter_libs, drift_flutter) |
| Editor | appflowy_editor |
| Settings | shared_preferences |
| DI | get_it |
| Code generation | build_runner, freezed, json_serializable, drift_dev |
| Android compileSdk | 35 (explicitly set — do not lower) |

---

## 2. Architecture — Module Boundaries

```
lib/
  app/          # App bootstrap, providers, router, theme, screens
  core/         # Shared utilities, base classes
  data/         # Repository implementations, DB, providers
  domain/       # Models, repository interfaces (pure Dart)
  features/
    ai/         # Gemini AI writing assistant — isolated
    auth/       # Authentication — isolated
    editor/     # Note editor wrapper
    export/     # Export feature
    folders/    # Folder management
    media/      # Image/attachment handling
    notes/      # Note list, note editor screen (94 KB — high-risk file)
    onboarding/ # Onboarding flow
    research/   # Research storage
    search/     # Search feature
    settings/   # Settings UI
    tags/       # Tag management
  shared/       # Shared widgets, helpers
```

**Protected module boundaries:**
- features/ai must not directly write to note content without user confirmation.
- features/notes/presentation/note_editor_screen.dart is large (~94 KB). Make surgical edits only. Never rewrite wholesale.
- app/providers/note_editor_provider.dart owns autosave. Do not duplicate save logic elsewhere.
- app/providers/settings_provider.dart owns all persisted settings. Do not read SharedPreferences directly from widgets.

---

## 3. Before Every Bug Fix — Mandatory Pre-Work

1. Restate the reported problem in your own words.
2. Define Expected Behavior and Actual Behavior explicitly.
3. Identify reproducible steps.
4. Inspect the relevant implementation and existing tests.
5. Trace the full event flow:
   User action → UI event → Provider/Notifier → Repository → DB/SharedPrefs → UI rebuild
6. Establish a root-cause hypothesis with supporting evidence from source code or logs.
7. Propose the smallest safe change and state which files will be modified.
8. Get approval before making risky structural changes.

Do NOT begin editing until steps 1–7 are complete.

---

## 4. During Implementation

- Work only within the approved scope.
- Modify only the files identified in the root-cause investigation.
- Preserve all unrelated working features and existing user data.
- Do not perform unrelated refactoring alongside a bug fix.
- Do not introduce new dependencies without explicit approval.
- Do not suppress exceptions silently (catch (_) {}). Log them at minimum.
- Do not fabricate success states or return fake data.
- Do not change, delete, or reset user notes, settings, or the SQLite database without explicit written approval.
- When modifying note_editor_screen.dart, verify that surrounding context is unchanged after editing.

---

## 5. Verification — Mandatory After Every Change

### 5.1 Automated checks (run in this order)

```powershell
# From project root: C:\Project\MNotes\mindsparq_notes

flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
```

Do not claim any check passed unless you ran it and observed the output.
Do not weaken a failing assertion to make a test pass.

### 5.2 Regression checks

After every fix, re-run tests for:
- The fixed feature
- Autosave and note persistence (NoteEditorController.saveImmediately)
- Settings persistence (SettingsNotifier)
- Any feature that shares state with the fixed module

### 5.3 Runtime verification

When the environment permits a running app:
- Reproduce the original bug to confirm it existed before the fix.
- Verify the fix in the running application.
- Close and reopen the note to confirm persistence.
- Restart the app to confirm settings survive restart.

If runtime verification is not possible, state explicitly:
"Runtime verification not performed — reason: [X]"

---

## 6. Acceptance Criteria Format

For every bug, produce a checklist:

| # | Criterion | Method | Result |
|---|---|---|---|
| 1 | Description of criterion | flutter test / Manual | PASS / FAIL / NOT TESTED |

Results must be one of: PASS, FAIL, NOT TESTED.
Do not use "likely", "should", or "assumed".

---

## 7. Reporting — Required Final Status

Use exactly one of these labels:

| Label | Meaning |
|---|---|
| FIXED AND VERIFIED | All acceptance criteria PASS with evidence |
| FIX IMPLEMENTED — VERIFICATION INCOMPLETE | Code changed; some checks not run |
| PARTIALLY FIXED | Some criteria PASS, some FAIL |
| NOT FIXED | Problem remains |
| BLOCKED | Specific blocker prevents progress |

Never use FIXED AND VERIFIED when only compilation or static analysis was checked.

---

## 8. Known High-Risk Areas (audit-identified, October 2026)

| Area | Risk | Location |
|---|---|---|
| Silent exception suppression | Errors swallowed without logging | note_editor_provider.dart:92, ai_writing_service.dart:128+184, attachment_storage_service.dart:45+97+152, research_storage_service.dart:67+77, editor_context_menu.dart:257, markdown_paste_service.dart:236, ai_assistant_tab.dart:106 |
| Content parse failure | Corrupt note silently becomes blank on open | note_editor_provider.dart:92-94 |
| Note editor screen size | 94 KB single file, high collision risk on edits | note_editor_screen.dart |
| Settings version migration | Overwrites user typography values on version bump | settings_provider.dart:79-84 |
| No Git history | Cannot diff against a clean baseline | Repository has no commits yet — commit before first fix |

---

## 9. Definition of Done

A bug is done only when:

- Requirement is understood and restated.
- Root cause is documented with evidence.
- Fix addresses the root cause (not a symptom).
- Acceptance criteria are defined and checked.
- flutter analyze passes.
- flutter test passes (or failures are explained).
- Runtime behavior is verified OR the limitation is documented.
- Existing functionality has been regression-tested.
- Final report accurately reflects evidence — no invented results.

---

## 10. Scope Safety Rules

- Do not perform database migrations or schema changes without explicit approval.
- Do not reset SharedPreferences unless fixing a documented settings bug.
- Do not change compileSdk below 35.
- Do not remove the settings version migration without ensuring existing users are not affected.
- Do not merge AI, editor, and notes logic into shared state.
- Do not auto-commit or push to Git on behalf of the user.

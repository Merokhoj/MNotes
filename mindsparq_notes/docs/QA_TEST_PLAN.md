# MindSparQ Note — QA Test Plan

> **Version:** 1.0 — October 2026
> **Status:** Baseline (pre-regression-suite)
> **Platform coverage:** Android, Windows, Linux, Web (where applicable)

---

## How to Use This File

- Before fixing a bug, find the relevant section and mark affected test cases.
- After a fix, re-run the affected section and record results.
- Add new test cases whenever a new feature is added or a bug is confirmed.
- Result values: **PASS** | **FAIL** | **NOT TESTED** | **N/A**

---

## A. Editor and Formatting

### A1 — Text Formatting

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| A1-01 | Bold applies via toolbar button | Manual | NOT TESTED | — |
| A1-02 | Bold applies via Ctrl+B shortcut | Manual | NOT TESTED | — |
| A1-03 | Italic applies via toolbar button | Manual | NOT TESTED | — |
| A1-04 | Italic applies via Ctrl+I shortcut | Manual | NOT TESTED | — |
| A1-05 | Underline applies via toolbar button | Manual | NOT TESTED | — |
| A1-06 | Bold+Italic combined apply correctly | Manual | NOT TESTED | — |
| A1-07 | Formatting clears correctly (toggle off) | Manual | NOT TESTED | — |
| A1-08 | Formatting preserved across undo/redo | Manual | NOT TESTED | — |

### A2 — Heading Levels

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| A2-01 | H1 button applies heading level 1 | Manual | NOT TESTED | — |
| A2-02 | H2 button applies heading level 2 | Manual | NOT TESTED | — |
| A2-03 | H3 button applies heading level 3 | Manual | NOT TESTED | — |
| A2-04 | Heading toolbar button shows active state when cursor is in heading | Manual | NOT TESTED | — |
| A2-05 | Clicking active heading button removes heading (toggle) | Manual | NOT TESTED | — |
| A2-06 | Heading persists after note reopen | Manual | NOT TESTED | — |

### A3 — Toolbar Active State

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| A3-01 | Bold button shows active when cursor in bold text | Manual | NOT TESTED | — |
| A3-02 | Italic button shows active when cursor in italic text | Manual | NOT TESTED | — |
| A3-03 | H1/H2/H3 buttons show active per cursor position | Manual | NOT TESTED | — |
| A3-04 | Active state updates when cursor moves between paragraphs | Manual | NOT TESTED | — |
| A3-05 | Active state resets when selection is cleared | Manual | NOT TESTED | — |

### A4 — Undo / Redo

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| A4-01 | Ctrl+Z undoes last character typed | Manual | NOT TESTED | — |
| A4-02 | Ctrl+Z undoes formatting change | Manual | NOT TESTED | — |
| A4-03 | Ctrl+Y/Ctrl+Shift+Z redoes undone action | Manual | NOT TESTED | — |
| A4-04 | Undo does not undo autosave (content remains in DB) | Manual | NOT TESTED | — |

---

## B. Save and Persistence

### B1 — Autosave

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| B1-01 | Content saves automatically ~800ms after typing stops | Manual + logs | NOT TESTED | — |
| B1-02 | isSaving indicator appears during save | Manual | NOT TESTED | — |
| B1-03 | isSaving clears after save completes | Manual | NOT TESTED | — |
| B1-04 | Title saves automatically after change | Manual | NOT TESTED | — |
| B1-05 | Rapid typing does not trigger multiple concurrent saves | Manual + logs | NOT TESTED | — |

### B2 — Note Reopen

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| B2-01 | Plain text persists after close and reopen | Manual | NOT TESTED | — |
| B2-02 | Bold/italic/heading formatting persists after reopen | Manual | NOT TESTED | — |
| B2-03 | Note with empty content reopens as blank (no crash) | Manual | NOT TESTED | — |
| B2-04 | Note with corrupted JSON content reopens as blank (no crash) | Unit test | NOT TESTED | — |
| B2-05 | Note title persists after reopen | Manual | NOT TESTED | — |

### B3 — App Restart

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| B3-01 | Notes list restored after app restart | Manual | NOT TESTED | — |
| B3-02 | Note content restored after app restart | Manual | NOT TESTED | — |
| B3-03 | Theme setting persists after restart | Manual | NOT TESTED | — |
| B3-04 | Font/font-size settings persist after restart | Manual | NOT TESTED | — |
| B3-05 | Sidebar width setting persists after restart | Manual | NOT TESTED | — |

---

## C. Images and Media

### C1 — Image Insertion

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| C1-01 | Image inserts at cursor position | Manual | NOT TESTED | — |
| C1-02 | Image path stored in attachment storage | Manual + DB | NOT TESTED | — |
| C1-03 | Image visible after note reopen | Manual | NOT TESTED | — |
| C1-04 | Missing image file handled gracefully (no crash) | Manual | NOT TESTED | — |

### C2 — Image Operations

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| C2-01 | Image can be deleted | Manual | NOT TESTED | — |
| C2-02 | Deleting image clears attachment storage entry | Manual + DB | NOT TESTED | — |
| C2-03 | Long note with multiple images scrolls without layout errors | Manual | NOT TESTED | — |

---

## D. Notes Management

### D1 — CRUD

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| D1-01 | Create new note — appears in list | Manual | NOT TESTED | — |
| D1-02 | Rename note — new title persists | Manual | NOT TESTED | — |
| D1-03 | Delete note — removed from list and DB | Manual | NOT TESTED | — |
| D1-04 | Note list sorted by updatedAt descending | Manual | NOT TESTED | — |
| D1-05 | Note preview updates after content change | Manual | NOT TESTED | — |

### D2 — Folders, Tags, Favorites

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| D2-01 | Note assigned to folder appears in folder view | Manual | NOT TESTED | — |
| D2-02 | Tag added to note appears in tag view | Manual | NOT TESTED | — |
| D2-03 | Toggling favorite updates favorites list immediately | Manual | NOT TESTED | — |
| D2-04 | Favorite state persists after restart | Manual | NOT TESTED | — |

---

## E. Search

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| E1-01 | Search returns notes containing query in title | Manual | NOT TESTED | — |
| E1-02 | Search returns notes containing query in preview/content | Manual | NOT TESTED | — |
| E1-03 | Clearing search restores full note list | Manual | NOT TESTED | — |

---

## F. Settings

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| F1-01 | Dark mode applies immediately | Manual | NOT TESTED | — |
| F1-02 | Light mode applies immediately | Manual | NOT TESTED | — |
| F1-03 | Font change reflects in editor immediately | Manual | NOT TESTED | — |
| F1-04 | Font size change reflects in editor immediately | Manual | NOT TESTED | — |
| F1-05 | Gemini API key saves and loads correctly | Manual | NOT TESTED | — |
| F1-06 | Line height change reflects in editor | Manual | NOT TESTED | — |
| F1-07 | Paragraph spacing change reflects in editor | Manual | NOT TESTED | — |
| F1-08 | Settings version migration resets typography on version bump | Unit test | NOT TESTED | — |

---

## G. AI Assistant

| ID | Test Case | Method | Last Result | Date |
|---|---|---|---|---|
| G1-01 | AI request fails gracefully when API key is empty | Manual | NOT TESTED | — |
| G1-02 | AI request fails gracefully when offline | Manual | NOT TESTED | — |
| G1-03 | AI error shown to user — no silent failure | Manual | NOT TESTED | — |
| G1-04 | AI response does not overwrite existing note without confirmation | Manual | NOT TESTED | — |

---

## H. Existing Automated Tests (as of October 2026)

| File | Purpose | Status |
|---|---|---|
| test/widget_test.dart | Basic widget smoke test | Run: `flutter test test/widget_test.dart` |
| test/editor_test.dart | Editor widget tests | Run: `flutter test test/editor_test.dart` |
| test/editor_test2.dart | Editor widget tests (2) | Run: `flutter test test/editor_test2.dart` |
| test/editor_test3.dart | Editor widget tests (3) | Run: `flutter test test/editor_test3.dart` |
| test/markdown_test.dart | Markdown parsing tests | Run: `flutter test test/markdown_test.dart` |
| test/spacing_test.dart | Spacing/typography tests | Run: `flutter test test/spacing_test.dart` |
| test/ai_writing_service_test.dart | AI writing service tests | Run: `flutter test test/ai_writing_service_test.dart` |
| test/phosphor_test.dart | Icon presence test | Run: `flutter test test/phosphor_test.dart` |

**Run all tests:** `flutter test`

---

## I. Regression Checklist (run after every bug fix)

After any fix, verify:

- [ ] `flutter analyze` passes with no new errors.
- [ ] `flutter test` — no new failures.
- [ ] Note create → edit → close → reopen preserves content.
- [ ] Settings survive app restart.
- [ ] No new silent `catch (_) {}` blocks introduced.
- [ ] note_editor_screen.dart diff reviewed for unintended changes.
- [ ] If editor changed: autosave still fires after 800ms.
- [ ] If settings changed: migration version and defaults correct.

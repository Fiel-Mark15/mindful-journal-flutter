# Settings, Tasks and Journal layouts — October 8, 2026

This pass implements the supplied request as an addition to the existing Mindful Journal app. No dependencies were added and the main navigation remains Home / Journal / + / Calendar / Profile.

## Settings and information pages

Profile now opens a dedicated grouped Settings screen. On phones all sections scroll in one column; at 900px and above a category list sits beside its detail. Profile editing, System/Light/Dark appearance, accent selection and writing preferences reuse the existing functionality. Word count and haptics connect to the existing shared session preferences.

Privacy Overview, Privacy Policy and Terms of Use are local, scrollable documents with bounded reading width and support for text scaling. Their text describes the current runtime-only implementation, selected-file behavior and absence of accounts, database, journal upload, AI APIs and cloud sync. They make no encryption or app-lock claim. Developer/contact information is explicitly unspecified and marked with a TODO in `legal_screen.dart`. Source comments require review and updates before production distribution or any change in actual data handling.

About includes the CSE101 edition and `1.0.0+1`, matched against `pubspec.yaml` by a test. Open-source licenses use Flutter's `showLicensePage` and its built-in registry.

## Clear Session

A destructive confirmation provides Cancel and Clear. Cancellation leaves all data untouched. Confirmation clears entries (including checklists, photos and drawings), standalone tasks, profile personalization, theme/accent, writing preferences, layout choice, favorite/used prompts and recent searches. The shell is recreated, so navigation, selection, check-in and inline draft state reset. Secondary routes close. Flutter image caches are cleared as well. Original imported files are never deleted. Starting examples are not reinserted until a fresh process launch.

Outgoing Settings route inputs are captured before navigation, avoiding access to a disposed shell during the reset/route transition.

## Tasks

`JournalTask` is independent from journal checklists: ID, title, completion, creation date, optional due date and category. Tasks live in the shared runtime session. Create/edit validates title and preserves creation/completion metadata; due dates and categories are optional. Delete has a confirmation. Today includes outstanding overdue tasks with a visible Overdue label; Upcoming, Undated and Completed hold the remaining groups.

Completion reuses the existing checked semantics, compress/drawn check and light haptic. Text fades/strikes softly; section movement waits for the standard 280ms completion interval. Profile always offers Tasks. Home shows at most two outstanding Today tasks only when there are some, keeping the initial Home uncluttered. Reflect on today opens the existing normal editor without generated content.

## Journal views

Card remains the default and retains animated record insertion. List is a compact scanning layout with date, title, preview, mood, optional collection/tags and favorite controls. Grid uses two to four columns according to available width, consistent photo/drawing cover ratios, and an accent/weather surface for text-only entries. Text-scaled cell heights avoid fixed-height overflow. Month grouping remains in every mode.

The view menu exposes selection and checkmarks. The choice is shared for the session, including Favorites, and resets to Card when cleared. A 280ms fade switches layouts (reduced motion skips it). Unique AnimatedList keys handle rapid switches safely. All modes consume the same searched/filtered data; favorites use the original record update callback. Wide reading/editing panes remain available. Grid can use the full available archive width until an entry is selected.

## Files

Added:

- `lib/models/journal_task.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/legal_screen.dart`
- `lib/screens/tasks_screen.dart`
- `lib/widgets/journal_entry_views.dart`
- `test/settings_tasks_views_test.dart`
- this report and Settings/Tasks/List/Grid/legal page previews

Changed `lib/app/app.dart`, `lib/core/experience/journal_experience.dart`, Home, Profile and Timeline screens, `lib/widgets/journal_components.dart`, the journal empty-state assertion and opt-in preview capture test. The existing editor, media import, drawings, rich formatting, prompts, templates, collections, calendar, streaks, insights and plus-button animation are retained.

## Validation

- Ten new tests pass: settings/document/license navigation; confirmation and complete root reset; task grouping/create/validation/edit/complete/delete; version consistency; shared view mode, search and favorites; enlarged-text Grid/Settings/documents at 320×640, 844×390 and 1440×900.
- Full regression suite: **78 tests passed**, two opt-in preview tests skipped (`flutter test --no-pub --concurrency=1`).
- Analyzer: no issues found.
- Both opt-in screenshot capture tests pass. Reviewed Settings, Tasks, Grid and Privacy document renders.
- Native iPhone 18 Pro simulator build/launch: **successful**, exit 0 (`flutter run -d 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 --no-resident --no-pub`). Xcode build took 12.1 seconds; updated files synced in 167ms.

## Scope and limits

All state is runtime-only; no backend, authentication, database, analytics, cloud sync or persistent settings were introduced. The legal text is scoped to this educational build and still has the requested developer/contact placeholder. Only the iOS native target is built/launched here; native accessibility and physical-device haptics require manual device review. Flutter widget tests cover the responsive layouts. No additional permanent navigation tab or unrelated task-manager feature was introduced.

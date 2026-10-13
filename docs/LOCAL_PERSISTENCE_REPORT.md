# Device-local persistence — October 11, 2026

Implemented for the existing Mindful Journal app without changing screen layouts or navigation. No Firebase or cloud storage was added. Android backup is disabled in the manifest.

## Services and files

- `lib/core/storage/local_journal_store.dart`: `LocalJournalStore`, startup loading, serialized snapshot writes, recovery backup, owned media storage and clear-data cleanup.
- `DeviceSettingsStorage` in that file: `SharedPreferencesAsync` adapter; settings key `mindful_journal.settings.v1`.
- `lib/app/app.dart`: hydrates storage before showing normal app state, subscribes to changes, commits entry saves, reports write failures with Retry and saves on background transitions.
- `lib/core/experience/journal_experience.dart`: serializes/restores tasks, prompt flags, searches, mood check-in, view mode and preferences.
- Existing model files now provide `toJson()` and `fromJson()` for entries, attachments, drawings/strokes, checklist items, formatting runs, tasks, profile, accent, preferences and collections.
- `test/local_persistence_test.dart`: file-based restart, serialization, queue, recovery, media, clear-data, traversal and startup gating tests.

## Storage layout

The application documents directory contains:

```text
mindful_journal/
  journal.json
  journal.json.bak
  journal.json.tmp   # only during a write
  media/
    <unique-id>.png
```

`journal.json` is a versioned snapshot of journal entries and tasks, including mood, favorites, tags, collection membership, checklist state, rich text formatting, attachment paths and editable drawing vectors. It also records the predefined collection catalog and prompt/history flags. Existing collections are predefined; there is no collection-management screen to change.

Shared preferences contains profile name/tagline and photo path, theme, the full custom accent colors, journal view mode, onboarding completion and all existing app preferences. Profile image bytes live in the media directory.

The existing picker validates and normalizes selected images to PNG bytes. These accepted bytes are copied into the app's documents directory before their relative paths are saved. Picker temporary paths are never persisted. Journal photos, profile pictures and drawing preview PNGs are restored from owned files; drawings also retain editable stroke data. Relative paths survive changes to the app sandbox root.

## Save and recovery behavior

Every existing entry create/edit/delete, mood update, favorite/checklist toggle, task create/edit/delete/completion, profile change, theme/accent change and preference change immediately queues a snapshot. Writes run in order, with immutable JSON snapshots captured at the time of the change. Editor and quick check-in success confirmation await persistence.

JSON is flushed to a temporary file and renamed into place. The previous valid JSON is retained as a recovery backup. A malformed main JSON can recover from the backup. If both are unreadable, startup displays Retry and preserves files instead of silently replacing user data. Missing or invalid media similarly surfaces a load error.

First-run samples are written only when neither the saved journal nor recovery backup exists. Deleting all entries does not reseed them. The existing Clear action saves an empty state before removing owned media and the backup. Ordinary deletion may leave older media and the previous snapshot on disk until Clear; there is no per-entry orphan cleanup.

Settings and JSON are separate writes, not one cross-file transaction. A write error is surfaced with retry; entry commit errors keep the editor draft available. Other existing controls update optimistically and queue immediate saves. There is no new encryption layer; files remain in the app's private device storage. Uninstalling or clearing Android app storage removes these records.

Dependencies: [shared_preferences](https://pub.dev/packages/shared_preferences) and [path_provider](https://pub.dev/packages/path_provider).

## Verification

- `dart format .`: passed.
- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --no-pub`: passed, 86 tests; 2 optional preview tests skipped.
- `flutter build apk --release --no-pub`: passed, APK approximately 57.1 MB.

APK: `build/app/outputs/flutter-apk/app-release.apk`. Existing app identifier and signing configuration were retained.

Tests create a fresh store instance and load real local JSON/media after writes, checking entries, photos, profile, theme/accent, tasks, tags, favorites, checklist state and preferences. They verify empty-journal reopening and startup waiting for hydration. No Android device was connected during this run, so actual installation and force-stop/reopen behavior was not manually verified on a phone.

Device acceptance: install APK, create an entry with a photo/checklist, update profile picture and theme, create a task, fully close the app, reopen, and verify the same data. Repeat after deleting all entries to confirm samples do not reappear.

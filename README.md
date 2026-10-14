# Mindful Journal — CSE101

An iOS-inspired personal journal for Fiel Mark Oronos CSE101 final project. The existing Flutter starter now includes a complete reflection → writing → reading flow with an indigo identity and an editorial writing surface.

## Features

- Mood check-in with five labeled choices and preselected editor mood.
- Create, read, edit, and confirmed deletion of journal entries.
- Date picker, required title/body validation, word count, unsaved-change protection.
- Chronological timeline grouped by month; useful empty states.
- Editable saved name, tagline and circular photo preview; Home updates immediately.
- Home / Journal / Calendar / Profile destinations, plus a separate global creation menu.
- Honest writing streaks, linked calendar history and backdated writing.
- Instant local search, mood/media/tag/Favorites filters and highlighted matches.
- Animated editable checklists, saved Favorites and secondary Insights.
- Up to four saved photos and two editable drawings per entry, with zoom previews.
- Pen, Marker, Highlighter, Pencil and a working Eraser; drawing undo/redo and clear.
- Eight accent themes plus a custom color picker, retaining System/Light/Dark.
- Selected-text and typing formatting, text colors/highlights, undo/redo, formatted reading and Focus mode.
- Live entry count, average mood, word total and most common mood; System/Light/Dark appearance.
- Centered tablet layouts and desktop side navigation, accessible buttons and mood semantics.
- Cmd/Ctrl+N on Home, Cmd/Ctrl+S in the editor, Escape to close with dirty-form protection.
- Original generated journal icon and matching iOS launch mark.

## Run and verify

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Validated with Flutter 3.47.7 / Dart 3.13.5. `shared_preferences` stores profile and appearance preferences; `path_provider` locates the app's Application Documents Directory for JSON records and media. Selected photos keep the existing validation and 1024px normalization before being copied as PNG files into app-owned storage.

## Local persistence

Startup loads saved entries, tasks, checklist state, favorites, tags, collection membership, profile and preferences before displaying the normal app. Mutations immediately queue serialized writes. Journal editor and quick check-in confirmation wait for the save to finish. Samples are inserted only when no saved journal or recovery file exists; an empty saved journal remains empty after reopening.

See [local persistence implementation and verification](docs/LOCAL_PERSISTENCE_REPORT.md). This implementation supersedes the runtime-only descriptions in earlier assignment and implementation documents. UI layout and navigation remain unchanged.

## Source map

- `lib/app/app.dart`: root state, startup hydration, persistence callbacks and themes.
- `lib/models/journal_entry.dart`: entry and mood models, bundled examples.
- `lib/core/`: design tokens and shared formatting/counting/sorting functions.
- `lib/screens/`: onboarding, Home shell, editor, reading, timeline, Profile.
- `lib/widgets/`: accessible mood selector and reusable canvas/cards/empty state.
- `test/`: behavior and responsive-layout verification; optional screenshot capture.
- `tools/generate_branding.py`: generate launcher/launch-image sizes from the approved master artwork.

## Platform status

The project includes Android, iOS and macOS runners. The Android release APK builds successfully at `build/app/outputs/flutter-apk/app-release.apk`. This validation ran on macOS without a connected Android device; an actual Android install/force-stop/reopen check remains a device acceptance step. The APK retains the existing signing configuration. Responsive widget checks exercise phone, tablet, desktop, landscape and enlarged text.

See [release steps](docs/RELEASE_GUIDE.md), [assignment mapping](docs/ASSIGNMENT_COMPLIANCE.md), [architecture](docs/ARCHITECTURE.md), [design system](docs/DESIGN_SYSTEM.md), [submission checklist](docs/SUBMISSION_GUIDE.md), and [future production roadmap](docs/PRODUCTION_ROADMAP.md).

## Branding

`assets/images/app_icon.png` is the final approved folded-leaf artwork, copied byte-for-byte from the supplied PNG. It is the single master source; do not draw, recolor or replace it. `flutter_launcher_icons` generates the iOS AppIcon catalog. The existing 80pt launch image is refreshed from the same source, with the storyboard and launch background preserved.

```sh
rtk proxy dart run flutter_launcher_icons
# Or refresh AppIcon and the existing launch-image sizes together:
rtk proxy python3 tools/generate_branding.py
```

See [icon integration and refresh instructions](docs/ICON_INTEGRATION_REPORT.md). iOS is the only existing runner; Android/macOS/Windows/Web icon generation stays disabled until those runners are added and reviewed.


## October 8 product experience pass

See [Product experience report](docs/PRODUCT_EXPERIENCE_REPORT.md) for Today and memory logic, Prompt Packs, templates, collections, quick check-ins, writing preferences, Reflection Rings and wide Journal reading/editing panes. All additions are runtime-only; the existing single List of entries, media and rich formatting remain in place.


## Settings, Tasks and layout refinement

See [Settings, Tasks and layouts report](docs/SETTINGS_TASKS_VIEWS_REPORT.md) for the latest incremental upgrade, session clearing, legal placeholders and verification.

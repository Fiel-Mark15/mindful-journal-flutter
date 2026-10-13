# Mindful Journal — additive product pass

Implemented from the master prompt supplied October 8, 2026. This extends the existing app and its visual identity. No packages were added.

## Product behavior

- **Today:** detects all saved entries by local civil date. Empty days offer “Write about today”; one entry offers “Continue writing”; multiple entries open a compact list. Mood, streak and recent entries remain available.
- **Memory resurfacing:** selects an earlier anniversary-date entry if available, otherwise the latest earlier entry. Today and future entries are excluded. Starting examples are explicitly labeled. Opens the original record; no simulated persisted history.
- **Prompt Packs:** 36 hand-written questions across nine categories. Hearts and exploration progress stay in runtime sets. A prompt becomes explored only after its entry is saved, not when selected. Available from Create and Profile.
- **Templates:** nine choices including Blank Page, Morning Check-In, Evening Reflection and Weekly Review. Section text is fully editable in the existing rich editor. Blank entry remains one tap away.
- **Collections:** General plus Personal, College, Ideas, Memories and Goals. A single optional collection ID per entry; a compact horizontal Journal selector and an editor picker. These group one runtime entry list.
- **Tags:** existing tag editing retained. Cards show at most two tags; reading shows all. Filters support multiple tags with AND matching, independently combined with mood, media and Favorites.
- **Favorites:** dedicated Profile destination plus existing reading heart and Journal filter. Removing a favorite updates the shared runtime record. Copying a record now retains creation date and all added metadata.
- **Quick Check-In:** choose a mood, optionally add up to eight activity tags, energy and a short note. Saves into the same JournalEntry model, without a separate data store. The previous Home mood-to-writing flow remains available.
- **Entry kinds:** Text, Photo Memory, Checklist, Drawing, Prompt Reflection and Quick Check-In. Shared editor and media models; quiet type labels in cards.
- **Calendar:** Entries is the default mode; Mood adds the existing weather glyphs. Date taps show entry count, recorded moods, previews and a past/today writing action. Future days do not pretend to be writable. Existing streak links and reached milestones remain.
- **Insights:** Reflection Rings label their denominators: this week’s writing days / 7, recorded mood variety / 5, and entries containing media or checklists / all entries. Additional cards show average words, longest reflection and frequently saved tags. Activity/mood descriptions require at least three positive-mood check-ins and two occurrences, and explicitly describe counts rather than psychological causation.
- **Writing preferences:** Modern, Editorial and platform Classic Serif body typography; 16–26 text size; Clean, Paper, Soft Lines and Dot Grid surfaces; default collection; word-count visibility in the editor; global haptics preference. UI chrome stays native. All choices are temporary.
- **Reading:** comfortable existing content width, inline media, typography preference, subtle collection/energy metadata, and edit/delete actions revealed with “Entry actions.”
- **Responsive:** phones retain Home / Journal / + / Calendar / Profile. Existing rail remains on large screens. At 1100px and above Journal can display its list beside reading and editing panes. The list does not change selection while the inline editor holds a draft. Save/cancel returns to reading. Dirty-draft protection remains active.

## Motion and accessibility

The existing plus rotation, spring and shine are preserved. Memory arrival uses a quiet fade and 8px rise. Onboarding adds a single, non-looping reveal of Reflect / Notice / Remember concepts. Saved checks draw over the standard 280ms completion interval. Existing 170ms / 280ms / 440ms motion constants remain; reduced-motion bypasses entrance and completion animation. Haptics honor one runtime preference for old and new controls. Existing mood, calendar, streak and checklist semantics remain; prompt hearts expose selected state. Validation brings the writing view back to missing metadata.

## Files added

- `lib/core/experience/journal_experience.dart`: static prompt/template/collection catalogs, temporary preferences and session lists/sets, inherited runtime access, Today and memory logic.
- `lib/screens/inspiration_screen.dart`: Prompt Packs, question favorites/progress and template selection.
- `lib/screens/quick_check_in_screen.dart`: fast mood/activity/energy/note entry creation.
- `lib/screens/journal_preferences_screen.dart`: functional runtime writing settings.
- `lib/widgets/journal_paper.dart`: light procedural paper styles.
- `lib/widgets/reflection_rings.dart`: original labeled arc visualization.
- `lib/widgets/saved_check.dart`: drawn save confirmation.
- `test/product_experience_test.dart`: logic, flow, wide editing and enlarged-text coverage.
- `test/product_previews_test.dart`: opt-in real Flutter-rendered product previews.
- `docs/PRODUCT_EXPERIENCE_REPORT.md`: this report.

## Files changed / model extensions

`JournalEntry` adds kind, collection ID, prompt ID/text and energy, while preserving formatting, photos, drawings, checklists, tags, favorites and creation date. The favorite-copy method retains every field. Existing sample entries keep their original content.

Changed `lib/app/app.dart`, `lib/models/journal_entry.dart`, `lib/core/utils/journal_search.dart`, Home, Journal editor, Timeline, Calendar, reading, Profile, Insights and onboarding screens; MonthCalendar and journal components; navigation, mood and checklist haptic calls. Updated existing tests only for changed routes, action disclosure and date-sheet behavior. Existing formatting/media/profile regression assertions remain.

## Validation

- Full serial suite: **68 tests passed**, two opt-in capture tests skipped.
- Analyzer: **No issues found** (`flutter analyze --no-pub`).
- Rendered preview review: **both opt-in capture tests passed**. Reviewed Home, Prompt Packs, Quick Check-In, writing preferences, Reflection Rings and wide Journal. PNGs in `docs/screenshots/` are real Flutter renders; `ios-simulator.png` is a native simulator capture.
- iPhone 18 Pro simulator build/launch: **successful** (`flutter run -d 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 --no-resident --no-pub`, exit 0). Xcode build completed in 16.2 seconds; files synced and the updated app launched. Native screenshot inspected.

## Intentionally excluded / postponed

The optional Memory Constellation experiment, inline search command syntax and long-press plus shortcut were omitted to keep the core predictable. No export/share placeholder exists. Collections are predefined organizational groups; this pass does not introduce multiple journals, databases or a collection management subsystem. No cloud, APIs, location, HealthKit, weather, AI, disk persistence or analytics were added. All entries, imported media, preferences, favorites and prompt progress reset when the process ends. Classic Serif uses the platform’s available font fallback; no font downloads.

Only iOS native build/launch is verified in this project. Flutter widget tests cover phone, landscape and large layouts; native macOS/Android/Web builds are not claimed. Native accessibility traversal, physical-device haptics and photo-picker interaction still need manual device review. Native UI automation was previously unavailable because computer-use permission was not granted; no bypass was used.

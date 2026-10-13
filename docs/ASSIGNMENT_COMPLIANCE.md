# CSE101 requirement mapping

Source: supplied `CSE101_Final_Project_Output.pdf`, pages 1, 3, and 4. The assigned iOS project is a clean personal journal with mood, date, title, and temporary entries, assigned to Fiel and Johndee. This mapping documents implementation; it does not certify the instructor's interpretation of detailed Modules 1–15, which were not provided.

| Requirement | Implementation / evidence |
| --- | --- |
| At least Home, Details/Form, Summary/Profile | Home, editor, reading, timeline and Profile routes under `lib/screens` |
| Page navigation | CupertinoPageRoute and Navigator in Home shell; reading/edit return flow |
| Text, Icon | Screen headings, body, mood labels and navigation icons |
| Image | Real bundled app mark using Image.asset on onboarding |
| Container, Card | Home mood surface and reusable entry/stat/settings cards |
| Button | FilledButton, TextButton, IconButton and standard navigation controls |
| TextField / input | Form with TextFormField title/body fields (TextField-backed form controls) |
| AppBar | Home, Profile, editor, reading and timeline scaffolds |
| Proper layout | Column, Row, ListView, Expanded, Wrap, LayoutBuilder, IndexedStack |
| Local data | Root List of JournalEntry and moodInfo Map; no persistent storage |
| Form and simple validation | Required non-whitespace title/body and explicit required mood feedback |
| Responsive design | Constrained 720px canvas; expanded side navigation; wrapping mood and stats |
| Testing / UI errors | Behavior tests, resize/text-scale/keyboard tests, rendered previews, iOS simulator launch |
| Source folder | This complete project; retain pubspec and all referenced assets |
| Screenshots | Flutter-rendered previews under `docs/screenshots`; see provenance in submission guide |
| Short documentation / roles | README and submission guide; member contributions must be filled truthfully |
| Demo | Sequence in submission guide; recording remains a manual submission step |
| APK | Required for Android-assigned projects; optional for this iOS-assigned project |

All records are temporary or hardcoded. Restarting restores two starting examples; new entries, edits, deletes profile photos, entry attachments, drawings, accent colors and appearance changes reset. There is no database, network backend, shared preferences or file-based journal persistence. The photo picker reads a user-selected image but does not write application data.

The source uses additional standard Flutter facilities such as PopScope, keyboard shortcuts, accessible controls and native haptic calls. Confirm these against the actual course modules if the instructor enforces a precise API whitelist; no detailed module syllabus was supplied. Core educational state management remains `setState()`.

The new runtime personalization requirement uses the official Flutter file_selector package for real image-file selection. Rich formatting uses SDK TextEditingController/TextSpan APIs, List flags and small runtime models; no third-party document editor or persistent service is added. Confirm plugin permission against a strict syllabus whitelist if the instructor applies one.

The dedicated Journal destination exceeds the required three-screen minimum, while the central creation action remains separate from navigation. New multimedia uses MemoryImage-compatible bytes and runtime stroke Lists; no database or user-media file writes were introduced. Existing required title/body/mood validation is preserved even for entries with media, so photos and drawings accompany a written reflection.

The October 8 pass adds a Calendar destination, secondary Insights/rhythm routes, local search/filters, Favorite metadata, checklist inputs and date-derived streaks. They use the same runtime List/setState architecture. No backend, database, package or native permission was added.


## October 8 product experience pass

See [Product experience report](PRODUCT_EXPERIENCE_REPORT.md) for Today and memory logic, Prompt Packs, templates, collections, quick check-ins, writing preferences, Reflection Rings and wide Journal reading/editing panes. All additions are runtime-only; the existing single List of entries, media and rich formatting remain in place.

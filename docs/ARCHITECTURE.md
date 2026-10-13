# Architecture

`JournalApp` owns the entry list, onboarding visibility, appearance mode, JournalAccent, and UserProfile (name, tagline and photo bytes). Its `setState()` callbacks insert a new ID, replace an existing ID, or remove one ID. The list's identity is retained so reading and timeline routes can query the same runtime records.

`JournalShell` owns the selected navigation destination and latest mood check-in. It presents Cupertino page routes and the mood sheet. An editor returns a `JournalEntry` through Navigator; cancelled editing returns no entry. Existing edits retain their ID. The shell refuses to reinsert an edited record that has disappeared and prevents simultaneous editor presentations. New IDs use the current microsecond timestamp; this is sufficient for this single-process, guarded form, not a distributed ID scheme.

Reading routes look up the entry by ID each time they rebuild. After awaiting an edit, reading and timeline refresh. Deletes mutate the root list and close the obsolete reading route. All asynchronous navigation code checks mounted state before using its State/context after return.

The editor owns and disposes title/body controllers. Title, body, inline formatting, mood, and date determine dirty state. A PopScope protects unsaved edits. Save and confirmed discard permit navigation after the pop configuration has updated. Form validation retains input; no draft is written to disk.

Shared formatting, word counting, and sorting live in `core/utils/journal_format.dart`. Sorting uses date descending, then ID descending. Word count counts readable whitespace-delimited tokens, excludes generated line-prefix markers and includes checklist text, consistently across editor, cards, reading, Profile and Insights. Date grouping and display use the local calendar date.

Keep the course architecture understandable: widgets, callbacks, local List/Map and `setState()`. No unused services, repositories, external state management, or database layers are included.

## Personalization and attributed editing

Profile editing uses a phone sheet or a bounded wider-screen dialog. Cancel discards changes; Save returns a new runtime UserProfile and updates the root with setState. The system image-file chooser uses Flutter’s file_selector plugin, with cancellation/error handling, a 5 MB source limit and a 24 megapixel limit. Images are decoded, reduced and reencoded into memory. Native image resources and editing controllers are disposed; no path or output file is stored.

JournalTextController keeps UTF-16 offsets aligned with per-character bit flags, compacted to immutable TextFormatRun records when saving. Bold, italic, underline, strike and heading apply to selected text or subsequent typing. Bullet, number and quote actions prefix complete lines, preserve inline styles and can toggle off. They are lightweight text prefixes, not a full block-document schema or automatic list continuation engine. Reading uses the same span renderer. Undo/redo keeps text, selection and attributes together, with a 50-snapshot bound. Native composing text remains underlined.

The custom phone navigation keeps its 58px create control centered, while desktop uses a navigation rail. Formatting sits above the keyboard; very short landscape viewports move it into the scrolling body and keep Save accessible in the app bar. Focus mode retains date/body and save access.

## Runtime media and color extension

JournalEntry now holds immutable attachment lists. Each attachment carries memory PNG/image bytes and, for editable sketches, a JournalDrawing with normalized strokes, background and aspect ratio. Editors copy the list before making changes, so cancel never mutates a saved entry. Photos are limited to four and drawings to two per entry. The shared core/media/image_import.dart service is reused by avatar and journal imports; no additional dependency was required.

InkDocument notifies an isolated CustomPainter/RepaintBoundary during pointer movement. Active points are mutable only while drawing, then frozen into a completed stroke. Stroke spacing and point limits bound a single gesture. Eraser strokes use BlendMode.clear inside a saved ink layer, preserving the canvas background; Undo removes the eraser operation as it does any other stroke. Drawing undo is separate from text undo. Clear discards the current drawing history after confirmation. Export uses a PictureRecorder and produces a runtime PNG bounded to 1200px. Image, picture, codec and controller resources are disposed.

TextAttributes extend existing per-character flags with optional color/highlight values. Selection, typing, line operations and text undo retain all attributes. TextFormatRun compacts these on save. Readable color variants are derived against the actual light/dark/highlight surface at rendering time. Word count ignores generated line-prefix markers.

Journal reuses TimelineScreen as an embedded destination, preserving the existing pushed View all route. The shell keeps destination state in IndexedStack and fades changes without replacing children. The center create control is an action, never a destination. On narrow widths/large text, its centered raised position is above the four destination labels; wider compact layouts place Home/Journal to its left and Calendar/Profile to its right.

Accent palettes are runtime values. ColorScheme.fromSeed derives related roles; contrast-adjusted primary/foreground, gradient stops, soft and border roles live in a ThemeExtension that interpolates through MaterialApp's theme transition. It changes accents and focused controls without recoloring prose globally.

## October 8 incremental pass

The shell now has four destinations; Calendar and secondary Your rhythm routes reuse a bounded month calendar. JournalStreakCalculator prepares unique civil-date keys using UTC midnight for year/month/day fields, avoiding elapsed-hour/DST assumptions. Current streak ends today or yesterday, allowing a reflection later today; older gaps reset it to zero. Longest streak counts consecutive distinct past/today dates. Weeks run Monday–Sunday; month/week totals exclude future dates. Duplicate entries count once, including any remaining starting examples.

Calendar groups entries by selected local calendar date and connects adjacent writing dates within each weekly row. Its mood indicator uses the most recently created entry: runtime createdAt, then entry date for older examples, then ID for deterministic ties. Reading and editor return paths refresh date records. Empty past/today dates can open an editor with initialDate; future dates show an explanation instead of a creation action.

TimelineScreen owns its search controller, focus, filter and AnimatedList diff locally. Queries match all case-insensitive terms across title, readable body, tags and checklist text. Filter predicates combine with AND. Root data is not changed by typing. Search matches tint previews without modifying stored prose. Ctrl/Cmd+F selects Journal and opens/focuses search. Escape clears/closes search; filtering is a transient sheet.

JournalEntry additionally holds runtime isFavorite, tags, checklist items and optional createdAt. Reading toggles Favorite through the same root save callback and immutable copyWith, preserving prose/media/date/formatting. Editor copies checklist state and validates nonblank items; tags are trimmed/deduplicated, at most eight of 24 characters. Checklists are limited to twenty items. Read mode shows saved checked state without editing it. Entry word totals include checklist text and exclude list markers.

A new saved writing day that extends current streak triggers a 700ms theme-tinted Home pulse and haptic feedback. If another destination is active, a brief local confirmation is shown. Duplicate same-date saves do not celebrate. Achieved milestone rows derive from the actual longest streak. Weekly rhythm is one shared widget across Home, Calendar rhythm details and Insights. Insights is a secondary route from Profile, never a navigation tab. All features remain in memory; no package or persistence layer was added.

Editor checklist updates preserve the editor-owned copied List identity. This lets callbacks from the previous frame read the newest item text if a completion toggle arrives immediately after typing; replacing that List could otherwise allow the toggle to overwrite new text. The saved entry still receives an immutable list, so cancelling the editor cannot alter a saved checklist.


## October 8 product experience pass

See [Product experience report](PRODUCT_EXPERIENCE_REPORT.md) for Today and memory logic, Prompt Packs, templates, collections, quick check-ins, writing preferences, Reflection Rings and wide Journal reading/editing panes. All additions are runtime-only; the existing single List of entries, media and rich formatting remain in place.

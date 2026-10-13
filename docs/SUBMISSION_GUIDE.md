# CSE101 submission guide

**Project:** iOS Style Personal Journal — Mindful Journal  
**Members:** Fiel and Johndee  
**Description:** A Flutter front-end journal with mood selection, dated temporary entries, validated writing, reading/edit/delete navigation, reflection statistics, appearance settings, editable profile, formatted writing, Focus mode and responsive layouts. Runtime data uses List/Map and setState.

## Member roles

Fill in actual work before submitting; contributions have not been invented:

| Member | Actual responsibilities | Evidence / files explained |
| --- | --- | --- |
| Fiel | To be completed | To be completed |
| Johndee | To be completed | To be completed |

## Screenshots and provenance

The files in `docs/screenshots` with names such as `home-light`, `editor-light`, `profile-light`, `reading-light`, `timeline-light`, `mood-check-in`, and `desktop-dark` are rendered by the actual application through Flutter's widget test engine. Phone previews use a 390×844 logical viewport; desktop uses 1440×900. Font rendering can differ from a native iPhone. They are useful visual QA and documentation previews, not native simulator evidence.

`ios-simulator.png` is a native screenshot of the launched iPhone simulator onboarding. Automated UI access to Device Hub was unavailable because Computer Use permissions were not granted. Further native navigation, screenshots and recording must be completed manually.

For submission, capture native Home, editor/form, reading/details, Profile/summary and a resized/tablet view using the running app. Keep the rendered previews clearly labeled if included. Capture a selected mood and a filled editor as well as empty states where useful.

## Suggested 90-second demonstration

1. Get Started; explain that the two entries are hardcoded examples.
2. Tap the mood banner, select Good, and choose Write about it.
3. Save an empty form to show validation; enter a title and body, then save.
4. View all, open the new entry, edit it, and show the updated reading page.
5. Open Profile, edit your name/tagline, then return Home to show the updated greeting. Explain the stats and five-point mood mapping.
6. Switch to Journal. Use the center + menu, add a photo or draw a sketch, apply Bold/text color and show formatted reading and the media viewer. Change appearance and accent. Show an enlarged-text or wider layout if available.
7. Delete an entry: first Cancel, then confirm Delete. Show the refreshed list.
8. Explain root List/Map ownership, setState, controller disposal, navigation, and the lack of a database. A fresh process resets changes.

Do not terminate the app midway through a demonstration unless demonstrating reset behavior. Hot reload can preserve memory; use a fresh process to demonstrate reset.

## Hand-in checklist

- Complete source folder, pubspec files, iOS native configuration and referenced assets.
- Native screenshots of the required screens and responsive view.
- README, brief description/features and completed member-role table.
- Short demo recording or live presentation.
- Analyzer and behavior-test results; accurately describe unverified platforms.
- APK only if the instructor additionally requests an Android build. The assigned project is iOS.

The detailed Modules 1–15 syllabus was not supplied. Check the APIs against it if the instructor restricts individual framework facilities. No claim of a class rank or grading outcome is made.

The October 8 additions can be demonstrated by switching to Calendar, selecting an empty past date and writing for that day; searching Journal instantly; marking an entry Favorite and filtering it; inserting/toggling a checklist and assigning tags; and opening Explore your insights from Profile. Explain that date-based metrics include starting examples and reset with the process.

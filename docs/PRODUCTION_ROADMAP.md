# Future production roadmap

These are future capabilities, not implemented features. Keep this graded edition runtime-only.

1. **Durable offline journal:** choose a supported local store in a separate production version; add migrations, stable distributed IDs, autosave, draft recovery and crash/restart tests. Only introduce a repository when a real storage implementation needs it.
2. **Finding and organizing:** persistent search/indexing, calendar export, on-this-day memories and configurable prompt collections. Runtime search/tags/favorites/calendar are now implemented. Define date/timezone and deleted-item rules before shipping.
3. **Richer expression:** persistent multimedia with permission and storage policies, structured rich documents beyond the current inline flags/line prefixes, Markdown/text/PDF export and import validation.
4. **Reflection:** long-term mood trends with transparent formulas, missing-data treatment and no medical claims. Runtime streaks and simple mood-balance insights are implemented. Do not mix sample data into real user metrics.
5. **Privacy and recovery:** threat model, device-backed encryption keys, biometric lock, encrypted backups and recovery. A lock screen alone is not encrypted storage.
6. **Return habits:** opt-in local reminders, widgets and platform-specific accessibility/performance verification.
7. **Optional sync:** user-controlled accounts, encrypted multi-device sync, offline conflict rules, deletion propagation and export/account deletion. Validate security and platform privacy disclosures before release.

Production readiness also needs localization, licensed assets, physical-device testing, profiling, signing, release automation and support/recovery policies. None is implied by the course build.

The runtime avatar/photo chooser, editable sketches, accent themes/custom color, text colors/highlights, fixed reflection prompt, inline formatting and Focus mode are implemented. Future additions include camera/gallery integration, cropping, checklist/link editing, export/import, audio/video, on-this-day memories, templates and opt-in AI reflection prompts with explicit privacy controls. Custom gradients, optional text-size customization, paper styles, journal naming, long-term trend charts, avatar Hero transitions and performance profiling remain future refinements. No 60fps measurement or production readiness claim is made.

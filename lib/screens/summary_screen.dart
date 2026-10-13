import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/color_picker.dart';
import '../core/utils/journal_format.dart';
import '../models/journal_entry.dart';
import '../models/user_profile.dart';
import '../widgets/journal_components.dart';
import '../widgets/profile_avatar.dart';
import 'profile_editor_sheet.dart';
import 'insights_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.entries,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.profile = const UserProfile(),
    this.onProfileChanged,
    this.accent = JournalAccent.indigo,
    this.onAccentChanged,
    this.onFavorites,
    this.onPrompts,
    this.onTemplates,
    this.onPreferences,
    this.onSettings,
    this.onTasks,
  });
  final VoidCallback? onFavorites,
      onPrompts,
      onTemplates,
      onPreferences,
      onSettings,
      onTasks;
  final List<JournalEntry> entries;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final UserProfile profile;
  final JournalAccent accent;
  final ValueChanged<JournalAccent>? onAccentChanged;
  final ValueChanged<UserProfile>? onProfileChanged;

  Future<void> _edit(BuildContext context) async {
    final result = await editProfile(context, profile);
    if (context.mounted && result != null) onProfileChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = entries.isEmpty
        ? null
        : entries.fold<int>(
                0,
                (sum, entry) => sum + moodInfo[entry.mood]!.score,
              ) /
              entries.length;
    final words = entries.fold<int>(
      0,
      (sum, entry) => sum + entryWordCount(entry),
    );
    final counts = <Mood, int>{};
    for (final entry in entries) {
      counts.update(entry.mood, (value) => value + 1, ifAbsent: () => 1);
    }
    final moods = Mood.values.where(counts.containsKey).toList()
      ..sort((a, b) {
        final frequency = counts[b]!.compareTo(counts[a]!);
        return frequency == 0 ? a.index.compareTo(b.index) : frequency;
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Your journal')),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Center(
              child: Semantics(
                label: 'Edit profile',
                button: true,
                child: InkWell(
                  onTap: onProfileChanged == null ? null : () => _edit(context),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ProfileAvatar(profile: profile, size: 88),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            if (profile.tagline.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(profile.tagline, textAlign: TextAlign.center),
              ),
            if (onProfileChanged != null)
              Center(
                child: TextButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                  label: const Text('Edit profile'),
                ),
              ),
            const SizedBox(height: 24),
            Text('Your reflection', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _Stat(
                        width: (constraints.maxWidth - 24) / 2,
                        value: '${entries.length}',
                        label: 'Entries',
                      ),
                      _Stat(
                        width: (constraints.maxWidth - 24) / 2,
                        value: average == null
                            ? '—'
                            : '${average.toStringAsFixed(1)}/5',
                        label: 'Average mood',
                      ),
                      _Stat(
                        width: (constraints.maxWidth - 24) / 2,
                        value: '$words',
                        label: 'Words written',
                      ),
                      _Stat(
                        width: (constraints.maxWidth - 24) / 2,
                        value: moods.isEmpty
                            ? 'None yet'
                            : moodInfo[moods.first]!.label,
                        label: 'Most common mood',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.chart_bar),
              title: const Text('Explore your insights'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => InsightsScreen(entries: entries),
                ),
              ),
            ),
            for (final shortcut in [
              (onFavorites, 'Favorites', Icons.favorite_border),
              (onPrompts, 'Prompt Packs', Icons.auto_awesome_outlined),
              (onTemplates, 'Templates', Icons.notes),
              (onPreferences, 'Journal preferences', Icons.tune),
              (onTasks, 'Tasks', Icons.task_alt),
            ])
              if (shortcut.$1 != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(shortcut.$3),
                  title: Text(shortcut.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: shortcut.$1,
                ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('About these numbers'),
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Only current saved entries count, including any remaining examples. Mood scores: Great 5, Good 4, Okay 3, Bad 2, Sad 1. Ties for most common mood follow this order.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    ListTile(
                      minVerticalPadding: 12,
                      leading: Icon(switch (mode) {
                        ThemeMode.system =>
                          CupertinoIcons.device_phone_portrait,
                        ThemeMode.light => CupertinoIcons.sun_max,
                        ThemeMode.dark => CupertinoIcons.moon,
                      }),
                      title: Text(switch (mode) {
                        ThemeMode.system => 'System',
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark',
                      }),
                      selected: mode == themeMode,
                      trailing: mode == themeMode
                          ? Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => onThemeModeChanged(mode),
                    ),
                ],
              ),
            ),
            if (onAccentChanged != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Color theme'),
                  subtitle: Text(accent.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await chooseAccent(context, accent);
                    if (context.mounted && result != null) {
                      onAccentChanged!(result);
                    }
                  },
                ),
              ),
            ],
            if (onSettings != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSettings,
              ),
            const SizedBox(height: 24),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.info_circle, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your journal, media and preferences are saved locally on this device.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.width, required this.value, required this.label});
  final double width;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(label),
      ],
    ),
  );
}

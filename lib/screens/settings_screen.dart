import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../core/theme/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/color_picker.dart';
import '../widgets/journal_components.dart';
import 'journal_preferences_screen.dart';
import 'profile_editor_sheet.dart';
import 'legal_screen.dart';

// Keep this in sync with pubspec.yaml. Verified by the settings test.
const journalAppVersion = '1.0.0+1';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.experience,
    required this.profile,
    required this.onProfileChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.accent,
    required this.onAccentChanged,
    this.onClearSession,
  });
  final JournalExperience experience;
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final JournalAccent accent;
  final ValueChanged<JournalAccent> onAccentChanged;
  final VoidCallback? onClearSession;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _profile;
  late ThemeMode _mode;
  late JournalAccent _accent;
  int _category = 0;
  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _mode = widget.themeMode;
    _accent = widget.accent;
  }

  Future<void> _edit() async {
    final result = await editProfile(context, _profile);
    if (mounted && result != null) {
      widget.onProfileChanged(result);
      setState(() => _profile = result);
    }
  }

  void _document(LegalDocument document) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => LegalScreen(document: document)),
  );
  void _preferences() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => JournalPreferencesScreen(experience: widget.experience),
    ),
  );
  Future<void> _clear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this session?'),
        content: const Text(
          'This clears the saved journal entries, tasks, photos, drawings, profile and settings on this device. Original selected files are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (!mounted || yes != true) return;
    final navigator = Navigator.of(context);
    widget.onClearSession?.call();
    navigator.popUntil((route) => route.isFirst);
  }

  Widget _row(
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? subtitle,
    bool destructive = false,
  }) => ListTile(
    minVerticalPadding: 12,
    leading: Icon(
      icon,
      color: destructive ? Theme.of(context).colorScheme.error : null,
    ),
    title: Text(
      title,
      style: destructive
          ? TextStyle(color: Theme.of(context).colorScheme.error)
          : null,
    ),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right, size: 18),
    onTap: onTap,
  );
  Widget _group(String title, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1) const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  List<Widget> _groups() => [
    _group('Profile', [
      _row(
        'Edit profile',
        Icons.person_outline,
        _edit,
        subtitle: _profile.displayName,
      ),
    ]),
    _group('Appearance', [
      for (final mode in ThemeMode.values)
        ListTile(
          leading: Icon(switch (mode) {
            ThemeMode.system => Icons.phone_iphone,
            ThemeMode.light => Icons.light_mode_outlined,
            ThemeMode.dark => Icons.dark_mode_outlined,
          }),
          title: Text(switch (mode) {
            ThemeMode.system => 'System',
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
          }),
          selected: _mode == mode,
          trailing: _mode == mode ? const Icon(Icons.check) : null,
          onTap: () {
            widget.onThemeModeChanged(mode);
            setState(() => _mode = mode);
          },
        ),
      _row('Accent color', Icons.palette_outlined, () async {
        final result = await chooseAccent(context, _accent);
        if (mounted && result != null) {
          widget.onAccentChanged(result);
          setState(() => _accent = result);
        }
      }, subtitle: _accent.name),
      _row('Text size and journal style', Icons.text_fields, _preferences),
    ]),
    _group('Writing', [
      _row(
        'Editor preferences',
        Icons.edit_note,
        _preferences,
        subtitle: 'Typography, paper and default collection',
      ),
      AnimatedBuilder(
        animation: widget.experience,
        builder: (context, _) {
          final p = widget.experience.preferences;
          void update({bool? words, bool? haptics}) => widget.experience.update(
            JournalPreferences(
              paper: p.paper,
              writing: p.writing,
              textSize: p.textSize,
              wordCount: words ?? p.wordCount,
              haptics: haptics ?? p.haptics,
              collectionId: p.collectionId,
            ),
          );
          return Column(
            children: [
              SwitchListTile(
                title: const Text('Show word count'),
                value: p.wordCount,
                onChanged: (v) => update(words: v),
              ),
              SwitchListTile(
                title: const Text('Haptics'),
                value: p.haptics,
                onChanged: (v) => update(haptics: v),
              ),
            ],
          );
        },
      ),
    ]),
    _group('Privacy & security', [
      _row(
        'Privacy overview',
        Icons.shield_outlined,
        () => _document(LegalDocument.overview),
      ),
      if (widget.onClearSession != null)
        _row(
          'Clear this session’s data',
          Icons.delete_outline,
          _clear,
          destructive: true,
        ),
    ]),
    _group('About', [
      const ListTile(
        leading: Icon(Icons.book_outlined),
        title: Text('Mindful Journal'),
        subtitle: Text('Version $journalAppVersion · CSE101 edition'),
      ),
      _row(
        'Privacy Policy',
        Icons.privacy_tip_outlined,
        () => _document(LegalDocument.privacy),
      ),
      _row(
        'Terms of Use',
        Icons.description_outlined,
        () => _document(LegalDocument.terms),
      ),
      _row(
        'Open-source licenses',
        Icons.code,
        () => showLicensePage(
          context: context,
          applicationName: 'Mindful Journal',
          applicationVersion: journalAppVersion,
        ),
      ),
    ]),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final groups = _groups();
        if (constraints.maxWidth < 900) {
          return JournalCanvas(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: groups,
            ),
          );
        }
        return Row(
          children: [
            SizedBox(
              width: 250,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (var i = 0; i < 5; i++)
                    ListTile(
                      title: Text(
                        [
                          'Profile',
                          'Appearance',
                          'Writing',
                          'Privacy & security',
                          'About',
                        ][i],
                      ),
                      selected: _category == i,
                      trailing: _category == i
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: () => setState(() => _category = i),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: JournalCanvas(
                child: ListView(
                  padding: const EdgeInsets.all(32),
                  children: [groups[_category]],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

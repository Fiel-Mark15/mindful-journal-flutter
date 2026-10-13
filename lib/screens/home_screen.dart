import 'package:flutter/cupertino.dart';
import '../core/experience/journal_experience.dart';
import '../core/utils/journal_search.dart';
import 'inspiration_screen.dart';
import 'quick_check_in_screen.dart';
import 'journal_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/journal_format.dart';
import '../core/utils/journal_streak.dart';
import '../widgets/writing_rhythm.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import '../models/journal_task.dart';
import '../widgets/journal_checklist.dart';
import '../models/journal_entry.dart';
import '../models/user_profile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/journal_navigation.dart';
import '../widgets/journal_components.dart';
import '../widgets/mood_selector.dart';
import '../widgets/mood_symbol.dart';
import 'entry_detail_screen.dart';
import 'journal_editor_screen.dart';
import 'summary_screen.dart';
import 'timeline_screen.dart';

class JournalShell extends StatefulWidget {
  const JournalShell({
    super.key,
    required this.entries,
    this.profile = const UserProfile(),
    this.onProfileChanged,
    this.accent = JournalAccent.indigo,
    this.onAccentChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onEntrySaved,
    required this.onEntryDeleted,
    this.onClearSession,
    this.onEntryCommitted,
  });
  final Future<void> Function(JournalEntry)? onEntryCommitted;
  final VoidCallback? onClearSession;
  final JournalAccent accent;
  final ValueChanged<JournalAccent>? onAccentChanged;
  final UserProfile profile;
  final ValueChanged<UserProfile>? onProfileChanged;
  final List<JournalEntry> entries;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<JournalEntry> onEntrySaved;
  final ValueChanged<String> onEntryDeleted;

  @override
  State<JournalShell> createState() => _JournalShellState();
}

class _JournalShellState extends State<JournalShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _navigationFade;
  @override
  void initState() {
    super.initState();
    _navigationFade = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      value: 1,
    );
  }

  @override
  void dispose() {
    _fallbackExperience.dispose();
    _navigationFade.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    if (!MediaQuery.disableAnimationsOf(context)) {
      _navigationFade.forward(from: .82);
    }
  }

  final _fallbackExperience = JournalExperience();
  JournalExperience get _experience =>
      ExperienceScope.maybeOf(context) ?? _fallbackExperience;
  int _index = 0;
  Mood? get _checkIn => _experience.checkIn;
  void _setCheckIn(Mood? mood) => _experience.setCheckIn(mood);
  bool _editorOpen = false;
  bool _creating = false;
  int _celebration = 0, _searchRequest = 0;
  void _searchJournal() {
    _selectDestination(1);
    setState(() => _searchRequest++);
  }

  void _rhythmDetails() => Navigator.of(context).push<void>(
    CupertinoPageRoute(
      builder: (_) => CalendarScreen(
        entries: widget.entries,
        onOpen: _openEntry,
        onCreate: (date) => _openEditor(date: date),
        embedded: false,
        rhythmDetails: true,
      ),
    ),
  );

  Future<void> _openEditor({
    JournalEntry? entry,
    Mood? mood,
    String? prompt,
    String? insert,
    EntryTemplate? template,
    String? promptId,
    EntryKind kind = EntryKind.text,
    DateTime? date,
  }) async {
    if (_editorOpen) return;
    _editorOpen = true;
    final beforeEditing = JournalStreakCalculator.calculate(widget.entries);
    final result = await Navigator.of(context).push<JournalEntry>(
      CupertinoPageRoute(
        builder: (_) => JournalEditorScreen(
          entry: entry,
          onCommit: widget.onEntryCommitted,
          initialMood: mood,
          initialPrompt: prompt,
          initialInsert: insert,
          initialDate: date,
          initialTemplate: template,
          promptId: promptId,
          kind: kind,
        ),
      ),
    );
    if (!mounted) return;
    _editorOpen = false;
    if (result != null) {
      // Only update an existing record if it still exists in this session.
      if (entry != null && entryWithId(widget.entries, entry.id) == null) {
        return;
      }
      final before = beforeEditing;
      final newDay = !before.days.contains(journalDay(result.date));
      widget.onEntrySaved(result);
      _experience.usePrompt(result.promptId);
      final after = JournalStreakCalculator.calculate(widget.entries);
      if (newDay && after.current > before.current) {
        setState(() => _celebration++);
        journalHaptic(context);
        if (_index != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 800),
              content: Text(
                'Another moment captured. ${after.current} day reflection streak.',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _openEntry(JournalEntry entry) async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (_) => EntryDetailScreen(
          id: entry.id,
          entries: widget.entries,
          onEdit: (entry) => _openEditor(entry: entry),
          onDelete: widget.onEntryDeleted,
          onChanged: widget.onEntrySaved,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _timeline() => Navigator.of(context).push<void>(
    CupertinoPageRoute(
      builder: (_) => TimelineScreen(
        entries: widget.entries,
        onOpen: _openEntry,
        onCreate: () => _openEditor(),
        onChanged: widget.onEntrySaved,
      ),
    ),
  );

  Future<void> _moodCheckIn() async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => _MoodSheet(
        initialMood: _checkIn,
        onSelected: (m) => setState(() => _setCheckIn(m)),
      ),
    );
    if (!mounted || mood == null) return;
    setState(() => _setCheckIn(mood));
    await _openEditor(mood: mood);
  }

  Future<void> _quickCheckIn() async {
    final result = await Navigator.of(context).push<JournalEntry>(
      CupertinoPageRoute(
        builder: (_) => QuickCheckInScreen(
          initialMood: _checkIn,
          onCommit: widget.onEntryCommitted,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final before = JournalStreakCalculator.calculate(widget.entries);
    widget.onEntrySaved(result);
    setState(() {
      _setCheckIn(result.mood);
      if (JournalStreakCalculator.calculate(widget.entries).current >
          before.current) {
        _celebration++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in saved'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  Future<void> _inspiration({bool templates = false}) async {
    final choice = await Navigator.of(context).push<InspirationChoice>(
      CupertinoPageRoute(
        builder: (_) =>
            InspirationScreen(experience: _experience, templates: templates),
      ),
    );
    if (!mounted || choice == null) return;
    await _openEditor(
      prompt: choice.prompt?.text,
      promptId: choice.prompt?.id,
      template: choice.template,
      kind: choice.prompt == null ? EntryKind.text : EntryKind.promptReflection,
    );
  }

  void _favorites() => Navigator.of(context).push<void>(
    CupertinoPageRoute(
      builder: (_) => TimelineScreen(
        entries: widget.entries,
        onOpen: _openEntry,
        onCreate: () => _openEditor(),
        initialFilter: const JournalFilter(favorites: true),
        onChanged: widget.onEntrySaved,
        title: 'Favorites',
      ),
    ),
  );
  void _preferences() => Navigator.of(context).push<void>(
    CupertinoPageRoute(
      builder: (_) => JournalPreferencesScreen(experience: _experience),
    ),
  );
  void _settings() {
    // The shell is replaced by Clear Session. Capture route inputs now so the
    // outgoing settings route never reads a disposed shell's context.
    final screen = SettingsScreen(
      experience: _experience,
      profile: widget.profile,
      onProfileChanged: widget.onProfileChanged ?? (_) {},
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      accent: widget.accent,
      onAccentChanged: widget.onAccentChanged ?? (_) {},
      onClearSession: widget.onClearSession,
    );
    Navigator.of(
      context,
    ).push<void>(CupertinoPageRoute(builder: (_) => screen));
  }

  void _tasks() => Navigator.of(context).push<void>(
    CupertinoPageRoute(
      builder: (_) =>
          TasksScreen(experience: _experience, onReflect: () => _openEditor()),
    ),
  );

  Future<void> _viewToday() async {
    final entries = todayEntries(widget.entries);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Today', style: Theme.of(sheet).textTheme.titleLarge),
            for (final entry in entries)
              EntryCard(
                entry: entry,
                onTap: () {
                  Navigator.pop(sheet);
                  _openEntry(entry);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMenu() async {
    if (_creating || _editorOpen) return;
    setState(() => _creating = true);
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Make a little space',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Write'),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil),
                  title: const Text('New journal entry'),
                  subtitle: const Text('Start with what’s on your mind.'),
                  onTap: () => Navigator.pop(context, 'entry'),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Quick'),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.heart),
                  title: const Text('Quick mood check-in'),
                  onTap: () => Navigator.pop(context, 'mood'),
                ),
                ListTile(
                  leading: const Icon(Icons.checklist),
                  title: const Text('Checklist'),
                  onTap: () => Navigator.pop(context, 'checklist'),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Creative'),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.photo),
                  title: const Text('Add photo memory'),
                  onTap: () => Navigator.pop(context, 'photo'),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.scribble),
                  title: const Text('Draw something'),
                  onTap: () => Navigator.pop(context, 'draw'),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Inspire'),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.sparkles),
                  title: const Text('Reflection prompt'),
                  subtitle: const Text('Explore nine local prompt packs.'),
                  onTap: () => Navigator.pop(context, 'prompt'),
                ),
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('Template'),
                  onTap: () => Navigator.pop(context, 'template'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (action == 'entry') await _openEditor();
    if (action == 'photo' || action == 'draw') {
      await _openEditor(
        insert: action,
        kind: action == 'photo' ? EntryKind.photoMemory : EntryKind.drawing,
      );
    }
    if (action == 'mood') await _quickCheckIn();
    if (action == 'prompt') await _inspiration();
    if (action == 'template') await _inspiration(templates: true);
    if (action == 'checklist') {
      await _openEditor(insert: 'checklist', kind: EntryKind.checklist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppLayout.expandedWidth;
    final home = _HomePage(
      entries: widget.entries,
      profile: widget.profile,
      checkIn: _checkIn,
      onCheckIn: _moodCheckIn,
      onNewEntry: () => _openEditor(),
      onEntryTap: _openEntry,
      onViewAll: _timeline,
      onProfile: () => _selectDestination(3),
      onRhythm: _rhythmDetails,
      celebration: _celebration,
      experience: _experience,
      onTasks: _tasks,
      onContinue: (entry) => _openEditor(entry: entry),
      onToday: _viewToday,
    );
    final profile = SummaryScreen(
      profile: widget.profile,
      onProfileChanged: widget.onProfileChanged,
      onFavorites: _favorites,
      onPrompts: () => _inspiration(),
      onTemplates: () => _inspiration(templates: true),
      onPreferences: _preferences,
      onTasks: _tasks,
      onSettings: _settings,
      accent: widget.accent,
      onAccentChanged: widget.onAccentChanged,
      entries: widget.entries,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    );
    final journal = TimelineScreen(
      entries: widget.entries,
      onOpen: _openEntry,
      onCreate: () => _openEditor(),
      embedded: true,
      searchRequest: _searchRequest,
      onChanged: widget.onEntrySaved,
      editorBuilder: (entry, close) => JournalEditorScreen(
        key: ValueKey('edit-${entry.id}'),
        onCommit: widget.onEntryCommitted,
        entry: entry,
        embedded: true,
        onFinished: (result) {
          if (result != null && entryWithId(widget.entries, entry.id) != null) {
            widget.onEntrySaved(result);
            _experience.usePrompt(result.promptId);
          }
          close();
        },
      ),
      detailBuilder: (entry, close, edit) => EntryDetailScreen(
        key: ValueKey(entry.id),
        id: entry.id,
        entries: widget.entries,
        onEdit: (_) async => edit(),
        onDelete: widget.onEntryDeleted,
        onChanged: widget.onEntrySaved,
        embedded: true,
        onClosed: close,
      ),
    );
    final pages = FadeTransition(
      opacity: _navigationFade,
      child: IndexedStack(
        index: _index,
        children: [
          home,
          journal,
          CalendarScreen(
            entries: widget.entries,
            onOpen: _openEntry,
            onCreate: (date) => _openEditor(date: date),
          ),
          profile,
        ],
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _searchJournal,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _searchJournal,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
          if (ModalRoute.of(context)?.isCurrent ?? false) _openEditor();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (ModalRoute.of(context)?.isCurrent ?? false) _openEditor();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      extended: true,
                      selectedIndex: _index,
                      onDestinationSelected: (index) {
                        journalHaptic(context);
                        _selectDestination(index);
                      },
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CreateButton(onTap: _createMenu, active: _creating),
                            const SizedBox(height: 12),
                            const Text('Create entry'),
                          ],
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.house),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.book),
                          label: Text('Journal'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.calendar),
                          label: Text('Calendar'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.person_crop_circle),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages),
                  ],
                )
              : pages,
          bottomNavigationBar: wide
              ? null
              : JournalNavigation(
                  index: _index,
                  onChanged: _selectDestination,
                  onCreate: _createMenu,
                  creating: _creating,
                ),
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.entries,
    required this.checkIn,
    required this.profile,
    required this.onCheckIn,
    required this.onNewEntry,
    required this.onEntryTap,
    required this.onViewAll,
    required this.onProfile,
    required this.onRhythm,
    required this.celebration,
    required this.onContinue,
    required this.onToday,
    required this.experience,
    required this.onTasks,
  });
  final List<JournalEntry> entries;
  final Mood? checkIn;
  final UserProfile profile;
  final VoidCallback onCheckIn;
  final VoidCallback onNewEntry;
  final ValueChanged<JournalEntry> onEntryTap;
  final VoidCallback onViewAll;
  final VoidCallback onProfile;
  final VoidCallback onRhythm;
  final int celebration;
  final ValueChanged<JournalEntry> onContinue;
  final VoidCallback onToday;
  final JournalExperience experience;
  final VoidCallback onTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final recent = sortedEntries(entries).take(3);
    final today = todayEntries(entries);
    final memory = resurfacedMemory(entries);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful Journal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: false,
        actions: [
          IconButton(
            tooltip: 'Open profile',
            onPressed: onProfile,
            icon: ProfileAvatar(profile: profile, size: 36),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          children: [
            Text('$greeting,', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(profile.greetingName, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(formatDate(DateTime.now()), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            Material(
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AccentPalette.of(context).gradient,
                ),
                child: InkWell(
                  onTap: onCheckIn,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: MoodSymbol(
                            mood: checkIn ?? Mood.great,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkIn == null
                                    ? 'How are you feeling today?'
                                    : 'Feeling ${moodInfo[checkIn]!.label.toLowerCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Take a moment to check in.',
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            StreakCard(
              rhythm: JournalStreakCalculator.calculate(entries),
              onTap: onRhythm,
              celebration: celebration,
            ),
            const SizedBox(height: 28),
            Text('Today', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: today.isEmpty
                    ? onNewEntry
                    : today.length == 1
                    ? () => onContinue(today.first)
                    : onToday,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              today.isEmpty
                                  ? 'Start a new entry'
                                  : today.length == 1
                                  ? "Today’s reflection"
                                  : '${today.length} moments today',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today.isEmpty
                                  ? 'Nothing written yet. What part of today do you want to remember?'
                                  : today.length == 1
                                  ? '${today.first.title} · ${entryWordCount(today.first)} words · ${moodInfo[today.first.mood]!.label}'
                                  : 'Return to the moments you captured.',
                            ),
                            Text(
                              today.isEmpty
                                  ? 'Write about today'
                                  : today.length == 1
                                  ? 'Continue writing'
                                  : 'View today',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.add,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: experience,
              builder: (context, _) {
                final tasks = orderedTasks(
                  experience.tasks.where(
                    (t) => taskGroup(t) == TaskGroup.today,
                  ),
                );
                if (tasks.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tasks for today',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: onTasks,
                                child: const Text('View tasks'),
                              ),
                            ],
                          ),
                          for (final task in tasks.take(2))
                            Row(
                              children: [
                                AnimatedChecklistCheck(
                                  label: task.title,
                                  checked: task.isCompleted,
                                  onToggle: () => experience.saveTask(
                                    task.withCompletion(!task.isCompleted),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          Text(
                            '${tasks.length} waiting today',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (memory != null) ...[
              TweenAnimationBuilder<double>(
                key: ValueKey('memory-${memory.id}'),
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onEntryTap(memory),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'From your journal',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formatDate(memory.date),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            memory.title,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            readableJournalText(memory.content),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (memory.attachments.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  memory.attachments.first.bytes,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Read again · ${memory.id.startsWith('sample-') ? 'Starting example' : 'This session'}',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent entries',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty) JournalEmptyState(onCreate: onNewEntry),
            ...recent.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EntryCard(entry: entry, onTap: () => onEntryTap(entry)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodSheet extends StatefulWidget {
  const _MoodSheet({this.initialMood, required this.onSelected});
  final Mood? initialMood;
  final ValueChanged<Mood> onSelected;
  @override
  State<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<_MoodSheet> {
  Mood? _mood;
  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'A moment for you',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close check-in',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.xmark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('There’s no right or wrong way to feel.'),
          const SizedBox(height: 24),
          MoodSelector(
            value: _mood,
            onChanged: (mood) {
              setState(() => _mood = mood);
              widget.onSelected(mood);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _mood == null
                  ? null
                  : () => Navigator.pop(context, _mood),
              child: const Text('Write about it'),
            ),
          ),
        ],
      ),
    ),
  );
}

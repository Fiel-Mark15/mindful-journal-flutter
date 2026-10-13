import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/core/experience/journal_experience.dart';
import 'package:ios_style_journal/core/utils/journal_search.dart';
import 'package:ios_style_journal/core/utils/journal_streak.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/screens/inspiration_screen.dart';
import 'package:ios_style_journal/screens/journal_editor_screen.dart';
import 'package:ios_style_journal/screens/quick_check_in_screen.dart';
import 'package:ios_style_journal/screens/calendar_screen.dart';
import 'package:ios_style_journal/screens/journal_preferences_screen.dart';
import 'personalization_test.dart' as helpers;

JournalEntry record(
  String id,
  DateTime date, {
  String? collection,
  List<String> tags = const [],
  String? prompt,
}) => JournalEntry(
  id: id,
  title: 'A moment',
  content: 'Quiet words',
  date: date,
  mood: Mood.good,
  collectionId: collection,
  tags: tags,
  promptText: prompt,
  createdAt: DateTime(2026, 10, 8, 18),
);
void main() {
  final today = DateTime(2026, 10, 8);
  test(
    'Today detection uses civil date; memories exclude today and future and favor anniversary',
    () {
      final records = [
        record('future', DateTime(2026, 10, 9)),
        record('today', DateTime(2026, 10, 8, 23)),
        record('recent', DateTime(2026, 10, 7)),
        record('anniversary', DateTime(2025, 10, 8)),
      ];
      expect(todayEntries(records, now: today).single.id, 'today');
      expect(resurfacedMemory(records, now: today)?.id, 'anniversary');
      expect(resurfacedMemory(records.take(2).toList(), now: today), isNull);
      expect(resurfacedMemory([records[2]], now: today)?.id, 'recent');
    },
  );
  test(
    'Collection and multi-tag predicates compose with search and prompt text',
    () {
      final records = [
        record(
          'a',
          today,
          collection: 'college',
          tags: ['Coding', 'School'],
          prompt: 'What surprised you?',
        ),
        record('b', today, tags: ['Coding']),
      ];
      expect(
        searchJournal(records, 'college', const JournalFilter()).single.id,
        'a',
      );
      expect(
        searchJournal(records, 'surprised', const JournalFilter()).single.id,
        'a',
      );
      expect(
        searchJournal(
          records,
          'coding',
          const JournalFilter(
            tags: ['coding', 'school'],
            collectionId: 'college',
          ),
        ).single.id,
        'a',
      );
      expect(
        searchJournal(
          records,
          '',
          const JournalFilter(collectionId: 'general'),
        ).single.id,
        'b',
      );
      expect(
        searchJournal(records, '', const JournalFilter(tags: ['missing'])),
        isEmpty,
      );
    },
  );
  test('Favorite copy retains new and original metadata', () {
    final original = JournalEntry(
      id: 'x',
      title: 'T',
      content: 'C',
      date: today,
      mood: Mood.good,
      createdAt: DateTime(2026, 10, 8, 19),
      collectionId: 'college',
      promptId: 'p',
      promptText: 'Question',
      kind: EntryKind.quickCheckIn,
      energy: 'High',
      tags: ['coding'],
    );
    final favorite = original.copyWith(isFavorite: true);
    expect(favorite.isFavorite, isTrue);
    expect(favorite.createdAt, original.createdAt);
    expect(favorite.collectionId, 'college');
    expect(favorite.promptId, 'p');
    expect(favorite.energy, 'High');
    expect(favorite.kind, EntryKind.quickCheckIn);
    expect(favorite.tags, ['coding']);
  });
  test(
    'Prompt favorites, exploration and recent searches are session-local',
    () {
      final a = JournalExperience(), b = JournalExperience();
      a.togglePrompt('p');
      a.usePrompt('p');
      a.usePrompt('p');
      expect(a.usedPrompts.length, 1);
      expect(b.usedPrompts, isEmpty);
      expect(b.favoritePrompts, isEmpty);
      for (var i = 0; i < 8; i++) {
        a.rememberSearch('query $i');
      }
      a.rememberSearch('query 7');
      expect(a.recentSearches.length, 5);
      expect(a.recentSearches.first, 'query 7');
      a.dispose();
      b.dispose();
    },
  );
  test('Seven day milestone requires seven distinct days', () {
    final records = [
      for (var i = 0; i < 7; i++)
        record('$i', today.subtract(Duration(days: i))),
    ];
    expect(JournalStreakCalculator.calculate(records, now: today).current, 7);
    expect(
      JournalStreakCalculator.calculate([
        ...records,
        records.first,
      ], now: today).current,
      7,
    );
  });
  testWidgets(
    'Prompt gallery favorite state and selection return exact prompt',
    (tester) async {
      final experience = JournalExperience();
      addTearDown(experience.dispose);
      InspirationChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspirationScreen(experience: experience),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily Reflection'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Favorite prompt').first);
      await tester.pumpAndSettle();
      expect(experience.favoritePrompts.length, 1);
      await tester.tap(find.text('Write with this prompt').first);
      await tester.pumpAndSettle();
      expect(result?.prompt?.text, promptPacks['Daily Reflection']!.first);
      expect(experience.usedPrompts, isEmpty);
    },
  );
  testWidgets('Template entry saves editable sections and preserves collection', (
    tester,
  ) async {
    JournalEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalEditorScreen(
                      initialTemplate: entryTemplates.firstWhere(
                        (t) => t.name == 'Weekly Review',
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Review'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mood-good')));
    await helpers.visible(tester, find.byKey(const ValueKey('entry-content')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-content')),
      'This week’s highlight\nI finished my project.\n\nNext week’s focus\nKeep learning.',
    );
    await tester.tap(find.byKey(const ValueKey('save-shortcut')));
    await tester.pumpAndSettle();
    expect(saved?.title, 'Weekly Review');
    expect(saved?.content, contains('I finished my project.'));
  });
  testWidgets(
    'Quick check-in validates mood and saves optional activity, note and energy',
    (tester) async {
      JournalEntry? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuickCheckInScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('Save check-in'));
      await tester.tap(find.text('Save check-in'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await helpers.visible(tester, find.byKey(const ValueKey('mood-great')));
      await tester.tap(find.byKey(const ValueKey('mood-great')));
      await tester.tap(find.text('Coding'));
      await helpers.visible(tester, find.text('High'));
      await tester.tap(find.text('High'));
      await helpers.visible(
        tester,
        find.byKey(const ValueKey('check-in-note')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('check-in-note')),
        'Made something useful.',
      );
      await helpers.visible(tester, find.text('Save check-in'));
      await tester.tap(find.text('Save check-in'));
      await tester.pumpAndSettle();
      expect(saved?.kind, EntryKind.quickCheckIn);
      expect(saved?.tags, ['coding']);
      expect(saved?.energy, 'High');
      expect(saved?.content, 'Made something useful.');
    },
  );
  testWidgets('Calendar switches mood mode and presents selected day sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CalendarScreen(
          entries: sampleEntries,
          onOpen: (_) async {},
          onCreate: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    await tester.tap(find.byKey(ValueKey('calendar-day-${journalDay(now)}')));
    await tester.pumpAndSettle();
    expect(find.text('Write for this day'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Preferences change body styling and all haptic preference state',
    (tester) async {
      final experience = JournalExperience();
      addTearDown(experience.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: JournalPreferencesScreen(experience: experience),
        ),
      );
      await tester.tap(find.text('Classic Serif'));
      await tester.pumpAndSettle();
      expect(experience.preferences.writing, WritingStyle.classicSerif);
      await tester.tap(find.text('Dot Grid'));
      await tester.pumpAndSettle();
      expect(experience.preferences.paper, PaperStyle.dotGrid);
      await helpers.visible(tester, find.text('Haptics'));
      await tester.tap(find.text('Haptics'));
      await tester.pumpAndSettle();
      expect(experience.preferences.haptics, isFalse);
    },
  );
  testWidgets('Wide Journal keeps reading and editing beside the archive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await helpers.app(tester);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A productive day'));
    await tester.pumpAndSettle();
    expect(find.text('Small steps'), findsOneWidget);
    expect(find.text('Your entry'), findsOneWidget);
    await tester.tap(find.byTooltip('Entry actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<JournalEditorScreen>(find.byType(JournalEditorScreen))
          .embedded,
      isTrue,
    );
    await tester.enterText(
      find.byKey(const ValueKey('entry-title')),
      'A brighter day',
    );
    await tester.tap(find.byKey(const ValueKey('save-shortcut')));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditorScreen), findsNothing);
    expect(find.text('A brighter day'), findsWidgets);
    expect(find.text('Small steps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('New creation tools fit $size with doubled text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final experience = JournalExperience();
      addTearDown(experience.dispose);
      Widget host(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: child,
      );
      for (final screen in [
        QuickCheckInScreen(),
        InspirationScreen(experience: experience),
        InspirationScreen(experience: experience, templates: true),
        JournalPreferencesScreen(experience: experience),
      ]) {
        await tester.pumpWidget(host(screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}

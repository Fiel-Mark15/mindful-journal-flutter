import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/core/utils/journal_streak.dart';
import 'package:ios_style_journal/core/utils/journal_search.dart';
import 'package:ios_style_journal/core/utils/journal_format.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/models/checklist_item.dart';
import 'package:ios_style_journal/widgets/month_calendar.dart';
import 'package:ios_style_journal/widgets/journal_checklist.dart';
import 'package:ios_style_journal/screens/timeline_screen.dart';
import 'package:ios_style_journal/screens/calendar_screen.dart';
import 'package:ios_style_journal/screens/journal_editor_screen.dart';
import 'personalization_test.dart' as helpers;

JournalEntry entry(
  String id,
  DateTime date, {
  String title = 'Quiet morning',
  String body = 'A little reflection',
  Mood mood = Mood.good,
  bool favorite = false,
  List<String> tags = const [],
  List<ChecklistItem> checklist = const [],
}) => JournalEntry(
  id: id,
  title: title,
  content: body,
  date: date,
  mood: mood,
  isFavorite: favorite,
  tags: tags,
  checklist: checklist,
);
void main() {
  final today = DateTime(2026, 10, 8);
  test('Empty and future-only dates do not create streaks', () {
    final empty = JournalStreakCalculator.calculate([], now: today);
    expect(
      [empty.current, empty.longest, empty.thisWeek, empty.thisMonth],
      [0, 0, 0, 0],
    );
    final future = JournalStreakCalculator.calculate([
      entry('f', DateTime(2026, 10, 9)),
    ], now: today);
    expect(future.current, 0);
    expect(future.longest, 0);
  });
  test(
    'Duplicate writing dates count once, today and yesterday extend a run',
    () {
      final entries = [
        entry('a', today),
        entry('b', DateTime(2026, 10, 8, 18)),
        entry('c', DateTime(2026, 10, 7)),
        entry('d', DateTime(2026, 10, 6)),
      ];
      final stats = JournalStreakCalculator.calculate(entries, now: today);
      expect(stats.current, 3);
      expect(stats.longest, 3);
      expect(stats.thisMonth, 3);
      expect(stats.thisWeek, 3);
      expect(
        JournalStreakCalculator.calculate(
          entries.where((e) => e.date.day != 8).toList(),
          now: today,
        ).current,
        2,
      );
    },
  );
  test('A missing day separates longest runs and current streak expires', () {
    final entries = [
      for (final day in [1, 2, 3, 5, 6]) entry('$day', DateTime(2026, 10, day)),
    ];
    final stats = JournalStreakCalculator.calculate(entries, now: today);
    expect(stats.current, 0);
    expect(stats.longest, 3);
    expect(
      JournalStreakCalculator.writingDaysForMonth(
        entries,
        DateTime(2026, 10),
        now: today,
      ),
      5,
    );
  });
  test('Civil days cross leap days/year boundaries; weeks begin Monday', () {
    expect(
      journalDay(DateTime(2024, 3, 1)) - journalDay(DateTime(2024, 2, 28)),
      2,
    );
    final stats = JournalStreakCalculator.calculate([
      entry('d', DateTime(2025, 12, 31)),
      entry('j', DateTime(2026, 1, 1)),
    ], now: DateTime(2026, 1, 1));
    expect(stats.current, 2);
    expect(stats.longest, 2);
    expect(stats.thisMonth, 1);
    expect(stats.thisWeek, 2);
    final monday = JournalStreakCalculator.calculate([
      entry('s', DateTime(2026, 10, 4)),
      entry('m', DateTime(2026, 10, 5)),
    ], now: DateTime(2026, 10, 5));
    expect(monday.thisWeek, 1);
  });
  test(
    'Search matches title, body, tags and checklist without case sensitivity',
    () {
      final entries = [
        entry(
          'a',
          today,
          title: 'Garden Walk',
          body: 'Fresh lavender',
          tags: ['Outdoors'],
          checklist: [const ChecklistItem(id: 'c', text: 'Call Mum')],
        ),
      ];
      for (final query in [
        'GARDEN',
        'lavender',
        'outdoors',
        'call mum',
        'garden lavender',
      ]) {
        expect(searchJournal(entries, query, const JournalFilter()).length, 1);
      }
      expect(searchJournal(entries, 'missing', const JournalFilter()), isEmpty);
      expect(
        searchJournal(entries, '', const JournalFilter(favorites: true)),
        isEmpty,
      );
      expect(
        searchJournal(
          [entries.single.copyWith(isFavorite: true)],
          '',
          const JournalFilter(favorites: true),
        ).length,
        1,
      );
      expect(
        searchJournal(entries, '', const JournalFilter(mood: Mood.sad)),
        isEmpty,
      );
      expect(
        searchJournal(
          entries,
          '',
          const JournalFilter(checklist: true, tag: 'OUTDOORS'),
        ).length,
        1,
      );
      expect(entryWordCount(entries.single), 4);
    },
  );
  testWidgets('Calendar has aligned date semantics and latest mood indicator', (
    tester,
  ) async {
    final entries = [
      entry('a', today, mood: Mood.great),
      entry('z', today, mood: Mood.sad),
    ];
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MonthCalendar(
            month: DateTime(2026, 10),
            selected: DateTime(2026, 10, 7),
            entries: entries,
            now: today,
            onSelected: (date) => selected = date,
          ),
        ),
      ),
    );
    final day = find.byKey(ValueKey('calendar-day-${journalDay(today)}'));
    expect(day, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label?.contains(
                  'October 8, 2026, 2 journal entries, mood Sad',
                ) ==
                true,
      ),
      findsOneWidget,
    );
    await tester.tap(day);
    expect(selected, today);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Calendar selected empty date opens backdated editor', (
    tester,
  ) async {
    await helpers.app(tester);
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final past = DateTime(now.year, now.month, 1);
    await tester.tap(find.byKey(ValueKey('calendar-day-${journalDay(past)}')));
    await tester.pumpAndSettle();
    await helpers.visible(tester, find.text('Write for this day').last);
    await tester.tap(find.text('Write for this day').last);
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditorScreen), findsOneWidget);
    expect(find.text(formatDate(past)), findsOneWidget);
  });
  testWidgets(
    'Instant search updates title/body/no-results and Escape closes it',
    (tester) async {
      await helpers.app(tester);
      await tester.tap(find.text('Journal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search journal'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('journal-search'));
      await tester.enterText(field, 'PRODUCTIVE');
      await tester.pumpAndSettle();
      expect(find.text('A productive day'), findsOneWidget);
      expect(find.text('Small steps'), findsNothing);
      await tester.enterText(field, 'one step');
      await tester.pumpAndSettle();
      expect(find.text('Small steps'), findsOneWidget);
      expect(find.text('A productive day'), findsNothing);
      await tester.enterText(field, 'missing');
      await tester.pumpAndSettle();
      expect(find.text('No matches yet.'), findsOneWidget);
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
      expect(find.text('2 entries · This session'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(field, findsNothing);
    },
  );
  testWidgets('Favorite toggle retains entry content and filters immediately', (
    tester,
  ) async {
    await helpers.app(tester);
    await tester.tap(find.text('Journal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A productive day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favorite'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites only'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('1 entry · This session'), findsOneWidget);
    expect(find.text('Small steps'), findsNothing);
    await tester.tap(find.text('A productive day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove favorite'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('No matches yet.'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('2 entries · This session'), findsOneWidget);
  });
  testWidgets(
    'Checklist animates, edits and saves alongside formatting and tags',
    (tester) async {
      await helpers.app(tester);
      await helpers.visible(tester, find.text('Start a new entry'));
      await tester.tap(find.text('Start a new entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mood-good')));
      await helpers.visible(tester, find.byKey(const ValueKey('entry-title')));
      await tester.enterText(
        find.byKey(const ValueKey('entry-title')),
        'Little wins',
      );
      await helpers.visible(
        tester,
        find.byKey(const ValueKey('entry-content')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('entry-content')),
        'A little progress.',
      );
      await tester.tap(find.byTooltip('Insert media'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checklist'));
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.byType(ChecklistBlock));
      final checklistField = find.byWidgetPredicate(
        (w) =>
            w is TextFormField && w.key.toString().contains('checklist-text-'),
      );
      await tester.enterText(checklistField, 'Finish presentation');
      await tester.tap(find.byType(AnimatedChecklistCheck));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<AnimatedChecklistCheck>(find.byType(AnimatedChecklistCheck))
            .checked,
        isTrue,
      );
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('5 words'));
      expect(find.text('5 words'), findsOneWidget);
      await tester.tap(find.byTooltip('Insert media'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, 800));
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.byKey(const ValueKey('entry-tags')));
      await tester.enterText(
        find.byKey(const ValueKey('entry-tags')),
        'school, Gratitude, SCHOOL',
      );
      await tester.tap(find.byKey(const ValueKey('save-shortcut')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Journal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Little wins'));
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.byType(ChecklistBlock));
      expect(find.text('Finish presentation'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedChecklistCheck>(find.byType(AnimatedChecklistCheck))
            .checked,
        isTrue,
      );
      expect(find.text('school'), findsOneWidget);
      expect(find.text('Gratitude'), findsOneWidget);
    },
  );
  testWidgets(
    'Control F opens Journal search from Home and Insights remains secondary',
    (tester) async {
      await helpers.app(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journal-search')), findsOneWidget);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('Explore your insights'));
      await tester.tap(find.text('Explore your insights'));
      await tester.pumpAndSettle();
      expect(find.text('Mood balance'), findsOneWidget);
      expect(find.text('Longest streak'), findsOneWidget);
      expect(find.text('20 words'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('Calendar and search fit $size with doubled text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await tester.pumpWidget(
        host(
          CalendarScreen(
            entries: sampleEntries,
            onOpen: (_) async {},
            onCreate: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(
          TimelineScreen(
            entries: sampleEntries,
            onOpen: (_) async {},
            onCreate: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search journal'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('journal-search')),
        'missing',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

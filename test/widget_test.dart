import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/app/app.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/core/utils/journal_format.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/screens/journal_editor_screen.dart';
import 'package:ios_style_journal/screens/summary_screen.dart';
import 'package:ios_style_journal/screens/home_screen.dart';
import 'package:ios_style_journal/screens/timeline_screen.dart';
import 'package:ios_style_journal/screens/entry_detail_screen.dart';
import 'package:ios_style_journal/screens/onboarding_screen.dart';

Future<void> start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const JournalApp(persist: false));
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 50,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> write(WidgetTester tester, String title, String body) async {
  await reveal(tester, find.byKey(const ValueKey('entry-title')));
  await tester.enterText(find.byKey(const ValueKey('entry-title')), title);
  await reveal(tester, find.byKey(const ValueKey('entry-content')));
  await tester.enterText(find.byKey(const ValueKey('entry-content')), body);
  await tapVisible(tester, find.byKey(const ValueKey('save-entry')));
}

void main() {
  test('Words and date ordering use consistent runtime rules', () {
    expect(wordCount('  a\nsmall   moment  '), 3);
    expect(wordCount('  '), 0);
    expect(sortedEntries(sampleEntries).first.id, 'sample-1');
    expect(sampleEntries.length, 2);
  });

  testWidgets(
    'Mood check-in hands off to validated create, read, edit and delete',
    (tester) async {
      await start(tester);
      expect(find.text('Mindful Journal'), findsOneWidget);
      await tester.tap(find.text('How are you feeling today?'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mood-good')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Write about it'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('save-entry')));
      expect(find.text('Please add a title.'), findsOneWidget);
      expect(
        find.text('Please write something before saving.'),
        findsOneWidget,
      );
      await write(
        tester,
        'A lovely morning',
        'I made time to enjoy the quiet.',
      );
      expect(find.byType(JournalEditorScreen), findsNothing);
      await tapVisible(tester, find.text('View all'));
      expect(find.text('3 entries · This session'), findsOneWidget);
      await tapVisible(tester, find.text('A lovely morning'));
      expect(find.text('Your entry'), findsOneWidget);
      await tester.tap(find.byTooltip('Entry actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit entry'));
      await tester.pumpAndSettle();
      await write(
        tester,
        'A thoughtful morning',
        'I made time for a quieter beginning.',
      );
      expect(find.text('A thoughtful morning'), findsOneWidget);
      expect(find.text('I made time for a quieter beginning.'), findsOneWidget);
      if (find.byTooltip('Delete entry').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Entry actions'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('A thoughtful morning'), findsOneWidget);
      if (find.byTooltip('Delete entry').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Entry actions'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('2 entries · This session'), findsOneWidget);
      expect(find.text('A thoughtful morning'), findsNothing);
    },
  );

  testWidgets('Dirty editor protects writing, and missing mood prevents save', (
    tester,
  ) async {
    await start(tester);
    await reveal(tester, find.text('Start a new entry'));
    await tester.tap(find.text('Start a new entry'));
    await tester.pumpAndSettle();
    await write(
      tester,
      'Keep this thought',
      'This writing should survive cancelled navigation.',
    );
    expect(find.text('Please choose a mood.'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Back'));
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('entry-content')))
          .controller!
          .text,
      'This writing should survive cancelled navigation.',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditorScreen), findsNothing);
  });

  testWidgets(
    'System back protects dirty input and Ctrl+S saves the active editor',
    (tester) async {
      await start(tester);
      await reveal(tester, find.text('Start a new entry'));
      await tester.tap(find.text('Start a new entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mood-great')));
      await tester.enterText(
        find.byKey(const ValueKey('entry-title')),
        'Shortcut entry',
      );
      await reveal(tester, find.byKey(const ValueKey('entry-content')));
      await tester.enterText(
        find.byKey(const ValueKey('entry-content')),
        'Saved using the keyboard.',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(JournalEditorScreen), findsNothing);
      await tapVisible(tester, find.text('View all'));
      expect(find.text('Shortcut entry'), findsOneWidget);
    },
  );

  testWidgets('Delete last entry produces a functional empty state', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, find.text('View all'));
    for (final title in ['A productive day', 'Small steps']) {
      await tapVisible(tester, find.text(title));
      if (find.byTooltip('Delete entry').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Entry actions'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }
    expect(find.text('0 entries · This session'), findsOneWidget);
    expect(find.text('Your journal is waiting.'), findsOneWidget);
    await tapVisible(tester, find.text('Create first entry'));
    expect(find.byType(JournalEditorScreen), findsOneWidget);
  });

  testWidgets('Appearance updates immediately and average keeps its fraction', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('4.5/5'), findsOneWidget);
    await tapVisible(tester, find.text('Dark'));
    expect(
      Theme.of(tester.element(find.text('Your journal'))).brightness,
      Brightness.dark,
    );
    await tapVisible(tester, find.text('Light'));
    expect(
      Theme.of(tester.element(find.text('Your journal'))).brightness,
      Brightness.light,
    );
    await tapVisible(tester, find.text('System'));
    await tester.drag(find.byType(ListView).last, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('4.5/5'), findsOneWidget);
  });

  testWidgets('Empty summary avoids fabricated scores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SummaryScreen(
          entries: const [],
          themeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
        ),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Responsive pages at $size, text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const JournalEditorScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const ValueKey('entry-content')));
        await tester.enterText(
          find.byKey(const ValueKey('entry-content')),
          'A keyboard-safe thought.',
        );
        await tester.tap(find.byKey(const ValueKey('save-shortcut')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: SummaryScreen(
              entries: sampleEntries,
              themeMode: ThemeMode.dark,
              onThemeModeChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final page in <Widget>[
          OnboardingScreen(onGetStarted: () {}),
          JournalShell(
            entries: sampleEntries,
            themeMode: ThemeMode.light,
            onThemeModeChanged: (_) {},
            onEntrySaved: (_) {},
            onEntryDeleted: (_) {},
          ),
          TimelineScreen(
            entries: sampleEntries,
            onOpen: (_) async {},
            onCreate: () async {},
          ),
          EntryDetailScreen(
            id: sampleEntries.first.id,
            entries: sampleEntries,
            onEdit: (_) async {},
            onDelete: (_) {},
          ),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: page,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}

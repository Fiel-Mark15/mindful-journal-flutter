import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/core/experience/journal_experience.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/models/journal_task.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/models/user_profile.dart';
import 'package:ios_style_journal/screens/home_screen.dart';
import 'package:ios_style_journal/screens/settings_screen.dart';
import 'package:ios_style_journal/screens/legal_screen.dart';
import 'package:ios_style_journal/screens/tasks_screen.dart';
import 'package:ios_style_journal/screens/timeline_screen.dart';
import 'package:ios_style_journal/widgets/journal_entry_views.dart';
import 'package:ios_style_journal/widgets/journal_checklist.dart';
import 'personalization_test.dart' as helpers;

Future<void> settings(WidgetTester tester) async {
  await tester.tap(find.text('Profile').last);
  await tester.pumpAndSettle();
  await helpers.visible(tester, find.text('Settings'));
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  test('Version matches pubspec without adding a version package', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: $journalAppVersion'),
    );
  });
  test(
    'Tasks group overdue dates with today, future, undated and completed separately',
    () {
      final now = DateTime(2026, 10, 8);
      JournalTask task({DateTime? due, bool done = false}) => JournalTask(
        id: 'x',
        title: 'One',
        createdAt: now,
        dueDate: due,
        isCompleted: done,
      );
      expect(
        taskGroup(task(due: DateTime(2026, 10, 7)), now: now),
        TaskGroup.today,
      );
      expect(taskGroup(task(due: now), now: now), TaskGroup.today);
      expect(
        taskGroup(task(due: DateTime(2026, 10, 9)), now: now),
        TaskGroup.upcoming,
      );
      expect(taskGroup(task(), now: now), TaskGroup.undated);
      expect(taskGroup(task(done: true), now: now), TaskGroup.completed);
    },
  );
  test(
    'Session reset clears tasks, prompts, searches, layout and writing preferences',
    () {
      final state = JournalExperience();
      state.saveTask(
        JournalTask(id: 't', title: 'Task', createdAt: DateTime.now()),
      );
      state.togglePrompt('p');
      state.usePrompt('p');
      state.rememberSearch('coding');
      state.update(const JournalPreferences(haptics: false, textSize: 24));
      state.setViewMode(JournalViewMode.grid);
      state.reset();
      expect(state.tasks, isEmpty);
      expect(state.favoritePrompts, isEmpty);
      expect(state.usedPrompts, isEmpty);
      expect(state.recentSearches, isEmpty);
      expect(state.viewMode, JournalViewMode.card);
      expect(state.preferences.haptics, isTrue);
      expect(state.preferences.textSize, 18);
      state.dispose();
    },
  );
  testWidgets(
    'Profile opens Settings, local documents and Flutter license page',
    (tester) async {
      await helpers.app(tester);
      await settings(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      for (final label in [
        'Privacy Policy',
        'Terms of Use',
        'Open-source licenses',
      ]) {
        await helpers.visible(tester, find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        if (label == 'Open-source licenses') {
          expect(find.byType(LicensePage), findsOneWidget);
        } else {
          expect(find.byType(LegalScreen), findsOneWidget);
          expect(find.text('Effective date: October 11, 2026'), findsOneWidget);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'Clear cancellation preserves content; confirmation resets root and all runtime state',
    (tester) async {
      await helpers.app(tester);
      final shell = tester.widget<JournalShell>(find.byType(JournalShell));
      final experience = ExperienceScope.maybeOf(
        tester.element(find.byType(JournalShell)),
      )!;
      experience.saveTask(
        JournalTask(id: 't', title: 'Keep me', createdAt: DateTime.now()),
      );
      experience.togglePrompt('p');
      experience.usePrompt('p');
      experience.rememberSearch('coding');
      experience.setViewMode(JournalViewMode.grid);
      experience.update(const JournalPreferences(haptics: false));
      shell.onProfileChanged!(const UserProfile(displayName: 'Fiel'));
      shell.onThemeModeChanged(ThemeMode.dark);
      shell.onAccentChanged!(JournalAccent.indigo);
      await tester.pumpAndSettle();
      await settings(tester);
      await helpers.visible(tester, find.text('Clear this session’s data'));
      await tester.tap(find.text('Clear this session’s data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(shell.entries.length, 2);
      expect(experience.tasks.length, 1);
      await tester.tap(find.text('Clear this session’s data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('John'), findsOneWidget);
      expect(
        tester.widget<JournalShell>(find.byType(JournalShell)).entries,
        isEmpty,
      );
      expect(experience.tasks, isEmpty);
      expect(experience.favoritePrompts, isEmpty);
      expect(experience.viewMode, JournalViewMode.card);
      expect(experience.preferences.haptics, isTrue);
      expect(
        tester.widget<JournalShell>(find.byType(JournalShell)).themeMode,
        ThemeMode.system,
      );
      expect(find.text('Home').last, findsOneWidget);
    },
  );
  testWidgets(
    'Task create validates title, edit preserves dates, completion and delete work',
    (tester) async {
      final state = JournalExperience();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        ExperienceScope(
          experience: state,
          child: MaterialApp(
            theme: AppTheme.light,
            home: TasksScreen(experience: state),
          ),
        ),
      );
      await tester.tap(find.text('Create a task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      expect(find.text('Add a task title.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('task-title')),
        'Finish project',
      );
      await tester.tap(find.text('Add due date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      expect(state.tasks.single.dueDate, isNotNull);
      final created = state.tasks.single.createdAt;
      await tester.tap(find.text('Finish project'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('task-title')),
        'Review project',
      );
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      expect(state.tasks.single.createdAt, created);
      expect(state.tasks.single.title, 'Review project');
      await tester.tap(find.byType(AnimatedChecklistCheck));
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.tasks.single.isCompleted, isTrue);
      expect(
        tester
            .widget<AnimatedChecklistCheck>(find.byType(AnimatedChecklistCheck))
            .checked,
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
      await tester.tap(find.byTooltip('Task actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.tasks.length, 1);
      await tester.tap(find.byTooltip('Task actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(state.tasks, isEmpty);
      expect(find.text('Nothing waiting for you.'), findsOneWidget);
    },
  );
  testWidgets(
    'Layout selection is session-wide and search/favorites retain the same records',
    (tester) async {
      await helpers.app(tester);
      await tester.tap(find.text('Journal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search journal'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('journal-search')),
        'productive',
      );
      await tester.pumpAndSettle();
      for (final mode in ['List View', 'Grid View', 'Card View', 'Grid View']) {
        await tester.tap(find.byTooltip('Journal view mode'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(mode));
        await tester.pumpAndSettle();
        expect(find.text('A productive day'), findsOneWidget);
        expect(find.text('Small steps'), findsNothing);
        expect(find.text('1 entry · This session'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Add favorite'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove favorite'), findsOneWidget);
      await tester.tap(find.byTooltip('Filter journal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorites only'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.byType(GridEntryCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('Grid, Settings and documents fit $size at doubled text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = JournalExperience()..setViewMode(JournalViewMode.grid);
      addTearDown(state.dispose);
      Widget host(Widget child) => ExperienceScope(
        experience: state,
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: child,
        ),
      );
      for (final page in [
        TimelineScreen(
          entries: sampleEntries,
          onOpen: (_) async {},
          onCreate: () async {},
        ),
        const LegalScreen(document: LegalDocument.privacy),
        const LegalScreen(document: LegalDocument.terms),
        TasksScreen(experience: state),
        SettingsScreen(
          experience: state,
          profile: const UserProfile(),
          onProfileChanged: (_) {},
          themeMode: ThemeMode.dark,
          onThemeModeChanged: (_) {},
          accent: JournalAccent.indigo,
          onAccentChanged: (_) {},
        ),
      ]) {
        await tester.pumpWidget(host(page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}

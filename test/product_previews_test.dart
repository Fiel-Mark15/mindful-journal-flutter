// Real Flutter-rendered previews. Opt-in, no native UI automation.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/core/experience/journal_experience.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/screens/inspiration_screen.dart';
import 'package:ios_style_journal/screens/quick_check_in_screen.dart';
import 'package:ios_style_journal/screens/journal_preferences_screen.dart';
import 'package:ios_style_journal/screens/insights_screen.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'personalization_test.dart' as helpers;
import 'package:ios_style_journal/screens/settings_screen.dart';
import 'package:ios_style_journal/screens/legal_screen.dart';
import 'package:ios_style_journal/screens/tasks_screen.dart';
import 'package:ios_style_journal/screens/timeline_screen.dart';
import 'package:ios_style_journal/models/journal_task.dart';
import 'package:ios_style_journal/models/user_profile.dart';

void main() {
  testWidgets('Capture new product previews', (tester) async {
    await tester.runAsync(() async {
      final sdk =
          Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
      final loader = FontLoader('Roboto');
      for (final name in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/Roboto-$name.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await loader.load();
      final material = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await material.load();
      final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        );
      await cupertino.load();
    });

    final experience = JournalExperience();
    addTearDown(experience.dispose);
    final key = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> host(Widget page) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ExperienceScope(
            experience: experience,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/screenshots/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await host(InspirationScreen(experience: experience));
    await capture('prompt-packs');
    await tester.tap(find.text('Daily Reflection'));
    await tester.pumpAndSettle();
    await capture('prompt-questions');
    await host(InspirationScreen(experience: experience, templates: true));
    await capture('templates');
    await host(const QuickCheckInScreen(initialMood: Mood.good));
    await capture('quick-check-in');
    await host(JournalPreferencesScreen(experience: experience));
    await capture('journal-preferences');
    await host(InsightsScreen(entries: sampleEntries));
    await capture('reflection-rings');
    await host(
      SettingsScreen(
        experience: experience,
        profile: const UserProfile(),
        onProfileChanged: (_) {},
        themeMode: ThemeMode.system,
        onThemeModeChanged: (_) {},
        accent: JournalAccent.indigo,
        onAccentChanged: (_) {},
        onClearSession: () {},
      ),
    );
    await capture('settings');
    await host(const LegalScreen(document: LegalDocument.privacy));
    await capture('privacy-policy');
    await host(const LegalScreen(document: LegalDocument.terms));
    await capture('terms-of-use');
    final now = DateTime.now();
    for (final task in [
      JournalTask(
        id: 'preview-1',
        title: 'Finish the project',
        createdAt: now,
        dueDate: now,
        category: 'College',
      ),
      JournalTask(
        id: 'preview-2',
        title: 'Review the presentation',
        createdAt: now,
        dueDate: now,
      ),
      JournalTask(id: 'preview-3', title: 'Take a quiet walk', createdAt: now),
      JournalTask(
        id: 'preview-4',
        title: 'Make time to reflect',
        createdAt: now,
        isCompleted: true,
      ),
    ]) {
      experience.saveTask(task);
    }
    await host(TasksScreen(experience: experience));
    await capture('tasks');
    final entries = List<JournalEntry>.of(sampleEntries);
    await host(
      TimelineScreen(
        entries: entries,
        onOpen: (_) async {},
        onCreate: () async {},
      ),
    );
    experience.setViewMode(JournalViewMode.list);
    await capture('journal-list-view');
    experience.setViewMode(JournalViewMode.grid);
    await capture('journal-grid-view');

    // Capture the real root app in a wide archive layout.
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = const Size(1440, 900);
    await helpers.app(tester);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A productive day'));
    await tester.pumpAndSettle();
    // Root screenshot boundary for this final view.
    final root = tester.binding.renderViews.single;
    await tester.runAsync(() async {
      final layer = root.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        Offset.zero & const Size(1440, 900),
        pixelRatio: 1,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/screenshots/journal-split-view.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: !const bool.fromEnvironment('CAPTURE_SCREENS'));
}

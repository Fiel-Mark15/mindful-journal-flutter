// Reproducible Flutter-rendered previews, not native device screenshots.
// flutter test test/screenshots_test.dart --dart-define=CAPTURE_SCREENS=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/app/app.dart';
import 'package:ios_style_journal/screens/drawing_screen.dart';
import 'package:ios_style_journal/widgets/attachment_gallery.dart';
import 'package:ios_style_journal/widgets/journal_checklist.dart';

void main() {
  testWidgets('Capture application previews', (tester) async {
    // Fonts are loaded from the local Flutter SDK for previews only.
    // No system font is copied into the app or distributed.
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const JournalApp(persist: false)),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/app_icon.png'),
        key.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/screenshots').create(recursive: true);
        await File(
          'docs/screenshots/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('onboarding');
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await capture('home-light');
    await tester.tap(find.text('Journal').last);
    await tester.pumpAndSettle();
    await capture('journal-tab');
    await tester.tap(find.byTooltip('Search journal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('journal-search')),
      'productive',
    );
    await tester.pumpAndSettle();
    await capture('journal-search');
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter journal'));
    await tester.pumpAndSettle();
    await capture('journal-filters');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    await capture('calendar-light');
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Create journal entry'));
    await tester.pumpAndSettle();
    await capture('creation-menu');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('How are you feeling today?'));
    await tester.pumpAndSettle();
    await capture('mood-check-in');
    await tester.tap(find.byKey(const ValueKey('mood-good')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write about it'));
    await tester.pumpAndSettle();
    await capture('editor-light');
    await tester.tap(find.byTooltip('Insert media'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(ChecklistBlock),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.byType(ChecklistBlock));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextFormField && w.key.toString().contains('checklist-text-'),
      ),
      'Make time for a quiet walk',
    );
    await tester.tap(find.byType(AnimatedChecklistCheck));
    await tester.pumpAndSettle();
    await capture('editor-checklist');
    await tester.scrollUntilVisible(
      find.text('Draw'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Draw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();
    final drawing = find.byKey(const ValueKey('drawing-canvas'));
    final pen = await tester.startGesture(
      tester.getCenter(drawing) - const Offset(70, 40),
    );
    await pen.moveBy(const Offset(50, 50));
    await pen.moveBy(const Offset(60, -45));
    await pen.up();
    await tester.pumpAndSettle();
    await capture('drawing-canvas');
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Save drawing'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (
      var attempt = 0;
      attempt < 20 && find.byType(DrawingScreen).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(AttachmentGallery));
    await tester.pumpAndSettle();
    await capture('editor-media');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View all'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('View all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    await capture('timeline-light');
    await tester.tap(find.text('A productive day'));
    await tester.pumpAndSettle();
    await capture('reading-light');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await capture('profile-light');
    await tester.scrollUntilVisible(
      find.text('Explore your insights'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Explore your insights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore your insights'));
    await tester.pumpAndSettle();
    await capture('insights-light');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await capture('profile-edit');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Color theme'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Color theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Color theme'));
    await tester.pumpAndSettle();
    await capture('theme-presets');
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await capture('home-ocean');
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dark'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Your journal'))).brightness,
      Brightness.dark,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await capture('profile-dark');
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await capture('home-dark');
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await capture('desktop-dark');
  }, skip: !const bool.fromEnvironment('CAPTURE_SCREENS'));
}

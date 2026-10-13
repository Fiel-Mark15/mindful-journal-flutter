import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/app/app.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/core/editing/journal_text_controller.dart';
import 'package:ios_style_journal/core/utils/journal_format.dart';
import 'package:ios_style_journal/models/journal_attachment.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/models/text_format.dart';
import 'package:ios_style_journal/screens/drawing_screen.dart';
import 'package:ios_style_journal/screens/journal_editor_screen.dart';
import 'package:ios_style_journal/screens/entry_detail_screen.dart';
import 'package:ios_style_journal/widgets/attachment_gallery.dart';
import 'package:ios_style_journal/widgets/color_picker.dart';
import 'personalization_test.dart' as helpers;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  test('All accent palettes and extreme custom colors remain readable', () {
    for (final accent in [
      ...JournalAccent.presets,
      JournalAccent.custom(Colors.white),
      JournalAccent.custom(Colors.black),
      JournalAccent.custom(Colors.yellow),
    ]) {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.themed(brightness, accent);
        expect(
          contrast(theme.colorScheme.primary, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        final gradient = theme.extension<AccentPalette>()!;
        expect(
          contrast(gradient.start, Colors.white),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(gradient.end, Colors.white), greaterThanOrEqualTo(4.5));
      }
    }
  });
  test('Text colors/highlights preserve inline styles and undo history', () {
    final controller = JournalTextController(text: 'A calm morning');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 6);
    controller.toggle(TextFormat.bold);
    controller.applyColor(Colors.blue);
    controller.applyColor(Colors.yellow, highlight: true);
    final run = controller.runs().single;
    expect(run.flags, TextFormat.bold);
    expect(run.color, Colors.blue.toARGB32());
    expect(run.highlight, Colors.yellow.toARGB32());
    controller.undo();
    expect(controller.runs().single.highlight, isNull);
    controller.redo();
    expect(controller.runs().single.highlight, Colors.yellow.toARGB32());
    for (final background in [Colors.white, const Color(0xFF14151F)]) {
      final span = attributedSpan(
        controller.text,
        controller.runs(),
        const TextStyle(fontSize: 17),
        background: background,
      );
      final styled = (span.children![1] as TextSpan).style!;
      expect(
        contrast(
          styled.color!,
          Color.alphaBlend(styled.backgroundColor!, background),
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(wordCount('• calm morning\n2. quiet day\n> keep going'), 6);
    expect(wordCount('• \n1.\n> '), 0);
    expect(readableJournalText('• \n1.\n> ').trim(), isEmpty);
    controller.selection = const TextSelection.collapsed(offset: 14);
    controller.applyColor(Colors.red);
    controller.value = controller.value.copyWith(
      text: '${controller.text}!',
      selection: const TextSelection.collapsed(offset: 15),
    );
    expect(controller.runs().last.color, Colors.red.toARGB32());
  });
  testWidgets(
    'Three destinations retain global creation and themes update cursor',
    (tester) async {
      await helpers.app(tester);
      await tester.tap(find.text('Journal').last);
      await tester.pumpAndSettle();
      expect(find.text('2 entries · This session'), findsOneWidget);
      await tester.tap(find.text('A productive day'));
      await tester.pumpAndSettle();
      expect(find.text('Your entry'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Create journal entry'));
      await tester.pumpAndSettle();
      expect(find.text('Add photo memory'), findsOneWidget);
      expect(find.text('Draw something'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('Color theme'));
      await tester.tap(find.text('Color theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ocean'));
      await tester.pumpAndSettle();
      expect(find.text('Ocean'), findsOneWidget);
      final rootTheme = Theme.of(tester.element(find.text('Color theme')));
      expect(
        rootTheme.colorScheme.primary,
        AppTheme.themed(
          Brightness.light,
          JournalAccent.presets[2],
        ).colorScheme.primary,
      );
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('Start a new entry'));
      await tester.tap(find.text('Start a new entry'));
      await tester.pumpAndSettle();
      await helpers.visible(
        tester,
        find.byKey(const ValueKey('entry-content')),
      );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('entry-content')),
          matching: find.byType(TextField),
        ),
      );
      final stateTheme = Theme.of(
        tester.element(find.byKey(const ValueKey('entry-content'))),
      );
      expect(field.cursorColor, stateTheme.colorScheme.primary);
      await tester.tap(find.byTooltip('Focus writing'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Insert media'), findsNothing);
      await tester.tap(find.byTooltip('Show writing tools'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Insert media'), findsOneWidget);
    },
  );
  testWidgets(
    'Custom accent picker changes semantic state and can be cancelled',
    (tester) async {
      await helpers.app(tester);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await helpers.visible(tester, find.text('Color theme'));
      await tester.tap(find.text('Color theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom accent'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rose'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use color'));
      await tester.pumpAndSettle();
      expect(find.text('Custom'), findsOneWidget);
      final theme = Theme.of(tester.element(find.text('Color theme')));
      expect(
        theme.colorScheme.primary,
        AppTheme.themed(
          Brightness.light,
          JournalAccent.custom(journalColors['Rose']!),
        ).colorScheme.primary,
      );
      await tester.tap(find.text('Color theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom accent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Custom'), findsOneWidget);
    },
  );
  testWidgets('Photos save into runtime entries, open zoom viewer and remove', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = (await rootBundle.load(
      'assets/images/app_icon.png',
    )).buffer.asUint8List();
    JournalEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.push<JournalEntry>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalEditorScreen(
                      initialMood: Mood.good,
                      pickImage: () async => bytes,
                    ),
                  ),
                );
              },
              child: const Text('Write'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();
    expect(find.byType(AttachmentGallery), findsNothing);
    await helpers.visible(tester, find.text('Add photo'));
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    expect(find.byType(AttachmentGallery), findsOneWidget);
    await helpers.visible(tester, find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(AttachmentGallery), findsNothing);
    for (var i = 0; i < 5; i++) {
      await helpers.visible(tester, find.text('Add photo'));
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('You can attach up to 4 photos per entry.'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, 2200));
    await tester.pumpAndSettle();
    await helpers.visible(tester, find.byKey(const ValueKey('entry-title')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-title')),
      'Photo memory',
    );
    await helpers.visible(tester, find.byKey(const ValueKey('entry-content')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-content')),
      'A moment worth keeping.',
    );
    await tester.tap(find.byKey(const ValueKey('save-shortcut')));
    await tester.pumpAndSettle();
    expect(saved!.attachments.length, 4);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EntryDetailScreen(
          id: saved!.id,
          entries: [saved!],
          onEdit: (_) async {},
          onDelete: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await helpers.visible(tester, find.byType(AttachmentGallery));
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    expect(find.text('Your entry'), findsOneWidget);
  });
  testWidgets(
    'Drawing strokes save as editable bytes; undo redo and cancel work',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      JournalAttachment? saved;
      JournalAttachment? editing;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await Navigator.push<JournalAttachment>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DrawingScreen(attachment: editing),
                    ),
                  );
                },
                child: const Text('Draw'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Draw'));
      await tester.pumpAndSettle();
      final canvas = find.byKey(const ValueKey('drawing-canvas'));
      final gesture = await tester.startGesture(
        tester.getCenter(canvas) - const Offset(50, 0),
      );
      await gesture.moveBy(const Offset(100, 30));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Undo drawing'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Save drawing',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Redo drawing'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Save drawing'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      for (var attempt = 0; attempt < 20 && saved == null; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.bytes.length, greaterThan(0));
      expect(saved!.drawing!.strokes.single.points.length, 2);
      final original = saved!;
      editing = original;
      await tester.tap(find.text('Draw'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Undo drawing'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard this drawing?'), findsOneWidget);
      await tester.tap(find.text('Keep drawing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel drawing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(original.drawing!.strokes.single.points.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Editor color tools apply to selected text and preserve Bold', (
    tester,
  ) async {
    await helpers.app(tester);
    await helpers.visible(tester, find.text('Start a new entry'));
    await tester.tap(find.text('Start a new entry'));
    await tester.pumpAndSettle();
    await helpers.visible(tester, find.byKey(const ValueKey('entry-content')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-content')),
      'Keep this color',
    );
    final controller =
        tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('entry-content')),
                )
                .controller!
            as JournalTextController;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await tester.tap(find.byTooltip('Bold'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Text color'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue'));
    await tester.tap(find.text('Use color'));
    await tester.pumpAndSettle();
    expect(controller.runs().single.color, journalColors['Blue']!.toARGB32());
    expect(controller.runs().single.flags, TextFormat.bold);
    await tester.tap(find.byTooltip('Insert media'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text highlight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amber'));
    await tester.tap(find.text('Use color'));
    await tester.pumpAndSettle();
    expect(
      controller.runs().single.highlight,
      journalColors['Amber']!.toARGB32(),
    );
    expect(controller.runs().single.color, journalColors['Blue']!.toARGB32());
    expect(controller.text, 'Keep this color');
  });
  testWidgets('Photo cancellation and errors preserve editor content', (
    tester,
  ) async {
    for (final picker in <Future<Uint8List?> Function()>[
      () async => null,
      () async => throw PlatformException(code: 'denied'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.light,
          home: JournalEditorScreen(pickImage: picker),
        ),
      );
      await tester.pumpAndSettle();
      await helpers.visible(
        tester,
        find.byKey(const ValueKey('entry-content')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('entry-content')),
        'Keep my writing',
      );
      await helpers.visible(tester, find.text('Add photo'));
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentGallery), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('entry-content')))
            .controller!
            .text,
        'Keep my writing',
      );
      expect(tester.takeException(), isNull);
    }
    expect(find.textContaining('access was denied'), findsOneWidget);
  });
  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('New drawing and color controls fit $size at enlarged text', (
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
      await tester.pumpWidget(host(const DrawingScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drawing-canvas')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Pen color'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(const JournalApp(persist: false)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Eraser clears rendered ink and its stroke can be undone', (
    tester,
  ) async {
    final ink = InkDocument();
    addTearDown(ink.dispose);
    ink.begin(const Offset(.1, .5), Colors.black, .1, BrushTool.pen);
    ink.move(const Offset(.9, .5));
    ink.end();
    Future<int> middleRed() async {
      int red = -1;
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        InkPainter(
          ink,
          Colors.white,
        ).paint(Canvas(recorder), const Size(100, 100));
        final picture = recorder.endRecording();
        final image = await picture.toImage(100, 100);
        final bytes = await image.toByteData();
        red = bytes!.getUint8((50 * 100 + 50) * 4);
        image.dispose();
        picture.dispose();
      });
      return red;
    }

    expect(await middleRed(), 0);
    ink.begin(const Offset(.5, .4), Colors.black, .1, BrushTool.eraser);
    ink.move(const Offset(.5, .6));
    ink.end();
    expect(await middleRed(), 255);
    ink.undo();
    expect(await middleRed(), 0);
    ink.redo();
    expect(await middleRed(), 255);
  });
}

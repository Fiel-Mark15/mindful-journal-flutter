import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/app/app.dart';
import 'package:ios_style_journal/models/user_profile.dart';
import 'package:ios_style_journal/screens/profile_editor_sheet.dart';
import 'package:ios_style_journal/screens/journal_editor_screen.dart';
import 'package:ios_style_journal/widgets/profile_avatar.dart';
import 'package:ios_style_journal/core/editing/journal_text_controller.dart';
import 'package:ios_style_journal/models/text_format.dart';

Future<void> visible(WidgetTester tester, Finder finder) async {
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
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const JournalApp(persist: false));
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Saved profile updates Home immediately; cancelled edits do not',
    (tester) async {
      await app(tester);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('profile-name')), '');
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('profile-name')),
        'Fiel Oronos',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-tagline')),
        'One page at a time.',
      );
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(find.text('Fiel Oronos'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Fiel'), findsOneWidget);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-name')),
        'Unsaved Name',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Fiel Oronos'), findsOneWidget);
    },
  );
  testWidgets('Center create menu opens entry, mood and a real prompt', (
    tester,
  ) async {
    await app(tester);
    await tester.tap(find.byTooltip('Create journal entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New journal entry'));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditorScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Create journal entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick mood check-in'));
    await tester.pumpAndSettle();
    expect(find.text('Quick check-in'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Create journal entry'));
    await tester.pumpAndSettle();
    await visible(tester, find.text('Reflection prompt'));
    await tester.tap(find.text('Reflection prompt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gratitude'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write with this prompt').first);
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('entry-content')));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('entry-content')))
          .controller!
          .text,
      contains('ordinary thing'),
    );
  });
  testWidgets('Formatting state and focus mode retain writing', (tester) async {
    await app(tester);
    await visible(tester, find.text('Start a new entry'));
    await tester.tap(find.text('Start a new entry'));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('entry-content')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-content')),
      'A quiet moment',
    );
    final controller =
        tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('entry-content')),
                )
                .controller!
            as JournalTextController;
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);
    await tester.pump();
    await tester.tap(find.byTooltip('Bold'));
    await tester.pumpAndSettle();
    expect(controller.runs().single.flags, TextFormat.bold);
    await tester.tap(find.byTooltip('Focus writing'));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling?'), findsNothing);
    expect(controller.text, 'A quiet moment');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Focus writing'), findsOneWidget);
    expect(controller.text, 'A quiet moment');
  });
  testWidgets('Saved formatting survives reading and reopening the editor', (
    tester,
  ) async {
    await app(tester);
    await visible(tester, find.text('Start a new entry'));
    await tester.tap(find.text('Start a new entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mood-great')));
    await visible(tester, find.byKey(const ValueKey('entry-title')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-title')),
      'Styled memory',
    );
    await visible(tester, find.byKey(const ValueKey('entry-content')));
    await tester.enterText(
      find.byKey(const ValueKey('entry-content')),
      'A quiet moment',
    );
    final controller =
        tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('entry-content')),
                )
                .controller!
            as JournalTextController;
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);
    await tester.pump();
    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-shortcut')));
    await tester.pumpAndSettle();
    await visible(tester, find.text('View all'));
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Styled memory'));
    await tester.pumpAndSettle();
    final reading = tester.widget<SelectableText>(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.textSpan != null,
      ),
    );
    final spans = reading.textSpan!.children!.cast<TextSpan>();
    expect(
      spans.any(
        (span) =>
            span.text == 'quiet' && span.style!.fontWeight == FontWeight.w700,
      ),
      isTrue,
    );
    await tester.tap(find.byTooltip('Entry actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('entry-content')));
    final reopened =
        tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('entry-content')),
                )
                .controller!
            as JournalTextController;
    expect(reopened.runs().single.flags, TextFormat.bold);
    expect(reopened.runs().single.start, 2);
    expect(reopened.runs().single.end, 7);
  });
  testWidgets(
    'Photo selection cancel/error is safe and removal previews default',
    (tester) async {
      Future<void> sheet(
        Future<Uint8List?> Function() picker, [
        Uint8List? photo,
      ]) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileEditorSheet(
                key: UniqueKey(),
                profile: UserProfile(photo: photo),
                pickPhoto: picker,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await sheet(() async => null);
      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).profile.photo,
        isNull,
      );
      await sheet(() async => throw PlatformException(code: 'denied'));
      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('access was denied'), findsOneWidget);
      final bytes = (await rootBundle.load(
        'assets/images/app_icon.png',
      )).buffer.asUint8List();
      await sheet(() async => bytes);
      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).profile.photo,
        bytes,
      );
      await tester.tap(find.text('Use default avatar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).profile.photo,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

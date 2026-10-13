import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/app/app.dart';
import 'package:ios_style_journal/core/storage/local_journal_store.dart';
import 'package:ios_style_journal/core/experience/journal_experience.dart';
import 'package:ios_style_journal/core/theme/app_theme.dart';
import 'package:ios_style_journal/models/journal_entry.dart';
import 'package:ios_style_journal/models/journal_attachment.dart';
import 'package:ios_style_journal/models/checklist_item.dart';
import 'package:ios_style_journal/models/text_format.dart';
import 'package:ios_style_journal/models/user_profile.dart';
import 'package:ios_style_journal/models/journal_task.dart';
import 'package:ios_style_journal/screens/home_screen.dart';

class MemorySettings implements SettingsStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String text) async {
    value = text;
  }
}

class GatedStore extends LocalJournalStore {
  GatedStore()
    : super(directory: Directory('unused'), settings: MemorySettings());
  final gate = Completer<StoredJournal>();
  int writes = 0;
  @override
  Future<StoredJournal> load() => gate.future;
  @override
  Future<void> save({
    required List<JournalEntry> entries,
    required UserProfile profile,
    required Map<String, dynamic> preferences,
    required Map<String, dynamic> experience,
  }) async {
    writes++;
  }
}

void main() {
  late Directory dir;
  late MemorySettings prefs;
  late LocalJournalStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mindful-storage-test-');
    prefs = MemorySettings();
    store = LocalJournalStore(directory: dir, settings: prefs);
  });
  tearDown(() async {
    await store.flush();
    await dir.delete(recursive: true);
  });
  final image = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
  final drawing = JournalDrawing(
    strokes: [
      InkStroke(
        points: [const Offset(.1, .2), const Offset(.3, .4)],
        color: Colors.indigo,
        width: .02,
        tool: BrushTool.highlighter,
      ),
    ],
    background: Colors.white,
    aspectRatio: 1.2,
  );
  JournalEntry entry() => JournalEntry(
    id: 'one',
    title: 'A lasting moment',
    content: 'My first saved journal',
    date: DateTime(2026, 10, 11),
    mood: Mood.good,
    createdAt: DateTime(2026, 10, 11, 18),
    formatting: [
      const TextFormatRun(
        0,
        2,
        TextFormat.bold,
        color: 0xff123456,
        highlight: 0xffaabbcc,
      ),
    ],
    attachments: [
      JournalAttachment(id: 'photo', bytes: image),
      JournalAttachment(
        id: 'drawing',
        bytes: Uint8List.fromList(image),
        drawing: drawing,
      ),
    ],
    checklist: [
      const ChecklistItem(
        id: 'check',
        text: 'Finish project',
        isCompleted: true,
      ),
    ],
    tags: ['coding', 'school'],
    collectionId: 'college',
    isFavorite: true,
    promptId: 'prompt',
    promptText: 'What matters?',
    energy: 'High',
    kind: EntryKind.promptReflection,
  );
  Future<void> save(
    List<JournalEntry> entries, {
    UserProfile profile = const UserProfile(),
    Map<String, dynamic> settings = const {},
    Map<String, dynamic> experience = const {},
  }) => store.save(
    entries: entries,
    profile: profile,
    preferences: settings,
    experience: experience,
  );
  test(
    'All entry, formatting, checklist, drawing and task fields serialize',
    () {
      final original = entry();
      final restored = JournalEntry.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );
      expect(restored.toJson(), original.toJson());
      expect(
        restored.attachments.last.drawing!.strokes.first.points,
        drawing.strokes.first.points,
      );
      final task = JournalTask(
        id: 't',
        title: 'Task',
        createdAt: DateTime(2026),
        dueDate: DateTime(2026, 10, 12),
        isCompleted: true,
        category: 'College',
      );
      expect(JournalTask.fromJson(task.toJson()).toJson(), task.toJson());
      for (final collection in journalCollections) {
        expect(
          JournalCollection.fromJson(collection.toJson()).toJson(),
          collection.toJson(),
        );
      }
    },
  );
  test(
    'Fresh store seeds once; deletion/empty journal survives reopening',
    () async {
      expect((await store.load()).entries.length, 2);
      await save([]);
      final reopened = await LocalJournalStore(
        directory: dir,
        settings: prefs,
      ).load();
      expect(reopened.entries, isEmpty);
      expect(await File('${dir.path}/journal.json').exists(), isTrue);
    },
  );
  test(
    'Entries, photos, drawings, profile, tasks and preferences survive new store instance',
    () async {
      await store.load();
      final experience = JournalExperience();
      experience.saveTask(
        JournalTask(
          id: 't',
          title: 'Review',
          createdAt: DateTime(2026),
          isCompleted: true,
        ),
      );
      experience.togglePrompt('p');
      experience.usePrompt('p');
      experience.setCheckIn(Mood.sad);
      final settings = {
        'theme': 'dark',
        'accent': JournalAccent.custom(const Color(0xff445566)).toJson(),
        'onboardingComplete': true,
        'viewMode': 'grid',
        'preferences': const JournalPreferences(
          paper: PaperStyle.dotGrid,
          writing: WritingStyle.classicSerif,
          haptics: false,
          collectionId: 'college',
          textSize: 24,
        ).toJson(),
      };
      await save(
        [entry()],
        profile: UserProfile(
          displayName: 'Fiel',
          tagline: 'Remember',
          photo: image,
        ),
        settings: settings,
        experience: experience.toJson(),
      );
      final raw = jsonDecode(
        await File('${dir.path}/journal.json').readAsString(),
      );
      expect(
        raw['entries'][0]['attachments'][0]['filePath'],
        startsWith('media/'),
      );
      expect(raw['entries'][0]['attachments'][0].containsKey('bytes'), isFalse);
      final loaded = await LocalJournalStore(
        directory: dir,
        settings: prefs,
      ).load();
      expect(loaded.entries.single.attachments.first.bytes, image);
      expect(
        loaded.entries.single.attachments.last.drawing!.toJson(),
        drawing.toJson(),
      );
      expect(loaded.profile.photo, image);
      expect(loaded.profile.displayName, 'Fiel');
      expect(loaded.settings, containsPair('theme', 'dark'));
      expect(loaded.settings, containsPair('viewMode', 'grid'));
      expect(loaded.settings, containsPair('onboardingComplete', true));
      expect(loaded.entries.single.isFavorite, isTrue);
      expect(loaded.entries.single.checklist.single.isCompleted, isTrue);
      expect(loaded.entries.single.tags, ['coding', 'school']);
      final restored = JournalExperience()
        ..restore(loaded.experience, loaded.settings);
      expect(restored.tasks.single.isCompleted, isTrue);
      expect(restored.preferences.paper, PaperStyle.dotGrid);
      expect(restored.preferences.textSize, 24);
      expect(restored.checkIn, Mood.sad);
      expect(restored.favoritePrompts, {'p'});
      restored.dispose();
      experience.dispose();
    },
  );
  test('Rapid snapshots are ordered and last deletion wins', () async {
    await store.load();
    await Future.wait([
      save([entry()]),
      save([entry().copyWith(isFavorite: false)]),
      save([]),
    ]);
    expect(
      (await LocalJournalStore(directory: dir, settings: prefs).load()).entries,
      isEmpty,
    );
  });
  test(
    'Valid backup recovers corrupt main; both corrupt never reseed or overwrite',
    () async {
      await store.load();
      await save([entry()]);
      await save([]);
      await File('${dir.path}/journal.json').writeAsString('broken');
      expect(
        (await LocalJournalStore(
          directory: dir,
          settings: prefs,
        ).load()).entries.single.title,
        'A lasting moment',
      );
      await File('${dir.path}/journal.json.bak').writeAsString('broken too');
      await expectLater(
        LocalJournalStore(directory: dir, settings: prefs).load(),
        throwsFormatException,
      );
      expect(await File('${dir.path}/journal.json').readAsString(), 'broken');
    },
  );
  test(
    'Clear removes saved media and backup while retaining empty file',
    () async {
      await store.load();
      await save([entry()], profile: UserProfile(photo: image));
      await save([]);
      await store.purgeClearedMedia();
      expect(await Directory('${dir.path}/media').exists(), isFalse);
      expect(await File('${dir.path}/journal.json.bak').exists(), isFalse);
      expect(
        (await LocalJournalStore(
          directory: dir,
          settings: prefs,
        ).load()).entries,
        isEmpty,
      );
    },
  );
  test('Traversal media paths are rejected', () async {
    await store.load();
    final json = entry().toJson();
    json['attachments'] = [
      {'id': 'evil', 'filePath': '../outside.png'},
    ];
    await File('${dir.path}/journal.json').writeAsString(
      jsonEncode({
        'version': 1,
        'entries': [json],
      }),
    );
    await expectLater(store.load(), throwsFormatException);
  });
  testWidgets(
    'Startup waits for storage; restored profile/theme/onboarding precede normal UI',
    (tester) async {
      final gate = GatedStore();
      await tester.pumpWidget(JournalApp(store: gate));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(JournalShell), findsNothing);
      gate.gate.complete(
        StoredJournal([], const UserProfile(displayName: 'Fiel'), {
          'theme': 'dark',
          'onboardingComplete': true,
          'viewMode': 'grid',
        }, {}),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fiel'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
      final shell = tester.widget<JournalShell>(find.byType(JournalShell));
      expect(shell.themeMode, ThemeMode.dark);
      shell.onThemeModeChanged(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(gate.writes, greaterThan(0));
    },
  );
}

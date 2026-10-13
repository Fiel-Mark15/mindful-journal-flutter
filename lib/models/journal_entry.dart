import 'checklist_item.dart';
import 'text_format.dart';
import 'journal_attachment.dart';

enum EntryKind {
  text,
  photoMemory,
  checklist,
  drawing,
  promptReflection,
  quickCheckIn,
}

enum Mood { great, good, okay, bad, sad }

class MoodInfo {
  const MoodInfo({required this.label, required this.score});

  final String label;
  final int score;
}

const Map<Mood, MoodInfo> moodInfo = {
  Mood.great: MoodInfo(label: 'Great', score: 5),
  Mood.good: MoodInfo(label: 'Good', score: 4),
  Mood.okay: MoodInfo(label: 'Okay', score: 3),
  Mood.bad: MoodInfo(label: 'Bad', score: 2),
  Mood.sad: MoodInfo(label: 'Sad', score: 1),
};

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    this.formatting = const [],
    this.attachments = const [],
    this.checklist = const [],
    this.tags = const [],
    this.isFavorite = false,
    this.createdAt,
    this.collectionId,
    this.promptId,
    this.promptText,
    this.kind = EntryKind.text,
    this.energy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'mood': mood.name,
    'formatting': formatting.map((r) => r.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'checklist': checklist.map((c) => c.toJson()).toList(),
    'tags': tags,
    'isFavorite': isFavorite,
    'createdAt': createdAt?.toIso8601String(),
    'collectionId': collectionId,
    'promptId': promptId,
    'promptText': promptText,
    'kind': kind.name,
    'energy': energy,
  };
  factory JournalEntry.fromJson(
    Map<String, dynamic> j, {
    List<JournalAttachment>? attachments,
  }) => JournalEntry(
    id: j['id'] as String,
    title: j['title'] as String,
    content: j['content'] as String,
    date: DateTime.parse(j['date'] as String),
    mood: Mood.values.byName(j['mood'] as String),
    formatting: (j['formatting'] as List? ?? [])
        .map((r) => TextFormatRun.fromJson(Map<String, dynamic>.from(r)))
        .toList(),
    attachments:
        attachments ??
        (j['attachments'] as List? ?? [])
            .map(
              (a) => JournalAttachment.fromJson(Map<String, dynamic>.from(a)),
            )
            .toList(),
    checklist: (j['checklist'] as List? ?? [])
        .map((c) => ChecklistItem.fromJson(Map<String, dynamic>.from(c)))
        .toList(),
    tags: List<String>.from(j['tags'] as List? ?? []),
    isFavorite: j['isFavorite'] as bool? ?? false,
    createdAt: j['createdAt'] == null
        ? null
        : DateTime.parse(j['createdAt'] as String),
    collectionId: j['collectionId'] as String?,
    promptId: j['promptId'] as String?,
    promptText: j['promptText'] as String?,
    kind: EntryKind.values.byName(j['kind'] as String? ?? 'text'),
    energy: j['energy'] as String?,
  );
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Mood mood;
  final List<TextFormatRun> formatting;
  final List<JournalAttachment> attachments;
  final List<ChecklistItem> checklist;
  final List<String> tags;
  final bool isFavorite;
  final DateTime? createdAt;
  final String? collectionId, promptId, promptText, energy;
  final EntryKind kind;
  JournalEntry copyWith({bool? isFavorite, List<ChecklistItem>? checklist}) =>
      JournalEntry(
        id: id,
        createdAt: createdAt,
        collectionId: collectionId,
        promptId: promptId,
        promptText: promptText,
        kind: kind,
        energy: energy,
        title: title,
        content: content,
        date: date,
        mood: mood,
        formatting: formatting,
        attachments: attachments,
        tags: tags,
        isFavorite: isFavorite ?? this.isFavorite,
        checklist: List.unmodifiable(checklist ?? this.checklist),
      );
}

final List<JournalEntry> sampleEntries = [
  JournalEntry(
    id: 'sample-1',
    title: 'A productive day',
    content: 'Today I made steady progress and learned a lot.',
    date: DateTime(2025, 9, 30),
    mood: Mood.great,
  ),
  JournalEntry(
    id: 'sample-2',
    title: 'Small steps',
    content: 'It is okay to take things one step at a time.',
    date: DateTime(2025, 9, 29),
    mood: Mood.good,
  ),
];

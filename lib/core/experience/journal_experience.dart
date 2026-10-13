import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_task.dart';
import '../utils/journal_streak.dart';
import '../utils/journal_format.dart';

enum JournalViewMode { list, card, grid }

enum PaperStyle { clean, paper, softLines, dotGrid }

enum WritingStyle { modern, editorial, classicSerif }

class JournalPreferences {
  const JournalPreferences({
    this.paper = PaperStyle.clean,
    this.writing = WritingStyle.modern,
    this.textSize = 18,
    this.wordCount = true,
    this.haptics = true,
    this.collectionId,
  });
  Map<String, dynamic> toJson() => {
    'paper': paper.name,
    'writing': writing.name,
    'textSize': textSize,
    'wordCount': wordCount,
    'haptics': haptics,
    'collectionId': collectionId,
  };
  factory JournalPreferences.fromJson(Map<String, dynamic> j) =>
      JournalPreferences(
        paper: PaperStyle.values.byName(j['paper'] as String? ?? 'clean'),
        writing: WritingStyle.values.byName(
          j['writing'] as String? ?? 'modern',
        ),
        textSize: (j['textSize'] as num? ?? 18).toDouble().clamp(16, 26),
        wordCount: j['wordCount'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        collectionId: j['collectionId'] as String?,
      );
  final PaperStyle paper;
  final WritingStyle writing;
  final double textSize;
  final bool wordCount, haptics;
  final String? collectionId;
  TextStyle bodyStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: textSize,
        height: writing == WritingStyle.editorial ? 1.85 : 1.6,
        fontFamily: writing == WritingStyle.classicSerif ? 'Georgia' : null,
      );
}

class JournalCollection {
  const JournalCollection(this.id, this.name, this.icon, this.accent);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'accent': accent.toARGB32(),
  };
  factory JournalCollection.fromJson(Map<String, dynamic> j) =>
      JournalCollection(
        j['id'] as String,
        j['name'] as String,
        journalCollections.where((c) => c.id == j['id']).firstOrNull?.icon ??
            Icons.folder_outlined,
        Color(j['accent'] as int),
      );
  final String id, name;
  final IconData icon;
  final Color accent;
}

const journalCollections = [
  JournalCollection(
    'personal',
    'Personal',
    Icons.person_outline,
    Colors.indigo,
  ),
  JournalCollection('college', 'College', Icons.school_outlined, Colors.blue),
  JournalCollection('ideas', 'Ideas', Icons.lightbulb_outline, Colors.amber),
  JournalCollection(
    'memories',
    'Memories',
    Icons.photo_outlined,
    Colors.purple,
  ),
  JournalCollection('goals', 'Goals', Icons.flag_outlined, Colors.teal),
];
String collectionName(String? id) =>
    journalCollections.where((c) => c.id == id).firstOrNull?.name ?? 'General';

class ReflectionPrompt {
  const ReflectionPrompt(this.id, this.pack, this.text);
  final String id, pack, text;
}

const promptPacks = <String, List<String>>{
  'Daily Reflection': [
    'What part of today do you want to remember?',
    'What surprised you today?',
    'Where did you find a moment of calm?',
    'What would you tell yourself about today?',
  ],
  'Gratitude': [
    'What ordinary thing felt especially good today?',
    'Who made your day a little easier?',
    'What small comfort are you grateful for?',
    'What did you appreciate about yourself today?',
  ],
  'Growth': [
    'What did you understand today that you did not understand before?',
    'What small step moved you forward?',
    'What mistake taught you something useful?',
    'What are you learning to accept?',
  ],
  'Relationships': [
    'When did you feel understood recently?',
    'Who would you like to reconnect with?',
    'What conversation stayed with you?',
    'How did you show care today?',
  ],
  'Goals': [
    'What is one small next step you can take?',
    'Which goal still feels meaningful?',
    'What can you let go of to make room?',
    'What would progress look like this week?',
  ],
  'Creativity': [
    'What idea would you explore without judgment?',
    'What caught your eye today?',
    'What would you make just for the joy of it?',
    'Describe today using a color and a sound.',
  ],
  'Memories': [
    'Which ordinary moment would you like to keep?',
    'What place brings back a clear memory?',
    'What detail of a happy day do you remember?',
    'What would you put in a time capsule today?',
  ],
  'Hard Days': [
    'What felt heavy today?',
    'What helped you get through a difficult moment?',
    'What do you need to hear right now?',
    'What is one gentle thing you can do for yourself?',
  ],
  'Self Discovery': [
    'When do you feel most like yourself?',
    'What value guided a choice today?',
    'What have you changed your mind about?',
    'What would you like to make more space for?',
  ],
};
final reflectionPrompts = [
  for (final pack in promptPacks.entries)
    for (var i = 0; i < pack.value.length; i++)
      ReflectionPrompt('${pack.key}-$i', pack.key, pack.value[i]),
];

class EntryTemplate {
  const EntryTemplate(this.name, this.sections);
  final String name;
  final List<String> sections;
  String get content => sections.map((s) => '$s\n\n').join('\n');
}

const entryTemplates = [
  EntryTemplate('Blank Page', []),
  EntryTemplate('Daily Reflection', [
    'What went well?',
    'What felt difficult?',
    'What do I want to remember?',
  ]),
  EntryTemplate('Morning Check-In', [
    'How am I feeling?',
    'What matters today?',
    'One small intention',
  ]),
  EntryTemplate('Evening Reflection', [
    'What went well?',
    'What felt difficult?',
    'What am I grateful for?',
    'One thing for tomorrow',
  ]),
  EntryTemplate('Gratitude', [
    'Three things I appreciate',
    'Someone I am thankful for',
    'A small joy',
  ]),
  EntryTemplate('Weekly Review', [
    "This week’s highlight",
    'Something I learned',
    'Something difficult',
    "Something I’m proud of",
    "Next week’s focus",
  ]),
  EntryTemplate('Goals', [
    'What I want to work toward',
    'Why it matters',
    'My next small step',
  ]),
  EntryTemplate('Memory', [
    'The moment',
    'The details I want to keep',
    'Why it matters to me',
  ]),
  EntryTemplate('Dream Journal', [
    'What I remember',
    'People and places',
    'How it felt',
  ]),
];

class JournalExperience extends ChangeNotifier {
  Mood? checkIn;
  void setCheckIn(Mood? mood) {
    checkIn = mood;
    notifyListeners();
  }

  JournalViewMode viewMode = JournalViewMode.card;
  final List<JournalTask> _tasks = [];
  List<JournalTask> get tasks => List.unmodifiable(_tasks);
  void setViewMode(JournalViewMode value) {
    if (viewMode == value) return;
    viewMode = value;
    notifyListeners();
  }

  void saveTask(JournalTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index < 0) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void reset() {
    _tasks.clear();
    checkIn = null;
    preferences = const JournalPreferences();
    viewMode = JournalViewMode.card;
    favoritePrompts.clear();
    usedPrompts.clear();
    recentSearches.clear();
    notifyListeners();
  }

  JournalPreferences preferences = const JournalPreferences();
  final Set<String> favoritePrompts = {}, usedPrompts = {};
  final List<String> recentSearches = [];
  Map<String, dynamic> toJson() => {
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'collections': journalCollections.map((c) => c.toJson()).toList(),
    'favoritePrompts': favoritePrompts.toList(),
    'usedPrompts': usedPrompts.toList(),
    'recentSearches': recentSearches,
    'checkIn': checkIn?.name,
  };
  void restore(Map<String, dynamic> data, Map<String, dynamic> settings) {
    _tasks
      ..clear()
      ..addAll(
        (data['tasks'] as List? ?? []).map(
          (t) => JournalTask.fromJson(Map<String, dynamic>.from(t)),
        ),
      );
    favoritePrompts
      ..clear()
      ..addAll(List<String>.from(data['favoritePrompts'] as List? ?? []));
    usedPrompts
      ..clear()
      ..addAll(List<String>.from(data['usedPrompts'] as List? ?? []));
    recentSearches
      ..clear()
      ..addAll(List<String>.from(data['recentSearches'] as List? ?? []));
    checkIn = data['checkIn'] == null
        ? null
        : Mood.values.byName(data['checkIn'] as String);
    preferences = JournalPreferences.fromJson(
      Map<String, dynamic>.from(settings['preferences'] ?? {}),
    );
    viewMode = JournalViewMode.values.byName(
      settings['viewMode'] as String? ?? 'card',
    );
  }

  void togglePrompt(String id) {
    if (!favoritePrompts.remove(id)) favoritePrompts.add(id);
    notifyListeners();
  }

  void usePrompt(String? id) {
    if (id != null && usedPrompts.add(id)) notifyListeners();
  }

  void update(JournalPreferences value) {
    preferences = value;
    notifyListeners();
  }

  void rememberSearch(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    recentSearches.remove(value);
    recentSearches.insert(0, value);
    if (recentSearches.length > 5) recentSearches.removeLast();
    notifyListeners();
  }
}

class ExperienceScope extends InheritedNotifier<JournalExperience> {
  const ExperienceScope({
    super.key,
    required JournalExperience experience,
    required super.child,
  }) : super(notifier: experience);
  static JournalExperience? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExperienceScope>()?.notifier;
  static JournalPreferences preferencesOf(BuildContext context) =>
      maybeOf(context)?.preferences ?? const JournalPreferences();
}

void journalHaptic(BuildContext context, {bool medium = false}) {
  if (ExperienceScope.preferencesOf(context).haptics) {
    if (medium) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }
}

List<JournalEntry> todayEntries(List<JournalEntry> entries, {DateTime? now}) =>
    sortedEntries(
      entries
          .where((e) => journalDay(e.date) == journalDay(now ?? DateTime.now()))
          .toList(),
    );
JournalEntry? resurfacedMemory(List<JournalEntry> entries, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final earlier = sortedEntries(
    entries.where((e) => journalDay(e.date) < journalDay(today)).toList(),
  );
  if (earlier.isEmpty) return null;
  final anniversary = earlier
      .where((e) => e.date.month == today.month && e.date.day == today.day)
      .firstOrNull;
  return anniversary ?? earlier.first;
}

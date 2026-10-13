import '../../models/journal_entry.dart';
import 'journal_format.dart';
import '../experience/journal_experience.dart';

class JournalFilter {
  const JournalFilter({
    this.mood,
    this.favorites = false,
    this.photo = false,
    this.drawing = false,
    this.checklist = false,
    this.tag,
    this.tags = const [],
    this.collectionId,
  });
  final Mood? mood;
  final bool favorites, photo, drawing, checklist;
  final String? tag, collectionId;
  final List<String> tags;
  bool get active =>
      mood != null ||
      favorites ||
      photo ||
      drawing ||
      checklist ||
      tag != null ||
      tags.isNotEmpty ||
      collectionId != null;
  bool matches(JournalEntry entry) =>
      (mood == null || entry.mood == mood) &&
      (!favorites || entry.isFavorite) &&
      (!photo || entry.attachments.any((a) => !a.isDrawing)) &&
      (!drawing || entry.attachments.any((a) => a.isDrawing)) &&
      (!checklist || entry.checklist.isNotEmpty) &&
      (collectionId == null ||
          (entry.collectionId ?? 'general') == collectionId) &&
      tags.every(
        (tag) => entry.tags.any(
          (t) =>
              t.toLowerCase().replaceFirst('#', '') ==
              tag.toLowerCase().replaceFirst('#', ''),
        ),
      ) &&
      (tag == null ||
          entry.tags.any((t) => t.toLowerCase() == tag!.toLowerCase()));
}

List<JournalEntry> searchJournal(
  List<JournalEntry> entries,
  String query,
  JournalFilter filter,
) {
  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  return sortedEntries(
    entries.where((entry) {
      final text =
          '${collectionName(entry.collectionId)} ${entry.promptText ?? ''} ${entry.title} ${readableJournalText(entry.content)} ${entry.tags.join(' ')} ${entry.checklist.map((c) => c.text).join(' ')}'
              .toLowerCase();
      return filter.matches(entry) && words.every(text.contains);
    }).toList(),
  );
}

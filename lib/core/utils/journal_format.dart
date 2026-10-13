import '../../models/journal_entry.dart';

String readableJournalText(String text) => text.replaceAll(
  RegExp(
    r'^[ \t]*(?:•(?:[ \t]+|$)|\d+\.(?:[ \t]+|$)|>(?:[ \t]+|$))',
    multiLine: true,
  ),
  '',
);
int wordCount(String text) =>
    RegExp(r'\S+').allMatches(readableJournalText(text)).length;

int entryWordCount(JournalEntry entry) =>
    wordCount(entry.content) +
    entry.checklist.fold<int>(0, (sum, item) => sum + wordCount(item.text));

String formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String monthLabel(DateTime date) {
  final parts = formatDate(date).split(' ');
  return '${parts.first} ${date.year}';
}

List<JournalEntry> sortedEntries(List<JournalEntry> entries) =>
    [...entries]..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate == 0 ? b.id.compareTo(a.id) : byDate;
    });

JournalEntry? entryWithId(List<JournalEntry> entries, String id) {
  for (final entry in entries) {
    if (entry.id == id) return entry;
  }
  return null;
}

import '../../models/journal_entry.dart';

/// Civil dates, not elapsed 24-hour periods: this is safe across DST changes.
int journalDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
DateTime dayFromKey(int key) {
  final utc = DateTime.fromMillisecondsSinceEpoch(
    key * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return DateTime(utc.year, utc.month, utc.day);
}

class JournalRhythm {
  const JournalRhythm({
    required this.days,
    required this.today,
    required this.current,
    required this.longest,
    required this.thisWeek,
    required this.thisMonth,
  });
  final Set<int> days;
  final DateTime today;
  final int current, longest, thisWeek, thisMonth;
}

class JournalStreakCalculator {
  static JournalRhythm calculate(List<JournalEntry> entries, {DateTime? now}) {
    final date = now ?? DateTime.now();
    final today = DateTime(date.year, date.month, date.day);
    final todayKey = journalDay(today);
    final days = entries
        .map((e) => journalDay(e.date))
        .where((d) => d <= todayKey)
        .toSet();
    var end = days.contains(todayKey) ? todayKey : todayKey - 1;
    var current = 0;
    while (days.contains(end)) {
      current++;
      end--;
    }
    final ordered = days.toList()..sort();
    var longest = 0, run = 0;
    int? previous;
    for (final day in ordered) {
      run = previous == day - 1 ? run + 1 : 1;
      if (run > longest) longest = run;
      previous = day;
    }
    final weekStart = todayKey - (today.weekday - 1);
    return JournalRhythm(
      days: Set.unmodifiable(days),
      today: today,
      current: current,
      longest: longest,
      thisWeek: days.where((d) => d >= weekStart && d < weekStart + 7).length,
      thisMonth: days.where((d) {
        final date = dayFromKey(d);
        return date.year == today.year && date.month == today.month;
      }).length,
    );
  }

  static int writingDaysForMonth(
    List<JournalEntry> entries,
    DateTime month, {
    DateTime? now,
  }) => calculate(entries, now: now).days.where((d) {
    final date = dayFromKey(d);
    return date.year == month.year && date.month == month.month;
  }).length;
}

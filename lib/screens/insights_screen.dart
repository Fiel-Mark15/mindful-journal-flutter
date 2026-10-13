import 'package:flutter/material.dart';
import '../widgets/reflection_rings.dart';
import '../models/journal_entry.dart';
import '../core/utils/journal_format.dart';
import '../core/utils/journal_streak.dart';
import '../widgets/journal_components.dart';
import '../widgets/writing_rhythm.dart';
import 'calendar_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.entries});
  final List<JournalEntry> entries;
  @override
  Widget build(BuildContext context) {
    final rhythm = JournalStreakCalculator.calculate(entries);
    final counts = <Mood, int>{
      for (final mood in Mood.values)
        mood: entries.where((e) => e.mood == mood).length,
    };
    final most = Mood.values.where((m) => counts[m]! > 0).toList()
      ..sort((a, b) {
        final comparison = counts[b]!.compareTo(counts[a]!);
        return comparison == 0 ? a.index.compareTo(b.index) : comparison;
      });
    final words = entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          wordCount(e.content) +
          e.checklist.fold<int>(0, (sum, c) => sum + wordCount(c.text)),
    );
    final tags = <String, int>{};
    for (final entry in entries) {
      for (final tag
          in entry.tags
              .map((t) => t.toLowerCase().replaceFirst('#', ''))
              .toSet()) {
        tags.update(tag, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final rankedTags = tags.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count == 0 ? a.key.compareTo(b.key) : count;
      });
    final longest = [...entries]
      ..sort((a, b) => entryWordCount(b).compareTo(entryWordCount(a)));
    final checkIns = entries
        .where(
          (e) =>
              e.kind == EntryKind.quickCheckIn &&
              (e.mood == Mood.great || e.mood == Mood.good),
        )
        .toList();
    final activities = <String, int>{};
    for (final e in checkIns) {
      for (final t in e.tags.toSet()) {
        activities.update(t, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final commonActivities = activities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Your reflection')),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            ReflectionRings(entries: entries),
            const SizedBox(height: 28),
            RhythmSummary(rhythm: rhythm, monthDays: rhythm.thisMonth),
            const SizedBox(height: 28),
            Text(
              'Writing rhythm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            WritingRhythm(rhythm: rhythm),
            const SizedBox(height: 12),
            Text("You've written ${rhythm.thisWeek} days this week."),
            const SizedBox(height: 28),
            Text('Mood balance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final mood in Mood.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${moodInfo[mood]!.label} · ${counts[mood]} ${counts[mood] == 1 ? 'entry' : 'entries'}',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: entries.isEmpty
                          ? 0
                          : counts[mood]! / entries.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Most common mood: ${most.isEmpty ? 'None yet' : moodInfo[most.first]!.label}',
            ),
            Text('${entries.length} entries · $words words'),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notes),
                  title: Text(
                    '${(words / entries.length).toStringAsFixed(1)} words per entry',
                  ),
                  subtitle: Text(
                    'Longest reflection: ${longest.first.title} · ${entryWordCount(longest.first)} words',
                  ),
                ),
              ),
            ],
            if (rankedTags.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tag),
                  title: const Text('Most used tags'),
                  subtitle: Text(
                    rankedTags
                        .take(3)
                        .map((t) => '#${t.key} · ${t.value} entries')
                        .join('\n'),
                  ),
                ),
              ),
            if (checkIns.length >= 3 &&
                commonActivities.isNotEmpty &&
                commonActivities.first.value >= 2)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('In your Great / Good check-ins'),
                  subtitle: Text(
                    '${commonActivities.first.key} appeared in ${commonActivities.first.value} of ${checkIns.length} check-ins. This describes saved tags, not a cause of mood.',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Only saved entries in this session count, including remaining starting examples. A writing day counts once. Current streak includes yesterday until today ends. Weeks start on Monday. Future dates are excluded from writing-day statistics.',
            ),
          ],
        ),
      ),
    );
  }
}

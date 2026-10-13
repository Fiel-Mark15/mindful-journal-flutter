import 'package:flutter/material.dart';
import '../core/utils/journal_streak.dart';
import '../core/utils/journal_format.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_components.dart';
import '../widgets/month_calendar.dart';
import '../widgets/writing_rhythm.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onCreate,
    this.embedded = true,
    this.rhythmDetails = false,
  });
  final List<JournalEntry> entries;
  final Future<void> Function(JournalEntry) onOpen;
  final Future<void> Function(DateTime) onCreate;
  final bool embedded, rhythmDetails;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selected, _month;
  bool _moodMode = false;
  Future<void> _dateSheet(DateTime date) async {
    setState(() => _selected = date);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheet) {
        final records = sortedEntries(
          widget.entries
              .where((e) => journalDay(e.date) == journalDay(date))
              .toList(),
        );
        final moods = records
            .map((e) => moodInfo[e.mood]!.label)
            .toSet()
            .join(', ');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(date),
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              Text(
                '${records.length} entries${moods.isEmpty ? "" : " · $moods"}',
              ),
              const SizedBox(height: 16),
              if (records.isEmpty) const Text('No reflection yet.'),
              for (final entry in records)
                EntryCard(
                  entry: entry,
                  onTap: () {
                    Navigator.pop(sheet);
                    _open(entry);
                  },
                ),
              if (journalDay(date) <= journalDay(DateTime.now()))
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _create();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Write for this day'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _move(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    _selected = DateTime(
      _month.year,
      _month.month,
      _selected.day.clamp(1, DateTime(_month.year, _month.month + 1, 0).day),
    );
  });
  Future<void> _open(JournalEntry entry) async {
    await widget.onOpen(entry);
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    await widget.onCreate(_selected);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rhythm = JournalStreakCalculator.calculate(widget.entries);
    final records = sortedEntries(
      widget.entries
          .where((e) => journalDay(e.date) == journalDay(_selected))
          .toList(),
    );
    final monthDays = JournalStreakCalculator.writingDaysForMonth(
      widget.entries,
      _month,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(widget.rhythmDetails ? 'Your rhythm' : 'Calendar'),
      ),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Entries'),
                  selected: !_moodMode,
                  onSelected: (_) => setState(() => _moodMode = false),
                ),
                ChoiceChip(
                  label: const Text('Mood'),
                  selected: _moodMode,
                  onSelected: (_) => setState(() => _moodMode = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RhythmSummary(rhythm: rhythm, monthDays: monthDays),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MonthCalendar(
              month: _month,
              selected: _selected,
              entries: widget.entries,
              moodMode: _moodMode,
              onSelected: _dateSheet,
            ),
            const SizedBox(height: 24),
            Text(
              formatDate(_selected),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${records.length} ${records.length == 1 ? 'entry' : 'entries'}',
            ),
            if (records.isEmpty) ...[
              const SizedBox(height: 16),
              const Text('No reflection yet.'),
              if (journalDay(_selected) <= journalDay(DateTime.now()))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Write for this day'),
                  ),
                )
              else
                const Text('You can write for this day when it arrives.'),
            ],
            ...records.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EntryCard(entry: entry, onTap: () => _open(entry)),
              ),
            ),
            if (widget.rhythmDetails) ...[
              const SizedBox(height: 24),
              Text(
                'Writing rhythm',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              WritingRhythm(rhythm: rhythm),
              const SizedBox(height: 24),
              for (final milestone in [
                7,
                14,
                30,
                50,
                100,
              ].where((m) => m <= rhythm.longest))
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text('$milestone day milestone'),
                  subtitle: const Text('Reached in this session’s entries.'),
                ),
              if (rhythm.longest < 7)
                const Text(
                  'Every reflection counts. Your first week will appear here when reached.',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class RhythmSummary extends StatelessWidget {
  const RhythmSummary({
    super.key,
    required this.rhythm,
    required this.monthDays,
  });
  final JournalRhythm rhythm;
  final int monthDays;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 24,
    runSpacing: 12,
    children: [
      for (final stat in [
        (rhythm.current, 'Current streak'),
        (rhythm.longest, 'Longest streak'),
        (monthDays, 'Writing days this month'),
      ])
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${stat.$1} ${stat.$1 == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(stat.$2),
          ],
        ),
    ],
  );
}

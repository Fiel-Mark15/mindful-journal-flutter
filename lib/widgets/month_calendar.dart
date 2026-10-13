import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/utils/journal_streak.dart';
import '../core/utils/journal_format.dart';
import '../models/journal_entry.dart';
import 'mood_symbol.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.entries,
    this.onSelected,
    this.now,
    this.moodMode = true,
  });
  final bool moodMode;
  final DateTime month, selected;
  final DateTime? now;
  final List<JournalEntry> entries;
  final ValueChanged<DateTime>? onSelected;
  @override
  Widget build(BuildContext context) {
    final groups = <int, List<JournalEntry>>{};
    for (final entry in sortedEntries(entries)) {
      groups.putIfAbsent(journalDay(entry.date), () => []).add(entry);
    }
    for (final records in groups.values) {
      records.sort((a, b) {
        final comparison = (b.createdAt ?? b.date).compareTo(
          a.createdAt ?? a.date,
        );
        return comparison == 0 ? b.id.compareTo(a.id) : comparison;
      });
    }
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final today = journalDay(now ?? DateTime.now());
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / 7;
        final height = math.max(
          54.0,
          MediaQuery.textScalerOf(context).scale(14) * 1.6 + 28,
        );
        return Column(
          children: [
            Row(
              children: [
                for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (
                  var index = 0;
                  index < ((offset + count + 6) ~/ 7) * 7;
                  index++
                )
                  if (index < offset || index >= offset + count)
                    SizedBox(width: width, height: height)
                  else
                    Builder(
                      builder: (context) {
                        final date = DateTime(
                          month.year,
                          month.month,
                          index - offset + 1,
                        );
                        final key = journalDay(date),
                            records = groups[journalDay(date)] ?? [];
                        final chosen = key == journalDay(selected),
                            isToday = key == today;
                        final left =
                            records.isNotEmpty &&
                            index % 7 != 0 &&
                            groups.containsKey(key - 1);
                        final right =
                            records.isNotEmpty &&
                            index % 7 != 6 &&
                            groups.containsKey(key + 1);
                        return Semantics(
                          label:
                              '${formatDate(date)}, ${records.length} ${records.length == 1 ? 'journal entry' : 'journal entries'}${records.isEmpty ? '' : ', mood ${moodInfo[records.first.mood]!.label}'}${isToday ? ', today' : ''}',
                          selected: chosen,
                          button: onSelected != null,
                          child: ExcludeSemantics(
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Material(
                                  color: chosen
                                      ? theme.colorScheme.primaryContainer
                                      : records.isNotEmpty
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: .08,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(
                                      left && !chosen ? 0 : 12,
                                    ),
                                    right: Radius.circular(
                                      right && !chosen ? 0 : 12,
                                    ),
                                  ),
                                  child: InkWell(
                                    key: ValueKey('calendar-day-$key'),
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: onSelected == null
                                        ? null
                                        : () => onSelected!(date),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: isToday
                                            ? Border.all(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 1.5,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: chosen
                                                  ? theme
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: chosen || isToday
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (records.isNotEmpty && !moodMode)
                                            Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: theme.colorScheme.primary,
                                            )
                                          else if (records.isNotEmpty)
                                            MoodSymbol(
                                              mood: records.first.mood,
                                              size: 14,
                                              color: chosen
                                                  ? theme
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : theme.colorScheme.primary,
                                            )
                                          else
                                            const SizedBox(height: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';

import '../core/theme/app_theme.dart';
import '../models/journal_entry.dart';
import 'mood_symbol.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key, required this.value, required this.onChanged});
  final Mood? value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: Mood.values.map((mood) {
      final info = moodInfo[mood]!;
      final selected = value == mood;
      final scheme = Theme.of(context).colorScheme;
      return Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: AppMotion.duration(context),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
          child: TextButton(
            key: ValueKey('mood-${mood.name}'),
            style: TextButton.styleFrom(
              foregroundColor: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onPressed: () {
              journalHaptic(context);
              onChanged(mood);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: MoodSymbol(
                    mood: mood,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(info.label),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}

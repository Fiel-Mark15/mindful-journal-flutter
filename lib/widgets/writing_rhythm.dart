import 'package:flutter/material.dart';
import '../core/utils/journal_streak.dart';
import '../core/theme/app_theme.dart';

class WritingRhythm extends StatelessWidget {
  const WritingRhythm({super.key, required this.rhythm});
  final JournalRhythm rhythm;
  @override
  Widget build(BuildContext context) {
    final today = journalDay(rhythm.today);
    final start = today - rhythm.today.weekday + 1;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Semantics(
              label:
                  '${dayFromKey(start + i).month}/${dayFromKey(start + i).day}, ${rhythm.days.contains(start + i) ? 'written' : 'no reflection'}${start + i == today ? ', today' : ''}',
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
                    const SizedBox(height: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rhythm.days.contains(start + i)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          width: start + i == today ? 2 : 1,
                          color: start + i == today
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: rhythm.days.contains(start + i)
                          ? Icon(
                              Icons.check,
                              size: 15,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : start + i == today
                          ? Icon(
                              Icons.circle,
                              size: 6,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.rhythm,
    required this.onTap,
    this.celebration = 0,
  });
  final JournalRhythm rhythm;
  final VoidCallback onTap;
  final int celebration;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Current journaling streak, ${rhythm.current} days',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(celebration),
          tween: Tween(
            begin: celebration == 0 || MediaQuery.disableAnimationsOf(context)
                ? 0
                : 1,
            end: 0,
          ),
          duration: const Duration(milliseconds: 700),
          builder: (context, pulse, child) => Container(
            color: Theme.of(context).colorScheme.primary.withValues(
              alpha:
                  pulse *
                  ([7, 14, 30, 50, 100].contains(rhythm.current) ? .18 : .12),
            ),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.duration(context),
                      child: Text(
                        '${rhythm.current} day reflection streak',
                        key: ValueKey(rhythm.current),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              WritingRhythm(rhythm: rhythm),
              const SizedBox(height: 12),
              Text(
                "You've written ${rhythm.thisWeek} ${rhythm.thisWeek == 1 ? 'day' : 'days'} this week.",
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

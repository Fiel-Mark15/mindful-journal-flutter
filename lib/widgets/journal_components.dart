import 'package:flutter/cupertino.dart';
import '../core/experience/journal_experience.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/journal_format.dart';
import '../models/journal_entry.dart';
import 'mood_symbol.dart';

class JournalCanvas extends StatelessWidget {
  const JournalCanvas({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
      child: child,
    ),
  );
}

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.query = '',
    this.onFavorite,
  });
  final JournalEntry entry;
  final VoidCallback onTap;
  final String query;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = moodInfo[entry.mood]!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDate(entry.date),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      tooltip: entry.isFavorite
                          ? 'Remove favorite'
                          : 'Add favorite',
                      isSelected: entry.isFavorite,
                      onPressed: onFavorite,
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                      ),
                    )
                  else if (entry.isFavorite)
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      semanticLabel: 'Favorite entry',
                    ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Mood: ${mood.label}',
                    child: ExcludeSemantics(
                      child: MoodSymbol(
                        mood: entry.mood,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                highlightJournalText(
                  entry.title,
                  query,
                  theme.colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text.rich(
                highlightJournalText(
                  entry.content,
                  query,
                  theme.colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (entry.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      entry.attachments.first.bytes,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (entry.tags.isNotEmpty ||
                  entry.collectionId != null ||
                  entry.kind != EntryKind.text)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (entry.collectionId != null)
                        Text(
                          collectionName(entry.collectionId),
                          style: theme.textTheme.labelSmall,
                        ),
                      if (entry.kind != EntryKind.text)
                        Text(switch (entry.kind) {
                          EntryKind.photoMemory => 'Photo memory',
                          EntryKind.drawing => 'Drawing',
                          EntryKind.checklist => 'Checklist',
                          EntryKind.promptReflection => 'Prompt reflection',
                          EntryKind.quickCheckIn => 'Check-in',
                          EntryKind.text => '',
                        }, style: theme.textTheme.labelSmall),
                      for (final tag in entry.tags.take(2))
                        Text(
                          '#${tag.replaceFirst('#', '')}',
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entryWordCount(entry)} words · ${mood.label}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JournalEmptyState extends StatelessWidget {
  const JournalEmptyState({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(
          CupertinoIcons.book,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Your journal is waiting.',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'A thought, a memory, a small moment.\nMake a little space for yourself.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onCreate,
          child: const Text('Create first entry'),
        ),
      ],
    ),
  );
}

TextSpan highlightJournalText(String text, String query, Color accent) {
  final terms = query
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map(RegExp.escape)
      .toList();
  if (terms.isEmpty) return TextSpan(text: text);
  final matches = RegExp(
    terms.join('|'),
    caseSensitive: false,
  ).allMatches(text);
  final spans = <TextSpan>[];
  var offset = 0;
  for (final match in matches) {
    if (match.start > offset) {
      spans.add(TextSpan(text: text.substring(offset, match.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: accent.withValues(alpha: .08),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    offset = match.end;
  }
  spans.add(TextSpan(text: text.substring(offset)));
  return TextSpan(children: spans);
}

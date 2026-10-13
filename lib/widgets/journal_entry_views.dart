import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../core/experience/journal_experience.dart';
import '../core/utils/journal_format.dart';
import 'journal_components.dart';
import 'mood_symbol.dart';

class CompactEntryTile extends StatelessWidget {
  const CompactEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onFavorite,
    this.query = '',
  });
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final String query;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 12),
                  child: Semantics(
                    label: 'Mood: ${moodInfo[entry.mood]!.label}',
                    child: MoodSymbol(
                      mood: entry.mood,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(entry.date),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
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
                      Text.rich(
                        highlightJournalText(
                          readableJournalText(entry.content),
                          query,
                          theme.colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.tags.isNotEmpty || entry.collectionId != null)
                        Text(
                          [
                            if (entry.collectionId != null)
                              collectionName(entry.collectionId),
                            ...entry.tags
                                .take(2)
                                .map((t) => '#${t.replaceFirst('#', '')}'),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
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
                      entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                  )
                else if (entry.isFavorite)
                  const Icon(
                    Icons.favorite,
                    size: 16,
                    semanticLabel: 'Favorite entry',
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class GridEntryCard extends StatelessWidget {
  const GridEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onFavorite,
    this.query = '',
  });
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final String query;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        color = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: entry.attachments.isNotEmpty
                  ? Image.memory(
                      entry.attachments.first.bytes,
                      fit: BoxFit.cover,
                      semanticLabel: entry.attachments.first.isDrawing
                          ? 'Drawing preview'
                          : 'Photo memory',
                      errorBuilder: (_, _, _) => Center(
                        child: MoodSymbol(
                          mood: entry.mood,
                          size: 32,
                          color: color,
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: .035),
                            color.withValues(
                              alpha: .13 + entry.mood.index * .015,
                            ),
                          ],
                        ),
                      ),
                      child: Center(
                        child: MoodSymbol(
                          mood: entry.mood,
                          size: 32,
                          color: color,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      highlightJournalText(entry.title, query, color),
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(entry.date),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            moodInfo[entry.mood]!.label,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onFavorite != null)
                          IconButton(
                            padding: EdgeInsets.zero,
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

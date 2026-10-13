import 'package:flutter/cupertino.dart';
import '../core/experience/journal_experience.dart';
import 'package:flutter/material.dart';

import '../core/utils/journal_format.dart';
import '../core/editing/journal_text_controller.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_components.dart';
import '../widgets/mood_symbol.dart';
import '../widgets/attachment_gallery.dart';
import '../widgets/journal_checklist.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.id,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
    this.onChanged,
    this.embedded = false,
    this.onClosed,
  });
  final bool embedded;
  final VoidCallback? onClosed;
  final String id;
  final List<JournalEntry> entries;
  final Future<void> Function(JournalEntry) onEdit;
  final ValueChanged<String> onDelete;
  final ValueChanged<JournalEntry>? onChanged;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _deleting = false, _showActions = false;

  Future<void> _edit(JournalEntry entry) async {
    await widget.onEdit(entry);
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    if (_deleting) return;
    _deleting = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text(
          'This entry will be removed from the current session. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _deleting = false;
    if (confirmed == true) {
      journalHaptic(context);
      widget.onDelete(widget.id);
      if (widget.embedded) {
        widget.onClosed?.call();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = entryWithId(widget.entries, widget.id);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Your entry'),
        actions: [
          if (entry != null && widget.onChanged != null)
            AnimatedScale(
              scale: entry.isFavorite ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              child: IconButton(
                tooltip: entry.isFavorite ? 'Remove favorite' : 'Add favorite',
                isSelected: entry.isFavorite,
                onPressed: () {
                  journalHaptic(context, medium: true);
                  widget.onChanged!(
                    entry.copyWith(isFavorite: !entry.isFavorite),
                  );
                  setState(() {});
                },
                icon: Icon(
                  entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: entry.isFavorite ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          if (entry != null)
            IconButton(
              tooltip: 'Entry actions',
              isSelected: _showActions,
              onPressed: () => setState(() => _showActions = !_showActions),
              icon: const Icon(Icons.more_horiz),
            ),
          if (entry != null && _showActions)
            IconButton(
              tooltip: 'Edit entry',
              onPressed: () => _edit(entry),
              icon: const Icon(CupertinoIcons.pencil),
            ),
          if (entry != null && _showActions)
            IconButton(
              tooltip: 'Delete entry',
              onPressed: _delete,
              icon: const Icon(CupertinoIcons.trash),
            ),
        ],
      ),
      body: JournalCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: entry == null
              ? [const Text('This entry is no longer available.')]
              : [
                  Text(
                    formatDate(entry.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: MoodSymbol(
                          mood: entry.mood,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        moodInfo[entry.mood]!.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (entry.collectionId != null || entry.energy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '${collectionName(entry.collectionId)}${entry.energy == null ? '' : ' · ${entry.energy} energy'}',
                      ),
                    ),
                  const SizedBox(height: 24),
                  SelectableText(
                    entry.title,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  SelectableText.rich(
                    attributedSpan(
                      entry.content,
                      entry.formatting,
                      ExperienceScope.preferencesOf(context).bodyStyle(context),
                      background: theme.scaffoldBackgroundColor,
                    ),
                  ),
                  if (entry.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ),
                  if (entry.checklist.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ChecklistBlock(items: entry.checklist),
                  ],
                  if (entry.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    AttachmentGallery(attachments: entry.attachments),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    '${entryWordCount(entry)} words · In this session',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
        ),
      ),
    );
  }
}

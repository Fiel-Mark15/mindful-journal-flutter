import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../widgets/journal_components.dart';

class InspirationChoice {
  const InspirationChoice({this.prompt, this.template});
  final ReflectionPrompt? prompt;
  final EntryTemplate? template;
}

class InspirationScreen extends StatefulWidget {
  const InspirationScreen({
    super.key,
    required this.experience,
    this.templates = false,
  });
  final JournalExperience experience;
  final bool templates;
  @override
  State<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends State<InspirationScreen> {
  String? _pack;
  bool _favorites = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.experience,
    builder: (context, _) {
      final prompts = reflectionPrompts
          .where(
            (p) =>
                (_pack == null || p.pack == _pack) &&
                (!_favorites ||
                    widget.experience.favoritePrompts.contains(p.id)),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.templates ? 'Templates' : _pack ?? 'Prompt Packs'),
          actions: [
            if (!widget.templates)
              IconButton(
                tooltip: _favorites
                    ? 'Show all prompt packs'
                    : 'Favorite prompts',
                isSelected: _favorites,
                onPressed: () => setState(() {
                  _favorites = !_favorites;
                  _pack = null;
                }),
                icon: Icon(_favorites ? Icons.favorite : Icons.favorite_border),
              ),
          ],
        ),
        body: JournalCanvas(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.templates) ...[
                const Text(
                  'Start blank, or choose a little structure. Every section is editable.',
                ),
                const SizedBox(height: 16),
                for (final template in entryTemplates)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.notes),
                      title: Text(template.name),
                      subtitle: Text(
                        template.sections.isEmpty
                            ? 'An open page'
                            : template.sections.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(
                        context,
                        InspirationChoice(template: template),
                      ),
                    ),
                  ),
              ] else if (_pack == null && !_favorites) ...[
                const Text(
                  'A question can be a gentle place to begin. Progress stays in this session.',
                ),
                const SizedBox(height: 16),
                for (final pack in promptPacks.entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: Text(pack.key),
                      subtitle: Text(
                        '${pack.value.length} prompts · ${reflectionPrompts.where((p) => p.pack == pack.key && widget.experience.usedPrompts.contains(p.id)).length} / ${pack.value.length} explored',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() => _pack = pack.key),
                    ),
                  ),
              ] else ...[
                if (_pack != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _pack = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('All packs'),
                  ),
                if (prompts.isEmpty)
                  const Text(
                    'No favorite prompts yet. Tap a heart beside a question to keep it here.',
                  ),
                for (final prompt in prompts)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prompt.text,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (widget.experience.usedPrompts.contains(
                                  prompt.id,
                                ))
                                  const Text('Explored this session'),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    InspirationChoice(prompt: prompt),
                                  ),
                                  child: const Text('Write with this prompt'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip:
                                widget.experience.favoritePrompts.contains(
                                  prompt.id,
                                )
                                ? 'Unfavorite prompt'
                                : 'Favorite prompt',
                            isSelected: widget.experience.favoritePrompts
                                .contains(prompt.id),
                            onPressed: () {
                              journalHaptic(context);
                              widget.experience.togglePrompt(prompt.id);
                            },
                            icon: Icon(
                              widget.experience.favoritePrompts.contains(
                                    prompt.id,
                                  )
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../widgets/journal_components.dart';

class JournalPreferencesScreen extends StatelessWidget {
  const JournalPreferencesScreen({super.key, required this.experience});
  final JournalExperience experience;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: experience,
    builder: (context, _) {
      final p = experience.preferences;
      void update({
        PaperStyle? paper,
        WritingStyle? writing,
        double? size,
        bool? words,
        bool? haptics,
        String? collection,
        bool clearCollection = false,
      }) => experience.update(
        JournalPreferences(
          paper: paper ?? p.paper,
          writing: writing ?? p.writing,
          textSize: size ?? p.textSize,
          wordCount: words ?? p.wordCount,
          haptics: haptics ?? p.haptics,
          collectionId: clearCollection ? null : collection ?? p.collectionId,
        ),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Journal preferences')),
        body: JournalCanvas(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Writing typography'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in WritingStyle.values)
                    ChoiceChip(
                      label: Text(switch (style) {
                        WritingStyle.modern => 'Modern',
                        WritingStyle.editorial => 'Editorial',
                        WritingStyle.classicSerif => 'Classic Serif',
                      }),
                      selected: p.writing == style,
                      onSelected: (_) => update(writing: style),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Paper style'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in PaperStyle.values)
                    ChoiceChip(
                      label: Text(switch (style) {
                        PaperStyle.clean => 'Clean',
                        PaperStyle.paper => 'Paper',
                        PaperStyle.softLines => 'Soft Lines',
                        PaperStyle.dotGrid => 'Dot Grid',
                      }),
                      selected: p.paper == style,
                      onSelected: (_) => update(paper: style),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Text size · ${p.textSize.round()}'),
              Slider(
                value: p.textSize,
                min: 16,
                max: 26,
                divisions: 10,
                label: '${p.textSize.round()}',
                onChanged: (v) => update(size: v),
              ),
              Text(
                'A little space for your thoughts.',
                style: p.bodyStyle(context),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: p.collectionId ?? 'general',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Default collection',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'general',
                    child: Text('General'),
                  ),
                  for (final collection in journalCollections)
                    DropdownMenuItem(
                      value: collection.id,
                      child: Text(collection.name),
                    ),
                ],
                onChanged: (id) =>
                    update(collection: id, clearCollection: id == 'general'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show word count'),
                value: p.wordCount,
                onChanged: (v) => update(words: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptics'),
                value: p.haptics,
                onChanged: (v) => update(haptics: v),
              ),
              const SizedBox(height: 16),
              const Text(
                'Preferences apply to writing and reading and are saved on this device.',
              ),
            ],
          ),
        ),
      );
    },
  );
}

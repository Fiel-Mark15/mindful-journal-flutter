import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../core/experience/journal_experience.dart';
import '../widgets/mood_selector.dart';
import '../widgets/saved_check.dart';
import '../core/theme/app_theme.dart';
import '../widgets/journal_components.dart';

const lifeAreas = [
  'School',
  'Work',
  'Coding',
  'Exercise',
  'Friends',
  'Family',
  'Health',
  'Rest',
  'Travel',
  'Creativity',
];

class QuickCheckInScreen extends StatefulWidget {
  const QuickCheckInScreen({super.key, this.initialMood, this.onCommit});
  final Mood? initialMood;
  final Future<void> Function(JournalEntry)? onCommit;
  @override
  State<QuickCheckInScreen> createState() => _QuickCheckInScreenState();
}

class _QuickCheckInScreenState extends State<QuickCheckInScreen> {
  final _note = TextEditingController();
  final _scroll = ScrollController();
  final Set<String> _activities = {};
  Mood? _mood;
  String? _energy;
  bool _error = false, _saving = false;
  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_mood == null) {
      setState(() => _error = true);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    journalHaptic(context, medium: true);
    final collectionId = ExperienceScope.preferencesOf(context).collectionId;
    final entry = JournalEntry(
      id: 'check-in-${now.microsecondsSinceEpoch}',
      title: '${moodInfo[_mood]!.label} moment',
      content: _note.text.trim(),
      date: DateTime(now.year, now.month, now.day),
      mood: _mood!,
      kind: EntryKind.quickCheckIn,
      energy: _energy,
      tags: List.unmodifiable(_activities.map((a) => a.toLowerCase())),
      collectionId: collectionId,
      createdAt: now,
    );
    try {
      await widget.onCommit?.call(entry);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this check-in. Please retry.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.normal,
    );
    if (mounted) Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quick check-in')),
    body: JournalCanvas(
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          MoodSelector(
            value: _mood,
            onChanged: (m) => setState(() {
              _mood = m;
              _error = false;
            }),
          ),
          if (_error)
            Text(
              'Please choose a mood.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 24),
          const Text('What was part of your day? · Optional'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final area in lifeAreas)
                FilterChip(
                  label: Text(area),
                  selected: _activities.contains(area),
                  onSelected:
                      !_activities.contains(area) && _activities.length >= 8
                      ? null
                      : (v) => setState(() {
                          if (v) {
                            _activities.add(area);
                          } else {
                            _activities.remove(area);
                          }
                        }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Energy · Optional'),
          Wrap(
            spacing: 8,
            children: [
              for (final energy in ['Low', 'Medium', 'High'])
                ChoiceChip(
                  label: Text(energy),
                  selected: _energy == energy,
                  onSelected: (v) =>
                      setState(() => _energy = v ? energy : null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('check-in-note'),
            controller: _note,
            maxLength: 240,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anything you want to remember?',
              hintText: 'One sentence is enough.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SavedCheck() : const Icon(Icons.check),
            label: Text(_saving ? 'Saving…' : 'Save check-in'),
          ),
          const SizedBox(height: 16),
          const Text('A small moment, saved on this device.'),
        ],
      ),
    ),
  );
}

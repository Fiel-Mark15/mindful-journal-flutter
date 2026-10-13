import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

const journalColors = <String, Color>{
  'Ink': Color(0xFF242638),
  'White': Colors.white,
  'Indigo': Color(0xFF5856D6),
  'Purple': Color(0xFF873CC4),
  'Blue': Color(0xFF2478C5),
  'Teal': Color(0xFF168D95),
  'Green': Color(0xFF21884C),
  'Amber': Color(0xFFE0AD32),
  'Orange': Color(0xFFDC702D),
  'Red': Color(0xFFCB393E),
  'Rose': Color(0xFFC54880),
};

class ColorChoice {
  const ColorChoice(this.color);
  final Color? color;
}

Future<ColorChoice?> chooseColor(
  BuildContext context, {
  required String title,
  Color? initial,
  bool allowDefault = false,
}) => showDialog<ColorChoice>(
  context: context,
  builder: (_) =>
      _ColorDialog(title: title, initial: initial, allowDefault: allowDefault),
);

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({
    required this.title,
    this.initial,
    required this.allowDefault,
  });
  final String title;
  final Color? initial;
  final bool allowDefault;
  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late HSLColor _color;
  bool _custom = false;
  @override
  void initState() {
    super.initState();
    _color = HSLColor.fromColor(widget.initial ?? journalColors['Indigo']!);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.allowDefault)
                  ActionChip(
                    label: const Text('Default'),
                    onPressed: () =>
                        Navigator.pop(context, const ColorChoice(null)),
                  ),
                for (final entry in journalColors.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    avatar: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    selected:
                        _color.toColor().toARGB32() == entry.value.toARGB32(),
                    onSelected: (_) => setState(
                      () => _color = HSLColor.fromColor(entry.value),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _custom = !_custom),
              icon: const Icon(Icons.tune),
              label: const Text('Custom color'),
            ),
            if (_custom) ...[
              const Text('Hue'),
              Slider(
                value: _color.hue,
                min: 0,
                max: 360,
                semanticFormatterCallback: (value) =>
                    '${value.round()} degrees',
                onChanged: (v) => setState(() => _color = _color.withHue(v)),
              ),
              const Text('Saturation'),
              Slider(
                value: _color.saturation,
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()} percent',
                onChanged: (v) =>
                    setState(() => _color = _color.withSaturation(v)),
              ),
              const Text('Lightness'),
              Slider(
                value: _color.lightness,
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()} percent',
                onChanged: (v) =>
                    setState(() => _color = _color.withLightness(v)),
              ),
            ],
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _color.toColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Text and accent colors use readable variants on light and dark surfaces.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, ColorChoice(_color.toColor())),
        child: const Text('Use color'),
      ),
    ],
  );
}

Future<JournalAccent?> chooseAccent(
  BuildContext context,
  JournalAccent current,
) => showModalBottomSheet<JournalAccent>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color theme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final accent in JournalAccent.presets)
                ChoiceChip(
                  avatar: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent.start, accent.end],
                      ),
                    ),
                  ),
                  label: Text(accent.name),
                  selected: current == accent,
                  onSelected: (_) => Navigator.pop(context, accent),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Custom accent'),
            subtitle: const Text(
              'Choose a color. Readable variants are derived for you.',
            ),
            onTap: () async {
              final result = await chooseColor(
                context,
                title: 'Custom accent',
                initial: current.seed,
              );
              if (context.mounted && result?.color != null) {
                Navigator.pop(context, JournalAccent.custom(result!.color!));
              }
            },
          ),
        ],
      ),
    ),
  ),
);

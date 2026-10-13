import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../core/theme/app_theme.dart';
import '../models/checklist_item.dart';

class ChecklistBlock extends StatelessWidget {
  const ChecklistBlock({super.key, required this.items, this.onChanged});
  final List<ChecklistItem> items;
  final ValueChanged<List<ChecklistItem>>? onChanged;
  void update(int index, ChecklistItem item) {
    final next = [...items];
    next[index] = item;
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (items.isNotEmpty || onChanged != null)
        Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
      for (var i = 0; i < items.length; i++)
        Padding(
          key: ValueKey(items[i].id),
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedChecklistCheck(
                label: items[i].text.isEmpty
                    ? 'Checklist item ${i + 1}'
                    : items[i].text,
                checked: items[i].isCompleted,
                onToggle: onChanged == null
                    ? null
                    : () => update(
                        i,
                        items[i].copyWith(isCompleted: !items[i].isCompleted),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedOpacity(
                  opacity: items[i].isCompleted ? .65 : 1,
                  duration: AppMotion.duration(context),
                  child: onChanged == null
                      ? Text(
                          items[i].text,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                decoration: items[i].isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        )
                      : TextFormField(
                          key: ValueKey('checklist-text-${items[i].id}'),
                          initialValue: items[i].text,
                          maxLength: 160,
                          decoration: InputDecoration(
                            hintText: 'A small thing to remember',
                            counterText: '',
                            isDense: true,
                          ),
                          style: TextStyle(
                            decoration: items[i].isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          onChanged: (text) =>
                              update(i, items[i].copyWith(text: text)),
                          validator: (text) =>
                              text == null || text.trim().isEmpty
                              ? 'Add text or remove this item.'
                              : null,
                        ),
                ),
              ),
              if (onChanged != null)
                IconButton(
                  tooltip: 'Delete checklist item ${i + 1}',
                  onPressed: () {
                    final next = [...items]..removeAt(i);
                    onChanged!(next);
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
      if (onChanged != null)
        TextButton.icon(
          onPressed: items.length >= 20
              ? null
              : () => onChanged!([
                  ...items,
                  ChecklistItem(
                    id: 'check-${DateTime.now().microsecondsSinceEpoch}',
                    text: '',
                  ),
                ]),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add checklist item'),
        ),
    ],
  );
}

class AnimatedChecklistCheck extends StatefulWidget {
  const AnimatedChecklistCheck({
    super.key,
    required this.label,
    required this.checked,
    this.onToggle,
  });
  final String label;
  final bool checked;
  final VoidCallback? onToggle;
  @override
  State<AnimatedChecklistCheck> createState() => _AnimatedChecklistCheckState();
}

class _AnimatedChecklistCheckState extends State<AnimatedChecklistCheck> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      checked: widget.checked,
      enabled: widget.onToggle != null,
      child: ExcludeSemantics(
        child: Tooltip(
          message: widget.onToggle == null
              ? (widget.checked ? 'Completed' : 'Not completed')
              : (widget.checked ? 'Mark incomplete' : 'Mark complete'),
          child: AnimatedScale(
            scale: _pressed ? .94 : 1,
            duration: AppMotion.duration(context),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onHighlightChanged: (pressed) =>
                    setState(() => _pressed = pressed),
                onTap: widget.onToggle == null
                    ? null
                    : () {
                        journalHaptic(context);
                        widget.onToggle!();
                      },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.checked ? 1 : 0),
                      duration: AppMotion.duration(context),
                      curve: AppMotion.curve,
                      builder: (context, value, _) => CustomPaint(
                        size: const Size(24, 24),
                        painter: _CheckPainter(
                          value,
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.onPrimary,
                          Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress, this.accent, this.foreground, this.border);
  final double progress;
  final Color accent, foreground, border;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(7),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Color.lerp(Colors.transparent, accent, progress)!,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Color.lerp(border, accent, progress)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final path = Path()
      ..moveTo(6, 12)
      ..lineTo(10, 16)
      ..lineTo(18, 8);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.foreground != foreground ||
      old.border != border;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../core/utils/journal_streak.dart';

class ReflectionRings extends StatelessWidget {
  const ReflectionRings({super.key, required this.entries});
  final List<JournalEntry> entries;
  @override
  Widget build(BuildContext context) {
    final rhythm = JournalStreakCalculator.calculate(entries);
    final moods = entries.map((e) => e.mood).toSet().length;
    final creative = entries
        .where((e) => e.attachments.isNotEmpty || e.checklist.isNotEmpty)
        .length;
    return Semantics(
      label:
          'Reflection rings. ${rhythm.thisWeek} of 7 writing days this week. $moods of 5 moods recorded. $creative of ${entries.length} entries include media or checklists.',
      child: Column(
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _RingsPainter([
                  rhythm.thisWeek / 7,
                  moods / 5,
                  entries.isEmpty ? 0 : creative / entries.length,
                ], Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Reflection Rings'),
          Text(
            '${rhythm.thisWeek}/7 days · $moods/5 moods · $creative creative entries',
            textAlign: TextAlign.center,
          ),
          const Text(
            'Outer: this week · Middle: mood variety · Inner: media or checklists',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCircle(center: center, radius: 68 - i * 18);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      paint.color = color.withValues(alpha: .08);
      canvas.drawArc(rect, -.8 * math.pi, 1.6 * math.pi, false, paint);
      paint.color = color.withValues(alpha: 1 - i * .22);
      canvas.drawArc(
        rect,
        -.8 * math.pi,
        1.6 * math.pi * values[i].clamp(0, 1),
        false,
        paint,
      );
    }
    canvas.drawCircle(center, 6, Paint()..color = color.withValues(alpha: .18));
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color || old.values.toString() != values.toString();
}

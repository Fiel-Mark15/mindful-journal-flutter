import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';

class JournalPaper extends StatelessWidget {
  const JournalPaper({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final style = ExperienceScope.preferencesOf(context).paper;
    final color = Theme.of(context).colorScheme.primary;
    return CustomPaint(painter: _PaperPainter(style, color), child: child);
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter(this.style, this.color);
  final PaperStyle style;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (style == PaperStyle.clean) return;
    if (style == PaperStyle.paper) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = color.withValues(alpha: .035),
      );
      return;
    }
    final paint = Paint()
      ..color = color.withValues(alpha: .075)
      ..strokeWidth = .6;
    if (style == PaperStyle.softLines) {
      for (double y = 32; y < size.height; y += 32) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
    if (style == PaperStyle.dotGrid) {
      for (double y = 16; y < size.height; y += 20) {
        for (double x = 12; x < size.width; x += 20) {
          canvas.drawCircle(Offset(x, y), .8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.style != style || old.color != color;
}

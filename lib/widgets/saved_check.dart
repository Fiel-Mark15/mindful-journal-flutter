import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SavedCheck extends StatelessWidget {
  const SavedCheck({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Saved',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.normal,
      builder: (context, value, _) => SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: _SavedPainter(
            value,
            IconTheme.of(context).color ??
                Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ),
  );
}

class _SavedPainter extends CustomPainter {
  const _SavedPainter(this.progress, this.color);
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .18, size.height * .52)
      ..lineTo(size.width * .42, size.height * .74)
      ..lineTo(size.width * .85, size.height * .25);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SavedPainter old) =>
      old.progress != progress || old.color != color;
}

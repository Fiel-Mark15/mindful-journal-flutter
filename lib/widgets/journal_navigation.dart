import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../core/theme/app_theme.dart';

class JournalNavigation extends StatelessWidget {
  const JournalNavigation({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onCreate,
    required this.creating,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreate;
  final bool creating;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 400 ||
          MediaQuery.textScalerOf(context).scale(12) > 18;
      Widget destination(String label, IconData icon, int value) => Expanded(
        child: _Destination(
          label: label,
          icon: icon,
          selected: index == value,
          onTap: () => onChanged(value),
        ),
      );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(4, compact ? 32 : 8, 4, 8),
                  child: Row(
                    children: compact
                        ? [
                            destination('Home', CupertinoIcons.house, 0),
                            destination('Journal', CupertinoIcons.book, 1),
                            destination('Calendar', CupertinoIcons.calendar, 2),
                            destination(
                              'Profile',
                              CupertinoIcons.person_crop_circle,
                              3,
                            ),
                          ]
                        : [
                            Expanded(
                              child: Row(
                                children: [
                                  destination('Home', CupertinoIcons.house, 0),
                                  destination(
                                    'Journal',
                                    CupertinoIcons.book,
                                    1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 64),
                            Expanded(
                              child: Row(
                                children: [
                                  destination(
                                    'Calendar',
                                    CupertinoIcons.calendar,
                                    2,
                                  ),
                                  destination(
                                    'Profile',
                                    CupertinoIcons.person_crop_circle,
                                    3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                  ),
                ),
              ),
              CreateButton(onTap: onCreate, active: creating),
            ],
          ),
        ),
      );
    },
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
      onPressed: () {
        journalHaptic(context);
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.duration(context),
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class CreateButton extends StatefulWidget {
  const CreateButton({super.key, required this.onTap, required this.active});
  final VoidCallback onTap;
  final bool active;
  @override
  State<CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<CreateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _reflect() {
    if (!MediaQuery.disableAnimationsOf(context)) _shine.forward(from: 0);
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Create journal entry',
    child: MouseRegion(
      onEnter: (_) => _reflect(),
      child: AnimatedScale(
        scale: _pressed ? .94 : 1,
        duration: AppMotion.duration(context),
        curve: Curves.easeOutBack,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AccentPalette.of(context).gradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x305856D6),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              onTap: () {
                journalHaptic(context);
                _reflect();
                widget.onTap();
              },
              child: Semantics(
                label: 'Create journal entry',
                button: true,
                child: ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: widget.active ? .125 : 0,
                    duration: AppMotion.duration(context),
                    curve: AppMotion.curve,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipOval(
                              child: AnimatedBuilder(
                                animation: _shine,
                                builder: (_, _) => CustomPaint(
                                  painter: _ShinePainter(_shine.value),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ShinePainter extends CustomPainter {
  const _ShinePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = -size.width + progress * size.width * 3;
    canvas.save();
    canvas.translate(center, size.height / 2);
    canvas.rotate(-.65);
    final rect = Rect.fromLTWH(-12, -size.height * 2, 24, size.height * 4);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, Color(0x35FFFFFF), Colors.transparent],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) => old.progress != progress;
}

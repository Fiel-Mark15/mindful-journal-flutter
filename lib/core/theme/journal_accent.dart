import 'package:flutter/material.dart';

/// Makes an explicitly chosen color readable on its actual presentation surface.
Color readableColor(Color color, Color background, {double minimum = 4.5}) {
  Color candidate = color.withValues(alpha: 1);
  double contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
  }

  final lighten = background.computeLuminance() < .179;
  for (var i = 0; i < 100 && contrast(candidate, background) < minimum; i++) {
    final hsl = HSLColor.fromColor(candidate);
    candidate = hsl
        .withLightness((hsl.lightness + (lighten ? .015 : -.015)).clamp(0, 1))
        .toColor();
  }
  return candidate;
}

@immutable
class JournalAccent {
  const JournalAccent(this.name, this.seed, this.start, this.end);
  Map<String, dynamic> toJson() => {
    'name': name,
    'seed': seed.toARGB32(),
    'start': start.toARGB32(),
    'end': end.toARGB32(),
  };
  factory JournalAccent.fromJson(Map<String, dynamic> j) => JournalAccent(
    j['name'] as String,
    Color(j['seed'] as int),
    Color(j['start'] as int),
    Color(j['end'] as int),
  );
  final String name;
  final Color seed, start, end;
  static const indigo = JournalAccent(
    'Indigo',
    Color(0xFF5856D6),
    Color(0xFF20233F),
    Color(0xFF5856D6),
  );
  static const presets = [
    indigo,
    JournalAccent(
      'Royal Purple',
      Color(0xFF7B3FC6),
      Color(0xFF302142),
      Color(0xFF7B3FC6),
    ),
    JournalAccent(
      'Ocean',
      Color(0xFF146CBA),
      Color(0xFF193448),
      Color(0xFF146CBA),
    ),
    JournalAccent(
      'Emerald',
      Color(0xFF167A57),
      Color(0xFF17392D),
      Color(0xFF167A57),
    ),
    JournalAccent(
      'Rose',
      Color(0xFFB33769),
      Color(0xFF482438),
      Color(0xFFB33769),
    ),
    JournalAccent(
      'Sunset',
      Color(0xFFB94B23),
      Color(0xFF482A32),
      Color(0xFFB94B23),
    ),
    JournalAccent(
      'Midnight',
      Color(0xFF405778),
      Color(0xFF202A3E),
      Color(0xFF405778),
    ),
    JournalAccent(
      'Warm Gold',
      Color(0xFF8A6818),
      Color(0xFF39301F),
      Color(0xFF8A6818),
    ),
  ];
  factory JournalAccent.custom(Color color) {
    final hsl = HSLColor.fromColor(color);
    return JournalAccent(
      'Custom',
      color,
      hsl.withLightness(.20).toColor(),
      color,
    );
  }
}

@immutable
class AccentPalette extends ThemeExtension<AccentPalette> {
  const AccentPalette({
    required this.start,
    required this.end,
    required this.soft,
    required this.border,
  });
  final Color start, end, soft, border;
  LinearGradient get gradient => LinearGradient(
    colors: [start, end],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static AccentPalette of(BuildContext context) =>
      Theme.of(context).extension<AccentPalette>()!;
  @override
  AccentPalette copyWith({
    Color? start,
    Color? end,
    Color? soft,
    Color? border,
  }) => AccentPalette(
    start: start ?? this.start,
    end: end ?? this.end,
    soft: soft ?? this.soft,
    border: border ?? this.border,
  );
  @override
  AccentPalette lerp(covariant AccentPalette? other, double t) => other == null
      ? this
      : AccentPalette(
          start: Color.lerp(start, other.start, t)!,
          end: Color.lerp(end, other.end, t)!,
          soft: Color.lerp(soft, other.soft, t)!,
          border: Color.lerp(border, other.border, t)!,
        );
}

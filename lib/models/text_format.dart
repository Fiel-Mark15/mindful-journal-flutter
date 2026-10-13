/// UTF-16 offsets, matching Flutter TextSelection. Formatting stays in memory.
class TextFormatRun {
  const TextFormatRun(
    this.start,
    this.end,
    this.flags, {
    this.color,
    this.highlight,
  });
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'flags': flags,
    'color': color,
    'highlight': highlight,
  };
  factory TextFormatRun.fromJson(Map<String, dynamic> j) => TextFormatRun(
    j['start'] as int,
    j['end'] as int,
    j['flags'] as int,
    color: j['color'] as int?,
    highlight: j['highlight'] as int?,
  );
  final int start;
  final int end;
  final int flags;
  final int? color;
  final int? highlight;
}

class TextFormat {
  static const bold = 1;
  static const italic = 2;
  static const underline = 4;
  static const strike = 8;
  static const heading = 16;
}

/// Immutable attributes ensure undo history never aliases mutable styles.
class TextAttributes {
  const TextAttributes({this.flags = 0, this.color, this.highlight});
  final int flags;
  final int? color, highlight;
  TextAttributes withFlags(int value) =>
      TextAttributes(flags: value, color: color, highlight: highlight);
  TextAttributes withColor(int? value) =>
      TextAttributes(flags: flags, color: value, highlight: highlight);
  TextAttributes withHighlight(int? value) =>
      TextAttributes(flags: flags, color: color, highlight: value);
  @override
  bool operator ==(Object other) =>
      other is TextAttributes &&
      other.flags == flags &&
      other.color == color &&
      other.highlight == highlight;
  @override
  int get hashCode => Object.hash(flags, color, highlight);
}

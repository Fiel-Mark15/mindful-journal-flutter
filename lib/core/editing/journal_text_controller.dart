import 'package:flutter/material.dart';
import '../../models/text_format.dart';
import '../theme/journal_accent.dart';

class _Snapshot {
  _Snapshot(this.value, this.styles, this.typingStyle);
  final TextEditingValue value;
  final List<TextAttributes> styles;
  final TextAttributes typingStyle;
}

/// A small attributed text controller for course-safe, in-memory formatting.
/// Inline attributes are separate from plain text; no Markdown markers are stored.
class JournalTextController extends TextEditingController {
  JournalTextController({String text = '', List<TextFormatRun> runs = const []})
    : super(text: text) {
    _styles = List.filled(text.length, const TextAttributes(), growable: true);
    for (final run in runs) {
      for (
        var i = run.start.clamp(0, text.length);
        i < run.end.clamp(0, text.length);
        i++
      ) {
        _styles[i] = TextAttributes(
          flags: run.flags,
          color: run.color,
          highlight: run.highlight,
        );
      }
    }
  }
  late List<TextAttributes> _styles;
  TextAttributes _typingStyle = const TextAttributes();
  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  _Snapshot _snapshot() => _Snapshot(value, [..._styles], _typingStyle);
  void _remember() {
    _undo.add(_snapshot());
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(_Snapshot snapshot) {
    _styles = [...snapshot.styles];
    _typingStyle = snapshot.typingStyle;
    super.value = snapshot.value;
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
  }

  @override
  set value(TextEditingValue next) {
    final old = super.value;
    if (next.text != old.text) {
      _remember();
      var prefix = 0;
      while (prefix < old.text.length &&
          prefix < next.text.length &&
          old.text[prefix] == next.text[prefix]) {
        prefix++;
      }
      var suffix = 0;
      while (suffix < old.text.length - prefix &&
          suffix < next.text.length - prefix &&
          old.text[old.text.length - 1 - suffix] ==
              next.text[next.text.length - 1 - suffix]) {
        suffix++;
      }
      // Prefer the editing selection when repeated characters make a plain
      // prefix/suffix diff ambiguous (for example inserting an "a" in "aaa").
      final selection = old.selection;
      if (selection.isValid) {
        final replacementLength =
            next.text.length -
            old.text.length +
            selection.end -
            selection.start;
        if (replacementLength >= 0 &&
            selection.start + replacementLength <= next.text.length &&
            old.text.substring(0, selection.start) ==
                next.text.substring(0, selection.start) &&
            old.text.substring(selection.end) ==
                next.text.substring(selection.start + replacementLength)) {
          prefix = selection.start;
          suffix = old.text.length - selection.end;
        }
      }
      final inserted = next.text.length - prefix - suffix;
      _styles = [
        ..._styles.take(prefix),
        ...List.filled(inserted, _typingStyle),
        ..._styles.skip(old.text.length - suffix),
      ];
    } else if (next.selection != old.selection &&
        next.selection.isValid &&
        _styles.isNotEmpty) {
      final position = (next.selection.extentOffset - 1).clamp(
        0,
        _styles.length - 1,
      );
      _typingStyle = _styles[position];
    }
    super.value = next;
  }

  bool selected(int flag) {
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return _typingStyle.flags & flag != 0;
    }
    return _styles
        .sublist(selection.start, selection.end)
        .every((style) => style.flags & flag != 0);
  }

  void toggle(int flag) {
    _remember();
    final off = selected(flag);
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      _typingStyle = _typingStyle.withFlags(
        off ? _typingStyle.flags & ~flag : _typingStyle.flags | flag,
      );
    } else {
      for (var i = selection.start; i < selection.end; i++) {
        _styles[i] = _styles[i].withFlags(
          off ? _styles[i].flags & ~flag : _styles[i].flags | flag,
        );
      }
    }
    notifyListeners();
  }

  int? get currentColor => _typingStyle.color;
  int? get currentHighlight => _typingStyle.highlight;
  void applyColor(Color? color, {bool highlight = false}) {
    _remember();
    TextAttributes update(TextAttributes attributes) => highlight
        ? attributes.withHighlight(color?.toARGB32())
        : attributes.withColor(color?.toARGB32());
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      _typingStyle = update(_typingStyle);
    } else {
      for (var i = selection.start; i < selection.end; i++) {
        _styles[i] = update(_styles[i]);
      }
      _typingStyle = update(_typingStyle);
    }
    notifyListeners();
  }

  /// Prefix actions operate on complete selected lines and toggle off cleanly.
  void prefixLines(String kind) {
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = selection.start == 0
        ? 0
        : text.lastIndexOf('\n', selection.start - 1) + 1;
    final last =
        selection.end > selection.start && text[selection.end - 1] == '\n'
        ? selection.end - 1
        : selection.end;
    final newline = text.indexOf('\n', last);
    final end = newline < 0 ? text.length : newline;
    final lines = text.substring(start, end).split('\n');
    final pattern = switch (kind) {
      'bullet' => RegExp(r'^• '),
      'number' => RegExp(r'^\d+\. '),
      _ => RegExp(r'^> '),
    };
    final remove = lines.every((line) => pattern.hasMatch(line));
    final patches = <({int offset, int length, String insert})>[];
    var offset = start;
    for (var i = 0; i < lines.length; i++) {
      final existing = RegExp(r'^(• |\d+\. |> )').firstMatch(lines[i]);
      final prefix = remove
          ? ''
          : switch (kind) {
              'bullet' => '• ',
              'number' => '${i + 1}. ',
              _ => '> ',
            };
      patches.add((offset: offset, length: existing?.end ?? 0, insert: prefix));
      offset += lines[i].length + 1;
    }
    _remember();
    var updated = text;
    for (final patch in patches.reversed) {
      updated = updated.replaceRange(
        patch.offset,
        patch.offset + patch.length,
        patch.insert,
      );
      _styles.replaceRange(
        patch.offset,
        patch.offset + patch.length,
        List.filled(patch.insert.length, const TextAttributes()),
      );
    }
    final difference = updated.length - text.length;
    super.value = TextEditingValue(
      text: updated,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: end + difference,
      ),
    );
  }

  List<TextFormatRun> runs({bool trim = false}) {
    final start = trim ? text.length - text.trimLeft().length : 0;
    final end = trim ? text.trimRight().length : text.length;
    final result = <TextFormatRun>[];
    var index = start;
    while (index < end) {
      final flag = _styles[index];
      var next = index + 1;
      while (next < end && _styles[next] == flag) {
        next++;
      }
      if (flag != const TextAttributes()) {
        result.add(
          TextFormatRun(
            index - start,
            next - start,
            flag.flags,
            color: flag.color,
            highlight: flag.highlight,
          ),
        );
      }
      index = next;
    }
    return result;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => attributedSpan(
    text,
    runs(),
    style ?? const TextStyle(),
    composing: withComposing ? value.composing : TextRange.empty,
    background: Theme.of(context).scaffoldBackgroundColor,
  );
}

TextSpan attributedSpan(
  String text,
  List<TextFormatRun> runs,
  TextStyle base, {
  TextRange composing = TextRange.empty,
  Color background = const Color(0xFFF8F8FC),
}) {
  final styles = List.filled(
    text.length,
    const TextAttributes(),
    growable: true,
  );
  for (final run in runs) {
    for (
      var i = run.start.clamp(0, text.length);
      i < run.end.clamp(0, text.length);
      i++
    ) {
      styles[i] = TextAttributes(
        flags: run.flags,
        color: run.color,
        highlight: run.highlight,
      );
    }
  }
  bool composingAt(int i) =>
      composing.isValid && i >= composing.start && i < composing.end;
  final children = <TextSpan>[];
  var i = 0;
  while (i < text.length) {
    final attributes = styles[i];
    final flags = attributes.flags;
    final highlight = attributes.highlight == null
        ? null
        : Color(attributes.highlight!).withValues(alpha: .22);
    final effectiveBackground = highlight == null
        ? background
        : Color.alphaBlend(highlight, background);
    final underlined = composingAt(i);
    var end = i + 1;
    while (end < text.length &&
        styles[end] == attributes &&
        composingAt(end) == underlined) {
      end++;
    }
    final decorations = <TextDecoration>[
      if (flags & TextFormat.underline != 0 || underlined)
        TextDecoration.underline,
      if (flags & TextFormat.strike != 0) TextDecoration.lineThrough,
    ];
    children.add(
      TextSpan(
        text: text.substring(i, end),
        style: base.copyWith(
          color: readableColor(
            attributes.color == null
                ? (base.color ?? Colors.black)
                : Color(attributes.color!),
            effectiveBackground,
          ),
          backgroundColor: highlight,
          fontWeight: flags & (TextFormat.bold | TextFormat.heading) != 0
              ? FontWeight.w700
              : base.fontWeight,
          fontStyle: flags & TextFormat.italic != 0
              ? FontStyle.italic
              : base.fontStyle,
          fontSize: flags & TextFormat.heading != 0
              ? (base.fontSize ?? 17) * 1.3
              : base.fontSize,
          decoration: decorations.isEmpty
              ? TextDecoration.none
              : TextDecoration.combine(decorations),
        ),
      ),
    );
    i = end;
  }
  return TextSpan(style: base, children: children);
}

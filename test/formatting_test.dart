import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_style_journal/core/editing/journal_text_controller.dart';
import 'package:ios_style_journal/models/text_format.dart';

void main() {
  test('Selected formatting survives text insertion and undo/redo', () {
    final controller = JournalTextController(text: 'Hello world');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    controller.toggle(TextFormat.bold);
    expect(controller.selected(TextFormat.bold), isTrue);
    expect(controller.runs().single.end, 5);
    controller.undo();
    expect(controller.runs(), isEmpty);
    controller.redo();
    expect(controller.runs().single.flags, TextFormat.bold);
    controller.selection = const TextSelection.collapsed(offset: 5);
    controller.value = const TextEditingValue(
      text: 'Hello! world',
      selection: TextSelection.collapsed(offset: 6),
    );
    expect(controller.runs().single.end, 6);
    controller.undo();
    expect(controller.text, 'Hello world');
    expect(controller.runs().single.end, 5);
  });
  test(
    'Collapsed toggle applies only to subsequent input and can be disabled',
    () {
      final controller = JournalTextController();
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.toggle(TextFormat.italic);
      controller.value = const TextEditingValue(
        text: 'Quiet',
        selection: TextSelection.collapsed(offset: 5),
      );
      expect(controller.runs().single.flags, TextFormat.italic);
      controller.toggle(TextFormat.italic);
      controller.value = const TextEditingValue(
        text: 'Quiet day',
        selection: TextSelection.collapsed(offset: 9),
      );
      expect(controller.runs().single.end, 5);
    },
  );
  test('Trimming relocates attributes and preserves combinations', () {
    final controller = JournalTextController(text: '  Memory  ');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 8);
    controller.toggle(TextFormat.underline);
    controller.toggle(TextFormat.strike);
    final run = controller.runs(trim: true).single;
    expect(run.start, 0);
    expect(run.end, 6);
    expect(run.flags, TextFormat.underline | TextFormat.strike);
  });
  test(
    'List and quote actions toggle whole lines and undo restores attributes',
    () {
      final controller = JournalTextController(text: 'First\nSecond');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 12,
      );
      controller.toggle(TextFormat.bold);
      controller.prefixLines('number');
      expect(controller.text, '1. First\n2. Second');
      expect(controller.runs().first.start, 3);
      controller.prefixLines('number');
      expect(controller.text, 'First\nSecond');
      controller.prefixLines('quote');
      expect(controller.text, '> First\n> Second');
      controller.undo();
      expect(controller.text, 'First\nSecond');
      expect(controller.runs().single.flags, TextFormat.bold);
      controller.prefixLines('bullet');
      expect(controller.text, '• First\n• Second');
    },
  );
  test('Repeated-character insertion follows the actual cursor position', () {
    final controller = JournalTextController(
      text: 'aaa',
      runs: const [TextFormatRun(2, 3, TextFormat.bold)],
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.value = const TextEditingValue(
      text: 'aaaa',
      selection: TextSelection.collapsed(offset: 1),
    );
    expect(controller.runs().single.start, 3);
    expect(controller.runs().single.end, 4);
  });
  test('Reopening a saved document uses the same rich reading attributes', () {
    final controller = JournalTextController(
      text: 'A moment',
      runs: const [TextFormatRun(2, 8, TextFormat.bold)],
    );
    addTearDown(controller.dispose);
    final span = attributedSpan(
      controller.text,
      controller.runs(),
      const TextStyle(fontSize: 17),
    );
    expect(span.toPlainText(), 'A moment');
    expect(
      (span.children!.last as TextSpan).style!.fontWeight,
      FontWeight.w700,
    );
  });
}

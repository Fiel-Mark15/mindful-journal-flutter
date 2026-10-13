import 'package:flutter/material.dart';
import '../core/editing/journal_text_controller.dart';
import '../models/text_format.dart';

class WritingToolbar extends StatelessWidget {
  const WritingToolbar({
    super.key,
    required this.controller,
    required this.onAction,
    this.onInsert,
    this.onColor,
  });
  final JournalTextController controller;
  final VoidCallback onAction;
  final VoidCallback? onInsert, onColor;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (onInsert != null)
            IconButton(
              tooltip: 'Insert media',
              onPressed: onInsert,
              icon: const Icon(Icons.add_circle_outline),
            ),
          if (onColor != null)
            IconButton(
              tooltip: 'Text color',
              onPressed: onColor,
              icon: const Icon(Icons.format_color_text),
            ),
          for (final tool in [
            (TextFormat.bold, Icons.format_bold, 'Bold'),
            (TextFormat.italic, Icons.format_italic, 'Italic'),
            (TextFormat.underline, Icons.format_underlined, 'Underline'),
            (TextFormat.strike, Icons.format_strikethrough, 'Strikethrough'),
            (TextFormat.heading, Icons.title, 'Heading'),
          ])
            Semantics(
              toggled: controller.selected(tool.$1),
              child: IconButton(
                tooltip: tool.$3,
                isSelected: controller.selected(tool.$1),
                onPressed: () {
                  controller.toggle(tool.$1);
                  onAction();
                },
                icon: Icon(tool.$2),
              ),
            ),
          IconButton(
            tooltip: 'Bulleted list',
            onPressed: () {
              controller.prefixLines('bullet');
              onAction();
            },
            icon: const Icon(Icons.format_list_bulleted),
          ),
          IconButton(
            tooltip: 'Numbered list',
            onPressed: () {
              controller.prefixLines('number');
              onAction();
            },
            icon: const Icon(Icons.format_list_numbered),
          ),
          IconButton(
            tooltip: 'Quote',
            onPressed: () {
              controller.prefixLines('quote');
              onAction();
            },
            icon: const Icon(Icons.format_quote),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: controller.canUndo
                ? () {
                    controller.undo();
                    onAction();
                  }
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: controller.canRedo
                ? () {
                    controller.redo();
                    onAction();
                  }
                : null,
            icon: const Icon(Icons.redo),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../models/journal_attachment.dart';

Future<void> viewAttachment(
  BuildContext context,
  JournalAttachment attachment,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: const Color(0xFF14151F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14151F),
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close preview',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(attachment.isDrawing ? 'Drawing' : 'Photo memory'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: .5,
          maxScale: 5,
          child: Image.memory(
            attachment.bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'This image could not be displayed.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  ),
);

class AttachmentGallery extends StatelessWidget {
  const AttachmentGallery({
    super.key,
    required this.attachments,
    this.onRemove,
    this.onEdit,
  });
  final List<JournalAttachment> attachments;
  final ValueChanged<JournalAttachment>? onRemove, onEdit;
  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns =
            attachments.length > 1 && constraints.maxWidth >= 280;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < attachments.length; i++)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label:
                          'Open ${attachments[i].isDrawing ? 'drawing' : 'photo'} ${i + 1}',
                      button: true,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          child: InkWell(
                            onTap: () =>
                                viewAttachment(context, attachments[i]),
                            child: AspectRatio(
                              aspectRatio: attachments.length == 1 ? 1.5 : 1.1,
                              child: Image.memory(
                                attachments[i].bytes,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onRemove != null ||
                        (onEdit != null && attachments[i].isDrawing))
                      Wrap(
                        children: [
                          if (onEdit != null && attachments[i].isDrawing)
                            TextButton.icon(
                              onPressed: () => onEdit!(attachments[i]),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit drawing'),
                            ),
                          if (onRemove != null)
                            TextButton.icon(
                              onPressed: () => onRemove!(attachments[i]),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

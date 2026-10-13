import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/journal_attachment.dart';
import '../widgets/color_picker.dart';

/// Paint notifications stay inside the canvas, never rebuilding the editor.
class InkDocument extends ChangeNotifier {
  InkDocument([List<InkStroke> initial = const []]) : strokes = [...initial];
  final List<InkStroke> strokes;
  final List<InkStroke> _redo = [];
  List<Offset> pending = [];
  InkStroke? active;
  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  void begin(Offset point, Color color, double width, BrushTool tool) {
    pending = [point];
    active = InkStroke.live(
      points: pending,
      color: color,
      width: width,
      tool: tool,
    );
    notifyListeners();
  }

  void move(Offset point) {
    if (active == null) return;
    if (pending.length >= 12000 || (point - pending.last).distance < .001) {
      return;
    }
    pending.add(point);
    notifyListeners();
  }

  void end() {
    if (active == null) return;
    strokes.add(
      InkStroke(
        points: active!.points,
        color: active!.color,
        width: active!.width,
        tool: active!.tool,
      ),
    );
    active = null;
    pending = [];
    _redo.clear();
    notifyListeners();
  }

  void cancelStroke() {
    active = null;
    pending = [];
    notifyListeners();
  }

  void undo() {
    if (strokes.isEmpty) return;
    _redo.add(strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    strokes.add(_redo.removeLast());
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    _redo.clear();
    cancelStroke();
  }
}

class InkPainter extends CustomPainter {
  InkPainter(this.document, this.background) : super(repaint: document);
  final InkDocument document;
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.srcOver);
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in [
      ...document.strokes,
      if (document.active != null) document.active!,
    ]) {
      final opacity = switch (stroke.tool) {
        BrushTool.highlighter => .25,
        BrushTool.pencil => .55,
        _ => 1.0,
      };
      final factor = switch (stroke.tool) {
        BrushTool.marker => 1.8,
        BrushTool.highlighter => 3.5,
        BrushTool.eraser => 3.0,
        _ => 1.0,
      };
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: opacity)
        ..strokeWidth = stroke.width * size.shortestSide * factor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.tool == BrushTool.eraser
            ? BlendMode.clear
            : BlendMode.srcOver;
      final points = stroke.points
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();
      if (points.length == 1) {
        canvas.drawCircle(
          points.first,
          paint.strokeWidth / 2,
          Paint()
            ..color = paint.color
            ..blendMode = paint.blendMode,
        );
      } else if (points.isNotEmpty) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) =>
      oldDelegate.document != document || oldDelegate.background != background;
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key, this.attachment});
  final JournalAttachment? attachment;
  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final InkDocument _ink;
  BrushTool _tool = BrushTool.pen;
  Color? _color;
  double _width = 5;
  Color? _background;
  double? _ratio;
  bool _dirty = false, _saving = false, _allowPop = false;
  int? _pointer;
  @override
  void initState() {
    super.initState();
    _ink = InkDocument(widget.attachment?.drawing?.strokes ?? []);
    _background = widget.attachment?.drawing?.background;
    _ratio = widget.attachment?.drawing?.aspectRatio;
  }

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_saving) return;
    final discard =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard this drawing?'),
                content: const Text('Unsaved strokes will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep drawing'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ) ==
            true;
    if (mounted && discard) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (_saving || _ink.strokes.isEmpty || _ink.active != null) return;
    setState(() => _saving = true);
    ui.Picture? picture;
    ui.Image? image;
    try {
      final ratio = _ratio ?? 1;
      final size = ratio >= 1
          ? Size(1200, 1200 / ratio)
          : Size(1200 * ratio, 1200);
      final recorder = ui.PictureRecorder();
      InkPainter(_ink, _background!).paint(Canvas(recorder), size);
      picture = recorder.endRecording();
      image = await picture.toImage(
        size.width.round().clamp(1, 1200),
        size.height.round().clamp(1, 1200),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || data == null) return;
      final result = JournalAttachment(
        id:
            widget.attachment?.id ??
            'drawing-${DateTime.now().microsecondsSinceEpoch}',
        bytes: data.buffer.asUint8List(),
        drawing: JournalDrawing(
          strokes: _ink.strokes,
          background: _background!,
          aspectRatio: ratio,
        ),
      );
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The drawing could not be prepared. Please try again.',
            ),
          ),
        );
      }
    } finally {
      image?.dispose();
      picture?.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _background ??= Theme.of(context).colorScheme.surface;
    _color ??= Theme.of(context).colorScheme.onSurface;
    return PopScope(
      canPop: _allowPop || !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cancel drawing',
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
          title: const Text('Draw something'),
          actions: [
            ListenableBuilder(
              listenable: _ink,
              builder: (_, _) => IconButton(
                tooltip: 'Save drawing',
                onPressed: _saving || _ink.strokes.isEmpty ? null : _save,
                icon: const Icon(Icons.check),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _ratio ??= constraints.maxWidth / constraints.maxHeight;
                    return Center(
                      child: AspectRatio(
                        aspectRatio: _ratio!,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            Offset normalize(Offset p) => Offset(
                              (p.dx / box.maxWidth).clamp(0, 1),
                              (p.dy / box.maxHeight).clamp(0, 1),
                            );
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: RepaintBoundary(
                                child: Listener(
                                  key: const ValueKey('drawing-canvas'),
                                  onPointerDown: (event) {
                                    if (_saving || _pointer != null) return;
                                    _pointer = event.pointer;
                                    setState(() => _dirty = true);
                                    _ink.begin(
                                      normalize(event.localPosition),
                                      _color!,
                                      _width / box.biggest.shortestSide,
                                      _tool,
                                    );
                                  },
                                  onPointerMove: (event) {
                                    if (event.pointer == _pointer) {
                                      _ink.move(normalize(event.localPosition));
                                    }
                                  },
                                  onPointerUp: (event) {
                                    if (event.pointer == _pointer) {
                                      _ink.end();
                                      _pointer = null;
                                      setState(() {});
                                    }
                                  },
                                  onPointerCancel: (event) {
                                    if (event.pointer == _pointer) {
                                      _ink.cancelStroke();
                                      _pointer = null;
                                    }
                                  },
                                  child: CustomPaint(
                                    painter: InkPainter(_ink, _background!),
                                    size: box.biggest,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            for (final tool in BrushTool.values)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    tool.name[0].toUpperCase() +
                                        tool.name.substring(1),
                                  ),
                                  selected: _tool == tool,
                                  onSelected: (_) =>
                                      setState(() => _tool = tool),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Pen color',
                            onPressed: () async {
                              final result = await chooseColor(
                                context,
                                title: 'Pen color',
                                initial: _color,
                              );
                              if (mounted && result?.color != null) {
                                setState(() => _color = result!.color);
                              }
                            },
                            icon: Icon(Icons.circle, color: _color),
                          ),
                          for (final thickness in [
                            (2.0, 'Thin'),
                            (5.0, 'Medium'),
                            (9.0, 'Thick'),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Tooltip(
                                message: '${thickness.$1.toInt()} pixel stroke',
                                child: ChoiceChip(
                                  label: Text(thickness.$2),
                                  selected: _width == thickness.$1,
                                  onSelected: (_) =>
                                      setState(() => _width = thickness.$1),
                                ),
                              ),
                            ),
                          ListenableBuilder(
                            listenable: _ink,
                            builder: (_, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Undo drawing',
                                  onPressed: _ink.canUndo
                                      ? () {
                                          _ink.undo();
                                          setState(() => _dirty = true);
                                        }
                                      : null,
                                  icon: const Icon(Icons.undo),
                                ),
                                IconButton(
                                  tooltip: 'Redo drawing',
                                  onPressed: _ink.canRedo
                                      ? () {
                                          _ink.redo();
                                          setState(() => _dirty = true);
                                        }
                                      : null,
                                  icon: const Icon(Icons.redo),
                                ),
                                IconButton(
                                  tooltip: 'Clear drawing',
                                  onPressed: _ink.canUndo
                                      ? () async {
                                          final clear = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Clear the canvas?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Clear'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (mounted && clear == true) {
                                            _ink.clear();
                                            setState(() => _dirty = true);
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

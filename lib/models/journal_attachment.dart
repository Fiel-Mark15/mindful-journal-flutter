import 'dart:typed_data';
import 'package:flutter/material.dart';

enum BrushTool { pen, marker, highlighter, pencil, eraser }

class InkStroke {
  InkStroke({
    required List<Offset> points,
    required this.color,
    required this.width,
    required this.tool,
  }) : points = List.unmodifiable(points);
  // The live stroke is private to the drawing session; freeze it on pointer up.
  InkStroke.live({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });
  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'color': color.toARGB32(),
    'width': width,
    'tool': tool.name,
  };
  factory InkStroke.fromJson(Map<String, dynamic> j) => InkStroke(
    points: (j['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
    color: Color(j['color'] as int),
    width: (j['width'] as num).toDouble(),
    tool: BrushTool.values.byName(j['tool'] as String),
  );
  final List<Offset> points; // Normalized coordinates, independent of pixels.
  final Color color;
  final double width; // Fraction of the canvas short side.
  final BrushTool tool;
}

class JournalDrawing {
  JournalDrawing({
    required List<InkStroke> strokes,
    required this.background,
    required this.aspectRatio,
  }) : strokes = List.unmodifiable(strokes);
  Map<String, dynamic> toJson() => {
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'background': background.toARGB32(),
    'aspectRatio': aspectRatio,
  };
  factory JournalDrawing.fromJson(Map<String, dynamic> j) => JournalDrawing(
    strokes: (j['strokes'] as List)
        .map((s) => InkStroke.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
    background: Color(j['background'] as int),
    aspectRatio: (j['aspectRatio'] as num).toDouble(),
  );
  final List<InkStroke> strokes;
  final Color background;
  final double aspectRatio;
}

class JournalAttachment {
  const JournalAttachment({
    required this.id,
    required this.bytes,
    this.drawing,
    this.filePath,
  });
  final String? filePath;
  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'drawing': drawing?.toJson(),
  };
  factory JournalAttachment.fromJson(
    Map<String, dynamic> j, {
    Uint8List? bytes,
  }) => JournalAttachment(
    id: j['id'] as String,
    bytes: bytes ?? Uint8List(0),
    filePath: j['filePath'] as String?,
    drawing: j['drawing'] == null
        ? null
        : JournalDrawing.fromJson(Map<String, dynamic>.from(j['drawing'])),
  );
  final String id;
  final Uint8List bytes;
  final JournalDrawing? drawing;
  bool get isDrawing => drawing != null;
}

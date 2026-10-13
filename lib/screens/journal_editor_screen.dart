import 'package:flutter/cupertino.dart';
import '../core/experience/journal_experience.dart';
import '../widgets/journal_paper.dart';
import '../widgets/saved_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/media/image_import.dart';
import '../models/journal_attachment.dart';
import '../models/checklist_item.dart';
import '../widgets/journal_checklist.dart';
import '../widgets/attachment_gallery.dart';
import '../widgets/color_picker.dart';
import 'drawing_screen.dart';
import '../core/utils/journal_format.dart';
import '../core/editing/journal_text_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/text_format.dart';
import '../widgets/writing_toolbar.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_components.dart';
import '../widgets/mood_selector.dart';

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({
    super.key,
    this.entry,
    this.initialMood,
    this.initialDate,
    this.initialPrompt,
    this.initialInsert,
    this.initialTemplate,
    this.promptId,
    this.kind = EntryKind.text,
    this.embedded = false,
    this.onFinished,
    this.onCommit,
    this.pickImage = chooseJournalImage,
  });
  final JournalEntry? entry;
  final Future<void> Function(JournalEntry)? onCommit;
  final bool embedded;
  final ValueChanged<JournalEntry?>? onFinished;
  final EntryTemplate? initialTemplate;
  final String? promptId;
  final EntryKind kind;
  final Mood? initialMood;
  final DateTime? initialDate;
  final String? initialPrompt;
  final String? initialInsert;
  final Future<Uint8List?> Function() pickImage;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _title;
  late final JournalTextController _content;
  final _bodyFocus = FocusNode();
  bool _focusMode = false;
  bool _focusTools = false, _importing = false, _drawingOpen = false;
  late List<JournalAttachment> _attachments;
  late List<ChecklistItem> _checklist;
  late final TextEditingController _tags;
  bool _showTags = false, _showChecklist = false;
  String? _mediaError;
  late DateTime _date;
  late final DateTime _originalDate;
  Mood? _mood;
  String? _collectionId;
  bool _initializedPreferences = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedPreferences) {
      _collectionId =
          widget.entry?.collectionId ??
          ExperienceScope.preferencesOf(context).collectionId;
      _initializedPreferences = true;
    }
  }

  bool _allowPop = false;
  bool _closing = false;
  bool _saving = false;
  bool _showMoodError = false;

  bool get _dirty =>
      _collectionId !=
          (widget.entry?.collectionId ??
              ExperienceScope.preferencesOf(context).collectionId) ||
      !_sameAttachments() ||
      _checkSignature(_checklist) !=
          _checkSignature(widget.entry?.checklist ?? []) ||
      _tags.text != (widget.entry?.tags.join(', ') ?? '') ||
      _title.text != (widget.entry?.title ?? '') ||
      _content.text != (widget.entry?.content ?? '') ||
      _formatSignature(_content.runs()) !=
          _formatSignature(widget.entry?.formatting ?? []) ||
      _mood != (widget.entry?.mood ?? widget.initialMood) ||
      _date != _originalDate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text:
          widget.entry?.title ??
          (widget.initialTemplate?.sections.isNotEmpty == true
              ? widget.initialTemplate!.name
              : ''),
    );
    _content = JournalTextController(
      text:
          widget.entry?.content ??
          (widget.initialTemplate?.content ??
              (widget.initialPrompt == null
                  ? ''
                  : '${widget.initialPrompt}\n\n')),
      runs: widget.entry?.formatting ?? [],
    );
    _attachments = [...?widget.entry?.attachments];
    _checklist = [...?widget.entry?.checklist];
    _tags = TextEditingController(text: widget.entry?.tags.join(', ') ?? '')
      ..addListener(_changed);
    _showTags = _tags.text.isNotEmpty;
    _showChecklist =
        _checklist.isNotEmpty || widget.initialInsert == 'checklist';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialInsert == 'photo') _addPhoto();
      if (widget.initialInsert == 'draw') _draw();
    });
    _mood = widget.entry?.mood ?? widget.initialMood;
    final date = widget.entry?.date ?? widget.initialDate ?? DateTime.now();
    _date = _originalDate = DateTime(date.year, date.month, date.day);
    _title.addListener(_changed);
    _content.addListener(_changed);
    _bodyFocus.addListener(_changed);
    _bodyFocus.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent ||
          !(HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _content.redo();
        } else {
          _content.undo();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _scroll.dispose();
    _tags.dispose();
    _title.dispose();
    _content.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _finish([JournalEntry? entry]) async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (widget.embedded) {
      widget.onFinished?.call(entry);
    } else {
      Navigator.of(context).pop(entry);
    }
  }

  Future<void> _close() async {
    if (_closing || _saving) return;
    _closing = true;
    if (!_dirty) {
      await _finish();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard your changes?'),
        content: const Text('Your unsaved writing will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _closing = false;
    if (discard == true) await _finish();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _date.isAfter(today) ? _date : today;
    final first = _date.isBefore(DateTime(1900)) ? _date : DateTime(1900);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: last,
    );
    if (mounted && selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (_saving || _closing || _importing) return;
    if (_focusMode && (_title.text.trim().isEmpty || _mood == null)) {
      setState(() => _focusMode = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _showMoodError = _mood == null);
    if (!valid || _mood == null) {
      _bodyFocus.unfocus();
      if (_scroll.hasClients) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _scroll.jumpTo(0);
        } else {
          await _scroll.animateTo(
            0,
            duration: AppMotion.normal,
            curve: AppMotion.curve,
          );
        }
      }
      return;
    }
    _saving = true;
    journalHaptic(context, medium: true);
    final entry = JournalEntry(
      id: widget.entry?.id ?? 'entry-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      content: _content.text.trim(),
      date: _date,
      mood: _mood!,
      formatting: List.unmodifiable(_content.runs(trim: true)),
      attachments: List.unmodifiable(_attachments),
      checklist: List.unmodifiable(
        _checklist.map((item) => item.copyWith(text: item.text.trim())),
      ),
      tags: List.unmodifiable(_parsedTags()),
      isFavorite: widget.entry?.isFavorite ?? false,
      collectionId: _collectionId,
      promptId: widget.entry?.promptId ?? widget.promptId,
      promptText: widget.entry?.promptText ?? widget.initialPrompt,
      kind: widget.entry?.kind ?? widget.kind,
      energy: widget.entry?.energy,
      createdAt: widget.entry == null
          ? DateTime.now()
          : widget.entry!.createdAt ?? widget.entry!.date,
    );
    try {
      await widget.onCommit?.call(entry);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save to this device. Your draft is still here.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {});
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.normal,
    );
    if (mounted) await _finish(entry);
  }

  String _formatSignature(List<TextFormatRun> runs) => runs
      .map(
        (run) =>
            '${run.start}:${run.end}:${run.flags}:${run.color}:${run.highlight}',
      )
      .join('|');
  void _format(int flag) {
    _content.toggle(flag);
    _bodyFocus.requestFocus();
  }

  void _escape() {
    if (_focusMode) {
      setState(() => _focusMode = false);
    } else {
      _close();
    }
  }

  String _checkSignature(List<ChecklistItem> items) => items
      .map((item) => '${item.id}:${item.text}:${item.isCompleted}')
      .join('|');
  List<String> _parsedTags() {
    final result = <String>[];
    for (final tag
        in _tags.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)) {
      if (!result.any((t) => t.toLowerCase() == tag.toLowerCase())) {
        result.add(tag);
      }
    }
    return result;
  }

  bool _sameAttachments() {
    final original = widget.entry?.attachments ?? [];
    if (original.length != _attachments.length) return false;
    for (var i = 0; i < original.length; i++) {
      if (!identical(original[i], _attachments[i])) return false;
    }
    return true;
  }

  Future<void> _addPhoto() async {
    if (_importing || _saving || _closing) return;
    if (_attachments.where((a) => !a.isDrawing).length >= 4) {
      setState(() => _mediaError = 'You can attach up to 4 photos per entry.');
      return;
    }
    setState(() {
      _importing = true;
      _mediaError = null;
    });
    try {
      final bytes = await widget.pickImage();
      if (mounted && bytes != null) {
        setState(
          () => _attachments.add(
            JournalAttachment(
              id: 'photo-${DateTime.now().microsecondsSinceEpoch}',
              bytes: bytes,
            ),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _mediaError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _mediaError =
              'Photo selection is unavailable or access was denied. Try another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _draw([JournalAttachment? attachment]) async {
    if (_importing || _drawingOpen || _saving || _closing) return;
    if (attachment == null &&
        _attachments.where((a) => a.isDrawing).length >= 2) {
      setState(
        () => _mediaError = 'You can attach up to 2 drawings per entry.',
      );
      return;
    }
    _drawingOpen = true;
    _bodyFocus.unfocus();
    final result = await Navigator.of(context).push<JournalAttachment>(
      MaterialPageRoute(builder: (_) => DrawingScreen(attachment: attachment)),
    );
    if (!mounted) return;
    _drawingOpen = false;
    if (result != null) {
      setState(() {
        final index = _attachments.indexWhere((a) => a.id == result.id);
        if (index < 0) {
          _attachments.add(result);
        } else {
          _attachments[index] = result;
        }
        _mediaError = null;
      });
    }
  }

  Future<void> _textColor({bool highlight = false}) async {
    final selection = _content.selection;
    final color = highlight ? _content.currentHighlight : _content.currentColor;
    final result = await chooseColor(
      context,
      title: highlight ? 'Text highlight' : 'Text color',
      initial: color == null ? null : Color(color),
      allowDefault: true,
    );
    if (!mounted || result == null) return;
    _content.selection = selection;
    _content.applyColor(result.color, highlight: highlight);
    _bodyFocus.requestFocus();
  }

  Future<void> _insert() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Add to this moment'),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Checklist'),
                onTap: () => Navigator.pop(context, 'checklist'),
              ),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('Tags'),
                onTap: () => Navigator.pop(context, 'tags'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('Add photo'),
                subtitle: const Text('Up to 4 photos, kept in this session.'),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.draw_outlined),
                title: const Text('Open drawing canvas'),
                onTap: () => Navigator.pop(context, 'draw'),
              ),
              ListTile(
                leading: const Icon(Icons.highlight),
                title: const Text('Text highlight'),
                onTap: () => Navigator.pop(context, 'highlight'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'checklist') {
      setState(() {
        _showChecklist = true;
        if (_checklist.isEmpty) {
          _checklist.add(
            ChecklistItem(
              id: 'check-${DateTime.now().microsecondsSinceEpoch}',
              text: '',
            ),
          );
        }
      });
    }
    if (action == 'tags') setState(() => _showTags = true);
    if (action == 'photo') await _addPhoto();
    if (action == 'draw') await _draw();
    if (action == 'highlight') await _textColor(highlight: true);
  }

  WritingToolbar _toolbar() => WritingToolbar(
    controller: _content,
    onAction: () => _bodyFocus.requestFocus(),
    onInsert: _insert,
    onColor: _textColor,
  );

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactKeyboard =
        MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom <
        300;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
        for (final meta in [true, false]) ...{
          SingleActivator(
            LogicalKeyboardKey.keyB,
            meta: meta,
            control: !meta,
          ): () =>
              _format(TextFormat.bold),
          SingleActivator(
            LogicalKeyboardKey.keyI,
            meta: meta,
            control: !meta,
          ): () =>
              _format(TextFormat.italic),
          SingleActivator(
            LogicalKeyboardKey.keyU,
            meta: meta,
            control: !meta,
          ): () =>
              _format(TextFormat.underline),
          SingleActivator(LogicalKeyboardKey.keyZ, meta: meta, control: !meta):
              _content.undo,
          SingleActivator(
            LogicalKeyboardKey.keyZ,
            meta: meta,
            control: !meta,
            shift: true,
          ): _content.redo,
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope<JournalEntry>(
          canPop: _allowPop || !_dirty,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _close();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Back',
                onPressed: _close,
                icon: const Icon(CupertinoIcons.back),
              ),
              title: Text(
                _focusMode
                    ? 'Focus writing'
                    : widget.entry == null
                    ? 'New entry'
                    : 'Edit entry',
              ),
              actions: [
                if (_focusMode)
                  IconButton(
                    tooltip: 'Show writing tools',
                    isSelected: _focusTools,
                    onPressed: () => setState(() => _focusTools = !_focusTools),
                    icon: const Icon(Icons.text_fields),
                  ),
                IconButton(
                  key: const ValueKey('save-shortcut'),
                  tooltip: 'Save entry',
                  onPressed: _saving || _importing ? null : _save,
                  icon: _saving
                      ? const SavedCheck()
                      : const Icon(CupertinoIcons.checkmark),
                ),
                IconButton(
                  tooltip: _focusMode ? 'Leave focus mode' : 'Focus writing',
                  onPressed: () {
                    setState(() => _focusMode = !_focusMode);
                    _bodyFocus.requestFocus();
                  },
                  icon: Icon(
                    _focusMode
                        ? CupertinoIcons.fullscreen_exit
                        : CupertinoIcons.fullscreen,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: compactKeyboard || (_focusMode && !_focusTools)
                ? null
                : Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: SafeArea(
                      top: false,
                      child: AnimatedSlide(
                        offset: _bodyFocus.hasFocus
                            ? Offset.zero
                            : const Offset(0, .04),
                        duration: AppMotion.duration(context),
                        curve: AppMotion.curve,
                        child: AnimatedOpacity(
                          opacity: _bodyFocus.hasFocus ? 1 : .85,
                          duration: AppMotion.duration(context),
                          child: _toolbar(),
                        ),
                      ),
                    ),
                  ),
            body: JournalCanvas(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  children: [
                    if (!_focusMode)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(CupertinoIcons.calendar, size: 18),
                          label: Text(formatDate(_date)),
                        ),
                      ),
                    if (!_focusMode) ...[
                      const SizedBox(height: 24),
                      Text(
                        'How are you feeling?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      MoodSelector(
                        value: _mood,
                        onChanged: (mood) => setState(() {
                          _mood = mood;
                          _showMoodError = false;
                        }),
                      ),
                      if (_showMoodError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Please choose a mood.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        initialValue: _collectionId ?? 'general',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Collection',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'general',
                            child: Text('General'),
                          ),
                          for (final c in journalCollections)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (id) => setState(
                          () => _collectionId = id == 'general' ? null : id,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const ValueKey('entry-title'),
                        controller: _title,
                        cursorColor: theme.colorScheme.primary,
                        style: theme.textTheme.headlineMedium,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Give this moment a name',
                        ),
                        validator: (value) =>
                            _required(value, 'Please add a title.'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (compactKeyboard && (!_focusMode || _focusTools))
                      _toolbar(),
                    JournalPaper(
                      child: TextFormField(
                        key: const ValueKey('entry-content'),
                        controller: _content,
                        focusNode: _bodyFocus,
                        cursorColor: theme.colorScheme.primary,
                        style: ExperienceScope.preferencesOf(
                          context,
                        ).bodyStyle(context),
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 7,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Your thoughts',
                          hintText: 'Start wherever you are…',
                          alignLabelWithHint: true,
                          border: InputBorder.none,
                        ),
                        validator: (value) => _required(
                          readableJournalText(value ?? ''),
                          'Please write something before saving.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_showTags && !_focusMode) ...[
                      TextFormField(
                        key: const ValueKey('entry-tags'),
                        controller: _tags,
                        maxLength: 240,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'Separate tags with commas',
                        ),
                        validator: (_) =>
                            _parsedTags().length > 8 ||
                                _parsedTags().any((t) => t.length > 24)
                            ? 'Use up to 8 tags, with 24 characters each.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_showChecklist) ...[
                      ChecklistBlock(
                        items: _checklist,
                        onChanged: (items) => setState(() {
                          _checklist
                            ..clear()
                            ..addAll(items);
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_attachments.isNotEmpty) ...[
                      AttachmentGallery(
                        attachments: _attachments,
                        onRemove: (attachment) =>
                            setState(() => _attachments.remove(attachment)),
                        onEdit: _draw,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_focusMode)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _importing ? null : _addPhoto,
                            icon: const Icon(Icons.photo_outlined),
                            label: Text(
                              _importing ? 'Opening picker…' : 'Add photo',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _importing ? null : () => _draw(),
                            icon: const Icon(Icons.draw_outlined),
                            label: const Text('Draw'),
                          ),
                        ],
                      ),
                    if (_mediaError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _mediaError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    if (ExperienceScope.preferencesOf(context).wordCount &&
                        !_focusMode)
                      Text(
                        '${wordCount(_content.text) + _checklist.fold<int>(0, (sum, item) => sum + wordCount(item.text))} words',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 24),
                    AnimatedScale(
                      scale: _saving ? .97 : 1,
                      duration: AppMotion.duration(context),
                      child: FilledButton.icon(
                        key: const ValueKey('save-entry'),
                        onPressed: _saving || _importing ? null : _save,
                        icon: _saving
                            ? const SavedCheck()
                            : const Icon(
                                CupertinoIcons.checkmark_alt,
                                size: 20,
                              ),
                        label: AnimatedSwitcher(
                          duration: AppMotion.duration(context),
                          child: Text(
                            key: ValueKey(_saving),
                            _saving
                                ? 'Saved'
                                : widget.entry == null
                                ? 'Save entry'
                                : 'Save changes',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Entries are saved locally on this device.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

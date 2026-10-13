import 'package:flutter/cupertino.dart';
import '../core/experience/journal_experience.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/journal_format.dart';
import '../core/utils/journal_search.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_components.dart';
import '../widgets/journal_entry_views.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onCreate,
    this.embedded = false,
    this.searchRequest = 0,
    this.initialFilter = const JournalFilter(),
    this.title,
    this.detailBuilder,
    this.editorBuilder,
    this.onChanged,
  });
  final Widget Function(JournalEntry, VoidCallback, VoidCallback)?
  detailBuilder;
  final Widget Function(JournalEntry, VoidCallback)? editorBuilder;
  final ValueChanged<JournalEntry>? onChanged;
  final JournalFilter initialFilter;
  final String? title;
  final bool embedded;
  final int searchRequest;
  final List<JournalEntry> entries;
  final Future<void> Function(JournalEntry) onOpen;
  final Future<void> Function() onCreate;
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  var _list = GlobalKey<AnimatedListState>();
  JournalViewMode _localMode = JournalViewMode.card;
  JournalViewMode? _lastMode;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lastMode != null && _lastMode != _mode) {
      _list = GlobalKey<AnimatedListState>();
    }
    _lastMode = _mode;
  }

  JournalViewMode get _mode =>
      ExperienceScope.maybeOf(context)?.viewMode ?? _localMode;
  void _modeChanged(JournalViewMode mode) {
    if (mode == _mode) return;
    setState(() {
      _list = GlobalKey<AnimatedListState>();
      _localMode = mode;
    });
    ExperienceScope.maybeOf(context)?.setViewMode(mode);
  }

  void _favorite(JournalEntry entry) {
    journalHaptic(context, medium: true);
    widget.onChanged?.call(entry.copyWith(isFavorite: !entry.isFavorite));
    _refresh();
  }

  bool _searching = false;
  String? _selectedId;
  bool _editing = false;
  bool get _split =>
      widget.detailBuilder != null && MediaQuery.sizeOf(context).width >= 1100;
  JournalFilter _filter = const JournalFilter();
  late List<JournalEntry> _visible;
  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _visible = searchJournal(widget.entries, '', _filter);
    _search.addListener(_refresh);
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimelineScreen old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.searchRequest != old.searchRequest) _openSearch();
      _refresh();
    });
  }

  void _refresh() {
    if (!mounted) return;
    if (widget.initialFilter.favorites && !_filter.favorites) {
      _filter = JournalFilter(
        mood: _filter.mood,
        favorites: true,
        photo: _filter.photo,
        drawing: _filter.drawing,
        checklist: _filter.checklist,
        tag: _filter.tag,
        tags: _filter.tags,
        collectionId: _filter.collectionId,
      );
    }
    final next = searchJournal(widget.entries, _search.text, _filter);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    if (_mode != JournalViewMode.card) {
      setState(() => _visible = next);
      return;
    }
    setState(() {
      for (var i = _visible.length - 1; i >= 0; i--) {
        if (!next.any((e) => e.id == _visible[i].id)) {
          final removed = _visible.removeAt(i);
          _list.currentState?.removeItem(
            i,
            (context, animation) => _row(removed, animation),
            duration: duration,
          );
        }
      }
      for (var i = 0; i < next.length; i++) {
        if (i < _visible.length && _visible[i].id == next[i].id) {
          _visible[i] = next[i];
          continue;
        }
        final existing = _visible.indexWhere((e) => e.id == next[i].id);
        if (existing >= 0) {
          final removed = _visible.removeAt(existing);
          _list.currentState?.removeItem(
            existing,
            (context, animation) => _row(removed, animation),
            duration: duration,
          );
        }
        _visible.insert(i, next[i]);
        _list.currentState?.insertItem(i, duration: duration);
      }
    });
  }

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeSearch() {
    ExperienceScope.maybeOf(context)?.rememberSearch(_search.text);
    _search.clear();
    setState(() => _searching = false);
    _focus.unfocus();
  }

  Future<void> _open(JournalEntry entry) async {
    ExperienceScope.maybeOf(context)?.rememberSearch(_search.text);
    if (_split) {
      setState(() => _selectedId = entry.id);
      return;
    }
    await widget.onOpen(entry);
    if (mounted) _refresh();
  }

  Future<void> _create() async {
    await widget.onCreate();
    if (mounted) _refresh();
  }

  Future<void> _filters() async {
    final result = await showModalBottomSheet<JournalFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _FilterSheet(
        filter: _filter,
        favoritesLocked: widget.initialFilter.favorites,
        tags: widget.entries.expand((e) => e.tags).toSet().toList()..sort(),
      ),
    );
    if (mounted && result != null) {
      _filter = result;
      _refresh();
    }
  }

  Widget _row(
    JournalEntry entry,
    Animation<double> animation, {
    bool compact = false,
  }) => SizeTransition(
    sizeFactor: animation,
    child: FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .03),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_visible.indexWhere((e) => e.id == entry.id) <= 0 ||
                  monthLabel(
                        _visible[_visible.indexWhere((e) => e.id == entry.id) -
                                1]
                            .date,
                      ) !=
                      monthLabel(entry.date))
                Text(
                  monthLabel(entry.date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              if (compact)
                CompactEntryTile(
                  entry: entry,
                  onTap: () => _open(entry),
                  query: _search.text,
                  onFavorite: widget.onChanged == null
                      ? null
                      : () => _favorite(entry),
                )
              else
                EntryCard(
                  entry: entry,
                  onFavorite: widget.onChanged == null
                      ? null
                      : () => _favorite(entry),
                  onTap: () => _open(entry),
                  query: _search.text,
                ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _openSearch,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          _openSearch,
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_searching) _closeSearch();
      },
    },
    child: Focus(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          title: AnimatedSwitcher(
            duration: AppMotion.duration(context),
            child: _searching
                ? TextField(
                    key: const ValueKey('journal-search'),
                    controller: _search,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search your journal…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    widget.title ??
                        (widget.embedded ? 'Journal' : 'All entries'),
                  ),
          ),
          actions: [
            IconButton(
              tooltip: _searching ? 'Close search' : 'Search journal',
              onPressed: _searching ? _closeSearch : _openSearch,
              icon: Icon(_searching ? Icons.close : Icons.search),
            ),
            IconButton(
              tooltip: 'Filter journal',
              isSelected: _filter.active,
              onPressed: _filters,
              icon: Icon(
                _filter.active ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
            ),
            Semantics(
              label: 'Journal view mode, ${_mode.name} selected',
              child: PopupMenuButton<JournalViewMode>(
                tooltip: 'Journal view mode',
                icon: Icon(switch (_mode) {
                  JournalViewMode.list => Icons.view_list_outlined,
                  JournalViewMode.card => Icons.view_agenda_outlined,
                  JournalViewMode.grid => Icons.grid_view,
                }),
                onSelected: _modeChanged,
                itemBuilder: (_) => [
                  for (final mode in JournalViewMode.values)
                    PopupMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${mode.name[0].toUpperCase()}${mode.name.substring(1)} View',
                            ),
                          ),
                          if (mode == _mode) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!widget.embedded && MediaQuery.sizeOf(context).width >= 400)
              IconButton(
                tooltip: 'New entry',
                onPressed: _create,
                icon: const Icon(CupertinoIcons.add),
              ),
          ],
        ),
        body: _archiveLayout(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in [
                            (null, 'All'),
                            ('general', 'General'),
                            ...journalCollections.map((c) => (c.id, c.name)),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c.$2),
                                selected: _filter.collectionId == c.$1,
                                onSelected: (_) {
                                  _filter = JournalFilter(
                                    mood: _filter.mood,
                                    favorites: _filter.favorites,
                                    photo: _filter.photo,
                                    drawing: _filter.drawing,
                                    checklist: _filter.checklist,
                                    tag: _filter.tag,
                                    tags: _filter.tags,
                                    collectionId: c.$1,
                                  );
                                  _refresh();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_searching && _search.text.isEmpty)
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final query
                              in ExperienceScope.maybeOf(
                                    context,
                                  )?.recentSearches ??
                                  <String>[])
                            ActionChip(
                              label: Text(query),
                              onPressed: () => _search.text = query,
                            ),
                          if (ExperienceScope.maybeOf(
                                context,
                              )?.recentSearches.isEmpty ??
                              true)
                            ActionChip(
                              label: const Text('Suggested: favorites'),
                              onPressed: () {
                                _filter = const JournalFilter(favorites: true);
                                _refresh();
                              },
                            ),
                        ],
                      ),
                    Text(
                      '${_visible.length} ${_visible.length == 1 ? 'entry' : 'entries'} · This session',
                    ),
                    if (_filter.mood != null ||
                        _filter.photo ||
                        _filter.drawing ||
                        _filter.checklist ||
                        _filter.tag != null ||
                        _filter.tags.isNotEmpty ||
                        _filter.collectionId != null ||
                        (_filter.favorites && !widget.initialFilter.favorites))
                      TextButton(
                        onPressed: () {
                          _filter = const JournalFilter();
                          _refresh();
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ),
              if (_visible.isEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child:
                        widget.entries.isEmpty &&
                            _search.text.trim().isEmpty &&
                            !_filter.active
                        ? JournalEmptyState(onCreate: _create)
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No matches yet.'),
                              SizedBox(height: 8),
                              Text('Try another word or remove a filter.'),
                            ],
                          ),
                  ),
                )
              else
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.duration(context),
                    child: KeyedSubtree(
                      key: ValueKey(_mode),
                      child: _entriesView(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _entriesView() {
    if (_mode == JournalViewMode.card) {
      return AnimatedList(
        key: _list,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        initialItemCount: _visible.length,
        itemBuilder: (context, index, animation) => index < _visible.length
            ? _row(_visible[index], animation)
            : const SizedBox.shrink(),
      );
    }
    if (_mode == JournalViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        itemCount: _visible.length,
        itemBuilder: (context, index) => _row(
          _visible[index],
          const AlwaysStoppedAnimation(1),
          compact: true,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 48;
        final columns = (width / 210).floor().clamp(2, 4);
        final cardWidth = (width - 12 * (columns - 1)) / columns;
        final scaler = MediaQuery.textScalerOf(context);
        final extent =
            cardWidth / 1.6 +
            scaler.scale(14) * 2.6 +
            scaler.scale(12) * 3.2 +
            76;
        final months = <String, List<JournalEntry>>{};
        for (final entry in _visible) {
          months.putIfAbsent(monthLabel(entry.date), () => []).add(entry);
        }
        return CustomScrollView(
          slivers: [
            for (final group in months.entries) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    group.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: extent,
                  ),
                  itemCount: group.value.length,
                  itemBuilder: (context, index) {
                    final entry = group.value[index];
                    return GridEntryCard(
                      entry: entry,
                      query: _search.text,
                      onTap: () => _open(entry),
                      onFavorite: widget.onChanged == null
                          ? null
                          : () => _favorite(entry),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        );
      },
    );
  }

  Widget _archiveLayout(BuildContext context, Widget list) {
    if (!_split) return JournalCanvas(child: list);
    final selected = entryWithId(widget.entries, _selectedId ?? '');
    if (selected == null && _mode == JournalViewMode.grid) return list;
    return Row(
      children: [
        SizedBox(
          width: 380,
          child: AbsorbPointer(absorbing: _editing, child: list),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? const Center(child: Text('Choose a moment to read.'))
              : _editing && widget.editorBuilder != null
              ? widget.editorBuilder!(selected, () {
                  setState(() => _editing = false);
                  _refresh();
                })
              : widget.detailBuilder!(selected, () {
                  setState(() => _selectedId = null);
                  _refresh();
                }, () => setState(() => _editing = true)),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.filter,
    required this.tags,
    this.favoritesLocked = false,
  });
  final bool favoritesLocked;
  final JournalFilter filter;
  final List<String> tags;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Mood? _mood;
  late bool _favorites, _photo, _drawing, _checklist;
  late Set<String> _tags;
  @override
  void initState() {
    super.initState();
    _mood = widget.filter.mood;
    _favorites = widget.filter.favorites;
    _photo = widget.filter.photo;
    _drawing = widget.filter.drawing;
    _checklist = widget.filter.checklist;
    _tags = {
      ...widget.filter.tags,
      if (widget.filter.tag != null) widget.filter.tag!,
    };
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter your journal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Any mood'),
                selected: _mood == null,
                onSelected: (_) => setState(() => _mood = null),
              ),
              for (final mood in Mood.values)
                ChoiceChip(
                  label: Text(moodInfo[mood]!.label),
                  selected: _mood == mood,
                  onSelected: (_) => setState(() => _mood = mood),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorites only'),
            value: _favorites,
            onChanged: widget.favoritesLocked
                ? null
                : (v) => setState(() => _favorites = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has photo'),
            value: _photo,
            onChanged: (v) => setState(() => _photo = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has drawing'),
            value: _drawing,
            onChanged: (v) => setState(() => _drawing = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has checklist'),
            value: _checklist,
            onChanged: (v) => setState(() => _checklist = v),
          ),
          if (widget.tags.isNotEmpty) ...[
            const Text('Tags · Match all selected'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Clear tags'),
                  onPressed: () => setState(() => _tags.clear()),
                ),
                for (final tag in widget.tags)
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, const JournalFilter()),
                child: const Text('Reset filters'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  JournalFilter(
                    mood: _mood,
                    favorites: _favorites,
                    photo: _photo,
                    drawing: _drawing,
                    checklist: _checklist,
                    tags: _tags.toList(),
                    collectionId: widget.filter.collectionId,
                  ),
                ),
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

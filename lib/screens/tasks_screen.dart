import 'package:flutter/material.dart';
import '../core/experience/journal_experience.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/journal_format.dart';
import '../core/utils/journal_streak.dart';
import '../models/journal_task.dart';
import '../widgets/journal_checklist.dart';
import '../widgets/journal_components.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.experience, this.onReflect});
  final JournalExperience experience;
  final VoidCallback? onReflect;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Set<String> _moving = {};
  Future<void> _toggle(JournalTask task) async {
    if (!_moving.add(task.id)) return;
    // Keep the row in its section while its existing check animation finishes.
    widget.experience.saveTask(task.withCompletion(!task.isCompleted));
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.normal,
    );
    if (mounted) setState(() => _moving.remove(task.id));
  }

  Future<void> _edit([JournalTask? task]) async {
    final result = await showModalBottomSheet<JournalTask>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => _TaskEditor(task: task),
    );
    if (mounted && result != null) widget.experience.saveTask(result);
  }

  Future<void> _delete(JournalTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) widget.experience.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.experience,
    builder: (context, _) {
      final tasks = orderedTasks(widget.experience.tasks);
      final groups = <TaskGroup, List<JournalTask>>{
        for (final group in TaskGroup.values) group: [],
      };
      for (final task in tasks) {
        final original = _moving.contains(task.id)
            ? task.withCompletion(!task.isCompleted)
            : task;
        groups[taskGroup(original)]!.add(task);
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          actions: [
            IconButton(
              tooltip: 'Create task',
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: JournalCanvas(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Small actions for your day. Journal checklists stay inside their entries.',
              ),
              const SizedBox(height: 24),
              if (tasks.isEmpty) ...[
                Text(
                  'Nothing waiting for you.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create a task'),
                  ),
                ),
              ],
              for (final group in TaskGroup.values)
                if (groups[group]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(switch (group) {
                      TaskGroup.today => 'Today',
                      TaskGroup.upcoming => 'Upcoming',
                      TaskGroup.undated => 'Undated',
                      TaskGroup.completed => 'Completed',
                    }, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final task in groups[group]!)
                    Card(
                      key: ValueKey('task-${task.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            AnimatedChecklistCheck(
                              label: task.title,
                              checked: task.isCompleted,
                              onToggle: () => _toggle(task),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _edit(task),
                                child: AnimatedOpacity(
                                  duration: AppMotion.duration(context),
                                  opacity: task.isCompleted ? .65 : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        if (task.dueDate != null ||
                                            task.category != null)
                                          Text(
                                            [
                                              if (task.dueDate != null)
                                                '${journalDay(task.dueDate!) < journalDay(DateTime.now()) && !task.isCompleted ? 'Overdue · ' : ''}${formatDate(task.dueDate!)}',
                                              if (task.category != null)
                                                task.category!,
                                            ].join(' · '),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Task actions',
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _edit(task);
                                } else {
                                  _delete(task);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit task'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete task'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              if (widget.onReflect != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton.icon(
                    onPressed: widget.onReflect,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Reflect on today'),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({this.task});
  final JournalTask? task;
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  DateTime? _due;
  String? _category;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _due = widget.task?.dueDate;
    _category = widget.task?.category;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _date() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (mounted && selected != null) setState(() => _due = selected);
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    journalHaptic(context, medium: true);
    Navigator.pop(
      context,
      JournalTask(
        id: widget.task?.id ?? 'task-${now.microsecondsSinceEpoch}',
        title: _title.text.trim(),
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? now,
        dueDate: _due,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task == null ? 'New task' : 'Edit task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('task-title'),
              controller: _title,
              maxLength: 160,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Task title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Add a task title.' : null,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _date,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _due == null ? 'Add due date' : formatDate(_due!),
                  ),
                ),
                if (_due != null)
                  IconButton(
                    tooltip: 'Remove due date',
                    onPressed: () => setState(() => _due = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _category ?? 'none',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category · Optional',
              ),
              items: [
                const DropdownMenuItem(value: 'none', child: Text('None')),
                for (final category in [
                  'Personal',
                  'College',
                  'Work',
                  'Health',
                  'Creative',
                ])
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) =>
                  setState(() => _category = value == 'none' ? null : value),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: _save, child: const Text('Save task')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

import '../core/utils/journal_streak.dart';

class JournalTask {
  const JournalTask({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.dueDate,
    this.category,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'category': category,
  };
  factory JournalTask.fromJson(Map<String, dynamic> j) => JournalTask(
    id: j['id'] as String,
    title: j['title'] as String,
    isCompleted: j['isCompleted'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
    dueDate: j['dueDate'] == null
        ? null
        : DateTime.parse(j['dueDate'] as String),
    category: j['category'] as String?,
  );
  final String id, title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? category;
  JournalTask withCompletion(bool completed) => JournalTask(
    id: id,
    title: title,
    createdAt: createdAt,
    isCompleted: completed,
    dueDate: dueDate,
    category: category,
  );
}

enum TaskGroup { today, upcoming, undated, completed }

TaskGroup taskGroup(JournalTask task, {DateTime? now}) {
  if (task.isCompleted) return TaskGroup.completed;
  if (task.dueDate == null) return TaskGroup.undated;
  return journalDay(task.dueDate!) <= journalDay(now ?? DateTime.now())
      ? TaskGroup.today
      : TaskGroup.upcoming;
}

List<JournalTask> orderedTasks(Iterable<JournalTask> tasks) =>
    tasks.toList()..sort((a, b) {
      final due = (a.dueDate ?? DateTime(9999)).compareTo(
        b.dueDate ?? DateTime(9999),
      );
      return due == 0 ? a.createdAt.compareTo(b.createdAt) : due;
    });

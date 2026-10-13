class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCompleted': isCompleted,
  };
  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
    id: j['id'] as String,
    text: j['text'] as String,
    isCompleted: j['isCompleted'] as bool? ?? false,
  );
  final String id, text;
  final bool isCompleted;
  ChecklistItem copyWith({String? text, bool? isCompleted}) => ChecklistItem(
    id: id,
    text: text ?? this.text,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final bool isCompleted;
  final String priority;
  final String listId;
  final String assignedTo;
  final String createdBy;
  final bool isFavorite;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.isCompleted = false,
    this.priority = 'medium',
    required this.listId,
    required this.assignedTo,
    required this.createdBy,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority,
      'listId': listId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 'medium',
      listId: map['listId'],
      assignedTo: map['assignedTo'],
      createdBy: map['createdBy'],
      isFavorite: map['isFavorite'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    String? priority,
    String? listId,
    String? assignedTo,
    String? createdBy,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      listId: listId ?? this.listId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
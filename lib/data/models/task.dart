import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String listId;
  final Timestamp? deadline;
  final String priority;
  final String createdBy;
  final String? assignedTo;
  final bool isCompleted;
  final bool isFavorite;
  final Timestamp createdAt;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.listId,
    this.deadline,
    this.priority = 'medium',
    required this.createdBy,
    this.assignedTo,
    this.isCompleted = false,
    this.isFavorite = false,
    Timestamp? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? Timestamp.now();

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      listId: map['listId'],
      deadline: map['deadline'],
      priority: map['priority'] ?? 'medium',
      createdBy: map['createdBy'],
      assignedTo: map['assignedTo'],
      isCompleted: map['isCompleted'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'listId': listId,
      'deadline': deadline,
      'priority': priority,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? listId,
    Timestamp? deadline,
    String? priority,
    String? createdBy,
    String? assignedTo,
    bool? isCompleted,
    bool? isFavorite,
    Timestamp? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      listId: listId ?? this.listId,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    listId,
    deadline,
    priority,
    createdBy,
    assignedTo,
    isCompleted,
    isFavorite,
    createdAt,
  ];
}
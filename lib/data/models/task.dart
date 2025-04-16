import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String listId;
  final Timestamp? deadline;
  final String? priority;
  final String ownerId;
  final String assignedTo;
  final bool isCompleted;
  final bool isFavorite;
  final Timestamp createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.listId,
    this.deadline,
    this.priority,
    required this.ownerId,
    required this.assignedTo,
    required this.isCompleted,
    required this.isFavorite,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? listId,
    Timestamp? deadline,
    String? priority,
    String? ownerId,
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
      ownerId: ownerId ?? this.ownerId,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      listId: map['listId'] ?? '',
      deadline: map['deadline'],
      priority: map['priority'],
      ownerId: map['ownerId'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
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
      'ownerId': ownerId,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    listId,
    deadline,
    priority,
    ownerId,
    assignedTo,
    isCompleted,
    isFavorite,
    createdAt,
  ];
}
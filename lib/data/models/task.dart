import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String listId;
  final String ownerId;
  final String? ownerUsername; // Новое поле
  final Timestamp createdAt;
  final Timestamp? deadline;
  final String? priority;
  final String assignedTo;
  final bool isCompleted;
  final bool isFavorite;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.listId,
    required this.ownerId,
    this.ownerUsername, // Новое поле
    Timestamp? createdAt,
    this.deadline,
    this.priority,
    required this.assignedTo,
    required this.isCompleted,
    required this.isFavorite,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? Timestamp.now();

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? '',
      description: map['description'],
      listId: map['listId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerUsername: map['ownerUsername'], // Новое поле
      createdAt: map['createdAt'] ?? Timestamp.now(),
      deadline: map['deadline'],
      priority: map['priority'],
      assignedTo: map['assignedTo'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'listId': listId,
      'ownerId': ownerId,
      'ownerUsername': ownerUsername, // Новое поле
      'createdAt': createdAt,
      'deadline': deadline,
      'priority': priority,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? listId,
    String? ownerId,
    String? ownerUsername, // Новое поле
    Timestamp? createdAt,
    Timestamp? deadline,
    String? priority,
    String? assignedTo,
    bool? isCompleted,
    bool? isFavorite,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      listId: listId ?? this.listId,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername, // Новое поле
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    listId,
    ownerId,
    ownerUsername, // Новое поле
    createdAt,
    deadline,
    priority,
    assignedTo,
    isCompleted,
    isFavorite,
  ];
}
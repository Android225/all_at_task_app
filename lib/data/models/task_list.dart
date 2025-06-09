import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TaskList extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String? description;
  final int? color;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final Map<String, String> members;
  final List<String> sharedLists;
  final List<String> pendingInvitees; // Добавлено поле

  const TaskList({
    required this.id,
    required this.name,
    required this.ownerId,
    this.description,
    this.color,
    required this.createdAt,
    this.lastUsed,
    this.members = const {},
    this.sharedLists = const [],
    this.pendingInvitees = const [], // Инициализация по умолчанию
  });

  TaskList copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? description,
    int? color,
    DateTime? createdAt,
    DateTime? lastUsed,
    Map<String, String>? members,
    List<String>? sharedLists,
    List<String>? pendingInvitees, // Добавлен параметр
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      members: members ?? this.members,
      sharedLists: sharedLists ?? this.sharedLists,
      pendingInvitees: pendingInvitees ?? this.pendingInvitees, // Добавлено
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'description': description,
      'color': color,
      'createdAt': createdAt,
      'lastUsed': lastUsed,
      'members': members,
      'sharedLists': sharedLists,
      'pendingInvitees': pendingInvitees, // Добавлено в маппинг
    };
  }

  static TaskList fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      description: map['description'] as String?,
      color: map['color'] as int?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUsed: map['lastUsed'] != null ? (map['lastUsed'] as Timestamp).toDate() : null,
      members: Map<String, String>.from(map['members'] ?? {}),
      sharedLists: List<String>.from(map['sharedLists'] ?? []),
      pendingInvitees: List<String>.from(map['pendingInvitees'] ?? []), // Добавлено
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ownerId,
    description,
    color,
    createdAt,
    lastUsed,
    members,
    sharedLists,
    pendingInvitees, // Добавлено в props
  ];
}
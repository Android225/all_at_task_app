import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class TaskList extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final Timestamp createdAt;
  final Timestamp? lastUsed;
  final String? description;
  final int color;
  final List<String> sharedLists;
  final Map<String, String> members;

  TaskList({
    String? id,
    required this.name,
    required this.ownerId,
    Timestamp? createdAt,
    this.lastUsed,
    this.description,
    this.color = 0xFF2196F3,
    this.sharedLists = const [],
    this.members = const {},
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? Timestamp.now();

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      name: map['name'],
      ownerId: map['ownerId'],
      createdAt: map['createdAt'],
      lastUsed: map['lastUsed'],
      description: map['description'],
      color: map['color'] ?? 0xFF2196F3,
      sharedLists: List<String>.from(map['sharedLists'] ?? []),
      members: Map<String, String>.from(map['members'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'lastUsed': lastUsed,
      'description': description,
      'color': color,
      'sharedLists': sharedLists,
      'members': members,
    };
  }

  @override
  List<Object?> get props => [id, name, ownerId, createdAt, lastUsed, description, color, sharedLists, members];
}
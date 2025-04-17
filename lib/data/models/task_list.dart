import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TaskList extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String ownerId;
  final Map<String, String> members;
  final List<String> sharedLists;
  final List<String> linkedLists;
  final Timestamp? createdAt;

  const TaskList({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.ownerId,
    required this.members,
    required this.sharedLists,
    required this.linkedLists,
    required this.createdAt,
  });

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String?,
      ownerId: map['ownerId'] as String,
      members: Map<String, String>.from(map['members'] as Map),
      sharedLists: List<String>.from(map['sharedLists'] ?? []),
      linkedLists: List<String>.from(map['linkedLists'] ?? []),
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'ownerId': ownerId,
      'members': members,
      'sharedLists': sharedLists,
      'linkedLists': linkedLists,
      'createdAt': createdAt,
    };
  }

  TaskList copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? ownerId,
    Map<String, String>? members,
    List<String>? sharedLists,
    List<String>? linkedLists,
    Timestamp? createdAt,
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      sharedLists: sharedLists ?? this.sharedLists,
      linkedLists: linkedLists ?? this.linkedLists,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    color,
    ownerId,
    members,
    sharedLists,
    linkedLists,
    createdAt,
  ];
}
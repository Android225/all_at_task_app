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

  const TaskList({
    required this.id,
    required this.name,
    required this.ownerId,
    this.description,
    this.color,
    required this.createdAt,
    this.lastUsed,
    required this.members,
    required this.sharedLists,
  });

  factory TaskList.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('members') || !map.containsKey('sharedLists')) {
      print('TaskList.fromMap: Missing fields in map: $map');
    }
    return TaskList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      description: map['description'],
      color: map['color'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (map['lastUsed'] as Timestamp?)?.toDate(),
      members: Map<String, String>.from(map['members'] ?? {}),
      sharedLists: List<String>.from(map['sharedLists'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'description': description,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'members': members,
      'sharedLists': sharedLists,
    };
  }

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
  ];
}
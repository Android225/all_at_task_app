import 'package:cloud_firestore/cloud_firestore.dart';

class TaskList {
  final String id;
  final String name;
  final String ownerId;
  final List<String> participants;
  final List<String> roles;
  final DateTime createdAt;

  TaskList({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.participants,
    required this.roles,
    required this.createdAt,
  });

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      roles: List<String>.from(map['roles'] ?? []),
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'participants': participants,
      'roles': roles,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class TaskList extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final Timestamp createdAt;

  TaskList({
    String? id,
    required this.name,
    required this.ownerId,
    Timestamp? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? Timestamp.now();

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      name: map['name'],
      ownerId: map['ownerId'],
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, name, ownerId, createdAt];
}
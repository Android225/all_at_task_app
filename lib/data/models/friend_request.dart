import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class FriendRequest extends Equatable {
  final String id;
  final String userId1;
  final String userId2;
  final String status;
  final Timestamp createdAt;

  const FriendRequest({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? const Uuid().v4(),
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'status': status,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, userId1, userId2, status, createdAt];
}
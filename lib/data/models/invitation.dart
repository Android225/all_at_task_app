import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Invitation extends Equatable {
  final String id;
  final String listId;
  final String inviteeId;
  final String inviterId;
  final String status;
  final Timestamp createdAt;

  const Invitation({
    required this.id,
    required this.listId,
    required this.inviteeId,
    required this.inviterId,
    required this.status,
    required this.createdAt,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] ?? const Uuid().v4(),
      listId: map['listId'] ?? '',
      inviteeId: map['inviteeId'] ?? '',
      inviterId: map['inviterId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'inviteeId': inviteeId,
      'inviterId': inviterId,
      'status': status,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, listId, inviteeId, inviterId, status, createdAt];
}
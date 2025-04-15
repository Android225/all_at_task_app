class TaskList {
  final String id;
  final String name;
  final String ownerId;
  final List<String> participants;
  final List<Map<String, dynamic>> roles;
  final String? parentListId;
  final DateTime createdAt;

  TaskList({
    required this.id,
    required this.name,
    required this.ownerId,
    this.participants = const [],
    this.roles = const [],
    this.parentListId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'participants': participants,
      'roles': roles,
      'parentListId': parentListId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      name: map['name'],
      ownerId: map['ownerId'],
      participants: List<String>.from(map['participants'] ?? []),
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? []),
      parentListId: map['parentListId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
class Group {
  final int? id;
  final String name;
  final int? leaderId;
  final int points;
  final String createdAt;
  final List<int> memberIds;

  Group({
    this.id,
    required this.name,
    this.leaderId,
    this.points = 0,
    required this.createdAt,
    this.memberIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'leader_id': leaderId,
      'points': points,
      'created_at': createdAt,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      leaderId: map['leader_id'],
      points: map['points'] ?? 0,
      createdAt: map['created_at'],
    );
  }

  Group copyWith({
    int? id,
    String? name,
    int? leaderId,
    int? points,
    String? createdAt,
    List<int>? memberIds,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      leaderId: leaderId ?? this.leaderId,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

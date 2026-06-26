class Member {
  final int? id;
  final String name;
  final String? birthdate;
  final String? interests;
  final String? responsibility;
  final String? description;
  final String? avatar;
  final int points;
  final String createdAt;

  Member({
    this.id,
    required this.name,
    this.birthdate,
    this.interests,
    this.responsibility,
    this.description,
    this.avatar,
    this.points = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthdate': birthdate,
      'interests': interests,
      'responsibility': responsibility,
      'description': description,
      'avatar': avatar,
      'points': points,
      'created_at': createdAt,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      birthdate: map['birthdate'],
      interests: map['interests'],
      responsibility: map['responsibility'],
      description: map['description'],
      avatar: map['avatar'],
      points: map['points'] ?? 0,
      createdAt: map['created_at'],
    );
  }

  Member copyWith({
    int? id,
    String? name,
    String? birthdate,
    String? interests,
    String? responsibility,
    String? description,
    String? avatar,
    int? points,
    String? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      interests: interests ?? this.interests,
      responsibility: responsibility ?? this.responsibility,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

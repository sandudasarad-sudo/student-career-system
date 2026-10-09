class SkillModel {
  final String id;
  final String userId;
  final String skillName;
  final String level; // "Beginner", "Intermediate", "Advanced", "Expert"
  final DateTime? createdAt;

  SkillModel({
    required this.id,
    required this.userId,
    required this.skillName,
    required this.level,
    this.createdAt,
  });

  String get name => skillName;
  String get proficiency => level;
  String get category => 'Technical';

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      skillName: (json['skillName'] ?? '').toString(),
      level: (json['level'] ?? 'Beginner').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'skillName': skillName, 'level': level};
  }

  static const List<String> allowedLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];
}

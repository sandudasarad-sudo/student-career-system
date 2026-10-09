class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> technologies;
  final String? role;
  final String? githubUrl;
  final String? liveUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // "Planned", "In Progress", "Completed"
  final DateTime? createdAt;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.technologies = const [],
    this.role,
    this.githubUrl,
    this.liveUrl,
    this.startDate,
    this.endDate,
    this.status = 'In Progress',
    this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTech = [];
    if (json['technologies'] != null && json['technologies'] is List) {
      parsedTech = (json['technologies'] as List)
          .map((item) => item.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ProjectModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      technologies: parsedTech,
      role: json['role']?.toString(),
      githubUrl: json['githubUrl']?.toString(),
      liveUrl: json['liveUrl']?.toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      status: (json['status'] ?? 'In Progress').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'technologies': technologies,
      'status': status,
    };
    if (role != null && role!.isNotEmpty) data['role'] = role;
    if (githubUrl != null && githubUrl!.isNotEmpty) {
      data['githubUrl'] = githubUrl;
    }
    if (liveUrl != null && liveUrl!.isNotEmpty) data['liveUrl'] = liveUrl;
    if (startDate != null) data['startDate'] = startDate!.toIso8601String();
    if (endDate != null) data['endDate'] = endDate!.toIso8601String();
    return data;
  }

  static const List<String> allowedStatuses = [
    'Planned',
    'In Progress',
    'Completed',
  ];
}

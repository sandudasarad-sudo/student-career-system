class JobModel {
  final String id;
  final String createdBy;
  final String title;
  final String company;
  final String? location;
  final String jobType;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final num? salaryMin;
  final num? salaryMax;
  final DateTime applicationDeadline;
  final String? externalApplyUrl;
  final bool isActive;
  final DateTime? createdAt;

  JobModel({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.company,
    this.location,
    required this.jobType,
    required this.description,
    this.requirements = const [],
    this.skills = const [],
    this.salaryMin,
    this.salaryMax,
    required this.applicationDeadline,
    this.externalApplyUrl,
    this.isActive = true,
    this.createdAt,
  });

  bool get isExpired => applicationDeadline.isBefore(DateTime.now());

  String get salaryText {
    if (salaryMin != null && salaryMax != null) {
      return '₹$salaryMin - ₹$salaryMax';
    } else if (salaryMin != null) {
      return 'From ₹$salaryMin';
    } else if (salaryMax != null) {
      return 'Up to ₹$salaryMax';
    }
    return 'Not specified';
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedReq = [];
    if (json['requirements'] != null && json['requirements'] is List) {
      parsedReq = (json['requirements'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> parsedSkills = [];
    if (json['skills'] != null && json['skills'] is List) {
      parsedSkills = (json['skills'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return JobModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      location: json['location']?.toString(),
      jobType: (json['jobType'] ?? 'Full-time').toString(),
      description: (json['description'] ?? '').toString(),
      requirements: parsedReq,
      skills: parsedSkills,
      salaryMin: json['salaryMin'] != null
          ? num.tryParse(json['salaryMin'].toString())
          : null,
      salaryMax: json['salaryMax'] != null
          ? num.tryParse(json['salaryMax'].toString())
          : null,
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.tryParse(json['applicationDeadline'].toString()) ??
                DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      externalApplyUrl: json['externalApplyUrl']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] : true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'company': company,
      'jobType': jobType,
      'description': description,
      'requirements': requirements,
      'skills': skills,
      'applicationDeadline': applicationDeadline.toIso8601String(),
      'isActive': isActive,
    };
    if (location != null && location!.isNotEmpty) data['location'] = location;
    if (salaryMin != null) data['salaryMin'] = salaryMin;
    if (salaryMax != null) data['salaryMax'] = salaryMax;
    if (externalApplyUrl != null && externalApplyUrl!.isNotEmpty) {
      data['externalApplyUrl'] = externalApplyUrl;
    }
    return data;
  }

  static const List<String> allowedJobTypes = [
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Remote',
  ];
}

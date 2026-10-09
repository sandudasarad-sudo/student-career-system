class EducationModel {
  final String id;
  final String userId;
  final String degree;
  final String institution;
  final String? branch;
  final int? startYear;
  final int? endYear;
  final double? cgpa;
  final String? educationLevel; // "10th", "12th", "Diploma", "Bachelor's", "Master's", "PhD", "Other"
  final DateTime? createdAt;

  EducationModel({
    required this.id,
    required this.userId,
    required this.degree,
    required this.institution,
    this.branch,
    this.startYear,
    this.endYear,
    this.cgpa,
    this.educationLevel,
    this.createdAt,
  });

  String? get fieldOfStudy => branch;

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      degree: (json['degree'] ?? '').toString(),
      institution: (json['institution'] ?? '').toString(),
      branch: json['branch']?.toString(),
      startYear: json['startYear'] != null
          ? int.tryParse(json['startYear'].toString())
          : null,
      endYear: json['endYear'] != null
          ? int.tryParse(json['endYear'].toString())
          : null,
      cgpa: json['cgpa'] != null
          ? double.tryParse(json['cgpa'].toString())
          : null,
      educationLevel: json['educationLevel']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'degree': degree,
      'institution': institution,
    };
    if (branch != null && branch!.isNotEmpty) data['branch'] = branch;
    if (startYear != null) data['startYear'] = startYear;
    if (endYear != null) data['endYear'] = endYear;
    if (cgpa != null) data['cgpa'] = cgpa;
    if (educationLevel != null && educationLevel!.isNotEmpty) {
      data['educationLevel'] = educationLevel;
    }
    return data;
  }

  static const List<String> allowedEducationLevels = [
    "10th",
    "12th",
    "Diploma",
    "Bachelor's",
    "Master's",
    "PhD",
    "Other",
  ];
}

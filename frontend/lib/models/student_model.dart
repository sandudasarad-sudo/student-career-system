class StudentModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? college;
  final String? branch;
  final int? year;
  final double? cgpa;
  final List<String> skills;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.college,
    this.branch,
    this.year,
    this.cgpa,
    this.skills = const [],
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String parsedUserId = '';
    if (json['userId'] is Map) {
      parsedUserId = (json['userId']['_id'] ?? json['userId']['id'] ?? '')
          .toString();
    } else {
      parsedUserId = (json['userId'] ?? '').toString();
    }

    double? parsedCgpa;
    if (json['cgpa'] != null) {
      parsedCgpa = double.tryParse(json['cgpa'].toString());
    }

    int? parsedYear;
    if (json['year'] != null) {
      parsedYear = int.tryParse(json['year'].toString());
    }

    List<String> parsedSkills = [];
    if (json['skills'] != null && json['skills'] is List) {
      parsedSkills = (json['skills'] as List)
          .map((item) => item.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return StudentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: parsedUserId,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender']?.toString(),
      college: json['college']?.toString(),
      branch: json['branch']?.toString(),
      year: parsedYear,
      cgpa: parsedCgpa,
      skills: parsedSkills,
      address: json['address']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name, 'email': email};
    if (phone != null && phone!.isNotEmpty) data['phone'] = phone;
    if (dateOfBirth != null) {
      data['dateOfBirth'] = dateOfBirth!.toIso8601String();
    }
    if (gender != null && gender!.isNotEmpty) data['gender'] = gender;
    if (college != null && college!.isNotEmpty) data['college'] = college;
    if (branch != null && branch!.isNotEmpty) data['branch'] = branch;
    if (year != null) data['year'] = year;
    if (cgpa != null) data['cgpa'] = cgpa;
    if (skills.isNotEmpty) data['skills'] = skills;
    if (address != null && address!.isNotEmpty) data['address'] = address;
    return data;
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "student" or "admin"
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStudent => role.toLowerCase() == 'student';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'student').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

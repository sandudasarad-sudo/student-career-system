class CertificationModel {
  final String id;
  final String userId;
  final String title;
  final String issuer;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? description;
  final DateTime? createdAt;

  CertificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.issuer,
    required this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
    this.description,
    this.createdAt,
  });

  String get name => title;
  String get issuingOrganization => issuer;

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      issuer: (json['issuer'] ?? '').toString(),
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      credentialId: json['credentialId']?.toString(),
      credentialUrl: json['credentialUrl']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'issuer': issuer,
      'issueDate': issueDate.toIso8601String(),
    };
    if (expiryDate != null) {
      data['expiryDate'] = expiryDate!.toIso8601String();
    }
    if (credentialId != null && credentialId!.isNotEmpty) {
      data['credentialId'] = credentialId;
    }
    if (credentialUrl != null && credentialUrl!.isNotEmpty) {
      data['credentialUrl'] = credentialUrl;
    }
    if (description != null && description!.isNotEmpty) {
      data['description'] = description;
    }
    return data;
  }
}

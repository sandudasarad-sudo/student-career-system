import 'education_model.dart';
import 'skill_model.dart';
import 'project_model.dart';
import 'certification_model.dart';

class ResumeModel {
  final String id;
  final String userId;
  final String? careerObjective;
  final String? summary;
  final List<EducationModel> educations;
  final List<SkillModel> skills;
  final List<ProjectModel> projects;
  final List<CertificationModel> certifications;
  final List<String> achievements;
  final List<String> languages;
  final String? resumeUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ResumeModel({
    required this.id,
    required this.userId,
    this.careerObjective,
    this.summary,
    this.educations = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.achievements = const [],
    this.languages = const [],
    this.resumeUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get templateName => 'Standard ATS';

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    List<EducationModel> parsedEdu = [];
    if (json['educationIds'] != null && json['educationIds'] is List) {
      for (var item in json['educationIds']) {
        if (item is Map<String, dynamic>) {
          parsedEdu.add(EducationModel.fromJson(item));
        }
      }
    }

    List<SkillModel> parsedSkills = [];
    if (json['skillIds'] != null && json['skillIds'] is List) {
      for (var item in json['skillIds']) {
        if (item is Map<String, dynamic>) {
          parsedSkills.add(SkillModel.fromJson(item));
        }
      }
    }

    List<ProjectModel> parsedProj = [];
    if (json['projectIds'] != null && json['projectIds'] is List) {
      for (var item in json['projectIds']) {
        if (item is Map<String, dynamic>) {
          parsedProj.add(ProjectModel.fromJson(item));
        }
      }
    }

    List<CertificationModel> parsedCerts = [];
    if (json['certificationIds'] != null && json['certificationIds'] is List) {
      for (var item in json['certificationIds']) {
        if (item is Map<String, dynamic>) {
          parsedCerts.add(CertificationModel.fromJson(item));
        }
      }
    }

    List<String> parsedAch = [];
    if (json['achievements'] != null && json['achievements'] is List) {
      parsedAch = (json['achievements'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> parsedLang = [];
    if (json['languages'] != null && json['languages'] is List) {
      parsedLang = (json['languages'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return ResumeModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      careerObjective: json['careerObjective']?.toString(),
      summary: json['summary']?.toString(),
      educations: parsedEdu,
      skills: parsedSkills,
      projects: parsedProj,
      certifications: parsedCerts,
      achievements: parsedAch,
      languages: parsedLang,
      resumeUrl: json['resumeUrl']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] : true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toRequestJson({
    List<String>? educationIds,
    List<String>? skillIds,
    List<String>? projectIds,
    List<String>? certificationIds,
  }) {
    final Map<String, dynamic> data = {
      'careerObjective': careerObjective ?? '',
      'summary': summary ?? '',
      'achievements': achievements,
      'languages': languages,
      'isActive': isActive,
    };
    if (educationIds != null) data['educationIds'] = educationIds;
    if (skillIds != null) data['skillIds'] = skillIds;
    if (projectIds != null) data['projectIds'] = projectIds;
    if (certificationIds != null) data['certificationIds'] = certificationIds;
    if (resumeUrl != null && resumeUrl!.isNotEmpty) {
      data['resumeUrl'] = resumeUrl;
    }
    return data;
  }
}

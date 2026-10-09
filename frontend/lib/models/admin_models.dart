import 'user_model.dart';
import 'student_model.dart';
import 'skill_model.dart';
import 'education_model.dart';
import 'project_model.dart';
import 'certification_model.dart';
import 'resume_model.dart';
import 'application_model.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int totalAdmins;

  final int studentsWithProfile;
  final int totalResumes;
  final int studentsWithCgpa;
  final double averageCgpa;

  final int totalSkills;
  final int totalEducationRecords;
  final int totalProjects;
  final int totalCertifications;

  final int totalJobs;
  final int activeJobs;
  final int inactiveJobs;
  final int expiredJobs;

  final int totalApplications;
  final Map<String, int> applicationStatusCounts;

  final List<ApplicationModel> recentApplications;
  final List<UserModel> recentStudents;

  AdminDashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalAdmins,
    required this.studentsWithProfile,
    required this.totalResumes,
    required this.studentsWithCgpa,
    required this.averageCgpa,
    required this.totalSkills,
    required this.totalEducationRecords,
    required this.totalProjects,
    required this.totalCertifications,
    required this.totalJobs,
    required this.activeJobs,
    required this.inactiveJobs,
    required this.expiredJobs,
    required this.totalApplications,
    required this.applicationStatusCounts,
    required this.recentApplications,
    required this.recentStudents,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    final profiles = json['profiles'] as Map<String, dynamic>? ?? {};
    final career = json['careerData'] as Map<String, dynamic>? ?? {};
    final jobs = json['jobs'] as Map<String, dynamic>? ?? {};
    final apps = json['applications'] as Map<String, dynamic>? ?? {};

    Map<String, int> statusCounts = {
      'Applied': int.tryParse(apps['Applied']?.toString() ?? '0') ?? 0,
      'Under Review':
          int.tryParse(apps['Under Review']?.toString() ?? '0') ?? 0,
      'Shortlisted': int.tryParse(apps['Shortlisted']?.toString() ?? '0') ?? 0,
      'Selected': int.tryParse(apps['Selected']?.toString() ?? '0') ?? 0,
      'Rejected': int.tryParse(apps['Rejected']?.toString() ?? '0') ?? 0,
      'Withdrawn': int.tryParse(apps['Withdrawn']?.toString() ?? '0') ?? 0,
    };

    List<ApplicationModel> recentApps = [];
    if (json['recentApplications'] != null &&
        json['recentApplications'] is List) {
      for (var item in json['recentApplications']) {
        if (item is Map<String, dynamic>) {
          recentApps.add(ApplicationModel.fromJson(item));
        }
      }
    }

    List<UserModel> recentStuds = [];
    if (json['recentStudents'] != null && json['recentStudents'] is List) {
      for (var item in json['recentStudents']) {
        if (item is Map<String, dynamic>) {
          recentStuds.add(UserModel.fromJson(item));
        }
      }
    }

    return AdminDashboardStats(
      totalUsers: int.tryParse(users['total']?.toString() ?? '0') ?? 0,
      totalStudents: int.tryParse(users['students']?.toString() ?? '0') ?? 0,
      totalAdmins: int.tryParse(users['admins']?.toString() ?? '0') ?? 0,
      studentsWithProfile:
          int.tryParse(profiles['studentsWithProfile']?.toString() ?? '0') ?? 0,
      totalResumes: int.tryParse(profiles['resumes']?.toString() ?? '0') ?? 0,
      studentsWithCgpa:
          int.tryParse(profiles['studentsWithCgpa']?.toString() ?? '0') ?? 0,
      averageCgpa:
          double.tryParse(profiles['averageCgpa']?.toString() ?? '0.0') ?? 0.0,
      totalSkills: int.tryParse(career['skills']?.toString() ?? '0') ?? 0,
      totalEducationRecords:
          int.tryParse(career['educationRecords']?.toString() ?? '0') ?? 0,
      totalProjects: int.tryParse(career['projects']?.toString() ?? '0') ?? 0,
      totalCertifications:
          int.tryParse(career['certifications']?.toString() ?? '0') ?? 0,
      totalJobs: int.tryParse(jobs['total']?.toString() ?? '0') ?? 0,
      activeJobs: int.tryParse(jobs['active']?.toString() ?? '0') ?? 0,
      inactiveJobs: int.tryParse(jobs['inactive']?.toString() ?? '0') ?? 0,
      expiredJobs: int.tryParse(jobs['expired']?.toString() ?? '0') ?? 0,
      totalApplications: int.tryParse(apps['total']?.toString() ?? '0') ?? 0,
      applicationStatusCounts: statusCounts,
      recentApplications: recentApps,
      recentStudents: recentStuds,
    );
  }
}

class ConsolidatedStudentDetails {
  final UserModel user;
  final StudentModel? student;
  final List<SkillModel> skills;
  final List<EducationModel> education;
  final List<ProjectModel> projects;
  final List<CertificationModel> certifications;
  final ResumeModel? resume;
  final List<ApplicationModel> applications;

  ConsolidatedStudentDetails({
    required this.user,
    this.student,
    this.skills = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.resume,
    this.applications = const [],
  });

  factory ConsolidatedStudentDetails.fromJson(Map<String, dynamic> json) {
    return ConsolidatedStudentDetails(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      student: json['student'] != null
          ? StudentModel.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      skills: (json['skills'] as List? ?? [])
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      education: (json['education'] as List? ?? [])
          .map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      projects: (json['projects'] as List? ?? [])
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      certifications: (json['certifications'] as List? ?? [])
          .map((e) => CertificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      resume: json['resume'] != null
          ? ResumeModel.fromJson(json['resume'] as Map<String, dynamic>)
          : null,
      applications: (json['applications'] as List? ?? [])
          .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

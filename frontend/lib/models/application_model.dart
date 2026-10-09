import 'job_model.dart';
import 'resume_model.dart';

class ApplicationModel {
  final String id;
  final String userId;
  final String? applicantName;
  final String? applicantEmail;
  final String jobId;
  final JobModel? job;
  final String resumeId;
  final ResumeModel? resume;
  final String? coverLetter;
  final String status;
  final DateTime appliedAt;
  final String? adminNotes;
  final DateTime? createdAt;

  ApplicationModel({
    required this.id,
    required this.userId,
    this.applicantName,
    this.applicantEmail,
    required this.jobId,
    this.job,
    required this.resumeId,
    this.resume,
    this.coverLetter,
    this.status = 'Applied',
    required this.appliedAt,
    this.adminNotes,
    this.createdAt,
  });

  bool get isWithdrawn => status == 'Withdrawn';
  bool get canWithdraw =>
      status != 'Withdrawn' && status != 'Selected' && status != 'Rejected';

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    String parsedUserId = '';
    String? parsedApplicantName;
    String? parsedApplicantEmail;

    if (json['userId'] is Map<String, dynamic>) {
      final userMap = json['userId'] as Map<String, dynamic>;
      parsedUserId = (userMap['_id'] ?? userMap['id'] ?? '').toString();
      parsedApplicantName = userMap['name']?.toString();
      parsedApplicantEmail = userMap['email']?.toString();
    } else {
      parsedUserId = (json['userId'] ?? '').toString();
    }

    String parsedJobId = '';
    JobModel? parsedJob;
    if (json['jobId'] is Map<String, dynamic>) {
      final jobMap = json['jobId'] as Map<String, dynamic>;
      parsedJobId = (jobMap['_id'] ?? jobMap['id'] ?? '').toString();
      parsedJob = JobModel.fromJson(jobMap);
    } else {
      parsedJobId = (json['jobId'] ?? '').toString();
    }

    String parsedResumeId = '';
    ResumeModel? parsedResume;
    if (json['resumeId'] is Map<String, dynamic>) {
      final resumeMap = json['resumeId'] as Map<String, dynamic>;
      parsedResumeId = (resumeMap['_id'] ?? resumeMap['id'] ?? '').toString();
      parsedResume = ResumeModel.fromJson(resumeMap);
    } else {
      parsedResumeId = (json['resumeId'] ?? '').toString();
    }

    return ApplicationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: parsedUserId,
      applicantName: parsedApplicantName,
      applicantEmail: parsedApplicantEmail,
      jobId: parsedJobId,
      job: parsedJob,
      resumeId: parsedResumeId,
      resume: parsedResume,
      coverLetter: json['coverLetter']?.toString(),
      status: (json['status'] ?? 'Applied').toString(),
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      adminNotes: json['adminNotes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static const List<String> adminAllowedStatuses = [
    'Applied',
    'Under Review',
    'Shortlisted',
    'Selected',
    'Rejected',
    'Withdrawn',
  ];
}

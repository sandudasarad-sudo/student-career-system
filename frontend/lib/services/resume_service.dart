import '../config/api_config.dart';
import '../models/resume_model.dart';
import 'api_service.dart';

class ResumeService {
  Future<ResumeModel?> getMyResume() async {
    try {
      final response = await ApiService.get(ApiConfig.resumeMy);
      if (response is Map && response['data'] != null) {
        return ResumeModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ResumeModel> createResume({
    String? careerObjective,
    String? summary,
    List<String> educationIds = const [],
    List<String> skillIds = const [],
    List<String> projectIds = const [],
    List<String> certificationIds = const [],
    List<String> achievements = const [],
    List<String> languages = const [],
    String? resumeUrl,
    bool isActive = true,
  }) async {
    final response = await ApiService.post(
      ApiConfig.resume,
      body: {
        'careerObjective': careerObjective ?? '',
        'summary': summary ?? '',
        'educationIds': educationIds,
        'skillIds': skillIds,
        'projectIds': projectIds,
        'certificationIds': certificationIds,
        'achievements': achievements,
        'languages': languages,
        if (resumeUrl != null && resumeUrl.isNotEmpty) 'resumeUrl': resumeUrl,
        'isActive': isActive,
      },
    );
    if (response is Map && response['data'] != null) {
      return ResumeModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create resume.');
  }

  Future<ResumeModel> updateResume(
    String id, {
    String? careerObjective,
    String? summary,
    List<String>? educationIds,
    List<String>? skillIds,
    List<String>? projectIds,
    List<String>? certificationIds,
    List<String>? achievements,
    List<String>? languages,
    String? resumeUrl,
    bool? isActive,
  }) async {
    final Map<String, dynamic> body = {};
    if (careerObjective != null) body['careerObjective'] = careerObjective;
    if (summary != null) body['summary'] = summary;
    if (educationIds != null) body['educationIds'] = educationIds;
    if (skillIds != null) body['skillIds'] = skillIds;
    if (projectIds != null) body['projectIds'] = projectIds;
    if (certificationIds != null) body['certificationIds'] = certificationIds;
    if (achievements != null) body['achievements'] = achievements;
    if (languages != null) body['languages'] = languages;
    if (resumeUrl != null) body['resumeUrl'] = resumeUrl;
    if (isActive != null) body['isActive'] = isActive;

    final response = await ApiService.put(ApiConfig.resumeById(id), body: body);
    if (response is Map && response['data'] != null) {
      return ResumeModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update resume.');
  }

  Future<void> deleteResume(String id) async {
    await ApiService.delete(ApiConfig.resumeById(id));
  }
}
